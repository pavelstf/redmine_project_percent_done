require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::PublicApi::V1Test < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def setup
    Setting.issue_done_ratio = 'issue_field'
  end

  def test_capabilities_exposes_the_versioned_contract
    with_project_percent_done_settings({}) do
      capabilities = ProjectPercentDone::PublicApi::V1.capabilities

      assert_equal 'project_percent_done', capabilities.contract_name
      assert_equal '1.0', capabilities.contract_version
      assert_equal '1.1.1', capabilities.plugin_version
      assert_equal '1.0', capabilities.algorithm_version
      assert_equal 'live', capabilities.calculation_mode
      assert_equal 'none', capabilities.persistence_mode
      assert_equal 'leaf_issues_only', capabilities.issue_scope
      assert_equal 'treat_as_100', capabilities.closed_issue_mode
      assert_equal 'use_average_estimate', capabilities.unestimated_issue_mode
      assert_equal true, capabilities.hours_weighted
      assert_equal true, capabilities.supports_raw_percent_done
      assert_equal true, capabilities.supports_estimate_coverage
      assert capabilities.frozen?
    end
  end

  def test_calculate_reports_mixed_estimate_coverage_and_weights
    create_test_issue(:done_ratio => 100, :estimated_hours => 10)
    create_test_issue(:done_ratio => 0, :estimated_hours => nil)

    with_project_percent_done_settings('unestimated_issue_mode' => 'use_average_estimate') do
      result = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)

      assert_equal true, result.progress_available
      assert_nil result.unavailable_reason
      assert_equal 50.0, result.raw_percent_done
      assert_equal 50, result.display_percent_done
      assert_equal 2, result.all_project_issue_count
      assert_equal 2, result.eligible_issue_count
      assert_equal 1, result.estimated_eligible_issue_count
      assert_equal 1, result.unestimated_eligible_issue_count
      assert_equal 2, result.included_issue_count
      assert_equal 0, result.excluded_parent_issue_count
      assert_equal 0, result.ignored_unestimated_issue_count
      assert_equal 10.0, result.known_estimated_hours
      assert_equal 10.0, result.imputed_weight
      assert_equal 20.0, result.total_applied_weight
      assert_equal 50.0, result.estimate_coverage_percent
      assert_equal 50.0, result.known_weight_percent
      assert_equal [:unestimated_issues], result.warnings
    end
  end

  def test_ignore_mode_keeps_unestimated_issues_in_coverage
    create_test_issue(:done_ratio => 100, :estimated_hours => 8)
    create_test_issue(:done_ratio => 0, :estimated_hours => 0)

    with_project_percent_done_settings('unestimated_issue_mode' => 'ignore') do
      result = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)

      assert_equal 2, result.eligible_issue_count
      assert_equal 1, result.unestimated_eligible_issue_count
      assert_equal 1, result.included_issue_count
      assert_equal 1, result.ignored_unestimated_issue_count
      assert_equal 50.0, result.estimate_coverage_percent
      assert_equal 8.0, result.known_estimated_hours
      assert_equal 0.0, result.imputed_weight
      assert_equal 8.0, result.total_applied_weight
      assert_equal 100.0, result.known_weight_percent
      assert_includes result.warnings, :unestimated_issues
    end
  end

  def test_equal_weight_mode_is_not_hours_weighted
    create_test_issue(:done_ratio => 100, :estimated_hours => 100)
    create_test_issue(:done_ratio => 0, :estimated_hours => nil)

    with_project_percent_done_settings('unestimated_issue_mode' => 'equal_weight_all') do
      capabilities = ProjectPercentDone::PublicApi::V1.capabilities
      result = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)

      assert_equal false, capabilities.hours_weighted
      assert_equal false, result.hours_weighted
      assert_equal 100.0, result.known_estimated_hours
      assert_equal 1.0, result.imputed_weight
      assert_equal 2.0, result.total_applied_weight
      assert_nil result.known_weight_percent
    end
  end

  def test_raw_and_display_percentages_are_distinct
    create_test_issue(:done_ratio => 0, :estimated_hours => 1)
    create_test_issue(:done_ratio => 100, :estimated_hours => 2)

    with_project_percent_done_settings('rounding_mode' => 'floor') do
      result = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)

      assert_in_delta 66.6667, result.raw_percent_done, 0.0001
      assert_equal 66, result.display_percent_done
    end
  end

  def test_zero_progress_is_available
    create_test_issue(:done_ratio => 0, :estimated_hours => 5)

    with_project_percent_done_settings({}) do
      result = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)

      assert_equal true, result.progress_available
      assert_nil result.unavailable_reason
      assert_equal 0.0, result.raw_percent_done
      assert_equal 0, result.display_percent_done
    end
  end

  def test_no_issues_is_unavailable
    with_project_percent_done_settings({}) do
      result = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)

      assert_equal false, result.progress_available
      assert_equal :no_eligible_issues, result.unavailable_reason
      assert_nil result.raw_percent_done
      assert_nil result.display_percent_done
      assert_nil result.estimate_coverage_percent
      assert_equal [:no_issues], result.warnings
    end
  end

  def test_no_usable_weight_is_unavailable
    create_test_issue(:done_ratio => 50, :estimated_hours => nil)

    with_project_percent_done_settings('unestimated_issue_mode' => 'ignore') do
      result = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)

      assert_equal false, result.progress_available
      assert_equal :no_usable_weight, result.unavailable_reason
      assert_nil result.raw_percent_done
      assert_nil result.display_percent_done
      assert_equal 1, result.ignored_unestimated_issue_count
      assert_equal [:unestimated_issues, :all_issues_unestimated, :no_usable_weight], result.warnings
    end
  end

  def test_public_result_does_not_expose_issue_records_or_ids
    issue = create_test_issue(:done_ratio => 50, :estimated_hours => 5)

    with_project_percent_done_settings({}) do
      result = ProjectPercentDone::PublicApi::V1.calculate(:project => test_project)
      payload = result.to_h

      refute_includes payload.keys, :included_issue_ids
      refute_includes payload.values, issue
      assert result.frozen?
      assert result.warnings.frozen?
      assert_raises(FrozenError) { result.warnings << :changed }

      payload[:warnings] << :copy_changed
      refute_includes result.warnings, :copy_changed
    end
  end

  def test_invalid_project_arguments_raise_argument_error
    assert_raises(ArgumentError) { ProjectPercentDone::PublicApi::V1.calculate(:project => nil) }
    assert_raises(ArgumentError) { ProjectPercentDone::PublicApi::V1.calculate(:project => Object.new) }
    assert_raises(ArgumentError) { ProjectPercentDone::PublicApi::V1.calculate(:project => Project.new) }
  end
end
