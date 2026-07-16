require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::TimelineTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_timeline_distinguishes_active_disabled_and_missing_weeks
    create_snapshot(Date.new(2026, 6, 28), 'active', 40)
    ProjectPercentDoneCollectionRun.create!(
      :source => 'cron', :status => 'disabled', :target_period_end => Date.new(2026, 7, 5),
      :started_at => Time.zone.local(2026, 7, 6), :completed_at => Time.zone.local(2026, 7, 6, 0, 1)
    )
    timeline = ProjectPercentDone::History::Timeline.new(test_project, :selection => '13', :today => Date.new(2026, 7, 12))
    entries = timeline.entries.index_by(&:period_end)

    assert_equal 'active', entries[Date.new(2026, 6, 28)].state
    assert_equal 'disabled', entries[Date.new(2026, 7, 5)].state
    assert_equal 'missing', entries[Date.new(2026, 7, 12)].state
  end

  def test_calendar_and_fiscal_quarter_options_include_exact_named_periods
    create_snapshot(Date.new(2026, 4, 5), 'active', 30)
    with_project_percent_done_settings(
      'history_reporting_year' => 'fiscal',
      'history_fiscal_year_start_month' => '4'
    ) do
      options = ProjectPercentDone::History::Timeline.new(test_project, :today => Date.new(2026, 7, 15)).options
      assert options.any? { |label, value| value == 'calendar:2026:q1' && label.include?('Q1 2026') }
      assert options.any? { |label, value| value == 'fiscal:2026:q4' && label.include?('FY2026 Q4') }
    end
  end

  def test_weeks_before_first_snapshot_are_planned_or_not_observed
    create_snapshot(Date.new(2026, 7, 5), 'active', 30).update!(:project_start_date => Date.new(2026, 6, 15))
    timeline = ProjectPercentDone::History::Timeline.new(test_project, :selection => '13', :today => Date.new(2026, 7, 12))
    entries = timeline.entries.index_by(&:period_end)

    assert_equal 'planned_not_started', entries[Date.new(2026, 6, 14)].state
    assert_equal 'not_observed', entries[Date.new(2026, 6, 21)].state
    assert_equal 'not_observed', entries[Date.new(2026, 6, 28)].state
    assert_equal 'active', entries[Date.new(2026, 7, 5)].state
  end

  def test_explicitly_disabled_week_before_first_snapshot_is_not_marked_unobserved
    create_snapshot(Date.new(2026, 7, 5), 'active', 30)
    ProjectPercentDoneCollectionRun.create!(
      :source => 'cron', :status => 'disabled', :target_period_end => Date.new(2026, 6, 28),
      :started_at => Time.zone.local(2026, 6, 29), :completed_at => Time.zone.local(2026, 6, 29, 0, 1)
    )

    entries = ProjectPercentDone::History::Timeline.new(
      test_project, :selection => '13', :today => Date.new(2026, 7, 12)
    ).entries.index_by(&:period_end)

    assert_equal 'disabled', entries[Date.new(2026, 6, 28)].state
  end

  private

  def create_snapshot(period_end, state, percent)
    ProjectPercentDoneSnapshot.create!(
      :project => test_project, :snapshot_kind => 'official', :period_end => period_end,
      :captured_at => Time.zone.local(period_end.year, period_end.month, period_end.day, 23, 59),
      :project_state => state, :display_percent_done => percent
    )
  end
end
