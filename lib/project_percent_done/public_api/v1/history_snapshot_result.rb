module ProjectPercentDone
  module PublicApi
    module V1
      class HistorySnapshotResult
        FIELDS = %i[
          project_id period_type period_end captured_at project_state
          progress_available unavailable_reason display_percent_done raw_percent_done
          estimate_coverage_percent warnings snapshot_source timing deviation_seconds
          algorithm_version plugin_version calculation_settings all_project_issue_count
          eligible_issue_count included_issue_count not_included_issue_count
          estimated_issue_count unestimated_issue_count estimated_eligible_issue_count
          unestimated_eligible_issue_count excluded_parent_issue_count
          ignored_unestimated_issue_count known_estimated_hours total_weight imputed_weight
        ].freeze

        attr_reader(*FIELDS)

        def self.from_snapshot(snapshot)
          available = snapshot.raw_percent_done.present? || snapshot.display_percent_done.present?
          new(
            :project_id => snapshot.project_id,
            :period_type => snapshot.period_type,
            :period_end => snapshot.period_end,
            :captured_at => snapshot.captured_at,
            :project_state => snapshot.project_state,
            :progress_available => available,
            :unavailable_reason => available ? nil : unavailable_reason(snapshot),
            :display_percent_done => snapshot.display_percent_done,
            :raw_percent_done => snapshot.raw_percent_done,
            :estimate_coverage_percent => snapshot.estimate_coverage_percent,
            :warnings => snapshot.warnings,
            :snapshot_source => snapshot.snapshot_source,
            :timing => snapshot.timing,
            :deviation_seconds => snapshot.deviation_seconds,
            :algorithm_version => snapshot.algorithm_version,
            :plugin_version => snapshot.plugin_version,
            :calculation_settings => snapshot.calculation_settings,
            :all_project_issue_count => snapshot.all_project_issue_count,
            :eligible_issue_count => snapshot.eligible_issue_count,
            :included_issue_count => snapshot.included_issue_count,
            :not_included_issue_count => snapshot.not_included_issue_count,
            :estimated_issue_count => snapshot.estimated_issue_count,
            :unestimated_issue_count => snapshot.unestimated_issue_count,
            :estimated_eligible_issue_count => snapshot.estimated_eligible_issue_count,
            :unestimated_eligible_issue_count => snapshot.unestimated_eligible_issue_count,
            :excluded_parent_issue_count => snapshot.excluded_parent_issue_count,
            :ignored_unestimated_issue_count => snapshot.ignored_unestimated_issue_count,
            :known_estimated_hours => snapshot.known_estimated_hours,
            :total_weight => snapshot.total_weight,
            :imputed_weight => snapshot.imputed_weight
          )
        end

        def self.unavailable(project_id:, period_type:, period_end:, unavailable_reason:)
          new(
            :project_id => project_id,
            :period_type => period_type.to_s,
            :period_end => period_end,
            :captured_at => nil,
            :project_state => nil,
            :progress_available => false,
            :unavailable_reason => unavailable_reason,
            :display_percent_done => nil,
            :raw_percent_done => nil,
            :estimate_coverage_percent => nil,
            :warnings => [],
            :snapshot_source => nil,
            :timing => nil,
            :deviation_seconds => nil,
            :algorithm_version => ProjectPercentDone::ALGORITHM_VERSION,
            :plugin_version => ProjectPercentDone::PLUGIN_VERSION,
            :calculation_settings => {},
            :all_project_issue_count => nil,
            :eligible_issue_count => nil,
            :included_issue_count => nil,
            :not_included_issue_count => nil,
            :estimated_issue_count => nil,
            :unestimated_issue_count => nil,
            :estimated_eligible_issue_count => nil,
            :unestimated_eligible_issue_count => nil,
            :excluded_parent_issue_count => nil,
            :ignored_unestimated_issue_count => nil,
            :known_estimated_hours => nil,
            :total_weight => nil,
            :imputed_weight => nil
          )
        end

        def initialize(**attributes)
          FIELDS.each do |field|
            value = immutable_value(attributes.fetch(field))
            instance_variable_set(:"@#{field}", value)
          end
          freeze
        end

        def to_h
          FIELDS.each_with_object({}) do |field, copy|
            copy[field] = mutable_copy(public_send(field))
          end
        end

        def progress_available?
          progress_available
        end

        def self.unavailable_reason(snapshot)
          return :project_closed if snapshot.project_state == 'closed'
          return :project_archived if snapshot.project_state == 'archived'
          return :project_out_of_scope if snapshot.project_state == 'out_of_scope'
          return :no_eligible_issues if snapshot.eligible_issue_count.to_i.zero?
          return :no_usable_weight if snapshot.total_weight.present? && !snapshot.total_weight.to_d.positive?

          :progress_unavailable
        end
        private_class_method :unavailable_reason

        private

        def immutable_value(value)
          return value.each_with_object({}) { |(key, item), copy| copy[key] = immutable_value(item) }.freeze if value.is_a?(Hash)
          return value.map { |item| immutable_value(item) }.freeze if value.is_a?(Array)
          return value.dup.freeze if value.is_a?(String)

          value
        end

        def mutable_copy(value)
          return value.each_with_object({}) { |(key, item), copy| copy[key] = mutable_copy(item) } if value.is_a?(Hash)
          return value.dup if value.is_a?(Array)
          return value.dup if value.is_a?(String)

          value
        end
      end
    end
  end
end
