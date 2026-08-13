require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::PlanMetricsTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def setup
    @start_field = create_project_date_custom_field('Observed start')
    @end_field = create_project_date_custom_field('Observed end')
  end

  def test_valid_plan_classifies_time_entries_and_calculates_calendar_variance
    set_project_custom_fields(
      test_project,
      @start_field => '2026-07-01',
      @end_field => '2026-07-31'
    )
    issue = create_test_issue
    TimeEntry.generate!(:issue => issue, :spent_on => Date.new(2026, 6, 30), :hours => 2)
    TimeEntry.generate!(:issue => issue, :spent_on => Date.new(2026, 7, 10), :hours => 5)
    TimeEntry.generate!(:issue => issue, :spent_on => Date.new(2026, 8, 1), :hours => 3)

    with_plan_settings do
      attributes = metrics(Date.new(2026, 8, 2), 60)
      assert_equal 'overdue_active', attributes[:plan_phase]
      assert_equal 10.to_d, attributes[:spent_hours_total]
      assert_equal 2.to_d, attributes[:hours_before_start]
      assert_equal 5.to_d, attributes[:hours_within_plan]
      assert_equal 3.to_d, attributes[:hours_after_planned_end]
      assert_equal 0.to_d, attributes[:hours_unclassified]
      assert_equal 2, attributes[:days_overdue]
      assert_equal(-40.to_d, attributes[:schedule_variance_points])
      assert_includes attributes[:plan_warnings], 'hours_before_project_start'
      assert_includes attributes[:plan_warnings], 'hours_after_planned_end'
    end
  end

  def test_future_project_with_hours_or_progress_is_pre_start_activity
    set_project_custom_fields(
      test_project,
      @start_field => '2026-08-01',
      @end_field => '2026-10-01'
    )
    TimeEntry.generate!(:issue => create_test_issue, :spent_on => Date.new(2026, 7, 10), :hours => 4)

    with_plan_settings do
      attributes = metrics(Date.new(2026, 7, 12), 10)
      assert_equal 'pre_start_activity', attributes[:plan_phase]
      assert attributes[:pre_start_activity]
      assert_equal 20, attributes[:days_before_start]
      assert_includes attributes[:plan_warnings], 'progress_before_project_start'
    end
  end

  def test_date_changes_are_measured_against_previous_official_snapshot
    ProjectPercentDoneSnapshot.create!(
      :project => test_project, :snapshot_kind => 'official', :period_end => Date.new(2026, 7, 5),
      :captured_at => Time.zone.local(2026, 7, 5, 23, 59), :project_state => 'active',
      :project_start_date => Date.new(2026, 7, 1), :project_planned_end_date => Date.new(2026, 9, 30)
    )
    set_project_custom_fields(
      test_project,
      @start_field => '2026-07-08',
      @end_field => '2026-10-31'
    )

    with_plan_settings do
      attributes = metrics(Date.new(2026, 7, 12), 20)
      assert attributes[:start_date_changed]
      assert attributes[:planned_end_date_changed]
      assert_equal 7, attributes[:start_date_change_days]
      assert_equal 31, attributes[:planned_end_date_change_days]
      refute attributes[:first_observed_plan]
    end
  end

  def test_single_start_boundary_still_classifies_pre_start_hours
    set_project_custom_fields(test_project, @start_field => '2026-08-01')
    TimeEntry.generate!(:issue => create_test_issue, :spent_on => Date.new(2026, 7, 1), :hours => 2)

    with_project_percent_done_settings(
      'history_project_start_custom_field_id' => @start_field.id.to_s
    ) do
      attributes = metrics(Date.new(2026, 7, 12), 0)
      assert_equal 'pre_start_activity', attributes[:plan_phase]
      assert_equal 2.to_d, attributes[:hours_before_start]
      assert_equal 0.to_d, attributes[:hours_after_planned_end]
      assert_equal 0.to_d, attributes[:hours_unclassified]
    end
  end

  private

  def with_plan_settings(&block)
    with_project_percent_done_settings(
      'history_project_start_custom_field_id' => @start_field.id.to_s,
      'history_project_planned_end_custom_field_id' => @end_field.id.to_s,
      &block
    )
  end

  def metrics(date, raw_progress)
    result = Struct.new(:raw_percent_done).new(raw_progress)
    ProjectPercentDone::History::PlanMetrics.new(
      test_project,
      :captured_on => date,
      :progress_result => result,
      :project_state => 'active'
    ).attributes
  end
end
