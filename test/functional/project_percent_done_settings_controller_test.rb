require File.expand_path('../test_helper', __dir__)

class ProjectPercentDoneSettingsControllerTest < ActionController::TestCase
  include ProjectPercentDoneTestSupport

  tests SettingsController

  setup do
    @request.session[:user_id] = 1
  end

  def test_settings_page_renders_history_help_and_diagnostics
    get :plugin, :params => { :id => ProjectPercentDone::PLUGIN_ID }
    assert_response :success
    assert_includes @response.body, I18n.t(:label_project_percent_done_history_settings)
    assert_includes @response.body, I18n.t(:label_project_percent_done_history_diagnostics)
    assert_select 'form.ppd-inline-form', :count => 0
    assert_select 'a.ppd-diagnostic-action[data-method="post"]', :count => 3
  end

  def test_settings_page_embeds_values_for_dynamic_project_type_selection
    field = create_project_type_custom_field

    get :plugin, :params => { :id => ProjectPercentDone::PLUGIN_ID }

    assert_response :success
    assert_select 'select#ppd-history-project-type-field[data-possible-values]'
    encoded_values = css_select('select#ppd-history-project-type-field').first['data-possible-values']
    assert_equal ['Internal', 'External'], JSON.parse(encoded_values).fetch(field.id.to_s)
    assert_select 'select#ppd-history-project-type-values[multiple]'
  end

  def test_settings_page_fills_new_defaults_for_legacy_saved_settings
    previous = Setting.plugin_redmine_project_percent_done
    Setting.plugin_redmine_project_percent_done = {
      'display_overview' => '0',
      'history_promotion_tolerance_days' => '',
      'history_issue_retention_weeks' => '',
      'history_inactive_grace_weeks' => '',
      'history_email_subject_template' => ''
    }

    get :plugin, :params => { :id => ProjectPercentDone::PLUGIN_ID }

    assert_response :success
    assert_select 'input[name="settings[history_promotion_tolerance_days]"][value="2"]'
    assert_select 'input[name="settings[history_issue_retention_weeks]"][value="52"]'
    assert_select 'input[name="settings[history_inactive_grace_weeks]"][value="4"]'
    assert_select 'input[name="settings[history_email_subject_template]"]' do |inputs|
      assert_equal ProjectPercentDone::Settings::DEFAULTS['history_email_subject_template'], inputs.first['value']
    end
    assert_select 'input[name="settings[display_overview]"][type="checkbox"][checked]', :count => 0
  ensure
    Setting.plugin_redmine_project_percent_done = previous
  end

  def test_history_dependent_sections_are_initially_hidden_when_history_is_disabled
    get :plugin, :params => { :id => ProjectPercentDone::PLUGIN_ID }

    assert_response :success
    assert_select 'fieldset[data-ppd-requires-history]', :count => 3
    assert_select 'fieldset[data-ppd-requires-history][hidden]', :count => 3
    assert_includes @response.body, 'refreshHistorySections'
  end

  def test_history_dependent_sections_are_initially_visible_when_history_is_enabled
    with_project_percent_done_settings('history_enabled' => '1') do
      get :plugin, :params => { :id => ProjectPercentDone::PLUGIN_ID }

      assert_response :success
      assert_select 'fieldset[data-ppd-requires-history]', :count => 3
      assert_select 'fieldset[data-ppd-requires-history][hidden]', :count => 0
      assert_select 'fieldset.ppd-settings-cron' do
        assert_select 'code', :text => ProjectPercentDone::History::CronCommand::SCHEDULE_EXAMPLE
        assert_select 'code#ppd-history-rake-command', :text => /redmine:project_percent_done:snapshots/
        assert_select 'code#ppd-history-full-cron-command', :text => /project_percent_done_snapshots\.log/
        assert_select 'button.ppd-copy-command[data-copy-target]', :count => 2
      end
    end
  end

  def test_invalid_enabled_history_configuration_is_not_saved
    original = Setting.plugin_redmine_project_percent_done
    post :plugin, :params => {
      :id => ProjectPercentDone::PLUGIN_ID,
      :settings => ProjectPercentDone::Settings::DEFAULTS.merge('history_enabled' => '1')
    }
    assert_response :success
    assert_includes @response.body, I18n.t(:text_project_percent_done_project_type_custom_field_missing)
    assert_equal original, Setting.plugin_redmine_project_percent_done
  end

  def test_valid_history_configuration_is_saved
    field = ProjectCustomField.create!(
      :name => "Single project type #{SecureRandom.hex(3)}",
      :field_format => 'list',
      :possible_values => %w[Internal External],
      :multiple => false,
      :is_for_all => true
    )
    proposed = ProjectPercentDone::Settings::DEFAULTS.merge(
      'history_enabled' => '1',
      'history_project_type_custom_field_id' => field.id.to_s,
      'history_project_type_values' => ['Internal'],
      'history_promotion_tolerance_days' => '3'
    )

    post :plugin, :params => {
      :id => ProjectPercentDone::PLUGIN_ID,
      :settings => proposed
    }

    assert_redirected_to plugin_settings_path(ProjectPercentDone::PLUGIN_ID)
    saved = Setting.plugin_redmine_project_percent_done
    assert_equal '1', saved['history_enabled']
    assert_equal field.id.to_s, saved['history_project_type_custom_field_id']
    assert_equal ['Internal'], saved['history_project_type_values']
    assert_equal '3', saved['history_promotion_tolerance_days']
  end
end
