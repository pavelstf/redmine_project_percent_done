require File.expand_path('../test_helper', __dir__)

class ProjectPercentDoneAdminControllerTest < ActionController::TestCase
  include ProjectPercentDoneTestSupport

  tests ProjectPercentDoneAdminController

  def test_regular_user_cannot_preview_or_purge_history
    user = User.where(:admin => false).where.not(:status => User::STATUS_ANONYMOUS).first
    @request.session[:user_id] = user.id

    post :preview
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
end
