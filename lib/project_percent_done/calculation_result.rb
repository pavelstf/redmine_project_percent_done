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
                :warnings

    def initialize(percent_done:, raw_percent_done:, issue_count:, not_included_issue_count:, estimated_issue_count:, unestimated_issue_count:, total_weight:, included_issue_ids:, not_included_issue_ids:, included_rows: [], not_included_rows: [], warnings: [])
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
        :warnings => warnings
      }
    end
  end
end
