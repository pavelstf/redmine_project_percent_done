module ProjectPercentDone
  class IssueBreakdownRow
    attr_reader :issue,
                :included,
                :original_done_ratio,
                :effective_done_ratio,
                :estimated_hours,
                :applied_weight,
                :weighted_value,
                :reason,
                :notes

    def initialize(issue:, included:, original_done_ratio:, effective_done_ratio:, estimated_hours:, applied_weight:, weighted_value:, reason: nil, notes: [])
      @issue = issue
      @included = included
      @original_done_ratio = original_done_ratio
      @effective_done_ratio = effective_done_ratio
      @estimated_hours = estimated_hours
      @applied_weight = applied_weight
      @weighted_value = weighted_value
      @reason = reason
      @notes = notes
    end

    def issue_id
      issue.id
    end

    def subject
      issue.subject
    end

    def status_name
      issue.status && issue.status.name
    end

    def closed?
      if issue.respond_to?(:closed?)
        issue.closed?
      elsif issue.status
        issue.status.is_closed?
      else
        false
      end
    end

    def included?
      included
    end
  end
end
