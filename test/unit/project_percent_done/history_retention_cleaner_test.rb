require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::RetentionCleanerTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_deletes_issue_details_older_than_the_configured_age_but_keeps_aggregate
    snapshot = create_snapshot(Date.new(2025, 1, 5), 'active')
    create_issue_snapshot(snapshot)

    with_project_percent_done_settings('history_issue_retention_weeks' => '52') do
      deleted = ProjectPercentDone::History::RetentionCleaner.new(
        :today => Date.new(2026, 7, 15)
      ).call

      assert_equal 1, deleted
      assert ProjectPercentDoneSnapshot.exists?(snapshot.id)
      assert_equal 0, snapshot.issue_snapshots.count
      assert snapshot.reload.details_purged_at.present?
    end
  end

  def test_deletes_all_details_after_the_inactive_grace_period
    active_snapshot = create_snapshot(Date.new(2026, 6, 7), 'active')
    closed_snapshot = create_snapshot(Date.new(2026, 6, 14), 'closed')
    create_issue_snapshot(active_snapshot)

    with_project_percent_done_settings(
      'history_issue_retention_weeks' => '520',
      'history_inactive_grace_weeks' => '4'
    ) do
      deleted = ProjectPercentDone::History::RetentionCleaner.new(
        :today => Date.new(2026, 7, 15)
      ).call

      assert_equal 1, deleted
      assert_equal 0, active_snapshot.issue_snapshots.count
      assert ProjectPercentDoneSnapshot.exists?(closed_snapshot.id)
    end
  end

  private

  def create_snapshot(period_end, state)
    ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'official',
      :period_end => period_end,
      :captured_at => Time.zone.local(period_end.year, period_end.month, period_end.day, 23, 59),
      :project_state => state,
      :snapshot_source => 'direct',
      :timing => 'on_time'
    )
  end

  def create_issue_snapshot(snapshot)
    ProjectPercentDoneIssueSnapshot.create!(
      :snapshot => snapshot,
      :issue_id => 99_999,
      :subject => 'Historical issue',
      :included => true
    )
  end
end
