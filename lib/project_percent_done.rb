require_relative 'project_percent_done/settings'
require_relative 'project_percent_done/issue_breakdown_row'
require_relative 'project_percent_done/calculation_result'
require_relative 'project_percent_done/project_progress_calculator'

module ProjectPercentDone
  PLUGIN_ID = 'redmine_project_percent_done'.freeze
end

Rails.configuration.to_prepare do
  require_relative 'project_percent_done/hooks'
end
