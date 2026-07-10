module ProjectPercentDone
  class CalculationResult
    attr_reader :percent_done,
                :raw_percent_done,
                :issue_count,
                :not_included_issue_count,
                :estimated_issue_count,
                :unestimated_issue_count,
                :total_weight,
                :included_issue_ids,
                :not_included_issue_ids,
                :included_rows,
                :not_included_rows,
                :warnings,
                :all_project_issue_count,
                :eligible_issue_count,
                :estimated_eligible_issue_count,
                :unestimated_eligible_issue_count,
                :included_issue_count,
                :excluded_parent_issue_count,
                :ignored_unestimated_issue_count,
                :known_estimated_hours,
                :imputed_weight,
                :estimate_coverage_percent

    def initialize(percent_done:, raw_percent_done:, issue_count:, not_included_issue_count:, estimated_issue_count:, unestimated_issue_count:, total_weight:, included_issue_ids:, not_included_issue_ids:, included_rows: [], not_included_rows: [], warnings: [], all_project_issue_count: 0, eligible_issue_count: 0, estimated_eligible_issue_count: 0, unestimated_eligible_issue_count: 0, included_issue_count: 0, excluded_parent_issue_count: 0, ignored_unestimated_issue_count: 0, known_estimated_hours: 0.0, imputed_weight: 0.0, estimate_coverage_percent: nil)
      @percent_done = percent_done
      @raw_percent_done = raw_percent_done
      @issue_count = issue_count
      @not_included_issue_count = not_included_issue_count
      @estimated_issue_count = estimated_issue_count
      @unestimated_issue_count = unestimated_issue_count
      @total_weight = total_weight
      @included_issue_ids = included_issue_ids
      @not_included_issue_ids = not_included_issue_ids
      @included_rows = included_rows
      @not_included_rows = not_included_rows
      @warnings = warnings
      @all_project_issue_count = all_project_issue_count
      @eligible_issue_count = eligible_issue_count
      @estimated_eligible_issue_count = estimated_eligible_issue_count
      @unestimated_eligible_issue_count = unestimated_eligible_issue_count
      @included_issue_count = included_issue_count
      @excluded_parent_issue_count = excluded_parent_issue_count
      @ignored_unestimated_issue_count = ignored_unestimated_issue_count
      @known_estimated_hours = known_estimated_hours
      @imputed_weight = imputed_weight
      @estimate_coverage_percent = estimate_coverage_percent
    end

    def to_h
      {
        :percent_done => percent_done,
        :raw_percent_done => raw_percent_done,
        :issue_count => issue_count,
        :not_included_issue_count => not_included_issue_count,
        :estimated_issue_count => estimated_issue_count,
        :unestimated_issue_count => unestimated_issue_count,
        :total_weight => total_weight,
        :included_issue_ids => included_issue_ids,
        :not_included_issue_ids => not_included_issue_ids,
        :included_rows => included_rows,
        :not_included_rows => not_included_rows,
        :warnings => warnings,
        :all_project_issue_count => all_project_issue_count,
        :eligible_issue_count => eligible_issue_count,
        :estimated_eligible_issue_count => estimated_eligible_issue_count,
        :unestimated_eligible_issue_count => unestimated_eligible_issue_count,
        :included_issue_count => included_issue_count,
        :excluded_parent_issue_count => excluded_parent_issue_count,
        :ignored_unestimated_issue_count => ignored_unestimated_issue_count,
        :known_estimated_hours => known_estimated_hours,
        :imputed_weight => imputed_weight,
        :estimate_coverage_percent => estimate_coverage_percent
      }
    end
  end
end
