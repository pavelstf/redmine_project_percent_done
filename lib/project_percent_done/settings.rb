module ProjectPercentDone
  module Settings
    ALLOWED_VALUES = begin
      values = {
        'issue_scope' => %w[leaf_issues_only],
        'closed_issue_mode' => %w[treat_as_100 use_done_ratio],
        'unestimated_issue_mode' => %w[use_average_estimate use_weight_1 ignore equal_weight_all],
        'rounding_mode' => %w[nearest_integer floor ceil]
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
      'rounding_mode' => 'nearest_integer'
    }.freeze

    class << self
      def all
        DEFAULTS.merge(raw_settings)
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
    end
  end
end
