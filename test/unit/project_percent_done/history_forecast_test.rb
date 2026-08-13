require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::ForecastTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_projects_completion_from_four_consecutive_active_points
    [20, 30, 40, 50].each_with_index { |percent, index| create_snapshot(Date.new(2026, 6, 7) + index.weeks, percent) }

    result = ProjectPercentDone::History::Forecast.new(test_project).call
    assert result.available?
    assert_equal Date.new(2026, 8, 2), result.projected_end_date
    assert_equal 4, result.sample_size
    assert_in_delta 10.0 / 7, result.slope_per_day, 0.0001
    assert_in_delta 1.0, result.r_squared, 0.0001
    assert_equal 'high', result.confidence
  end

  def test_gap_prevents_older_points_from_satisfying_minimum_sample
    [Date.new(2026, 5, 31), Date.new(2026, 6, 7), Date.new(2026, 6, 21), Date.new(2026, 6, 28)].each_with_index do |date, index|
      create_snapshot(date, 10 + index * 10)
    end

    result = ProjectPercentDone::History::Forecast.new(test_project).call
    refute result.available?
    assert_equal 'insufficient_points', result.reason
    assert_equal 2, result.sample_size
  end

  def test_future_start_blocks_forecast
    4.times { |index| create_snapshot(Date.new(2026, 6, 7) + index.weeks, 10 + index * 10, :start_date => Date.new(2026, 8, 1)) }

    result = ProjectPercentDone::History::Forecast.new(test_project).call
    refute result.available?
    assert_equal 'project_not_started', result.reason
  end

  def test_monthly_snapshots_do_not_feed_weekly_forecast
    4.times do |index|
      create_snapshot(Date.new(2026, 6, 7) + index.weeks, 10 + index * 10, :period_type => 'monthly')
    end

    result = ProjectPercentDone::History::Forecast.new(test_project).call
    refute result.available?
    assert_equal 'no_history', result.reason
  end

  private

  def create_snapshot(period_end, percent, start_date: Date.new(2026, 5, 1), period_type: 'weekly')
    ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'official',
      :period_type => period_type,
      :period_end => period_end,
      :captured_at => Time.zone.local(period_end.year, period_end.month, period_end.day, 23, 59),
      :project_state => 'active',
      :raw_percent_done => percent,
      :display_percent_done => percent,
      :project_start_date => start_date,
      :project_planned_end_date => Date.new(2026, 8, 15),
      :plan_phase => 'within_planned_period'
    )
  end
end
