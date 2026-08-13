class ProjectPercentDoneAdminController < ApplicationController
  before_action :require_system_admin

  def preview
    result = ProjectPercentDone::History::SnapshotCollector.new(
      :source => 'admin_preview',
      :preview => true
    ).call.run
    flash[:notice] = l(
      :text_project_percent_done_history_preview_result,
      :projects => result[:project_count],
      :issues => result[:estimated_issue_count],
      :errors => result[:errors].join(', ').presence || l(:label_none)
    )
    redirect_to_plugin_settings
  end

  def capture
    run = ProjectPercentDone::History::SnapshotCollector.new(:source => 'admin').call.run
    flash[:notice] = l(
      :text_project_percent_done_history_capture_result,
      :status => run.status,
      :projects => run.projects_succeeded,
      :failures => run.projects_failed
    )
    redirect_to_plugin_settings
  end

  def test_email
    ProjectPercentDone::History::Notifier.deliver_test
    flash[:notice] = l(:text_project_percent_done_history_test_email_sent)
    redirect_to_plugin_settings
  rescue StandardError => error
    flash[:error] = error.message
    redirect_to_plugin_settings
  end

  def purge
    project = Project.find(params[:project_id])
    unless params[:confirm].to_s == project.identifier
      render_403
      return
    end

    snapshot_count = ProjectPercentDoneSnapshot.where(:project_id => project.id).count
    issue_count = ProjectPercentDoneIssueSnapshot
                  .joins(:snapshot)
                  .where(:project_percent_done_snapshots => { :project_id => project.id })
                  .count
    ProjectPercentDoneSnapshot.where(:project_id => project.id).destroy_all
    flash[:notice] = l(
      :text_project_percent_done_history_purge_result,
      :snapshots => snapshot_count,
      :issues => issue_count
    )
    redirect_to project_percent_done_path(:project_id => project.identifier)
  end

  def purge_preview
    project = Project.find(params[:project_id])
    render :json => {
      :project => project.identifier,
      :snapshots => ProjectPercentDoneSnapshot.where(:project_id => project.id).count,
      :issue_snapshots => ProjectPercentDoneIssueSnapshot.joins(:snapshot).where(
        :project_percent_done_snapshots => { :project_id => project.id }
      ).count
    }
  end

  private

  def require_system_admin
    render_403 unless User.current.admin?
  end

  def redirect_to_plugin_settings
    redirect_to plugin_settings_path(ProjectPercentDone::PLUGIN_ID)
  end
end
