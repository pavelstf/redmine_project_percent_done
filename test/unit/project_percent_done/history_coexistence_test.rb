require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::CoexistenceTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_owns_history_when_progress_history_plugin_is_not_active
    with_progress_history_plugin_active(false) do
      assert ProjectPercentDone::History::Coexistence.owns_history?
    end
  end

  def test_does_not_own_history_when_progress_history_plugin_is_active
    with_progress_history_plugin_active(true) do
      refute ProjectPercentDone::History::Coexistence.owns_history?
    end
  end

  def test_progress_history_settings_activate_coexistence_when_available
    skip 'Project Progress History plugin is not loaded in this Redmine runtime' unless defined?(ProjectProgressHistory::Settings)

    previous_settings = Setting.plugin_redmine_project_progress_history
    Setting.plugin_redmine_project_progress_history = { 'history_enabled' => '1', 'history_page_enabled' => '0' }

    assert ProjectPercentDone::History::Coexistence.progress_history_plugin_active?
  ensure
    Setting.plugin_redmine_project_progress_history = previous_settings if defined?(previous_settings)
  end

  def test_sanitizes_project_percent_done_history_flags
    sanitized = ProjectPercentDone::History::Coexistence.sanitize_project_percent_done_settings(
      'display_project_tab' => '1',
      'history_enabled' => '1',
      :history_email_enabled => '1'
    )

    assert_equal '1', sanitized['display_project_tab']
    assert_equal '0', sanitized['history_enabled']
    assert_equal '0', sanitized['history_email_enabled']
  end
end
