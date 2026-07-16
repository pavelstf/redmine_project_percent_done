require File.expand_path('../test_helper', __dir__)

class ProjectPercentDoneHooksTest < ActionController::TestCase
  tests ProjectsController
  include ProjectPercentDoneTestSupport

  def setup
    @request.session[:user_id] = 1
  end

  def test_project_overview_hook_renders_history_link_without_plugin_helper_context
    with_project_percent_done_settings(
      'display_overview' => '1',
      'history_enabled' => '1'
    ) do
      get :show, :params => { :id => test_project.identifier }

      assert_response :success
      assert_select "a[href=\"#{project_percent_done_history_path(:project_id => test_project.identifier)}\"]",
                    :text => I18n.t(:label_project_percent_done_history_tab)
    end
  end
end
