require File.expand_path('../test_helper', __dir__)

class ProjectPercentDoneControllerTest < ActionController::TestCase
  include ProjectPercentDoneTestSupport

  def setup
    @request.session[:user_id] = 1
    Setting.issue_done_ratio = 'issue_field'
  end

  def test_json_endpoint_returns_not_found_when_rest_api_is_disabled
    with_project_percent_done_settings('enable_rest_api' => '0') do
      get :show, :params => { :project_id => test_project.identifier, :format => 'json' }

      assert_response 404
    end
  end

  def test_json_endpoint_returns_project_percent_done_when_rest_api_is_enabled
    create_test_issue(:done_ratio => 50, :estimated_hours => 10)

    with_project_percent_done_settings('enable_rest_api' => '1') do
      get :show, :params => { :project_id => test_project.identifier, :format => 'json' }

      assert_response :success
      payload = ActiveSupport::JSON.decode(@response.body)
      assert_equal 50, payload['project_percent_done']['percent_done']
      assert_equal test_project.identifier, payload['project_percent_done']['project_identifier']
      assert_equal(
        %w[
          calculation_mode closed_issue_mode estimated_issue_count issue_count
          not_included_issue_count percent_done project_id project_identifier
          raw_percent_done total_weight unestimated_issue_count
          unestimated_issue_mode warnings
        ],
        payload['project_percent_done'].keys.sort
      )
    end
  end
end
