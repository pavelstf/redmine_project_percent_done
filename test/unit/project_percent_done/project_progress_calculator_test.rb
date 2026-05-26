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
    end
  end

  def test_keeps_parent_issue_when_child_is_in_another_project
    other_project = Project.create!(
      :name => "Other Project Percent Done Test #{SecureRandom.hex(4)}",
      :identifier => "ppd-other-#{SecureRandom.hex(4)}",
      :is_public => true
    )
    parent = create_test_issue(:done_ratio => 80, :estimated_hours => 10)
    create_test_issue(:project => other_project, :parent_issue_id => parent.id, :done_ratio => 0, :estimated_hours => 10)

    with_project_percent_done_settings({}) do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 80, result.percent_done
      assert_equal 1, result.issue_count
    end
  end

  def test_treats_closed_issue_as_100_when_enabled
    create_test_issue(:status => closed_status, :done_ratio => 20, :estimated_hours => 10)

    with_project_percent_done_settings('closed_issue_mode' => 'treat_as_100') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 100, result.percent_done
    end
  end

  def test_uses_done_ratio_for_closed_issue_when_configured
    create_test_issue(:status => closed_status, :done_ratio => 20, :estimated_hours => 10)

    with_project_percent_done_settings('closed_issue_mode' => 'use_done_ratio') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 20, result.percent_done
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

  def test_ignores_unestimated_issues_when_configured
    create_test_issue(:done_ratio => 100, :estimated_hours => 10)
    create_test_issue(:done_ratio => 0, :estimated_hours => nil)

    with_project_percent_done_settings('unestimated_issue_mode' => 'ignore') do
      result = ProjectPercentDone::ProjectProgressCalculator.new(test_project).call

      assert_equal 100, result.percent_done
      assert_equal 10.0, result.total_weight
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
end
