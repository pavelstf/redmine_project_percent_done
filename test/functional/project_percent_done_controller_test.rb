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

  def test_regular_user_can_view_aggregate_history_without_issue_snapshot_subjects
    snapshot = ProjectPercentDoneSnapshot.create!(
      :project => test_project, :snapshot_kind => 'official', :period_end => Date.new(2026, 7, 12),
      :captured_at => Time.zone.local(2026, 7, 12, 23, 59), :project_state => 'active',
      :display_percent_done => 50
    )
    ProjectPercentDoneIssueSnapshot.create!(
      :snapshot => snapshot, :issue_id => 999_999, :subject => 'ADMIN-ONLY HISTORIC SUBJECT', :included => true
    )
    user = User.where(:admin => false).where.not(:status => User::STATUS_ANONYMOUS).first
    @request.session[:user_id] = user.id

    with_project_percent_done_settings(
      'display_project_tab' => '1',
      'history_enabled' => '1',
      'history_visibility' => 'project_access'
    ) do
      get :history, :params => { :project_id => test_project.identifier }
      assert_response :success
      assert_includes @response.body, I18n.t(:label_project_percent_done_history)
      refute_includes @response.body, 'ADMIN-ONLY HISTORIC SUBJECT'
    end
  end

  def test_calculation_and_history_are_rendered_on_separate_pages
    with_project_percent_done_settings(
      'display_project_tab' => '1',
      'history_enabled' => '1',
      'history_visibility' => 'project_access'
    ) do
      get :show, :params => { :project_id => test_project.identifier }

      assert_response :success
      assert_equal :project_percent_done, @controller.current_menu_item
      assert_includes @response.body, I18n.t(:label_project_percent_done_details)
      assert_select "a[href=\"#{project_percent_done_history_path(:project_id => test_project.identifier)}\"]",
                    :text => I18n.t(:label_project_percent_done_history_tab)
      refute_includes @response.body, 'data-ppd-history'

      get :history, :params => { :project_id => test_project.identifier }

      assert_response :success
      assert_equal :project_percent_done_history, @controller.current_menu_item
      assert_select 'section[data-ppd-history]', :count => 1
      assert_select "form.ppd-history-controls[action=\"#{project_percent_done_history_path(:project_id => test_project.identifier)}\"]"
      assert_select 'select[name=?]', 'history_period_type'
      assert_includes @response.body, I18n.t(
        :text_project_percent_done_history_no_official_snapshots,
        :period_type => I18n.t(:label_project_percent_done_history_period_type_weekly).downcase
      )
      assert_includes @response.body, I18n.t(:label_project_percent_done_history_chart_mode_control)
      refute_includes @response.body, I18n.t(:label_project_percent_done_history_chart_mode)
    end
  end

  def test_history_page_can_render_monthly_snapshots
    ProjectPercentDoneSnapshot.create!(
      :project => test_project, :snapshot_kind => 'official', :period_type => 'monthly',
      :period_end => Date.new(2026, 7, 31),
      :captured_at => Time.zone.local(2026, 8, 1, 0, 15), :project_state => 'active',
      :display_percent_done => 44
    )

    with_project_percent_done_settings(
      'display_project_tab' => '1',
      'history_enabled' => '1',
      'history_visibility' => 'project_access'
    ) do
      get :history, :params => {
        :project_id => test_project.identifier,
        :history_period_type => 'monthly',
        :history_period => '6'
      }

      assert_response :success
      assert_select 'select[name=?] option[selected=?][value=?]', 'history_period_type', 'selected', 'monthly'
      assert_includes @response.body, '44%'
      refute_includes @response.body, I18n.t(:label_project_percent_done_history_forecast)
    end
  end

  def test_project_menu_items_use_project_visibility_permission
    items = Redmine::MenuManager.items(:project_menu)
    calculation_item = items.children.detect { |item| item.name == :project_percent_done }
    history_item = items.children.detect { |item| item.name == :project_percent_done_history }
    user = User.where(:admin => false).where.not(:status => User::STATUS_ANONYMOUS).first

    assert_equal :view_project, calculation_item.permission
    assert_equal :view_project, history_item.permission

    with_project_percent_done_settings(
      'display_project_tab' => '1',
      'history_enabled' => '1',
      'history_visibility' => 'project_access'
    ) do
      assert_nothing_raised { calculation_item.allowed?(user, test_project) }
      assert_nothing_raised { history_item.allowed?(user, test_project) }
    end
  end

  def test_history_page_is_not_available_without_enabled_collection_or_existing_history
    with_project_percent_done_settings('history_enabled' => '0', 'history_visibility' => 'project_access') do
      get :history, :params => { :project_id => test_project.identifier }

      assert_response 404
    end
  end

  def test_history_page_is_hidden_when_collection_runs_in_shadow_mode
    with_project_percent_done_settings('history_enabled' => '1', 'history_visibility' => 'hidden') do
      get :history, :params => { :project_id => test_project.identifier }

      assert_response 404
    end
  end

  def test_admin_only_history_visibility_allows_admin_but_not_regular_user
    with_project_percent_done_settings('history_enabled' => '1', 'history_visibility' => 'admins_only') do
      get :history, :params => { :project_id => test_project.identifier }
      assert_response :success

      user = User.where(:admin => false).where.not(:status => User::STATUS_ANONYMOUS).first
      @request.session[:user_id] = user.id

      get :history, :params => { :project_id => test_project.identifier }
      assert_response 404
    end
  end
end
