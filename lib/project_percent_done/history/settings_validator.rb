module ProjectPercentDone
  module History
    class SettingsValidator
      Result = Struct.new(:errors, :warnings, keyword_init: true) do
        def valid?
          errors.empty?
        end
      end

      def initialize(settings = nil)
        @settings = settings && ProjectPercentDone::Settings::DEFAULTS.merge(settings.stringify_keys)
      end

      def call
        errors = []
        warnings = []

        if enabled?('history_enabled')
          errors.concat(project_selection_errors)
        end

        if enabled?('history_email_enabled')
          recipients = email_recipients
          errors << 'email_recipients_missing' if recipients.empty?
          errors << 'email_recipients_invalid' if recipients.any? { |address| !valid_email?(address) }
          errors << 'email_subject_invalid' unless SubjectRenderer.valid_template?(
            setting('history_email_subject_template').to_s
          )
        end

        errors.concat(plan_date_field_errors)

        warnings << 'history_disabled' unless enabled?('history_enabled')
        Result.new(:errors => errors.uniq, :warnings => warnings.uniq)
      end

      private

      def valid_email?(address)
        parsed = Mail::Address.new(address)
        parsed.address == address && parsed.domain.present?
      rescue StandardError
        false
      end

      def project_selection_errors
        return ProjectSelector.new.validation_errors unless @settings

        field = ProjectCustomField.find_by(:id => setting('history_project_type_custom_field_id').to_i)
        values = Array(setting('history_project_type_values')).map(&:to_s).reject(&:blank?)
        errors = []
        errors << 'project_type_custom_field_missing' unless field
        errors << 'project_type_custom_field_not_list' if field && field.field_format != 'list'
        errors << 'project_type_values_missing' if values.empty?
        errors << 'project_type_values_stale' if field && (values - Array(field.possible_values).map(&:to_s)).any?
        errors
      end

      def plan_date_field_errors
        start_id = setting('history_project_start_custom_field_id').to_i
        end_id = setting('history_project_planned_end_custom_field_id').to_i
        errors = []
        errors.concat(date_field_errors('project_start', start_id)) if start_id.positive?
        errors.concat(date_field_errors('project_planned_end', end_id)) if end_id.positive?
        errors << 'plan_date_fields_must_differ' if start_id.positive? && start_id == end_id
        errors
      end

      def date_field_errors(role, id)
        field = ProjectCustomField.find_by(:id => id)
        return ["#{role}_custom_field_missing"] unless field
        return ["#{role}_custom_field_must_be_date"] unless field.field_format == 'date'

        []
      end

      def enabled?(key)
        setting(key).to_s == '1'
      end

      def email_recipients
        setting('history_email_recipients').to_s.split(',').map(&:strip).reject(&:blank?).uniq(&:downcase)
      end

      def setting(key)
        @settings ? @settings[key] : ProjectPercentDone::Settings.value(key)
      end
    end
  end
end
