module ProjectPercentDone
  module History
    class ProjectSelector
      attr_reader :custom_field, :allowed_values

      def initialize
        @custom_field = ProjectPercentDone::Settings.history_project_type_custom_field
        @allowed_values = ProjectPercentDone::Settings.history_project_type_values
      end

      def ready?
        validation_errors.empty?
      end

      def validation_errors
        errors = []
        errors << 'project_type_custom_field_missing' unless custom_field
        errors << 'project_type_custom_field_not_list' if custom_field && custom_field.field_format != 'list'
        errors << 'project_type_values_missing' if allowed_values.empty?
        errors << 'project_type_values_stale' if custom_field && (allowed_values - possible_values).any?
        errors
      end

      def projects
        current_scope_ids = Project.all.each_with_object([]) do |project, ids|
          ids << project.id if project.active? && in_scope?(project)
        end
        tracked_ids = ProjectPercentDoneSnapshot.distinct.pluck(:project_id)
        Project.where(:id => (current_scope_ids | tracked_ids)).order(:id).to_a
      end

      def in_scope?(project)
        ready? && (values_for(project) & allowed_values).any?
      end

      def values_for(project)
        return [] unless custom_field

        Array(project.custom_field_value(custom_field)).flatten.map(&:to_s).map(&:strip).reject(&:blank?).uniq
      end

      private

      def possible_values
        Array(custom_field.possible_values).map(&:to_s)
      end
    end
  end
end
