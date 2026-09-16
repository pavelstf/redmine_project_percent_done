require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::ProjectProgressCalculatorTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def setup
    Setting.issue_done_ratio = 'issue_field'
  end

  def test_returns_zero_when_project_has_no_issues
    with_project_percent_done_settings({}) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 0, result.percent_done
      assert_equal [:no_issues], result.warnings
    end
  end

  def test_calculates_weighted_average_from_estimated_leaf_issues
    create_test_issue(:done_ratio => 100, :estimated_hours => 10)
    create_test_issue(:done_ratio => 50, :estimated_hours => 20)
    create_test_issue(:done_ratio => 0, :estimated_hours => 10)

    with_project_percent_done_settings({}) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 50, result.percent_done
      assert_equal 40.0, result.total_weight
      assert_equal 3, result.issue_count
    end
  end

  def test_excludes_parent_issue_when_child_is_in_same_project
    parent = create_test_issue(:done_ratio => 100, :estimated_hours => 100)
    create_test_issue(:parent_issue_id => parent.id, :done_ratio => 0, :estimated_hours => 10)

    with_project_percent_done_settings({}) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 0, result.percent_done
      assert_equal 1, result.issue_count
      assert_equal 10.0, result.total_weight
      assert_equal 1, result.excluded_parent_issue_count
    end
  end

  def test_keeps_parent_issue_when_child_is_in_another_project
    other_project = Project.create!(
      :name => "Other Project Percent Done Test #{SecureRandom.hex(4)}",
      :identifier => "ppd-other-#{SecureRandom.hex(4)}",
      :is_public => true
    )
    with_settings(:cross_project_subtasks => 'system') do
      parent = create_test_issue(:done_ratio => 80, :estimated_hours => 10)
      create_test_issue(:project => other_project, :parent_issue_id => parent.id, :done_ratio => 0, :estimated_hours => 10)

      with_project_percent_done_settings({}) do
        result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

        assert_equal 0, result.percent_done
        assert_equal 1, result.issue_count
        assert_equal 10.0, result.total_weight
      end
    end
  end

  def test_treats_closed_issue_as_100_when_enabled
    create_test_issue(:status => closed_status, :done_ratio => 20, :estimated_hours => 10)

    with_project_percent_done_settings('closed_issue_mode' => 'treat_as_100') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 100, result.percent_done
    end
  end

  def test_empty_non_progress_settings_keep_existing_behavior
    create_test_issue(:done_ratio => 100, :estimated_hours => 10)
    create_test_issue(:done_ratio => 0, :estimated_hours => 10)

    with_project_percent_done_settings(
      'non_progress_status_ids' => [],
      'non_progress_tracker_ids' => []
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 50, result.percent_done
      assert_equal 2, result.issue_count
      assert_equal 0, result.excluded_non_progress_issue_count
      assert_empty result.non_progress_status_ids
      assert_empty result.non_progress_tracker_ids
    end
  end

  def test_excludes_leaf_issue_with_selected_closed_status
    excluded_status = IssueStatus.create!(:name => "Dropped #{SecureRandom.hex(3)}", :is_closed => true)
    create_test_issue(:done_ratio => 0, :estimated_hours => 10)
    create_test_issue(:status => excluded_status, :done_ratio => 100, :estimated_hours => 30)

    with_project_percent_done_settings(
      'non_progress_status_scope' => 'closed_only',
      'non_progress_status_ids' => [excluded_status.id.to_s]
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 0, result.percent_done
      assert_equal 1, result.issue_count
      assert_equal 1, result.eligible_issue_count
      assert_equal 1, result.excluded_non_progress_issue_count
      assert_equal 30.0, result.excluded_non_progress_estimated_hours
      assert_equal 30.0, result.excluded_non_progress_applied_weight
      assert_equal [excluded_status.id], result.non_progress_status_ids
      assert_equal [excluded_status.name], result.non_progress_status_names
      assert_includes result.not_included_rows.map(&:reason), :non_progress_status
    end
  end

  def test_excludes_leaf_issues_with_multiple_selected_closed_statuses
    dropped = IssueStatus.create!(:name => "Dropped #{SecureRandom.hex(3)}", :is_closed => true)
    rejected = IssueStatus.create!(:name => "Rejected #{SecureRandom.hex(3)}", :is_closed => true)
    create_test_issue(:done_ratio => 50, :estimated_hours => 10)
    create_test_issue(:status => dropped, :done_ratio => 100, :estimated_hours => 10)
    create_test_issue(:status => rejected, :done_ratio => 100, :estimated_hours => 10)

    with_project_percent_done_settings(
      'non_progress_status_scope' => 'closed_only',
      'non_progress_status_ids' => [dropped.id.to_s, rejected.id.to_s]
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 50, result.percent_done
      assert_equal 1, result.issue_count
      assert_equal 2, result.excluded_non_progress_issue_count
      assert_equal [dropped.id, rejected.id], result.non_progress_status_ids
    end
  end

  def test_open_status_exclusion_requires_all_status_scope
    parked = IssueStatus.create!(:name => "Parked #{SecureRandom.hex(3)}", :is_closed => false)
    create_test_issue(:done_ratio => 0, :estimated_hours => 10)
    create_test_issue(:status => parked, :done_ratio => 100, :estimated_hours => 10)

    with_project_percent_done_settings(
      'non_progress_status_scope' => 'closed_only',
      'non_progress_status_ids' => [parked.id.to_s]
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 50, result.percent_done
      assert_equal 0, result.excluded_non_progress_issue_count
    end

    with_project_percent_done_settings(
      'non_progress_status_scope' => 'all',
      'non_progress_status_ids' => [parked.id.to_s]
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 0, result.percent_done
      assert_equal 1, result.excluded_non_progress_issue_count
      assert_equal [parked.id], result.non_progress_status_ids
    end
  end

  def test_excludes_leaf_issue_with_selected_tracker
    non_progress_tracker = create_tracker("Non-progress #{SecureRandom.hex(3)}")
    create_test_issue(:done_ratio => 0, :estimated_hours => 10)
    create_test_issue(:tracker => non_progress_tracker, :done_ratio => 100, :estimated_hours => 20)

    with_project_percent_done_settings(
      'non_progress_tracker_scope' => 'all',
      'non_progress_tracker_ids' => [non_progress_tracker.id.to_s]
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 0, result.percent_done
      assert_equal 1, result.issue_count
      assert_equal 1, result.excluded_non_progress_issue_count
      assert_equal [non_progress_tracker.id], result.non_progress_tracker_ids
      assert_equal [non_progress_tracker.name], result.non_progress_tracker_names
      assert_includes result.not_included_rows.map(&:reason), :non_progress_tracker
    end
  end

  def test_tracker_exclusion_requires_tracker_scope
    non_progress_tracker = create_tracker("Non-progress #{SecureRandom.hex(3)}")
    create_test_issue(:done_ratio => 0, :estimated_hours => 10)
    create_test_issue(:tracker => non_progress_tracker, :done_ratio => 100, :estimated_hours => 20)

    with_project_percent_done_settings(
      'non_progress_tracker_scope' => 'none',
      'non_progress_tracker_ids' => [non_progress_tracker.id.to_s]
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 67, result.percent_done
      assert_equal 2, result.issue_count
      assert_equal 0, result.excluded_non_progress_issue_count
      assert_empty result.non_progress_tracker_ids
      refute_includes result.not_included_rows.map(&:reason), :non_progress_tracker
    end
  end

  def test_excludes_leaf_issues_with_multiple_selected_trackers
    tracker_a = create_tracker("Admin #{SecureRandom.hex(3)}")
    tracker_b = create_tracker("Support #{SecureRandom.hex(3)}")
    create_test_issue(:done_ratio => 25, :estimated_hours => 10)
    create_test_issue(:tracker => tracker_a, :done_ratio => 100, :estimated_hours => 10)
    create_test_issue(:tracker => tracker_b, :done_ratio => 100, :estimated_hours => 10)

    with_project_percent_done_settings(
      'non_progress_tracker_scope' => 'all',
      'non_progress_tracker_ids' => [tracker_a.id.to_s, tracker_b.id.to_s]
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 25, result.percent_done
      assert_equal 1, result.issue_count
      assert_equal 2, result.excluded_non_progress_issue_count
      assert_equal [tracker_a.id, tracker_b.id], result.non_progress_tracker_ids
    end
  end

  def test_combined_status_and_tracker_exclusions_count_issue_once
    dropped = IssueStatus.create!(:name => "Dropped #{SecureRandom.hex(3)}", :is_closed => true)
    non_progress_tracker = create_tracker("Non-progress #{SecureRandom.hex(3)}")
    create_test_issue(:done_ratio => 0, :estimated_hours => 10)
    create_test_issue(:status => dropped, :tracker => non_progress_tracker, :done_ratio => 100, :estimated_hours => 10)

    with_project_percent_done_settings(
      'non_progress_status_scope' => 'closed_only',
      'non_progress_status_ids' => [dropped.id.to_s],
      'non_progress_tracker_scope' => 'all',
      'non_progress_tracker_ids' => [non_progress_tracker.id.to_s]
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 0, result.percent_done
      assert_equal 1, result.excluded_non_progress_issue_count
      assert_equal [:non_progress_status_and_tracker], result.not_included_rows.map(&:reason).uniq
    end
  end

  def test_non_progress_status_wins_before_closed_issue_mode
    dropped = IssueStatus.create!(:name => "Dropped #{SecureRandom.hex(3)}", :is_closed => true)
    create_test_issue(:done_ratio => 0, :estimated_hours => 10)
    create_test_issue(:status => dropped, :done_ratio => 20, :estimated_hours => 10)

    with_project_percent_done_settings(
      'closed_issue_mode' => 'treat_as_100',
      'non_progress_status_scope' => 'closed_only',
      'non_progress_status_ids' => [dropped.id.to_s]
    ) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 0, result.percent_done
      assert_equal 10.0, result.total_weight
      assert_equal 1, result.excluded_non_progress_issue_count
      refute_includes result.included_rows.flat_map(&:notes), :closed_issue_treated_as_100
    end
  end

  def test_uses_done_ratio_for_closed_issue_when_configured
    create_test_issue(:status => closed_status, :done_ratio => 20, :estimated_hours => 10)

    with_project_percent_done_settings('closed_issue_mode' => 'use_done_ratio') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 20, result.percent_done
    end
  end

  def test_uses_status_default_done_ratio_when_redmine_is_status_derived
    status = IssueStatus.create!(
      :name => "Progress Status #{SecureRandom.hex(4)}",
      :default_done_ratio => 70
    )
    create_test_issue(:status => status, :done_ratio => 10, :estimated_hours => 10)
    Setting.issue_done_ratio = 'issue_status'

    with_project_percent_done_settings('closed_issue_mode' => 'use_done_ratio') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 70, result.percent_done
    end
  ensure
    Setting.issue_done_ratio = 'issue_field'
  end

  def test_applies_all_rounding_modes
    create_test_issue(:done_ratio => 0, :estimated_hours => 1)
    create_test_issue(:done_ratio => 100, :estimated_hours => 2)

    {
      'nearest_integer' => 67,
      'floor' => 66,
      'ceil' => 67
    }.each do |rounding_mode, expected|
      with_project_percent_done_settings('rounding_mode' => rounding_mode) do
        result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

        assert_equal expected, result.percent_done
        assert_in_delta 66.6667, result.raw_percent_done, 0.0001
      end
    end
  end

  def test_does_not_roll_up_subproject_issues
    subproject = Project.create!(
      :name => "Subproject Percent Done Test #{SecureRandom.hex(4)}",
      :identifier => "ppd-subproject-#{SecureRandom.hex(4)}",
      :parent => test_project,
      :is_public => true
    )
    create_test_issue(:done_ratio => 100, :estimated_hours => 10)
    create_test_issue(:project => subproject, :done_ratio => 0, :estimated_hours => 100)

    with_project_percent_done_settings({}) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 100, result.percent_done
      assert_equal 1, result.all_project_issue_count
    end
  end

  def test_uses_average_estimate_for_unestimated_issues
    create_test_issue(:done_ratio => 100, :estimated_hours => 10)
    create_test_issue(:done_ratio => 0, :estimated_hours => nil)

    with_project_percent_done_settings('unestimated_issue_mode' => 'use_average_estimate') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 50, result.percent_done
      assert_equal 20.0, result.total_weight
      assert_includes result.warnings, :unestimated_issues
    end
  end

  def test_average_estimate_mode_uses_fallback_weight_when_all_issues_are_unestimated
    create_test_issue(:done_ratio => 100, :estimated_hours => nil)
    create_test_issue(:done_ratio => 0, :estimated_hours => 0)

    with_project_percent_done_settings('unestimated_issue_mode' => 'use_average_estimate') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 50, result.percent_done
      assert_equal 2.0, result.total_weight
      assert_equal 2, result.unestimated_eligible_issue_count
      assert_equal 2.0, result.imputed_weight
    end
  end

  def test_uses_weight_one_for_unestimated_issues
    create_test_issue(:done_ratio => 100, :estimated_hours => 3)
    create_test_issue(:done_ratio => 0, :estimated_hours => nil)

    with_project_percent_done_settings('unestimated_issue_mode' => 'use_weight_1') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 75, result.percent_done
      assert_equal 4.0, result.total_weight
      assert_equal 1.0, result.imputed_weight
    end
  end

  def test_ignores_unestimated_issues_when_configured
    create_test_issue(:done_ratio => 100, :estimated_hours => 10)
    create_test_issue(:done_ratio => 0, :estimated_hours => nil)

    with_project_percent_done_settings('unestimated_issue_mode' => 'ignore') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 100, result.percent_done
      assert_equal 10.0, result.total_weight
      assert_equal 2, result.eligible_issue_count
      assert_equal 1, result.unestimated_eligible_issue_count
      assert_equal 1, result.ignored_unestimated_issue_count
    end
  end

  def test_uses_equal_weight_for_all_issues_when_configured
    create_test_issue(:done_ratio => 100, :estimated_hours => 100)
    create_test_issue(:done_ratio => 0, :estimated_hours => 1)

    with_project_percent_done_settings('unestimated_issue_mode' => 'equal_weight_all') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 50, result.percent_done
      assert_equal 2.0, result.total_weight
    end
  end

  def test_zero_and_negative_estimates_are_unestimated
    create_test_issue(:done_ratio => 100, :estimated_hours => 5)
    create_test_issue(:done_ratio => 0, :estimated_hours => 0)
    negative_estimate_issue = create_test_issue(:done_ratio => 0, :estimated_hours => nil)
    negative_estimate_issue.update_column(:estimated_hours, -2)

    with_project_percent_done_settings('unestimated_issue_mode' => 'ignore') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 1, result.estimated_eligible_issue_count
      assert_equal 2, result.unestimated_eligible_issue_count
      assert_equal 2, result.ignored_unestimated_issue_count
    end
  end

  private

  def create_tracker(name)
    tracker = Tracker.create!(:name => name, :default_status => open_status)
    test_project.trackers << tracker unless test_project.trackers.exists?(tracker.id)
    tracker
  end
end
