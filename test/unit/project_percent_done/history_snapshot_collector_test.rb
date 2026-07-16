require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::SnapshotCollectorTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def setup
    Setting.issue_done_ratio = 'issue_field'
    @custom_field = create_project_type_custom_field
    set_project_custom_field_values(test_project, @custom_field, ['Internal'])
    create_test_issue(:done_ratio => 50, :estimated_hours => 10)
  end

  def test_monday_capture_creates_direct_official_snapshot_with_issue_details
    with_history_settings do
      result = collect_at(2026, 7, 13, 0, 15)
      snapshot = ProjectPercentDoneSnapshot.official.find_by!(
        :project_id => test_project.id,
        :period_end => Date.new(2026, 7, 12)
      )

      assert_equal 'successful', result.run.status
      assert_equal 'direct', snapshot.snapshot_source
      assert_equal 'on_time', snapshot.timing
      assert_equal 50, snapshot.display_percent_done
      assert_equal 1, snapshot.issue_snapshots.count
      assert_equal 1, result.run.snapshots_promoted
      assert_equal 1, result.run.issue_snapshots_created
    end
  end

  def test_daily_capture_rotates_only_the_previous_operational_snapshot
    with_history_settings do
      collect_at(2026, 7, 13, 0, 15)
      collect_at(2026, 7, 14, 0, 15)
      first_operational = ProjectPercentDoneSnapshot.operational.find_by!(:project_id => test_project.id)

      collect_at(2026, 7, 15, 0, 15)

      assert_equal 1, ProjectPercentDoneSnapshot.official.where(:project_id => test_project.id).count
      assert_equal 1, ProjectPercentDoneSnapshot.operational.where(:project_id => test_project.id).count
      refute ProjectPercentDoneSnapshot.exists?(first_operational.id)
    end
  end

  def test_missed_monday_promotes_the_closer_snapshot_before_sunday_end
    with_history_settings do
      collect_at(2026, 7, 12, 0, 15)
      previous = ProjectPercentDoneSnapshot.operational.find_by!(:project_id => test_project.id)

      collect_at(2026, 7, 14, 0, 15)
      official = ProjectPercentDoneSnapshot.official.find_by!(
        :project_id => test_project.id,
        :period_end => Date.new(2026, 7, 12)
      )

      assert_equal previous.id, official.id
      assert_equal 'promoted', official.snapshot_source
      assert_equal 'early', official.timing
      assert_operator official.deviation_seconds, :>, 0
      assert_equal 1, ProjectPercentDoneSnapshot.operational.where(:project_id => test_project.id).count
    end
  end

  def test_repeated_execution_keeps_only_one_operational_snapshot_per_day
    with_history_settings do
      collect_at(2026, 7, 14, 0, 15)
      collect_at(2026, 7, 14, 8, 0)
      third = collect_at(2026, 7, 14, 12, 0)

      assert_equal 'successful', third.run.status
      assert_equal 0, third.run.projects_failed
      assert_equal 1, ProjectPercentDoneSnapshot.operational.where(:project_id => test_project.id).count
      assert_equal 0, third.run.snapshots_created
      assert_equal 0, third.run.snapshots_promoted
      assert_equal 0, third.run.issue_snapshots_created
    end
  end

  def test_candidate_outside_configured_tolerance_is_not_promoted
    with_history_settings('history_promotion_tolerance_days' => '0') do
      collect_at(2026, 7, 14, 0, 15)

      assert_equal 0, ProjectPercentDoneSnapshot.official.where(:project_id => test_project.id).count
      assert_equal 1, ProjectPercentDoneSnapshot.operational.where(:project_id => test_project.id).count
    end
  end

  def test_initial_collection_skips_untracked_closed_project
    test_project.update!(:status => Project::STATUS_CLOSED)

    with_history_settings do
      result = collect_at(2026, 7, 13, 0, 15)

      assert_equal 0, result.run.projects_processed
      assert_equal 0, result.run.snapshots_created
      assert_not ProjectPercentDoneSnapshot.where(:project_id => test_project.id).exists?
    end
  end

  private

  def with_history_settings(extra = {}, &block)
    with_project_percent_done_settings(
      {
        'history_enabled' => '1',
        'history_detail_level' => 'project_and_issues',
        'history_project_type_custom_field_id' => @custom_field.id.to_s,
        'history_project_type_values' => ['Internal']
      }.merge(extra),
      &block
    )
  end

  def collect_at(year, month, day, hour, minute)
    now = Time.zone.local(year, month, day, hour, minute)
    ProjectPercentDone::History::SnapshotCollector.new(:now => now, :source => 'test').call
  end
end
