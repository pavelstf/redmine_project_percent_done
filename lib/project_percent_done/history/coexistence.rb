module ProjectPercentDone
  module History
    module Coexistence
      PROGRESS_HISTORY_PLUGIN_ID = 'redmine_project_progress_history'.freeze

      class << self
        def progress_history_plugin_active?
          return false unless progress_history_plugin_available?

          progress_history_collection_enabled? || progress_history_page_enabled?
        rescue StandardError
          false
        end

        def progress_history_plugin_available?
          redmine_plugin_registered?(PROGRESS_HISTORY_PLUGIN_ID) || defined?(ProjectProgressHistory)
        end

        def owns_history?
          !progress_history_plugin_active?
        end

        def guarded_reason
          PROGRESS_HISTORY_PLUGIN_ID
        end

        def sanitize_project_percent_done_settings(settings)
          existing = existing_settings
          sanitized = existing.merge(stringified_settings(settings))

          sanitized.keys.grep(/\Ahistory_/).each do |key|
            sanitized[key] = existing[key] if existing.key?(key)
          end

          sanitized.merge(
            'history_enabled' => '0',
            'history_email_enabled' => '0'
          )
        end

        private

        def existing_settings
          settings = defined?(Setting) ? (Setting.plugin_redmine_project_percent_done || {}) : {}
          stringified_settings(settings)
        end

        def stringified_settings(settings)
          settings.to_h.each_with_object({}) do |(key, value), sanitized|
            sanitized[key.to_s] = value
          end
        end

        def progress_history_collection_enabled?
          progress_history_setting_enabled?(:history_enabled?)
        end

        def progress_history_page_enabled?
          progress_history_setting_enabled?(:history_page_enabled?)
        end

        def progress_history_setting_enabled?(method_name)
          return false unless defined?(ProjectProgressHistory::Settings)
          return false unless ProjectProgressHistory::Settings.respond_to?(method_name)

          ProjectProgressHistory::Settings.public_send(method_name)
        end

        def redmine_plugin_registered?(plugin_id)
          return false unless defined?(Redmine::Plugin)

          registered = registered_plugins
          return false unless registered

          if registered.respond_to?(:key?)
            registered.key?(plugin_id.to_sym) || registered.key?(plugin_id.to_s)
          else
            Array(registered).any? do |plugin|
              candidate = plugin.respond_to?(:id) ? plugin.id : plugin
              candidate.to_s == plugin_id
            end
          end
        end

        def registered_plugins
          if Redmine::Plugin.respond_to?(:registered_plugins)
            Redmine::Plugin.registered_plugins
          elsif Redmine::Plugin.respond_to?(:all)
            Redmine::Plugin.all
          end
        end
      end
    end
  end
end
