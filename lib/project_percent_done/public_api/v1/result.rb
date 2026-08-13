module ProjectPercentDone
  module PublicApi
    module V1
      class Result
        FIELDS = %i[
          progress_available unavailable_reason raw_percent_done display_percent_done
          all_project_issue_count eligible_issue_count estimated_eligible_issue_count
          unestimated_eligible_issue_count included_issue_count excluded_parent_issue_count
          ignored_unestimated_issue_count known_estimated_hours imputed_weight
          total_applied_weight estimate_coverage_percent known_weight_percent issue_scope
          closed_issue_mode unestimated_issue_mode hours_weighted warnings
        ].freeze

        attr_reader(*FIELDS)

        def initialize(**attributes)
          FIELDS.each do |field|
            value = attributes.fetch(field)
            value = immutable_value(value)
            instance_variable_set(:"@#{field}", value)
          end
          freeze
        end

        def to_h
          FIELDS.each_with_object({}) do |field, copy|
            value = public_send(field)
            copy[field] =
              if value.is_a?(Array)
                value.dup
              elsif value.is_a?(String)
                value.dup
              else
                value
              end
          end
        end

        private

        def immutable_value(value)
          return value.map { |item| immutable_value(item) }.freeze if value.is_a?(Array)
          return value.dup.freeze if value.is_a?(String)

          value
        end
      end
    end
  end
end
