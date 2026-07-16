module ProjectPercentDone
  module SettingsControllerPatch
    def plugin
      if request.post? && params[:id].to_s == ProjectPercentDone::PLUGIN_ID
        proposed = params[:settings] ? params[:settings].permit!.to_h : {}
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
      end
      super
    end
  end
end
