module ProjectPercentDone
  module SettingsControllerPatch
    def plugin
      if request.post? && params[:id].to_s == ProjectPercentDone::PLUGIN_ID
        proposed = params[:settings] ? params[:settings].permit!.to_h : {}
        if ProjectPercentDone::History::Coexistence.owns_history?
          validation = ProjectPercentDone::History::SettingsValidator.new(proposed).call
          if validation.errors.any?
            @plugin = Redmine::Plugin.find(params[:id])
            @partial = @plugin.settings[:partial]
            @settings = ProjectPercentDone::Settings::DEFAULTS.merge(proposed)
            flash.now[:error] = validation.errors.map do |code|
              l("text_project_percent_done_#{code}", :default => code)
            end.join('; ')
            render :action => 'plugin'
            return
          end
        else
          params[:settings] = ProjectPercentDone::History::Coexistence.sanitize_project_percent_done_settings(proposed)
        end
      end
      super
    end
  end
end
