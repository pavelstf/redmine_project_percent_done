module ProjectPercentDone
  module History
    class SnapshotCollector
      Result = Struct.new(:run, :preview, keyword_init: true)

      attr_reader :now, :source, :preview

      def initialize(now: nil, source: 'cron', preview: false)
        @now = now || Time.zone.now
        @source = source.to_s
        @preview = preview
      end

      def call
        return preview_result if preview

        with_collector_lock do
          run = ProjectPercentDoneCollectionRun.create!(
            :source => source,
            :status => 'running',
            :target_period_end => completed_period_end,
            :started_at => now,
            :errors_list => []
          )
          collect(run)
          ProjectPercentDone::History::Notifier.new(run).deliver
          Result.new(:run => run, :preview => false)
        end
      end

      private

      def collect(run)
        unless ProjectPercentDone::Settings.history_enabled?
          return finish_run(run, 'disabled')
        end

        selector = ProjectSelector.new
        unless selector.ready?
          run.errors_list = selector.validation_errors
          return finish_run(run, 'failed')
        end

        previous_run = ProjectPercentDoneCollectionRun
                       .where(:target_period_end => completed_period_end)
                       .where.not(:id => run.id)
                       .latest_first
                       .first
        previous_problem = previous_run && %w[partial failed].include?(previous_run.status)

        selector.projects.each do |project|
          run.projects_processed += 1
          begin
            created, promoted, issue_count = collect_project(project, selector, run)
            run.projects_succeeded += 1
            run.snapshots_created += created
            run.snapshots_promoted += promoted
            run.issue_snapshots_created += issue_count
          rescue StandardError => error
            run.projects_failed += 1
            append_error(run, project, error)
          end
        end

        run.details_deleted = RetentionCleaner.new(:today => now.to_date).call
        run.snapshot_type = run.snapshots_promoted.positive? ? 'official' : 'operational'
        status = if run.projects_failed.positive? && run.projects_succeeded.positive?
                   'partial'
                 elsif run.projects_failed.positive?
                   'failed'
                 elsif previous_problem
                   run.projects_recovered = run.projects_succeeded
                   'recovery'
                 else
                   'successful'
                 end
        finish_run(run, status)
      rescue StandardError => error
        append_error(run, nil, error)
        finish_run(run, 'failed')
      end

      def collect_project(project, selector, run)
        existing = ProjectPercentDoneSnapshot.operational
                                             .where(:project_id => project.id)
                                             .where(:captured_at => now.beginning_of_day..now.end_of_day)
                                             .first
        return [0, 0, 0] if existing

        values = selector.values_for(project)
        state = project_state(project, selector.in_scope?(project))
        result = calculate(project, state)
        snapshot = nil
        issue_count = 0

        promoted = false
        ProjectPercentDoneSnapshot.transaction do
          snapshot = create_snapshot(project, values, state, result, run)
          issue_count = create_issue_snapshots(snapshot, result)
          promoted = officialize_if_due(project, snapshot, run)
          rotate_operational(project, snapshot)
        end
        [1, promoted ? 1 : 0, issue_count]
      end

      def project_state(project, in_scope)
        return 'archived' if project.archived?
        return 'closed' if project.closed?
        return 'active' if project.active? && in_scope

        'out_of_scope'
      end

      def calculate(project, state)
        return nil unless state == 'active'

        mode = ProjectPercentDone::Settings.history_issue_details? ? :details : :summary
        ProjectPercentDone::ProjectProgressCalculator.new(project, :mode => mode).call
      end

      def create_snapshot(project, values, state, result, run)
        plan_attributes = PlanMetrics.new(
          project,
          :captured_on => now.to_date,
          :progress_result => result,
          :project_state => state
        ).attributes
        plan_warnings = plan_attributes.delete(:plan_warnings)
        attributes = {
          :project => project,
          :collection_run => run,
          :snapshot_kind => 'operational',
          :captured_at => now,
          :project_state => state,
          :snapshot_source => 'direct',
          :timing => 'on_time',
          :deviation_seconds => 0,
          :project_type_values => values,
          :algorithm_version => ProjectPercentDone::ALGORITHM_VERSION,
          :plugin_version => ProjectPercentDone::PLUGIN_VERSION,
          :rounding_mode => ProjectPercentDone::Settings.rounding_mode,
          :calculation_settings => ProjectPercentDone::Settings.history_calculation_settings,
          :warnings => Array(result.try(:warnings)) + plan_warnings
        }
        attributes.merge!(result_attributes(result)) if result
        attributes.merge!(plan_attributes)
        ProjectPercentDoneSnapshot.create!(attributes)
      end

      def result_attributes(result)
        {
          :display_percent_done => result.percent_done,
          :raw_percent_done => result.raw_percent_done,
          :all_project_issue_count => result.all_project_issue_count,
          :eligible_issue_count => result.eligible_issue_count,
          :included_issue_count => result.included_issue_count,
          :not_included_issue_count => result.not_included_issue_count,
          :estimated_issue_count => result.estimated_issue_count,
          :unestimated_issue_count => result.unestimated_issue_count,
          :estimated_eligible_issue_count => result.estimated_eligible_issue_count,
          :unestimated_eligible_issue_count => result.unestimated_eligible_issue_count,
          :excluded_parent_issue_count => result.excluded_parent_issue_count,
          :ignored_unestimated_issue_count => result.ignored_unestimated_issue_count,
          :known_estimated_hours => result.known_estimated_hours,
          :total_weight => result.total_weight,
          :imputed_weight => result.imputed_weight,
          :estimate_coverage_percent => result.estimate_coverage_percent
        }
      end

      def create_issue_snapshots(snapshot, result)
        return 0 unless result && ProjectPercentDone::Settings.history_issue_details?

        rows = result.included_rows + result.not_included_rows
        rows.each do |row|
          issue = row.issue
          ProjectPercentDoneIssueSnapshot.create!(
            :snapshot => snapshot,
            :issue_id => issue.id,
            :subject => issue.subject,
            :status_id => issue.status_id,
            :status_name => issue.status.try(:name),
            :original_done_ratio => row.original_done_ratio,
            :effective_done_ratio => row.effective_done_ratio,
            :estimated_hours => row.estimated_hours,
            :applied_weight => row.applied_weight,
            :weighted_value => row.weighted_value,
            :included => row.included,
            :exclusion_reason => row.reason.try(:to_s),
            :notes => row.notes
          )
        end
        rows.size
      end

      def officialize_if_due(project, current_snapshot, run)
        return false if ProjectPercentDoneSnapshot.official.exists?(
          :project_id => project.id,
          :period_end => completed_period_end
        )

        tolerance = ProjectPercentDone::Settings.history_promotion_tolerance_days.days
        candidates = ProjectPercentDoneSnapshot.operational
                                               .where(:project_id => project.id)
                                               .where(:captured_at => (target_boundary - tolerance)..(target_boundary + tolerance))
                                               .to_a
        candidate = candidates.min_by do |snapshot|
          [(snapshot.captured_at - target_boundary).abs, snapshot.captured_at > target_boundary ? 1 : 0]
        end
        return false unless candidate

        deviation = (candidate.captured_at - target_boundary).to_i
        direct = candidate.id == current_snapshot.id && candidate.captured_at.to_date == completed_period_end + 1.day
        candidate.update!(
          :snapshot_kind => 'official',
          :period_end => completed_period_end,
          :officialized_by_run => run,
          :snapshot_source => direct ? 'direct' : 'promoted',
          :timing => direct ? 'on_time' : (deviation.negative? ? 'early' : 'late'),
          :deviation_seconds => deviation.abs
        )
        true
      end

      def rotate_operational(project, current_snapshot)
        keep_id = current_snapshot.reload.operational? ? current_snapshot.id : nil
        scope = ProjectPercentDoneSnapshot.operational.where(:project_id => project.id)
        scope = scope.where.not(:id => keep_id) if keep_id
        scope.find_each(&:destroy!)
      end

      def completed_period_end
        @completed_period_end ||= begin
          date = now.to_date
          date - (date.wday.zero? ? 7 : date.wday)
        end
      end

      def target_boundary
        @target_boundary ||= Time.zone.local(
          completed_period_end.year,
          completed_period_end.month,
          completed_period_end.day,
          23, 59, 59
        )
      end

      def preview_result
        selector = ProjectSelector.new
        payload = {
          :ready => selector.ready?,
          :errors => selector.validation_errors,
          :project_count => selector.ready? ? selector.projects.size : 0,
          :estimated_issue_count => selector.ready? ? selector.projects.select { |project| project.active? && selector.in_scope?(project) }.sum { |project| project.issues.count } : 0
        }
        Result.new(:run => payload, :preview => true)
      end

      def finish_run(run, status)
        completed_at = Time.zone.now
        run.status = status
        run.completed_at = completed_at
        run.duration_ms = ((completed_at - run.started_at) * 1000).round
        run.save!
        run
      end

      def append_error(run, project, error)
        Rails.logger.error(
          "[ProjectPercentDone] Snapshot failed for project #{project.try(:id) || '-'}: " \
          "#{error.class}: #{error.message}\n#{Array(error.backtrace).first(10).join("\n")}"
        )
        errors = run.errors_list
        errors << {
          'project_id' => project.try(:id),
          'project_name' => project.try(:name),
          'error_class' => error.class.name,
          'message' => 'project_snapshot_failed'
        }
        run.errors_list = errors
      end

      def with_collector_lock
        lock_path = Rails.root.join('tmp', 'project_percent_done_snapshots.lock')
        FileUtils.mkdir_p(lock_path.dirname)
        File.open(lock_path, 'w') do |file|
          raise 'snapshot_collector_already_running' unless file.flock(File::LOCK_EX | File::LOCK_NB)

          yield
        ensure
          file.flock(File::LOCK_UN) rescue nil
        end
      end
    end
  end
end
