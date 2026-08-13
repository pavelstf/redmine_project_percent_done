module ProjectPercentDone
  module History
    class MonthlyStatus
      Result = Struct.new(
        :state,
        :latest_period_end,
        :checked_period_end,
        :next_period_end,
        :expected_capture_date,
        :days_remaining,
        keyword_init: true
      ) do
        def disabled?
          state == 'disabled'
        end

        def waiting?
          state == 'waiting'
        end

        def due_today?
          state == 'due_today'
        end

        def overdue?
          state == 'overdue_missing'
        end
      end

      attr_reader :project, :today

      def initialize(project: nil, today: nil)
        @project = project
        @today = today || Time.zone.today
      end

      def call
        return result('disabled', current_month_end) unless ProjectPercentDone::Settings.history_enabled?

        if latest_period_end && latest_period_end >= current_month_end
          result('waiting', next_month_end(latest_period_end))
        elsif missing_last_completed_month?
          if latest_period_end.nil? && today > expected_capture_date(last_completed_month_end)
            result('waiting', current_month_end)
          else
            state = today > expected_capture_date(last_completed_month_end) ? 'overdue_missing' : 'due_today'
            result(state, last_completed_month_end)
          end
        else
          result('waiting', current_month_end)
        end
      end

      private

      def result(state, period_end)
        expected = expected_capture_date(period_end)
        Result.new(
          :state => state,
          :latest_period_end => latest_period_end,
          :checked_period_end => state == 'waiting' ? nil : period_end,
          :next_period_end => period_end,
          :expected_capture_date => expected,
          :days_remaining => [expected - today, 0].max.to_i
        )
      end

      def missing_last_completed_month?
        !snapshot_scope.exists?(:period_end => last_completed_month_end)
      end

      def latest_period_end
        @latest_period_end ||= snapshot_scope.maximum(:period_end)
      end

      def snapshot_scope
        scope = ProjectPercentDoneSnapshot.monthly_official
        project ? scope.where(:project_id => project.id) : scope
      end

      def last_completed_month_end
        @last_completed_month_end ||= today.beginning_of_month - 1.day
      end

      def current_month_end
        @current_month_end ||= today.end_of_month
      end

      def expected_capture_date(period_end)
        period_end + 1.day
      end

      def next_month_end(period_end)
        (period_end + 1.day).end_of_month
      end
    end
  end
end
