require_relative 'lib/project_percent_done'

Redmine::Plugin.register :redmine_project_percent_done do
  name 'Redmine Project Percent Done'
  author 'PAvcho'
  description 'Calculates project completion percentage from issue % done and relative issue weight.'
  version ProjectPercentDone::PLUGIN_VERSION
  requires_redmine :version_or_higher => '5.0.0'

  settings(
    :default => ProjectPercentDone::Settings::DEFAULTS,
    :partial => 'settings/project_percent_done_settings'
  )

  menu(
    :project_menu,
    :project_percent_done,
    {
      :controller => 'project_percent_done',
      :action => 'show'
    },
    :caption => :label_project_percent_done,
    :after => :overview,
    :param => :project_id,
    :permission => :view_project,
    :if => Proc.new { ProjectPercentDone::Settings.display_project_tab? }
  )

  menu(
    :project_menu,
    :project_percent_done_history,
    {
      :controller => 'project_percent_done',
      :action => 'history'
    },
    :caption => :label_project_percent_done_history_tab,
    :after => :project_percent_done,
    :param => :project_id,
    :permission => :view_project,
    :if => Proc.new do |project|
      ProjectPercentDone::Settings.history_enabled? ||
        (project && ProjectPercentDoneSnapshot.where(:project_id => project.id).exists?)
    end
  )
end
