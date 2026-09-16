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
      history_available = ProjectPercentDone::Settings.history_available_for_project?(project)
      latest_snapshots = cached_latest_snapshots(controller, project)

      controller.send(
        :render_to_string,
        :partial => partial,
        :locals => {
          :project => project,
          :result => result,
          :history_available => history_available,
          :latest_snapshots => latest_snapshots
        }
      )
    end

    def cached_summary_result(controller, project)
      cache = controller.instance_variable_get(:@project_percent_done_summary_cache) || {}
      controller.instance_variable_set(:@project_percent_done_summary_cache, cache)
      cache[project.id] ||= ProjectPercentDone::ProjectProgressCalculator.new(project, :mode => :summary).call
    end

    def cached_latest_snapshots(controller, project)
      return {} unless ActiveRecord::Base.connection.data_source_exists?(ProjectPercentDoneSnapshot.table_name)

      cache = controller.instance_variable_get(:@project_percent_done_latest_snapshots_cache) || {}
      controller.instance_variable_set(:@project_percent_done_latest_snapshots_cache, cache)
      cache[project.id] ||= begin
        scope = ProjectPercentDoneSnapshot.where(:project_id => project.id)
        {
          :operational => scope.operational.order(:captured_at => :desc, :id => :desc).first,
          :official_weekly => scope.weekly_official.order(:period_end => :desc, :captured_at => :desc, :id => :desc).first,
          :official_monthly => scope.monthly_official.order(:period_end => :desc, :captured_at => :desc, :id => :desc).first
        }
      end
    end
  end
end
