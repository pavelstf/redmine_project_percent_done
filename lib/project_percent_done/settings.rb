module ProjectPercentDone
  module Settings
    ALLOWED_VALUES = begin
      values = {
        'issue_scope' => %w[leaf_issues_only],
        'closed_issue_mode' => %w[treat_as_100 use_done_ratio],
        'unestimated_issue_mode' => %w[use_average_estimate use_weight_1 ignore equal_weight_all],
        'rounding_mode' => %w[nearest_integer floor ceil],
        'history_detail_level' => %w[project_only project_and_issues],
        'history_chart_mode' => %w[percent_only extended],
        'history_default_period' => %w[13 26 52 104 current_quarter current_year all],
        'history_change_display' => %w[hidden percentage_points relative_percent],
        'history_reporting_year' => %w[calendar fiscal],
        'history_email_notification_level' => %w[weekly_only weekly_plus_problems every_execution],
        'history_email_recipient_mode' => %w[to bcc]
      }
      values.each_value { |allowed| allowed.each(&:freeze).freeze }
      values.freeze
    end

    DEFAULTS = {
      'display_overview' => '1',
      'display_sidebar' => '1',
      'display_project_tab' => '0',
      'enable_rest_api' => '0',
      'issue_scope' => 'leaf_issues_only',
      'closed_issue_mode' => 'treat_as_100',
      'unestimated_issue_mode' => 'use_average_estimate',
      'rounding_mode' => 'nearest_integer',
      'history_enabled' => '0',
      'history_detail_level' => 'project_only',
      'history_project_type_custom_field_id' => '',
      'history_project_type_values' => [],
      'history_project_start_custom_field_id' => '',
      'history_project_planned_end_custom_field_id' => '',
      'history_promotion_tolerance_days' => '2',
      'history_issue_retention_weeks' => '52',
      'history_inactive_grace_weeks' => '4',
      'history_chart_mode' => 'percent_only',
      'history_default_period' => '52',
      'history_change_display' => 'percentage_points',
      'history_reporting_year' => 'calendar',
      'history_fiscal_year_start_month' => '1',
      'history_email_enabled' => '0',
      'history_email_notification_level' => 'weekly_only',
      'history_email_recipient_mode' => 'bcc',
      'history_email_recipients' => '',
      'history_email_subject_template' => '[Redmine] Progress digest | %{date} | period %{period_end} | %{snapshot_type} | %{status}'
    }.freeze

    FORM_BLANK_DEFAULT_KEYS = %w[
      history_promotion_tolerance_days
      history_issue_retention_weeks
      history_inactive_grace_weeks
      history_email_subject_template
    ].freeze

    class << self
      def all
        DEFAULTS.merge(raw_settings)
      end

      def form_values(settings)
        supplied = (settings || {}).to_h.stringify_keys
        DEFAULTS.merge(supplied).tap do |values|
          FORM_BLANK_DEFAULT_KEYS.each do |key|
            values[key] = DEFAULTS[key] if values[key].blank?
          end
        end
      end

      def value(key)
        all[key.to_s]
      end

      def display_overview?
        enabled?('display_overview')
      end

      def display_sidebar?
        enabled?('display_sidebar')
      end

      def display_project_tab?
        enabled?('display_project_tab')
      end

      def enable_rest_api?
        enabled?('enable_rest_api')
      end

      def html_details_enabled?
        display_overview? || display_sidebar? || display_project_tab?
      end

      def issue_scope
        normalized_value('issue_scope')
      end

      def closed_issue_mode
        normalized_value('closed_issue_mode')
      end

      def treat_closed_issues_as_100?
        closed_issue_mode == 'treat_as_100'
      end

      def unestimated_issue_mode
        normalized_value('unestimated_issue_mode')
      end

      def rounding_mode
        normalized_value('rounding_mode')
      end

      def history_enabled?
        enabled?('history_enabled')
      end

      def history_detail_level
        normalized_value('history_detail_level')
      end

      def history_issue_details?
        history_detail_level == 'project_and_issues'
      end

      def history_project_type_custom_field_id
        positive_integer_value('history_project_type_custom_field_id')
      end

      def history_project_type_custom_field
        return nil unless defined?(ProjectCustomField)

        ProjectCustomField.find_by(:id => history_project_type_custom_field_id)
      end

      def history_project_type_values
        Array(value('history_project_type_values')).map(&:to_s).map(&:strip).reject(&:blank?).uniq
      end

      def history_project_start_custom_field_id
        positive_integer_value('history_project_start_custom_field_id')
      end

      def history_project_start_custom_field
        project_date_custom_field(history_project_start_custom_field_id)
      end

      def history_project_planned_end_custom_field_id
        positive_integer_value('history_project_planned_end_custom_field_id')
      end

      def history_project_planned_end_custom_field
        project_date_custom_field(history_project_planned_end_custom_field_id)
      end

      def history_promotion_tolerance_days
        bounded_integer_value('history_promotion_tolerance_days', 0, 3)
      end

      def history_issue_retention_weeks
        bounded_integer_value('history_issue_retention_weeks', 13, 520)
      end

      def history_inactive_grace_weeks
        bounded_integer_value('history_inactive_grace_weeks', 0, 52)
      end

      def history_chart_mode
        normalized_value('history_chart_mode')
      end

      def history_default_period
        normalized_value('history_default_period')
      end

      def history_change_display
        normalized_value('history_change_display')
      end

      def history_reporting_year
        normalized_value('history_reporting_year')
      end

      def history_fiscal_year_start_month
        bounded_integer_value('history_fiscal_year_start_month', 1, 12)
      end

      def history_email_enabled?
        enabled?('history_email_enabled')
      end

      def history_email_notification_level
        normalized_value('history_email_notification_level')
      end

      def history_email_recipient_mode
        normalized_value('history_email_recipient_mode')
      end

      def history_email_recipients
        value('history_email_recipients').to_s.split(',').map(&:strip).reject(&:blank?).uniq(&:downcase)
      end

      def history_email_subject_template
        value('history_email_subject_template').to_s
      end

      def history_calculation_settings
        {
          'issue_scope' => issue_scope,
          'closed_issue_mode' => closed_issue_mode,
          'unestimated_issue_mode' => unestimated_issue_mode,
          'rounding_mode' => rounding_mode,
          'project_start_custom_field_id' => history_project_start_custom_field_id,
          'project_planned_end_custom_field_id' => history_project_planned_end_custom_field_id,
          'plan_calendar_mode' => 'calendar_days_v1'
        }
      end

      private

      def raw_settings
        if defined?(Setting)
          Setting.plugin_redmine_project_percent_done || {}
        else
          {}
        end
      end

      def enabled?(key)
        value(key).to_s == '1'
      end

      def normalized_value(key)
        key = key.to_s
        candidate = value(key).to_s
        ALLOWED_VALUES.fetch(key).include?(candidate) ? candidate : DEFAULTS.fetch(key)
      end

      def positive_integer_value(key)
        integer = value(key).to_i
        integer.positive? ? integer : nil
      end

      def bounded_integer_value(key, minimum, maximum)
        default = DEFAULTS.fetch(key).to_i
        integer = Integer(value(key).to_s, 10)
        integer.between?(minimum, maximum) ? integer : default
      rescue ArgumentError, TypeError
        default
      end

      def project_date_custom_field(id)
        return nil unless defined?(ProjectCustomField) && id

        ProjectCustomField.find_by(:id => id)
      end
    end
  end
end
