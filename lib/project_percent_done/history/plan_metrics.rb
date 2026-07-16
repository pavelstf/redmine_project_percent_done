module ProjectPercentDone
  module History
    class PlanMetrics
      CALENDAR_MODE = 'calendar_days_v1'.freeze

      attr_reader :project, :captured_on, :progress_result, :project_state

      def initialize(project, captured_on:, progress_result:, project_state:)
        @project = project
        @captured_on = captured_on
        @progress_result = progress_result
        @project_state = project_state
      end

      def attributes
        start_field = ProjectPercentDone::Settings.history_project_start_custom_field
        end_field = ProjectPercentDone::Settings.history_project_planned_end_custom_field
        start_date = custom_date(start_field)
        end_date = custom_date(end_field)
        valid_plan = start_date && end_date && end_date > start_date
        time = time_metrics(start_date, end_date, valid_plan)
        previous = previous_official_snapshot
        elapsed = elapsed_metrics(start_date, end_date, valid_plan)
        raw_progress = progress_result.try(:raw_percent_done)

        {
          :project_start_custom_field_id => start_field.try(:id),
          :project_start_custom_field_name => start_field.try(:name),
          :project_planned_end_custom_field_id => end_field.try(:id),
          :project_planned_end_custom_field_name => end_field.try(:name),
          :project_start_date => start_date,
          :project_planned_end_date => end_date,
          :plan_calendar_mode => CALENDAR_MODE,
          :plan_phase => plan_phase(start_date, end_date, valid_plan, time, raw_progress),
          :first_observed_plan => previous.nil?,
          :start_date_changed => previous.present? && previous.project_start_date != start_date,
          :planned_end_date_changed => previous.present? && previous.project_planned_end_date != end_date,
          :start_date_change_days => date_difference(start_date, previous.try(:project_start_date)),
          :planned_end_date_change_days => date_difference(end_date, previous.try(:project_planned_end_date)),
          :schedule_variance_points => schedule_variance(raw_progress, elapsed[:elapsed_plan_percent]),
          :pre_start_activity => pre_start_activity?(start_date, time, raw_progress),
          :post_end_activity => time[:hours_after_planned_end].positive?
        }.merge(elapsed).merge(time).merge(:plan_warnings => warnings(start_field, end_field, start_date, end_date, valid_plan, time, raw_progress))
      end

      private

      def custom_date(field)
        return nil unless field

        value = project.custom_field_value(field)
        return value if value.is_a?(Date)
        return nil if value.blank?

        Date.iso8601(value.to_s)
      rescue ArgumentError
        nil
      end

      def previous_official_snapshot
        ProjectPercentDoneSnapshot.official
                                  .where(:project_id => project.id)
                                  .order(:period_end => :desc, :id => :desc)
                                  .first
      end

      def elapsed_metrics(start_date, end_date, valid_plan)
        return empty_elapsed_metrics unless valid_plan

        duration = (end_date - start_date).to_i
        elapsed = (captured_on - start_date).to_i
        percent = [[elapsed.to_f / duration * 100, 0].max, 100].min
        {
          :planned_duration_days => duration,
          :elapsed_plan_days => elapsed,
          :elapsed_plan_percent => percent,
          :days_before_start => [elapsed * -1, 0].max,
          :days_overdue => [(captured_on - end_date).to_i, 0].max
        }
      end

      def empty_elapsed_metrics
        {
          :planned_duration_days => nil,
          :elapsed_plan_days => nil,
          :elapsed_plan_percent => nil,
          :days_before_start => nil,
          :days_overdue => nil
        }
      end

      def time_metrics(start_date, end_date, valid_plan)
        rows = TimeEntry.where(:project_id => project.id)
                        .where('spent_on <= ?', captured_on)
                        .pluck(:spent_on, :hours)
        total = rows.sum { |_date, hours| hours.to_d }
        before = (start_date && (valid_plan || end_date.nil?)) ? rows.select { |date, _hours| date < start_date }.sum { |_date, hours| hours.to_d } : 0.to_d
        within = valid_plan ? rows.select { |date, _hours| date.between?(start_date, end_date) }.sum { |_date, hours| hours.to_d } : 0.to_d
        after = (end_date && (valid_plan || start_date.nil?)) ? rows.select { |date, _hours| date > end_date }.sum { |_date, hours| hours.to_d } : 0.to_d
        {
          :spent_hours_total => total,
          :time_entry_count => rows.size,
          :hours_before_start => before,
          :hours_within_plan => within,
          :hours_after_planned_end => after,
          :hours_unclassified => total - before - within - after,
          :first_time_entry_on => rows.map(&:first).min,
          :last_time_entry_on => rows.map(&:first).max
        }
      end

      def plan_phase(start_date, end_date, valid_plan, time, raw_progress)
        if start_date && captured_on < start_date
          return pre_start_activity?(start_date, time, raw_progress) ? 'pre_start_activity' : 'planned_not_started'
        end
        if end_date && captured_on > end_date
          return project_state == 'active' ? 'overdue_active' : 'after_planned_end'
        end
        return 'insufficient_date_data' unless valid_plan

        'within_planned_period'
      end

      def pre_start_activity?(start_date, time, raw_progress)
        !!(start_date && captured_on < start_date &&
          (time[:hours_before_start].positive? || raw_progress.to_d.positive?))
      end

      def schedule_variance(raw_progress, elapsed_percent)
        return nil if raw_progress.nil? || elapsed_percent.nil?

        raw_progress.to_d - elapsed_percent.to_d
      end

      def date_difference(current, previous)
        return nil unless current && previous && current != previous

        (current - previous).to_i
      end

      def warnings(start_field, end_field, start_date, end_date, valid_plan, time, raw_progress)
        values = []
        values << 'plan_start_date_missing_or_invalid' if start_field && !start_date
        values << 'plan_end_date_missing_or_invalid' if end_field && !end_date
        values << 'plan_end_not_after_start' if start_date && end_date && !valid_plan
        values << 'hours_before_project_start' if time[:hours_before_start].positive?
        values << 'progress_before_project_start' if start_date && captured_on < start_date && raw_progress.to_d.positive?
        values << 'hours_after_planned_end' if time[:hours_after_planned_end].positive?
        values
      end
    end
  end
end
