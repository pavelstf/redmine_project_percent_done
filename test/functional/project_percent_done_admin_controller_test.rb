require File.expand_path('../test_helper', __dir__)

class ProjectPercentDoneAdminControllerTest < ActionController::TestCase
  include ProjectPercentDoneTestSupport

  tests ProjectPercentDoneAdminController

  def test_regular_user_cannot_preview_or_purge_history
    user = User.where(:admin => false).where.not(:status => User::STATUS_ANONYMOUS).first
    @request.session[:user_id] = user.id

    post :preview
    assert_response 403

    post :test_email
    assert_response 403

    delete :purge, :params => { :project_id => test_project.id, :confirm => test_project.identifier }
    assert_response 403
  end

  def test_admin_purge_requires_exact_identifier_and_deletes_only_history
    @request.session[:user_id] = 1
    snapshot = ProjectPercentDoneSnapshot.create!(
      :project => test_project, :snapshot_kind => 'official', :period_end => Date.new(2026, 7, 12),
      :captured_at => Time.zone.local(2026, 7, 12, 23, 59), :project_state => 'active'
    )

    delete :purge, :params => { :project_id => test_project.id, :confirm => 'wrong' }
    assert_response 403
    assert ProjectPercentDoneSnapshot.exists?(snapshot.id)

    delete :purge, :params => { :project_id => test_project.id, :confirm => test_project.identifier }
    assert_redirected_to project_percent_done_path(:project_id => test_project.identifier)
    refute ProjectPercentDoneSnapshot.exists?(snapshot.id)
    assert Project.exists?(test_project.id)
  end

  def test_capture_is_forbidden_when_progress_history_plugin_is_active
    @request.session[:user_id] = 1
    with_progress_history_plugin_active(true) do
      post :capture

      assert_response :forbidden
    end
  end

  def test_test_email_failure_never_renders_external_exception_html
    @request.session[:user_id] = 1
    notifier = ProjectPercentDone::History::Notifier
    original = notifier.method(:deliver_test)
    notifier.singleton_class.define_method(:deliver_test) do
      raise StandardError, '<img src=x onerror=alert(1)>SMTP_SECRET'
    end
    with_progress_history_plugin_active(false) do
      post :test_email
      assert_response :redirect
      assert_equal I18n.t(:text_project_percent_done_history_test_email_failed), flash[:error]
      rendered = @controller.view_context.render_flash_messages
      refute_includes rendered, '<img'
      refute_includes rendered, 'SMTP_SECRET'
    end
  ensure
    notifier.singleton_class.define_method(:deliver_test, original) if original
  end

  def test_test_email_is_forbidden_when_progress_history_plugin_is_active
    @request.session[:user_id] = 1
    with_progress_history_plugin_active(true) do
      post :test_email
      assert_response :forbidden
    end
  end
end
