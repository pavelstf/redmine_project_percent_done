require 'csv'

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
      format.csv { send_details_csv }
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
    if request.format.html? || request.format.csv?
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
      :non_progress_status_scope => ProjectPercentDone::Settings.non_progress_status_scope,
      :non_progress_status_ids => ProjectPercentDone::Settings.non_progress_status_ids,
      :non_progress_tracker_scope => ProjectPercentDone::Settings.non_progress_tracker_scope,
      :non_progress_tracker_ids => ProjectPercentDone::Settings.non_progress_tracker_ids,
      :excluded_non_progress_issue_count => @result.excluded_non_progress_issue_count,
      :excluded_non_progress_estimated_hours => @result.excluded_non_progress_estimated_hours,
      :excluded_non_progress_applied_weight => @result.excluded_non_progress_applied_weight,
      :non_progress_status_names => @result.non_progress_status_names,
      :non_progress_tracker_names => @result.non_progress_tracker_names,
      :closed_issue_mode => ProjectPercentDone::Settings.closed_issue_mode,
      :unestimated_issue_mode => ProjectPercentDone::Settings.unestimated_issue_mode,
      :calculation_mode => 'live',
      :warnings => @result.warnings
    }
  end

  def result_mode
    request.format.html? || request.format.csv? ? :details : :summary
  end

  def send_details_csv
    table = params[:table].to_s
    exporter = csv_exporters[table]
    return render_404 unless exporter

    send_data(
      utf8_csv(exporter.call),
      :type => 'text/csv; charset=utf-8',
      :filename => csv_filename(table)
    )
  end

  def csv_exporters
    {
      'included' => method(:included_csv_rows),
      'not_included' => method(:not_included_csv_rows)
    }
  end

  def utf8_csv(rows)
    "\uFEFF" + CSV.generate do |csv|
      rows.each { |row| csv << row.map { |value| csv_safe_value(value) } }
    end
  end

  def csv_safe_value(value)
    return value unless value.is_a?(String)
    return value unless value.match?(/\A[=+\-@]/)

    "'#{value}"
  end

  def csv_filename(table)
    project_part = @project.identifier.presence || @project.id
    filename_parts = ['project-percent-done', project_part, table]
    filter_part = csv_filename_filter_part
    filename_parts << filter_part if filter_part.present?
    filename_parts << Date.current
    "#{filename_parts.join('-')}.csv"
  end

  def csv_filename_filter_part
    parts = []
    parts << csv_slug(csv_filter_quick) if csv_filter_quick.present?
    parts << "status-#{csv_slug(csv_filter_status)}" if csv_filter_status.present?
    parts << "filter-#{csv_slug(csv_filter_secondary)}" if csv_filter_secondary.present?
    parts << "search-#{csv_slug(csv_filter_search, 32)}" if csv_filter_search.present?
    parts.presence&.join('-')
  end

  def csv_slug(value, limit = nil)
    slug = value.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|-+\z/, '')
    slug = slug.first(limit).gsub(/-+\z/, '') if limit && slug.present?
    slug.presence || 'filtered'
  end

  def included_csv_rows
    rows = [[
      l(:field_issue),
      l(:field_subject),
      l(:field_status),
      l(:field_done_ratio),
      l(:label_project_percent_done_effective_done_ratio),
      l(:field_estimated_hours),
      l(:label_project_percent_done_applied_weight),
      l(:label_project_percent_done_weighted_value),
      l(:label_project_percent_done_notes)
    ]]

    filtered_included_rows.each do |row|
      rows << [
        row.issue_id,
        row.subject,
        row.status_name,
        csv_percent(row.original_done_ratio),
        csv_percent(row.effective_done_ratio),
        csv_decimal(row.estimated_hours),
        csv_decimal(row.applied_weight),
        csv_decimal(row.weighted_value),
        included_note_labels(row).join(', ')
      ]
    end

    rows
  end

  def not_included_csv_rows
    rows = [[
      l(:field_issue),
      l(:field_subject),
      l(:field_status),
      l(:field_done_ratio),
      l(:field_estimated_hours),
      l(:label_project_percent_done_reason)
    ]]

    filtered_not_included_rows.each do |row|
      rows << [
        row.issue_id,
        row.subject,
        row.status_name,
        csv_percent(row.original_done_ratio),
        csv_decimal(row.estimated_hours),
        not_included_reason_label(row)
      ]
    end

    rows
  end

  def visible_rows(rows)
    rows.select { |row| row.issue.visible? }
  end

  def filtered_included_rows
    visible_rows(@result.included_rows).select do |row|
      csv_matches_search?(included_search_text(row)) &&
        csv_matches_status?(row.status_name) &&
        csv_matches_secondary?(row.notes.map(&:to_s)) &&
        csv_matches_quick?(included_quick_filter_keys(row))
    end
  end

  def filtered_not_included_rows
    visible_rows(@result.not_included_rows).select do |row|
      csv_matches_search?(not_included_search_text(row)) &&
        csv_matches_status?(row.status_name) &&
        csv_matches_secondary?([row.reason.to_s]) &&
        csv_matches_quick?(not_included_quick_filter_keys(row))
    end
  end

  def included_search_text(row)
    [
      row.issue_id,
      row.subject,
      row.status_name,
      row.original_done_ratio,
      row.effective_done_ratio,
      row.estimated_hours,
      row.applied_weight,
      row.weighted_value,
      included_note_labels(row).join(' ')
    ].join(' ')
  end

  def not_included_search_text(row)
    [
      row.issue_id,
      row.subject,
      row.status_name,
      row.original_done_ratio,
      row.estimated_hours,
      not_included_reason_label(row)
    ].join(' ')
  end

  def included_note_labels(row)
    row.notes.map { |note| l(:"label_project_percent_done_note_#{note}") }
  end

  def not_included_reason_label(row)
    l(:"label_project_percent_done_reason_#{row.reason}")
  end

  def csv_matches_search?(value)
    search = csv_filter_search
    search.blank? || value.to_s.downcase.include?(search.downcase)
  end

  def csv_matches_status?(value)
    status = csv_filter_status
    status.blank? || value.to_s == status
  end

  def csv_matches_secondary?(values)
    secondary = csv_filter_secondary
    secondary.blank? || values.include?(secondary)
  end

  def csv_matches_quick?(values)
    quick = csv_filter_quick
    quick.blank? || values.include?(quick)
  end

  def included_quick_filter_keys(row)
    keys = []
    keys << 'closed_as_100' if row.notes.map(&:to_s).include?('closed_issue_treated_as_100')
    keys << 'has_notes' if row.notes.any?
    keys << 'estimated' if row.estimated_hours.present?
    keys << 'unestimated' if row.estimated_hours.blank?
    keys << (row.effective_done_ratio.to_f >= 100.0 ? 'complete' : 'incomplete')
    keys
  end

  def not_included_quick_filter_keys(row)
    reason = row.reason.to_s
    keys = [reason]
    if reason == 'non_progress_status_and_tracker'
      keys << 'non_progress_status'
      keys << 'non_progress_tracker'
    end
    keys
  end

  def csv_filter_search
    params[:filter_search].to_s.strip
  end

  def csv_filter_status
    params[:filter_status].to_s.strip
  end

  def csv_filter_secondary
    params[:filter_secondary].to_s.strip
  end

  def csv_filter_quick
    params[:filter_quick].to_s.strip
  end

  def csv_decimal(value)
    return nil if value.nil?

    format('%.2f', value.to_d)
  end

  def csv_percent(value)
    value.nil? ? nil : "#{csv_decimal(value)}%"
  end

  def load_history
    @history_period_type = %w[weekly monthly].include?(params[:history_period_type]) ? params[:history_period_type] : 'weekly'
    @history_timeline = ProjectPercentDone::History::Timeline.new(
      @project,
      :selection => params[:history_period],
      :period_type => @history_period_type
    )
    @history_entries = @history_timeline.entries
    @history_forecast = @history_period_type == 'weekly' ? ProjectPercentDone::History::Forecast.new(@project).call : nil
    @history_monthly_status = ProjectPercentDone::History::MonthlyStatus.new(:project => @project).call
    @history_chart_mode = %w[percent_only extended].include?(params[:history_chart_mode]) ? params[:history_chart_mode] : ProjectPercentDone::Settings.history_chart_mode
    @history_change_mode = %w[hidden percentage_points relative_percent].include?(params[:history_change_mode]) ? params[:history_change_mode] : ProjectPercentDone::Settings.history_change_display
    @history_page = [params[:history_page].to_i, 1].max
    history_pairs = @history_entries.each_with_index.to_a.reverse
    @history_page_count = [(history_pairs.size / 50.0).ceil, 1].max
    @history_page = [@history_page, @history_page_count].min
    @history_table_pairs = history_pairs.slice((@history_page - 1) * 50, 50) || []
  end
end
