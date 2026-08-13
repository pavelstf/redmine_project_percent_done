require_relative 'v1/capabilities'
require_relative 'v1/result'
require_relative 'v1/history_capabilities'
require_relative 'v1/history_snapshot_result'

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

        def history_capabilities
          HistoryCapabilities.new(
            :contract_name => CONTRACT_NAME,
            :contract_version => CONTRACT_VERSION,
            :history_contract_version => '1.0',
            :plugin_version => ProjectPercentDone::PLUGIN_VERSION,
            :algorithm_version => ProjectPercentDone::ALGORITHM_VERSION,
            :history_supported => true,
            :history_enabled => ProjectPercentDone::Settings.history_enabled?,
            :supported_period_types => %i[weekly monthly],
            :default_period_type => :monthly,
            :supports_official_snapshots => true,
            :supports_monthly_snapshots => true,
            :supports_progress_at => true,
            :calculation_mode => 'snapshot',
            :persistence_mode => 'snapshots'
          )
        end

        def latest_official_snapshot(project:, period_type: :monthly)
          validate_project!(project)
          type = normalize_period_type!(period_type)
          snapshot = official_scope(project, type).latest_first.first
          snapshot ? HistorySnapshotResult.from_snapshot(snapshot) : unavailable_history_result(project, type, nil, :snapshot_missing)
        end

        def official_snapshot_for(project:, period_type:, period_end:)
          validate_project!(project)
          type = normalize_period_type!(period_type)
          date = normalize_date!(period_end, 'period_end')
          snapshot = official_scope(project, type).find_by(:period_end => date)
          snapshot ? HistorySnapshotResult.from_snapshot(snapshot) : unavailable_history_result(project, type, date, :snapshot_missing)
        end

        def official_snapshots_between(project:, period_type:, from:, to:)
          validate_project!(project)
          type = normalize_period_type!(period_type)
          from_date = normalize_date!(from, 'from')
          to_date = normalize_date!(to, 'to')
          raise ArgumentError, 'from must be on or before to' if from_date > to_date

          official_scope(project, type)
            .where(:period_end => from_date..to_date)
            .order(:period_end => :asc, :id => :asc)
            .map { |snapshot| HistorySnapshotResult.from_snapshot(snapshot) }
        end

        def progress_at(project:, date:, preferred_period_type: :monthly)
          validate_project!(project)
          type = normalize_period_type!(preferred_period_type)
          target_date = normalize_date!(date, 'date')
          return monthly_progress_at(project, target_date) if type == 'monthly'

          official_snapshot_for(:project => project, :period_type => type, :period_end => target_date)
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

        def normalize_period_type!(period_type)
          value = period_type.to_s
          raise ArgumentError, 'period_type must be weekly or monthly' unless %w[weekly monthly].include?(value)

          value
        end

        def normalize_date!(value, name)
          return value if value.is_a?(Date)
          return value.to_date if value.respond_to?(:to_date)

          Date.iso8601(value.to_s)
        rescue ArgumentError
          raise ArgumentError, "#{name} must be a date"
        end

        def official_scope(project, period_type)
          ProjectPercentDoneSnapshot.official
                                    .where(:project_id => project.id, :period_type => period_type)
        end

        def monthly_progress_at(project, date)
          period_end = date.end_of_month
          return unavailable_history_result(project, 'monthly', period_end, :period_not_completed) if Time.zone.today <= period_end

          official_snapshot_for(:project => project, :period_type => 'monthly', :period_end => period_end)
        end

        def unavailable_history_result(project, period_type, period_end, reason)
          HistorySnapshotResult.unavailable(
            :project_id => project.id,
            :period_type => period_type,
            :period_end => period_end,
            :unavailable_reason => reason
          )
        end
      end
    end
  end
end
