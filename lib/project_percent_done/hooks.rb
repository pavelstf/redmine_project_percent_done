module ProjectPercentDone
  class Hooks < Redmine::Hook::ViewListener
    def view_projects_show_right(context = {})
      return ''.html_safe unless ProjectPercentDone::Settings.display_overview?

      render_project_percent_done_partial(context, 'hooks/project_percent_done/overview')
    end

    def view_projects_show_sidebar_bottom(context = {})
      return ''.html_safe unless ProjectPercentDone::Settings.display_sidebar?

      render_project_percent_done_partial(context, 'hooks/project_percent_done/sidebar')
    end

    private

    def render_project_percent_done_partial(context, partial)
      controller = context[:controller]
      project = context[:project]
      return ''.html_safe unless controller && project

      result = cached_summary_result(controller, project)

      controller.send(
        :render_to_string,
        :partial => partial,
        :locals => { :project => project, :result => result }
      )
    end

    def cached_summary_result(controller, project)
      cache = controller.instance_variable_get(:@project_percent_done_summary_cache) || {}
      controller.instance_variable_set(:@project_percent_done_summary_cache, cache)
      cache[project.id] ||= ProjectPercentDone::ProjectProgressCalculator.new(project, :mode => :summary).call
    end
  end
end
