module ProjectPercentDone
  PLUGIN_ID = 'redmine_project_percent_done'.freeze
  PLUGIN_VERSION = '1.1.1'.freeze
  ALGORITHM_VERSION = '1.0'.freeze
end

require_relative 'project_percent_done/settings'
require_relative 'project_percent_done/issue_breakdown_row'
require_relative 'project_percent_done/calculation_result'
require_relative 'project_percent_done/project_progress_calculator'
require_relative 'project_percent_done/public_api/v1'

Rails.configuration.to_prepare do
  require_relative 'project_percent_done/hooks'
end
