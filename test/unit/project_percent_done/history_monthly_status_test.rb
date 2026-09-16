require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::MonthlyStatusTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_waiting_state_reports_next_monthly_capture_date
    create_monthly_snapshot(Date.new(2026, 7, 31))

    with_project_percent_done_settings('history_enabled' => '1') do
      status = ProjectPercentDone::History::MonthlyStatus.new(
        :project => test_project,
        :today => Date.new(2026, 8, 12)
      ).call

      assert status.waiting?
      assert_equal Date.new(2026, 8, 31), status.next_period_end
      assert_equal Date.new(2026, 9, 1), status.expected_capture_date
      assert_equal 20, status.days_remaining
      assert_equal Date.new(2026, 7, 31), status.latest_period_end
    end
  end

  def test_initial_monthly_shadow_start_waits_for_current_month
    with_project_percent_done_settings('history_enabled' => '1') do
      status = ProjectPercentDone::History::MonthlyStatus.new(
        :project => test_project,
        :today => Date.new(2026, 8, 12)
      ).call

      assert status.waiting?
      assert_equal Date.new(2026, 8, 31), status.next_period_end
      assert_equal Date.new(2026, 9, 1), status.expected_capture_date
    end
  end

  def test_overdue_state_reports_gap_after_monthly_history_has_started
    create_monthly_snapshot(Date.new(2026, 6, 30))

    with_project_percent_done_settings('history_enabled' => '1') do
      status = ProjectPercentDone::History::MonthlyStatus.new(
        :project => test_project,
        :today => Date.new(2026, 8, 12)
      ).call

      assert status.overdue?
      assert_equal Date.new(2026, 7, 31), status.next_period_end
      assert_equal Date.new(2026, 8, 1), status.expected_capture_date
      assert_equal Date.new(2026, 6, 30), status.latest_period_end
    end
  end

  def test_disabled_state_does_not_report_due_work
    with_project_percent_done_settings('history_enabled' => '0') do
      status = ProjectPercentDone::History::MonthlyStatus.new(
        :project => test_project,
        :today => Date.new(2026, 8, 12)
      ).call

      assert status.disabled?
      assert_equal Date.new(2026, 8, 31), status.next_period_end
      assert_equal Date.new(2026, 9, 1), status.expected_capture_date
    end
  end

  def test_waiting_state_moves_after_newer_staging_simulation_snapshot
    create_monthly_snapshot(Date.new(2026, 8, 31))

    with_project_percent_done_settings('history_enabled' => '1') do
      status = ProjectPercentDone::History::MonthlyStatus.new(
        :project => test_project,
        :today => Date.new(2026, 8, 12)
      ).call

      assert status.waiting?
      assert_equal Date.new(2026, 8, 31), status.latest_period_end
      assert_equal Date.new(2026, 9, 30), status.next_period_end
      assert_equal Date.new(2026, 10, 1), status.expected_capture_date
    end
  end

  private

  def create_monthly_snapshot(period_end)
    ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'official',
      :period_type => 'monthly',
      :period_end => period_end,
      :captured_at => Time.zone.local(period_end.year, period_end.month, period_end.day, 23, 59),
      :project_state => 'active',
      :display_percent_done => 50
    )
  end
end
