module ProjectPercentDone
  module PublicApi
    module V1
      class HistoryCapabilities
        FIELDS = %i[
          contract_name contract_version history_contract_version plugin_version
          algorithm_version history_supported history_enabled supported_period_types
          default_period_type supports_official_snapshots supports_monthly_snapshots
          supports_progress_at calculation_mode persistence_mode
        ].freeze

        attr_reader(*FIELDS)

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
