module ProjectPercentDone
  module History
    class Forecast
      Result = Struct.new(
        :available, :reason, :projected_end_date, :planned_end_variance_days,
        :sample_size, :slope_per_day, :r_squared, :confidence,
        keyword_init: true
      ) do
        def available?
          available
        end
      end

      MINIMUM_POINTS = 4
      MAXIMUM_POINTS = 8

      attr_reader :project

      def initialize(project)
        @project = project
      end

      def call
        snapshots = ProjectPercentDoneSnapshot.weekly_official
                                              .where(:project_id => project.id)
                                              .order(:period_end => :asc)
                                              .to_a
        latest = snapshots.last
        return unavailable('no_history') unless latest
        return unavailable('latest_snapshot_not_active') unless latest.active?
        return unavailable('invalid_plan_dates') unless valid_plan?(latest)
        return unavailable('project_not_started') if latest.period_end < latest.project_start_date
        return unavailable('project_complete') if latest.raw_percent_done.to_d >= 100

        sample = trailing_consecutive_sample(snapshots)
        return unavailable('insufficient_points', sample.size) if sample.size < MINIMUM_POINTS

        regression = linear_regression(sample)
        return unavailable('non_positive_progress_slope', sample.size) unless regression[:slope].positive?

        projected_days = (100.0 - regression[:intercept]) / regression[:slope]
        projected_date = sample.first.period_end + projected_days.ceil.days
        return unavailable('projection_not_after_latest', sample.size) if projected_date <= latest.period_end

        Result.new(
          :available => true,
          :projected_end_date => projected_date,
          :planned_end_variance_days => (projected_date - latest.project_planned_end_date).to_i,
          :sample_size => sample.size,
          :slope_per_day => regression[:slope],
          :r_squared => regression[:r_squared],
          :confidence => confidence(regression[:r_squared])
        )
      end

      private

      def valid_plan?(snapshot)
        snapshot.project_start_date && snapshot.project_planned_end_date &&
          snapshot.project_planned_end_date > snapshot.project_start_date
      end

      def trailing_consecutive_sample(snapshots)
        sample = []
        snapshots.reverse_each do |snapshot|
          break unless snapshot.active? && snapshot.raw_percent_done.present?
          break if sample.any? && (sample.last.period_end - snapshot.period_end).to_i != 7

          sample << snapshot
          break if sample.size == MAXIMUM_POINTS
        end
        sample.reverse
      end

      def linear_regression(sample)
        origin = sample.first.period_end
        xs = sample.map { |snapshot| (snapshot.period_end - origin).to_f }
        ys = sample.map { |snapshot| snapshot.raw_percent_done.to_f }
        x_mean = xs.sum / xs.size
        y_mean = ys.sum / ys.size
        denominator = xs.sum { |x| (x - x_mean)**2 }
        slope = denominator.zero? ? 0.0 : xs.each_index.sum { |index| (xs[index] - x_mean) * (ys[index] - y_mean) } / denominator
        intercept = y_mean - slope * x_mean
        predictions = xs.map { |x| intercept + slope * x }
        total_variance = ys.sum { |y| (y - y_mean)**2 }
        residual_variance = ys.each_index.sum { |index| (ys[index] - predictions[index])**2 }
        r_squared = total_variance.zero? ? 0.0 : 1.0 - (residual_variance / total_variance)
        { :slope => slope, :intercept => intercept, :r_squared => [[r_squared, 0].max, 1].min }
      end

      def confidence(r_squared)
        return 'high' if r_squared >= 0.8
        return 'medium' if r_squared >= 0.5

        'low'
      end

      def unavailable(reason, sample_size = 0)
        Result.new(:available => false, :reason => reason, :sample_size => sample_size)
      end
    end
  end
end
