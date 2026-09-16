module ProjectPercentDone
  module History
    class StagingDemo
      SOURCE = 'staging_test'.freeze
      PROJECT_IDENTIFIER = 'ppd-history-test'.freeze
      PROJECT_NAME = 'PPD History Staging Test'.freeze
      CONFIRMATION = 'STAGING_DEMO_HISTORY'.freeze
      ISSUE_PREFIX = '[PPD DEMO]'.freeze
      ISSUE_BLUEPRINTS = [
        ['Project initiation and requirements', 20, 100],
        ['Solution design', 20, 100],
        ['Core implementation', 40, 80],
        ['Integration and data migration', 50, 60],
        ['Verification and acceptance', 50, 30],
        ['Deployment and handover', 20, 10]
      ].freeze
      PROGRESS_FACTORS = {
        0 => 0.12, 1 => 0.20, 5 => 0.34, 8 => 0.43, 9 => 0.52,
        10 => 0.61, 11 => 0.70, 12 => 0.78, 13 => 0.86, 14 => 0.93,
        15 => 1.0
      }.freeze

      Result = Struct.new(
        :action, :project, :snapshots, :issue_snapshots, :runs, :message,
        keyword_init: true
      )

      def initialize(action:, confirmation:, host_name: nil, today: nil)
        @action = action.to_s
        @confirmation = confirmation.to_s
        @host_name = (host_name || Setting.host_name).to_s.downcase.sub(/:\d+\z/, '')
        @today = today || Time.zone.today
      end

      def call
        validate_safety!
        return preview if action == 'preview'

        action == 'seed' ? seed : cleanup
      end

      private

      attr_reader :action, :confirmation, :host_name, :today

      def validate_safety!
        raise ArgumentError, 'ACTION must be preview, seed, or cleanup' unless %w[preview seed cleanup].include?(action)
        raise ArgumentError, "CONFIRM must equal #{CONFIRMATION}" unless confirmation == CONFIRMATION
        raise ArgumentError, "Refusing non-staging host: #{host_name}" unless %w[redminestaging.gcr.bg www.redminestaging.gcr.bg].include?(host_name)
      end

      def preview
        project = Project.find_by(:identifier => PROJECT_IDENTIFIER)
        Result.new(
          :action => action,
          :project => project,
          :snapshots => project ? project_snapshots(project).count : 0,
          :issue_snapshots => project ? project_issue_snapshots(project).count : 0,
          :runs => demo_runs.count,
          :message => project ? 'Demo project exists.' : 'Demo project will be created.'
        )
      end

      def seed
        project = find_or_create_project
        ensure_demo_project_owned!(project)
        remove_demo_data(project)
        dates = demo_periods
        plan = demo_plan(dates)
        apply_demo_project_fields(project, plan)
        issues = recreate_demo_issues(project)
        recreate_demo_time_entries(project, issues, plan)
        calculation = ProjectPercentDone::ProjectProgressCalculator.new(project, :mode => :details).call
        validate_live_progress!(calculation)

        disabled_date = dates[2]
        missing_date = dates[6]
        create_run(disabled_date, 'disabled', 0, 0)

        snapshots = 0
        issue_snapshots = 0
        dates.each_with_index do |period_end, index|
          next if [disabled_date, missing_date].include?(period_end)

          state = demo_state(index)
          run = create_run(period_end, 'successful', 1, state == 'active' ? issues.size : 0)
          progress = state == 'active' ? historical_progress(calculation, index) : nil
          snapshot = create_snapshot(project, run, period_end, index, state, progress, plan)
          snapshots += 1
          issue_snapshots += create_issue_snapshots(snapshot, progress[:rows]) if state == 'active'
        end

        Result.new(
          :action => action,
          :project => project,
          :snapshots => snapshots,
          :issue_snapshots => issue_snapshots,
          :runs => demo_runs.count,
          :message => format(
            'Synthetic staging history created: live %d%%, %.0f estimated hours, %.0f reported hours.',
            calculation.percent_done,
            calculation.known_estimated_hours,
            TimeEntry.where(:project_id => project.id).sum(:hours)
          )
        )
      end

      def cleanup
        project = Project.find_by(:identifier => PROJECT_IDENTIFIER)
        return Result.new(:action => action, :snapshots => 0, :issue_snapshots => 0, :runs => 0, :message => 'Demo project does not exist.') unless project

        ensure_demo_project_owned!(project)
        snapshots = project_snapshots(project).count
        issue_snapshots = project_issue_snapshots(project).count
        runs = demo_runs.count
        remove_demo_data(project)

        Result.new(
          :action => action,
          :project => project,
          :snapshots => snapshots,
          :issue_snapshots => issue_snapshots,
          :runs => runs,
          :message => 'Synthetic history removed; the demo project and issues were kept.'
        )
      end

      def find_or_create_project
        project = Project.find_or_initialize_by(:identifier => PROJECT_IDENTIFIER)
        if project.new_record?
          project.name = PROJECT_NAME
          project.is_public = false
          project.enabled_module_names = %w[issue_tracking time_tracking]
          project.custom_field_values = required_project_custom_field_values(project)
          project.save!
        elsif (%w[issue_tracking time_tracking] - project.enabled_module_names).any?
          project.enabled_module_names = (project.enabled_module_names + %w[issue_tracking time_tracking]).uniq
          project.save!
        end
        project
      end

      def required_project_custom_field_values(project)
        project.available_custom_fields.select(&:is_required?).each_with_object({}) do |field, values|
          value = demo_custom_field_value(field, project)
          if value.blank? || (value.is_a?(Array) && value.all?(&:blank?))
            raise "Required project custom field #{field.name.inspect} has no usable demo value."
          end

          values[field.id.to_s] = field.multiple? ? Array(value) : Array(value).first
        end
      end

      def demo_custom_field_value(field, project)
        return field.default_value if field.default_value.present?

        option = field.possible_values_options(project).find do |candidate|
          custom_field_option_value(candidate).present?
        end
        return custom_field_option_value(option) if option

        case field.field_format
        when 'bool'
          '0'
        when 'date'
          today.iso8601
        when 'int', 'float'
          '1'
        when 'string', 'text', 'link'
          'STAGING DEMO'
        end
      end

      def custom_field_option_value(option)
        option.is_a?(Array) ? option.last : option
      end

      def ensure_demo_project_owned!(project)
        unless project.name == PROJECT_NAME && !project.is_public?
          raise "Project #{PROJECT_IDENTIFIER} is not the protected demo project; refusing to modify it."
        end

        ensure_work_items_are_demo_only!(project)
      end

      def remove_demo_data(project)
        project_snapshots(project).destroy_all
        demo_runs.delete_all
      end

      def ensure_work_items_are_demo_only!(project)
        foreign_issue = Issue.where(:project_id => project.id)
                             .where.not('subject LIKE ?', "#{ISSUE_PREFIX}%")
                             .exists?
        return unless foreign_issue

        raise "Project #{PROJECT_IDENTIFIER} contains non-demo issues; refusing to replace its work items."
      end

      def recreate_demo_issues(project)
        old_issues = Issue.where(:project_id => project.id).where('subject LIKE ?', "#{ISSUE_PREFIX}%")
        TimeEntry.where(:issue_id => old_issues.select(:id)).delete_all
        old_issues.destroy_all

        tracker = Tracker.sorted.first || raise('No tracker is available for demo issues.')
        project.trackers << tracker unless project.trackers.exists?(tracker.id)
        status = IssueStatus.where(:is_closed => false).sorted.first || raise('No open issue status is available.')
        priority = IssuePriority.where(:is_default => true).first || IssuePriority.first || raise('No issue priority is available.')
        author = User.active.where(:admin => true).first || raise('No active administrator is available.')

        ISSUE_BLUEPRINTS.map do |name, estimated_hours, done_ratio|
          Issue.create!(
            :project => project,
            :tracker => tracker,
            :status => status,
            :priority => priority,
            :author => author,
            :subject => "#{ISSUE_PREFIX} #{name}",
            :estimated_hours => estimated_hours,
            :done_ratio => done_ratio
          )
        end
      end

      def recreate_demo_time_entries(project, issues, plan)
        activity = project.activities.first || raise('No active time-entry activity is available.')
        user = User.active.where(:admin => true).first || raise('No active administrator is available.')
        start_date = plan[:changed_start]
        entries = [
          [0, start_date - 2.days, 4], [0, start_date + 5.days, 10], [0, start_date + 12.days, 8],
          [1, start_date + 10.days, 8], [1, start_date + 20.days, 12],
          [2, start_date + 25.days, 12], [2, start_date + 40.days, 12], [2, start_date + 55.days, 12],
          [3, start_date + 45.days, 10], [3, start_date + 60.days, 10], [3, start_date + 68.days, 10],
          [4, start_date + 65.days, 6], [4, plan[:changed_end] - 5.days, 6], [4, plan[:changed_end] + 5.days, 6],
          [5, plan[:changed_end] + 8.days, 6]
        ]

        entries.each do |issue_index, spent_on, hours|
          entry = TimeEntry.new(
            :project => project,
            :issue => issues.fetch(issue_index),
            :user => user,
            :author => user,
            :activity => activity,
            :spent_on => spent_on,
            :hours => hours,
            :comments => 'PPD staging demo history'
          )
          entry.custom_field_values = required_custom_field_values(entry)
          entry.save!
        end
      end

      def required_custom_field_values(record)
        record.available_custom_fields.select(&:is_required?).each_with_object({}) do |field, values|
          value = demo_custom_field_value(field, record)
          if value.blank? || (value.is_a?(Array) && value.all?(&:blank?))
            raise "Required #{record.class.name} custom field #{field.name.inspect} has no usable demo value."
          end

          values[field.id.to_s] = field.multiple? ? Array(value) : Array(value).first
        end
      end

      def apply_demo_project_fields(project, plan)
        values = {}
        type_field = ProjectPercentDone::Settings.history_project_type_custom_field
        selected_type = ProjectPercentDone::Settings.history_project_type_values.first
        values[type_field.id.to_s] = type_field.multiple? ? [selected_type] : selected_type if type_field && selected_type

        start_field = ProjectPercentDone::Settings.history_project_start_custom_field
        end_field = ProjectPercentDone::Settings.history_project_planned_end_custom_field
        values[start_field.id.to_s] = plan[:changed_start].iso8601 if start_field
        values[end_field.id.to_s] = plan[:changed_end].iso8601 if end_field
        return if values.empty?

        project.custom_field_values = values
        project.save!
        project.reload
      end

      def validate_live_progress!(calculation)
        return if calculation.percent_done.between?(55, 65)

        raise "Demo issues produced #{calculation.percent_done}% live progress; expected approximately 60%. Check the configured done-ratio mode."
      end

      def demo_periods
        last_sunday = today - today.wday
        (0...16).map { |offset| last_sunday - (15 - offset).weeks }
      end

      def demo_plan(dates)
        {
          :original_start => dates.first + 14.days,
          :changed_start => dates.first + 21.days,
          :original_end => dates.last + 28.days,
          :changed_end => dates.last - 14.days
        }
      end

      def demo_state(index)
        return 'closed' if [3, 4].include?(index)
        return 'out_of_scope' if index == 7

        'active'
      end

      def create_run(period_end, status, snapshots, details)
        captured_at = Time.zone.local(period_end.year, period_end.month, period_end.day, 23, 55)
        ProjectPercentDoneCollectionRun.create!(
          :source => SOURCE,
          :status => status,
          :snapshot_type => status == 'disabled' ? nil : 'official',
          :target_period_end => period_end,
          :started_at => captured_at,
          :completed_at => captured_at + 20.seconds,
          :projects_processed => snapshots,
          :projects_succeeded => snapshots,
          :snapshots_created => snapshots,
          :snapshots_promoted => snapshots,
          :issue_snapshots_created => details,
          :email_status => 'not_attempted',
          :duration_ms => 20_000,
          :errors_list => []
        )
      end

      def create_snapshot(project, run, period_end, index, state, progress, plan)
        active = state == 'active'
        start_date = index >= 10 ? plan[:changed_start] : plan[:original_start]
        end_date = index >= 11 ? plan[:changed_end] : plan[:original_end]
        planned_days = (end_date - start_date).to_i
        elapsed_days = (period_end - start_date).to_i
        elapsed_percent = planned_days.positive? ? (elapsed_days.to_f / planned_days * 100) : nil
        elapsed_percent = [[elapsed_percent, 0].max, 100].min if elapsed_percent
        after_end = period_end > end_date
        time = demo_time_metrics(project, period_end, start_date, end_date)
        plan_phase = if period_end < start_date
                       progress && progress[:raw_percent].positive? ? 'pre_start_activity' : 'planned_not_started'
                     elsif after_end
                       active ? 'overdue_active' : 'after_planned_end'
                     else
                       'within_planned_period'
                     end

        ProjectPercentDoneSnapshot.create!(
          :project => project,
          :collection_run => run,
          :officialized_by_run => run,
          :snapshot_kind => 'official',
          :period_end => period_end,
          :captured_at => run.started_at,
          :project_state => state,
          :snapshot_source => 'direct',
          :timing => 'on_time',
          :deviation_seconds => 0,
          :project_type_values => demo_project_type_values,
          :project_start_date => start_date,
          :project_planned_end_date => end_date,
          :plan_calendar_mode => 'calendar_days_v1',
          :first_observed_plan => index.zero?,
          :start_date_changed => index == 10,
          :planned_end_date_changed => index == 11,
          :start_date_change_days => index == 10 ? 7 : nil,
          :planned_end_date_change_days => index == 11 ? -42 : nil,
          :planned_duration_days => planned_days,
          :elapsed_plan_days => elapsed_days,
          :elapsed_plan_percent => elapsed_percent,
          :schedule_variance_points => active && elapsed_percent ? progress[:raw_percent] - elapsed_percent : nil,
          :days_overdue => after_end ? (period_end - end_date).to_i : nil,
          :spent_hours_total => time[:total],
          :time_entry_count => time[:count],
          :hours_before_start => time[:before],
          :hours_within_plan => time[:within],
          :hours_after_planned_end => time[:after],
          :hours_unclassified => time[:unclassified],
          :first_time_entry_on => time[:first_on],
          :last_time_entry_on => time[:last_on],
          :pre_start_activity => plan_phase == 'pre_start_activity',
          :post_end_activity => time[:after].positive?,
          :plan_phase => plan_phase,
          :display_percent_done => active ? progress[:display_percent] : nil,
          :raw_percent_done => active ? progress[:raw_percent] : nil,
          :all_project_issue_count => active ? progress[:calculation].all_project_issue_count : nil,
          :eligible_issue_count => active ? progress[:calculation].eligible_issue_count : nil,
          :included_issue_count => active ? progress[:calculation].included_issue_count : nil,
          :not_included_issue_count => active ? progress[:calculation].not_included_issue_count : nil,
          :estimated_issue_count => active ? progress[:calculation].estimated_issue_count : nil,
          :unestimated_issue_count => active ? progress[:calculation].unestimated_issue_count : nil,
          :estimated_eligible_issue_count => active ? progress[:calculation].estimated_eligible_issue_count : nil,
          :unestimated_eligible_issue_count => active ? progress[:calculation].unestimated_eligible_issue_count : nil,
          :known_estimated_hours => active ? progress[:calculation].known_estimated_hours : nil,
          :total_weight => active ? progress[:calculation].total_weight : nil,
          :imputed_weight => active ? progress[:calculation].imputed_weight : nil,
          :estimate_coverage_percent => active ? progress[:calculation].estimate_coverage_percent : nil,
          :warnings => demo_warnings(plan_phase, time),
          :calculation_settings => ProjectPercentDone::Settings.history_calculation_settings,
          :algorithm_version => ProjectPercentDone::ALGORITHM_VERSION,
          :plugin_version => ProjectPercentDone::PLUGIN_VERSION,
          :rounding_mode => ProjectPercentDone::Settings.rounding_mode
        )
      end

      def demo_warnings(plan_phase, time)
        warnings = []
        warnings << 'progress_before_project_start' if plan_phase == 'pre_start_activity'
        warnings << 'hours_before_project_start' if time[:before].positive?
        warnings << 'hours_after_planned_end' if time[:after].positive?
        warnings
      end

      def demo_project_type_values
        ProjectPercentDone::Settings.history_project_type_values.presence || ['STAGING DEMO']
      end

      def historical_progress(calculation, index)
        factor = PROGRESS_FACTORS.fetch(index)
        rows = calculation.included_rows.map do |row|
          original = (row.original_done_ratio.to_f * factor).round(4)
          effective = (row.effective_done_ratio.to_f * factor).round(4)
          {
            :source => row,
            :original_done_ratio => original,
            :effective_done_ratio => effective,
            :weighted_value => (row.applied_weight.to_f * effective / 100).round(4)
          }
        end
        raw = rows.sum { |row| row[:weighted_value] } / calculation.total_weight.to_f * 100

        {
          :calculation => calculation,
          :rows => rows,
          :raw_percent => raw,
          :display_percent => round_percent(raw)
        }
      end

      def round_percent(value)
        case ProjectPercentDone::Settings.rounding_mode
        when 'floor' then value.floor
        when 'ceil' then value.ceil
        else value.round
        end
      end

      def demo_time_metrics(project, period_end, start_date, end_date)
        rows = TimeEntry.where(:project_id => project.id)
                        .where('spent_on <= ?', period_end)
                        .pluck(:spent_on, :hours)
        total = rows.sum { |_date, hours| hours.to_d }
        before = rows.select { |date, _hours| date < start_date }.sum { |_date, hours| hours.to_d }
        within = rows.select { |date, _hours| date.between?(start_date, end_date) }.sum { |_date, hours| hours.to_d }
        after = rows.select { |date, _hours| date > end_date }.sum { |_date, hours| hours.to_d }
        {
          :total => total,
          :count => rows.size,
          :before => before,
          :within => within,
          :after => after,
          :unclassified => total - before - within - after,
          :first_on => rows.map(&:first).min,
          :last_on => rows.map(&:first).max
        }
      end

      def create_issue_snapshots(snapshot, rows)
        rows.each do |values|
          row = values[:source]
          issue = row.issue
          ProjectPercentDoneIssueSnapshot.create!(
            :snapshot => snapshot,
            :issue_id => issue.id,
            :subject => issue.subject,
            :status_id => issue.status_id,
            :status_name => issue.status.name,
            :original_done_ratio => values[:original_done_ratio],
            :effective_done_ratio => values[:effective_done_ratio],
            :estimated_hours => row.estimated_hours,
            :applied_weight => row.applied_weight,
            :weighted_value => values[:weighted_value],
            :included => row.included,
            :notes => ['staging_demo']
          )
        end
        rows.size
      end

      def demo_runs
        ProjectPercentDoneCollectionRun.where(:source => SOURCE)
      end

      def project_snapshots(project)
        ProjectPercentDoneSnapshot.where(:project_id => project.id)
      end

      def project_issue_snapshots(project)
        ProjectPercentDoneIssueSnapshot.joins(:snapshot).where(
          :project_percent_done_snapshots => { :project_id => project.id }
        )
      end
    end
  end
end
