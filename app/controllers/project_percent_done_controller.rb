class ProjectPercentDoneController < ApplicationController
  helper :project_percent_done

  before_action :find_project
  before_action :authorize_project_visibility
  before_action :ensure_enabled_location

  accept_api_auth :show

  def show
    @result = ProjectPercentDone::ProjectProgressCalculator.new(@project, :mode => result_mode).call

    respond_to do |format|
      format.html
      format.json { render :json => { :project_percent_done => api_payload } }
      format.api
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    @project = Project.find_by_identifier(params[:project_id])
    render_404 unless @project
  end

  def authorize_project_visibility
    render_403 unless @project && @project.visible?
  end

  def ensure_enabled_location
    if request.format.html?
      render_404 unless ProjectPercentDone::Settings.html_details_enabled?
    else
      render_404 unless ProjectPercentDone::Settings.enable_rest_api?
    end
  end

  def api_payload
    {
      :project_id => @project.id,
      :project_identifier => @project.identifier,
      :percent_done => @result.percent_done,
      :raw_percent_done => @result.raw_percent_done,
      :issue_count => @result.issue_count,
      :not_included_issue_count => @result.not_included_issue_count,
      :estimated_issue_count => @result.estimated_issue_count,
      :unestimated_issue_count => @result.unestimated_issue_count,
      :total_weight => @result.total_weight,
      :closed_issue_mode => ProjectPercentDone::Settings.closed_issue_mode,
      :unestimated_issue_mode => ProjectPercentDone::Settings.unestimated_issue_mode,
      :calculation_mode => 'live',
      :warnings => @result.warnings
    }
  end

  def result_mode
    request.format.html? ? :details : :summary
  end
end
