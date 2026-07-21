class ProjectPercentDoneController < ApplicationController
  helper :project_percent_done

  menu_item :project_percent_done, :only => :show
  menu_item :project_percent_done_history, :only => :history

  before_action :find_project
  before_action :authorize_project_visibility
  before_action :ensure_enabled_location, :only => :show
  before_action :ensure_history_available, :only => :history

  accept_api_auth :show

  def show
    @result = ProjectPercentDone::ProjectProgressCalculator.new(@project, :mode => result_mode).call

    respond_to do |format|
      format.html
      format.json { render :json => { :project_percent_done => api_payload } }
      format.api
    end
  end

  def history
    load_history
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

  def ensure_history_available
    render_404 unless ProjectPercentDone::Settings.history_available_for_project?(@project)
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

  def load_history
    @history_timeline = ProjectPercentDone::History::Timeline.new(
      @project,
      :selection => params[:history_period]
    )
    @history_entries = @history_timeline.entries
    @history_forecast = ProjectPercentDone::History::Forecast.new(@project).call
    @history_chart_mode = %w[percent_only extended].include?(params[:history_chart_mode]) ? params[:history_chart_mode] : ProjectPercentDone::Settings.history_chart_mode
    @history_change_mode = %w[hidden percentage_points relative_percent].include?(params[:history_change_mode]) ? params[:history_change_mode] : ProjectPercentDone::Settings.history_change_display
    @history_page = [params[:history_page].to_i, 1].max
    history_pairs = @history_entries.each_with_index.to_a.reverse
    @history_page_count = [(history_pairs.size / 50.0).ceil, 1].max
    @history_page = [@history_page, @history_page_count].min
    @history_table_pairs = history_pairs.slice((@history_page - 1) * 50, 50) || []
  end
end
