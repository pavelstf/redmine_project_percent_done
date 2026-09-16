require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::SettingsTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_normalizes_invalid_calculation_settings_to_defaults
    with_project_percent_done_settings(
      'issue_scope' => 'invalid',
      'non_progress_status_scope' => 'invalid',
      'non_progress_tracker_scope' => 'invalid',
      'closed_issue_mode' => 'invalid',
      'unestimated_issue_mode' => 'invalid',
      'rounding_mode' => 'invalid'
    ) do
      assert_equal 'leaf_issues_only', ProjectPercentDone::Settings.issue_scope
      assert_equal 'none', ProjectPercentDone::Settings.non_progress_status_scope
      assert_equal 'none', ProjectPercentDone::Settings.non_progress_tracker_scope
      assert_equal 'treat_as_100', ProjectPercentDone::Settings.closed_issue_mode
      assert_equal 'use_average_estimate', ProjectPercentDone::Settings.unestimated_issue_mode
      assert_equal 'nearest_integer', ProjectPercentDone::Settings.rounding_mode
    end
  end

  def test_non_progress_ids_are_normalized_and_filtered_by_scope
    open = IssueStatus.create!(:name => "Parked #{SecureRandom.hex(3)}", :is_closed => false)
    closed = IssueStatus.create!(:name => "Dropped #{SecureRandom.hex(3)}", :is_closed => true)
    tracker = Tracker.create!(:name => "Admin #{SecureRandom.hex(3)}", :default_status => open_status)

    with_project_percent_done_settings(
      'non_progress_status_scope' => 'closed_only',
      'non_progress_status_ids' => ['', open.id.to_s, closed.id.to_s, closed.id.to_s, 'not-a-number'],
      'non_progress_tracker_scope' => 'all',
      'non_progress_tracker_ids' => ['', tracker.id.to_s, tracker.id.to_s, '999999999']
    ) do
      assert_equal [closed.id], ProjectPercentDone::Settings.non_progress_status_ids
      assert_equal [tracker.id], ProjectPercentDone::Settings.non_progress_tracker_ids
    end

    with_project_percent_done_settings(
      'non_progress_status_scope' => 'all',
      'non_progress_status_ids' => [open.id.to_s, closed.id.to_s]
    ) do
      assert_equal [open.id, closed.id], ProjectPercentDone::Settings.non_progress_status_ids
    end
  end

  def test_no_status_exclusion_scope_ignores_saved_status_ids
    closed = IssueStatus.create!(:name => "Dropped #{SecureRandom.hex(3)}", :is_closed => true)

    with_project_percent_done_settings(
      'non_progress_status_scope' => 'none',
      'non_progress_status_ids' => [closed.id.to_s]
    ) do
      assert_equal [], ProjectPercentDone::Settings.non_progress_status_ids
      assert_equal [], ProjectPercentDone::Settings.non_progress_statuses
    end
  end

  def test_no_tracker_exclusion_scope_ignores_saved_tracker_ids
    tracker = Tracker.create!(:name => "Admin #{SecureRandom.hex(3)}", :default_status => open_status)

    with_project_percent_done_settings(
      'non_progress_tracker_scope' => 'none',
      'non_progress_tracker_ids' => [tracker.id.to_s]
    ) do
      assert_equal [], ProjectPercentDone::Settings.non_progress_tracker_ids
      assert_equal [], ProjectPercentDone::Settings.non_progress_trackers
    end
  end

  def test_tracker_exclusion_scope_keeps_selected_tracker_ids
    tracker = Tracker.create!(:name => "Admin #{SecureRandom.hex(3)}", :default_status => open_status)

    with_project_percent_done_settings(
      'non_progress_tracker_scope' => 'all',
      'non_progress_tracker_ids' => [tracker.id.to_s]
    ) do
      assert_equal 'all', ProjectPercentDone::Settings.non_progress_tracker_scope
      assert_equal [tracker.id], ProjectPercentDone::Settings.non_progress_tracker_ids
      assert_equal [tracker], ProjectPercentDone::Settings.non_progress_trackers
    end
  end

  def test_legacy_tracker_ids_without_scope_keep_tracker_exclusions_enabled
    tracker = Tracker.create!(:name => "Admin #{SecureRandom.hex(3)}", :default_status => open_status)
    previous = Setting.plugin_redmine_project_percent_done

    Setting.plugin_redmine_project_percent_done = { 'non_progress_tracker_ids' => [tracker.id.to_s] }

    assert_equal 'all', ProjectPercentDone::Settings.non_progress_tracker_scope
    assert_equal [tracker.id], ProjectPercentDone::Settings.non_progress_tracker_ids
    assert_equal 'all', ProjectPercentDone::Settings.form_values('non_progress_tracker_ids' => [tracker.id.to_s])['non_progress_tracker_scope']
  ensure
    Setting.plugin_redmine_project_percent_done = previous
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
