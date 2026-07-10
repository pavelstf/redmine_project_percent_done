require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::SettingsTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_normalizes_invalid_calculation_settings_to_defaults
    with_project_percent_done_settings(
      'issue_scope' => 'invalid',
      'closed_issue_mode' => 'invalid',
      'unestimated_issue_mode' => 'invalid',
      'rounding_mode' => 'invalid'
    ) do
      assert_equal 'leaf_issues_only', ProjectPercentDone::Settings.issue_scope
      assert_equal 'treat_as_100', ProjectPercentDone::Settings.closed_issue_mode
      assert_equal 'use_average_estimate', ProjectPercentDone::Settings.unestimated_issue_mode
      assert_equal 'nearest_integer', ProjectPercentDone::Settings.rounding_mode
    end
  end
end
