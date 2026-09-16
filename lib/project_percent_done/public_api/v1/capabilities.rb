module ProjectPercentDone
  module PublicApi
    module V1
      class Capabilities
        FIELDS = %i[
          contract_name contract_version plugin_version algorithm_version
          calculation_mode persistence_mode issue_scope closed_issue_mode
          non_progress_status_scope non_progress_status_ids
          non_progress_tracker_scope non_progress_tracker_ids
          unestimated_issue_mode hours_weighted supports_raw_percent_done
          supports_estimate_coverage
        ].freeze

        attr_reader(*FIELDS)

        def initialize(**attributes)
          FIELDS.each do |field|
            instance_variable_set(:"@#{field}", immutable_value(attributes.fetch(field)))
          end
          freeze
        end

        def to_h
          FIELDS.each_with_object({}) do |field, copy|
            value = public_send(field)
            copy[field] = mutable_copy(value)
          end
        end

        private

        def immutable_value(value)
          return value.map { |item| immutable_value(item) }.freeze if value.is_a?(Array)
          return value.dup.freeze if value.is_a?(String)

          value
        end

        def mutable_copy(value)
          return value.dup if value.is_a?(Array)
          return value.dup if value.is_a?(String)

          value
        end
      end
    end
  end
end
