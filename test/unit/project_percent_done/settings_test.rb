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

  def test_history_defaults_are_conservative
    with_project_percent_done_settings({}) do
      refute ProjectPercentDone::Settings.history_enabled?
      assert_equal 'project_only', ProjectPercentDone::Settings.history_detail_level
      assert_equal 'hidden', ProjectPercentDone::Settings.history_visibility
      refute ProjectPercentDone::Settings.history_visible?
      assert_equal 2, ProjectPercentDone::Settings.history_promotion_tolerance_days
      assert_equal 52, ProjectPercentDone::Settings.history_issue_retention_weeks
      assert_equal 4, ProjectPercentDone::Settings.history_inactive_grace_weeks
      assert_equal 'percent_only', ProjectPercentDone::Settings.history_chart_mode
      assert_equal '52', ProjectPercentDone::Settings.history_default_period
      assert_equal 'percentage_points', ProjectPercentDone::Settings.history_change_display
      assert_equal 'calendar', ProjectPercentDone::Settings.history_reporting_year
      assert_equal 1, ProjectPercentDone::Settings.history_fiscal_year_start_month
      refute ProjectPercentDone::Settings.history_email_enabled?
      assert_equal 'weekly_only', ProjectPercentDone::Settings.history_email_notification_level
      assert_equal 'bcc', ProjectPercentDone::Settings.history_email_recipient_mode
    end
  end

  def test_history_numeric_settings_fall_back_when_out_of_range
    with_project_percent_done_settings(
      'history_promotion_tolerance_days' => '4',
      'history_issue_retention_weeks' => '12',
      'history_inactive_grace_weeks' => '53',
      'history_fiscal_year_start_month' => '0'
    ) do
      assert_equal 2, ProjectPercentDone::Settings.history_promotion_tolerance_days
      assert_equal 52, ProjectPercentDone::Settings.history_issue_retention_weeks
      assert_equal 4, ProjectPercentDone::Settings.history_inactive_grace_weeks
      assert_equal 1, ProjectPercentDone::Settings.history_fiscal_year_start_month
    end
  end

  def test_history_visibility_modes
    admin = User.find(1)
    user = User.where(:admin => false).where.not(:status => User::STATUS_ANONYMOUS).first

    with_project_percent_done_settings('history_visibility' => 'hidden') do
      assert_equal 'hidden', ProjectPercentDone::Settings.history_visibility
      refute ProjectPercentDone::Settings.history_visible?(admin)
      refute ProjectPercentDone::Settings.history_visible?(user)
    end

    with_project_percent_done_settings('history_visibility' => 'admins_only') do
      assert_equal 'admins_only', ProjectPercentDone::Settings.history_visibility
      assert ProjectPercentDone::Settings.history_visible?(admin)
      refute ProjectPercentDone::Settings.history_visible?(user)
    end

    with_project_percent_done_settings('history_visibility' => 'project_access') do
      assert_equal 'project_access', ProjectPercentDone::Settings.history_visibility
      assert ProjectPercentDone::Settings.history_visible?(admin)
      assert ProjectPercentDone::Settings.history_visible?(user)
    end

    with_project_percent_done_settings('history_visibility' => 'invalid') do
      assert_equal 'hidden', ProjectPercentDone::Settings.history_visibility
      refute ProjectPercentDone::Settings.history_visible?(admin)
    end
  end
end
