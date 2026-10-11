module ProjectPercentDone
  module PublicApi
    module V1
      class Result
        BASE_FIELDS = %i[
          progress_available unavailable_reason raw_percent_done display_percent_done
          all_project_issue_count eligible_issue_count estimated_eligible_issue_count
          unestimated_eligible_issue_count included_issue_count excluded_parent_issue_count
          excluded_non_progress_issue_count excluded_non_progress_estimated_hours
          excluded_non_progress_applied_weight non_progress_status_scope non_progress_status_ids
          non_progress_tracker_scope non_progress_tracker_ids non_progress_status_names non_progress_tracker_names
          ignored_unestimated_issue_count known_estimated_hours imputed_weight
          total_applied_weight estimate_coverage_percent known_weight_percent issue_scope
          closed_issue_mode unestimated_issue_mode hours_weighted warnings
        ].freeze
        EVIDENCE_FIELDS = %i[project_id metrics provider_metadata issue_evidence].freeze
        FIELDS = (BASE_FIELDS + EVIDENCE_FIELDS).freeze

        attr_reader(*FIELDS)

        def initialize(include_evidence: false, **attributes)
          @include_evidence = include_evidence
          fields.each do |field|
            value = attributes.fetch(field)
            value = immutable_value(value)
            instance_variable_set(:"@#{field}", value)
          end
          freeze
        end

        def to_h
          fields.each_with_object({}) do |field, copy|
            value = public_send(field)
            copy[field] = mutable_copy(value)
          end
        end

        private

        def fields
          @include_evidence ? FIELDS : BASE_FIELDS
        end

        def immutable_value(value)
          return value.map { |item| immutable_value(item) }.freeze if value.is_a?(Array)
          return value.each_with_object({}) { |(key, item), copy| copy[key] = immutable_value(item) }.freeze if value.is_a?(Hash)
          return value.dup.freeze if value.is_a?(String)

          value
        end

        def mutable_copy(value)
          return value.map { |item| mutable_copy(item) } if value.is_a?(Array)
          return value.each_with_object({}) { |(key, item), copy| copy[key] = mutable_copy(item) } if value.is_a?(Hash)
          return value.dup if value.is_a?(String)

          value
        end
      end
    end
  end
end
