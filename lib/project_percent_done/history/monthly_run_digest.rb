module ProjectPercentDone
  module History
    class MonthlyRunDigest
      Summary = Struct.new(
        :period_end,
        :total_count,
        :available_count,
        :min_percent,
        :max_percent,
        :avg_percent,
        :state_counts,
        keyword_init: true
      )

      attr_reader :run

      def initialize(run)
        @run = run
      end

      def snapshots
        @snapshots ||= ProjectPercentDoneSnapshot.monthly_official
                                                 .where(:officialized_by_run_id => run.id)
                                                 .to_a
      end

      def summaries
        @summaries ||= snapshots.group_by(&:period_end).sort_by { |period_end, _rows| period_end }.map do |period_end, rows|
          values = rows.map(&:display_percent_done).compact
          Summary.new(
            :period_end => period_end,
            :total_count => rows.size,
            :available_count => values.size,
            :min_percent => values.min,
            :max_percent => values.max,
            :avg_percent => values.any? ? (values.sum.to_f / values.size) : nil,
            :state_counts => rows.group_by(&:project_state).transform_values(&:size)
          )
        end
      end

      def any?
        snapshots.any?
      end

      def status
        @status ||= MonthlyStatus.new(:today => run.started_at.to_date).call
      end
    end
  end
end
