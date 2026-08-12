module ProjectPercentDone
  PLUGIN_ID = 'redmine_project_percent_done'.freeze
  PLUGIN_VERSION = '1.3.0'.freeze
  ALGORITHM_VERSION = '1.0'.freeze
end

require_relative 'project_percent_done/settings'
require_relative 'project_percent_done/issue_breakdown_row'
require_relative 'project_percent_done/calculation_result'
require_relative 'project_percent_done/project_progress_calculator'
require_relative 'project_percent_done/public_api/v1'
require_relative 'project_percent_done/history/project_selector'
require_relative 'project_percent_done/history/retention_cleaner'
require_relative 'project_percent_done/history/plan_metrics'
require_relative 'project_percent_done/history/forecast'
require_relative 'project_percent_done/history/timeline'
require_relative 'project_percent_done/history/subject_renderer'
require_relative 'project_percent_done/history/settings_validator'
require_relative 'project_percent_done/history/notifier'
require_relative 'project_percent_done/history/snapshot_collector'
require_relative 'project_percent_done/history/cron_command'
require_relative 'project_percent_done/history/staging_demo'
require_relative 'project_percent_done/settings_controller_patch'

require_dependency 'settings_controller'
SettingsController.prepend(ProjectPercentDone::SettingsControllerPatch) unless SettingsController < ProjectPercentDone::SettingsControllerPatch

Rails.configuration.to_prepare do
  require_relative 'project_percent_done/hooks'
  SettingsController.prepend(ProjectPercentDone::SettingsControllerPatch) unless SettingsController < ProjectPercentDone::SettingsControllerPatch
end
