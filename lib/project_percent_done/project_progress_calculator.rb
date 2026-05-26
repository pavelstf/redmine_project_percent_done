module ProjectPercentDone
  class ProjectProgressCalculator
    attr_reader :project, :mode

    def initialize(project, mode: :details)
      @project = project
      @mode = mode.to_sym
    end

    def call
      all_issues = project_issues
      all_issue_ids = all_issues.map(&:id)
      candidate_issues = calculation_candidates(all_issues)
      return empty_result(:no_issues, all_issue_ids) if candidate_issues.empty?

      candidate_estimated_issues = candidate_issues.select { |issue| estimated?(issue) }
      average_estimate = average_estimate_for(candidate_estimated_issues)
      included_issues = []

      candidate_issues.each do |issue|
        included_issues << issue if included_weight_for(issue, average_estimate).to_f.positive?
      end

      estimated_issues = included_issues.select { |issue| estimated?(issue) }
      estimated_issue_count = estimated_issues.size
      unestimated_issue_count = included_issues.size - estimated_issue_count
      average_estimate = average_estimate_for(estimated_issues)

      weighted_sum = 0.0
      total_weight = 0.0

      included_issues.each do |issue|
        weight = weight_for(issue, average_estimate)

        weighted_sum += weighted_value_for(issue, weight)
        total_weight += weight
      end

      included_issue_ids = included_issues.map(&:id)
      not_included_issue_ids = all_issue_ids - included_issue_ids
      included_rows = details_mode? ? breakdown_rows_for(included_issues, true, average_estimate) : []
      not_included_rows = details_mode? ? breakdown_rows_for(all_issues.reject { |issue| included_issue_ids.include?(issue.id) }, false, average_estimate) : []

      if total_weight <= 0
        return empty_result(:no_weight, all_issue_ids, included_issue_ids, not_included_issue_ids, estimated_issue_count, unestimated_issue_count, included_rows, not_included_rows)
      end

      raw_percent_done = (weighted_sum / total_weight) * 100.0

      CalculationResult.new(
        :percent_done => rounded(raw_percent_done),
        :raw_percent_done => raw_percent_done,
        :issue_count => included_issues.size,
        :not_included_issue_count => not_included_issue_ids.size,
        :estimated_issue_count => estimated_issue_count,
        :unestimated_issue_count => unestimated_issue_count,
        :total_weight => total_weight,
        :included_issue_ids => included_issue_ids,
        :not_included_issue_ids => not_included_issue_ids,
        :included_rows => included_rows,
        :not_included_rows => not_included_rows,
        :warnings => warnings_for(included_issues, unestimated_issue_count)
      )
    end

    private

    def details_mode?
      mode == :details
    end

    def project_issues
      scope = Issue.where(:project_id => project.id)

      if details_mode?
        scope.includes(:status).to_a
      else
        scope.includes(:status)
             .select(:id, :project_id, :parent_id, :status_id, :done_ratio, :estimated_hours)
             .to_a
      end
    end

    def calculation_candidates(all_issues)
      return all_issues unless ProjectPercentDone::Settings.issue_scope == 'leaf_issues_only'

      @parent_issue_ids = all_issues.map(&:parent_id).compact.uniq
      all_issues.reject { |issue| @parent_issue_ids.include?(issue.id) }
    end

    def done_ratio_for(issue)
      ratio =
        if ProjectPercentDone::Settings.treat_closed_issues_as_100? && issue_closed?(issue)
          100
        elsif status_done_ratio_enabled?
          status_default_done_ratio(issue) || issue.done_ratio
        else
          issue.done_ratio
        end

      normalize_percent(ratio)
    end

    def status_done_ratio_enabled?
      defined?(Setting) && Setting.issue_done_ratio == 'issue_status'
    end

    def status_default_done_ratio(issue)
      issue.status && issue.status.default_done_ratio
    end

    def issue_closed?(issue)
      if issue.respond_to?(:closed?)
        issue.closed?
      elsif issue.status
        issue.status.is_closed?
      else
        false
      end
    end

    def normalize_percent(value)
      [[value.to_f, 0.0].max, 100.0].min
    end

    def estimated?(issue)
      issue.estimated_hours.to_f > 0
    end

    def average_estimate_for(estimated_issues)
      return nil if estimated_issues.empty?

      estimated_issues.sum { |issue| issue.estimated_hours.to_f } / estimated_issues.size
    end

    def weight_for(issue, average_estimate)
      return 1.0 if ProjectPercentDone::Settings.unestimated_issue_mode == 'equal_weight_all'
      return issue.estimated_hours.to_f if estimated?(issue)

      case ProjectPercentDone::Settings.unestimated_issue_mode
      when 'use_average_estimate'
        average_estimate || 1.0
      when 'use_weight_1'
        1.0
      when 'ignore'
        nil
      else
        average_estimate || 1.0
      end
    end

    def included_weight_for(issue, average_estimate)
      weight_for(issue, average_estimate)
    end

    def breakdown_rows_for(issues, included, average_estimate)
      issues.map do |issue|
        applied_weight = included ? weight_for(issue, average_estimate).to_f : 0.0
        effective_done_ratio = done_ratio_for(issue)

        ProjectPercentDone::IssueBreakdownRow.new(
          :issue => issue,
          :included => included,
          :original_done_ratio => normalize_percent(issue.done_ratio),
          :effective_done_ratio => effective_done_ratio,
          :estimated_hours => issue.estimated_hours,
          :applied_weight => applied_weight,
          :weighted_value => (effective_done_ratio / 100.0) * applied_weight,
          :reason => included ? nil : not_included_reason(issue),
          :notes => notes_for(issue, included, applied_weight, average_estimate)
        )
      end
    end

    def not_included_reason(issue)
      return :parent_issue_excluded if ProjectPercentDone::Settings.issue_scope == 'leaf_issues_only' && parent_issue_in_project?(issue)
      return :unestimated_issue_ignored if ProjectPercentDone::Settings.unestimated_issue_mode == 'ignore' && !estimated?(issue)

      :not_in_calculation_scope
    end

    def parent_issue_in_project?(issue)
      Array(@parent_issue_ids).include?(issue.id)
    end

    def notes_for(issue, included, applied_weight, average_estimate)
      notes = []
      notes << :closed_issue_treated_as_100 if included && ProjectPercentDone::Settings.treat_closed_issues_as_100? && issue_closed?(issue)
      notes << :status_done_ratio_used if included && status_done_ratio_enabled? && status_default_done_ratio(issue)
      notes << :average_estimate_used if included && !estimated?(issue) && ProjectPercentDone::Settings.unestimated_issue_mode == 'use_average_estimate' && average_estimate
      notes << :fallback_weight_1_used if included && !estimated?(issue) && applied_weight == 1.0
      notes
    end

    def weighted_value_for(issue, weight)
      (done_ratio_for(issue) / 100.0) * weight
    end

    def rounded(raw_percent_done)
      case ProjectPercentDone::Settings.rounding_mode
      when 'floor'
        raw_percent_done.floor
      when 'ceil'
        raw_percent_done.ceil
      else
        raw_percent_done.round
      end
    end

    def warnings_for(issues, unestimated_issue_count)
      warnings = []
      warnings << :unestimated_issues if unestimated_issue_count.positive?
      warnings << :all_issues_unestimated if unestimated_issue_count == issues.size
      warnings
    end

    def empty_result(warning, all_issue_ids = [], included_issue_ids = [], not_included_issue_ids = all_issue_ids, estimated_issue_count = 0, unestimated_issue_count = 0, included_rows = [], not_included_rows = [])
      CalculationResult.new(
        :percent_done => 0,
        :raw_percent_done => 0.0,
        :issue_count => included_issue_ids.size,
        :not_included_issue_count => not_included_issue_ids.size,
        :estimated_issue_count => estimated_issue_count,
        :unestimated_issue_count => unestimated_issue_count,
        :total_weight => 0.0,
        :included_issue_ids => included_issue_ids,
        :not_included_issue_ids => not_included_issue_ids,
        :included_rows => included_rows,
        :not_included_rows => not_included_rows,
        :warnings => [warning]
      )
    end
  end
end
