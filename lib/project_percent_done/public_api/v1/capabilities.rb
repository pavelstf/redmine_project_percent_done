module ProjectPercentDone
  module PublicApi
    module V1
      class Capabilities
        FIELDS = %i[
          contract_name contract_version plugin_version algorithm_version
          calculation_mode persistence_mode issue_scope closed_issue_mode
          unestimated_issue_mode hours_weighted supports_raw_percent_done
          supports_estimate_coverage
        ].freeze

        attr_reader(*FIELDS)

        def initialize(**attributes)
          FIELDS.each do |field|
            value = attributes.fetch(field)
            value = value.dup.freeze if value.is_a?(String)
            instance_variable_set(:"@#{field}", value)
          end
          freeze
        end

        def to_h
          FIELDS.each_with_object({}) do |field, copy|
            value = public_send(field)
            copy[field] = value.is_a?(String) ? value.dup : value
          end
        end
      end
    end
  end
end
