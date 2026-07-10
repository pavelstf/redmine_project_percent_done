require_relative 'v1/capabilities'
require_relative 'v1/result'

module ProjectPercentDone
  module PublicApi
    module V1
      CONTRACT_NAME = 'project_percent_done'.freeze
      CONTRACT_VERSION = '1.0'.freeze

      class << self
        def capabilities
          Capabilities.new(
            :contract_name => CONTRACT_NAME,
            :contract_version => CONTRACT_VERSION,
            :plugin_version => ProjectPercentDone::PLUGIN_VERSION,
            :algorithm_version => ProjectPercentDone::ALGORITHM_VERSION,
            :calculation_mode => 'live',
            :persistence_mode => 'none',
            :issue_scope => ProjectPercentDone::Settings.issue_scope,
            :closed_issue_mode => ProjectPercentDone::Settings.closed_issue_mode,
            :unestimated_issue_mode => ProjectPercentDone::Settings.unestimated_issue_mode,
            :hours_weighted => hours_weighted?,
            :supports_raw_percent_done => true,
            :supports_estimate_coverage => true
          )
        end

        def calculate(project:)
          validate_project!(project)
          calculation = ProjectPercentDone::ProjectProgressCalculator.new(project, :mode => :summary).call

          Result.new(
            :progress_available => calculation.total_weight.positive?,
            :unavailable_reason => unavailable_reason(calculation),
            :raw_percent_done => calculation.total_weight.positive? ? calculation.raw_percent_done : nil,
            :display_percent_done => calculation.total_weight.positive? ? calculation.percent_done : nil,
            :all_project_issue_count => calculation.all_project_issue_count,
            :eligible_issue_count => calculation.eligible_issue_count,
            :estimated_eligible_issue_count => calculation.estimated_eligible_issue_count,
            :unestimated_eligible_issue_count => calculation.unestimated_eligible_issue_count,
            :included_issue_count => calculation.included_issue_count,
            :excluded_parent_issue_count => calculation.excluded_parent_issue_count,
            :ignored_unestimated_issue_count => calculation.ignored_unestimated_issue_count,
            :known_estimated_hours => calculation.known_estimated_hours,
            :imputed_weight => calculation.imputed_weight,
            :total_applied_weight => calculation.total_weight,
            :estimate_coverage_percent => calculation.estimate_coverage_percent,
            :known_weight_percent => known_weight_percent(calculation),
            :issue_scope => ProjectPercentDone::Settings.issue_scope,
            :closed_issue_mode => ProjectPercentDone::Settings.closed_issue_mode,
            :unestimated_issue_mode => ProjectPercentDone::Settings.unestimated_issue_mode,
            :hours_weighted => hours_weighted?,
            :warnings => public_warnings(calculation)
          )
        end

        private

        def validate_project!(project)
          valid_type = defined?(Project) && project.is_a?(Project)
          persisted = valid_type && project.respond_to?(:persisted?) && project.persisted?
          raise ArgumentError, 'project must be a persisted Project' unless persisted
        end

        def hours_weighted?
          ProjectPercentDone::Settings.unestimated_issue_mode != 'equal_weight_all'
        end

        def unavailable_reason(calculation)
          return nil if calculation.total_weight.positive?
          return :no_eligible_issues if calculation.eligible_issue_count.zero?

          :no_usable_weight
        end

        def known_weight_percent(calculation)
          return nil unless hours_weighted? && calculation.total_weight.positive?

          (calculation.known_estimated_hours / calculation.total_weight) * 100.0
        end

        def public_warnings(calculation)
          warnings = []
          warnings << :no_issues if calculation.all_project_issue_count.zero?
          warnings << :no_eligible_issues if calculation.all_project_issue_count.positive? && calculation.eligible_issue_count.zero?
          warnings << :unestimated_issues if calculation.unestimated_eligible_issue_count.positive?
          warnings << :all_issues_unestimated if calculation.eligible_issue_count.positive? && calculation.estimated_eligible_issue_count.zero?
          warnings << :no_usable_weight if calculation.eligible_issue_count.positive? && !calculation.total_weight.positive?
          warnings
        end
      end
    end
  end
end
