module ProjectPercentDone
  module History
    class RetentionCleaner
      BATCH_SIZE = 200

      attr_reader :today

      def initialize(today: nil)
        @today = today || Time.zone.today
      end

      def call
        delete_by_age + delete_for_inactive_projects
      end

      def preview_count
        (age_scope.to_a + inactive_scope.to_a).uniq.sum { |snapshot| snapshot.issue_snapshots.count }
      end

      private

      def delete_by_age
        cutoff = today - ProjectPercentDone::Settings.history_issue_retention_weeks.weeks
        purge_snapshots(age_scope(cutoff))
      end

      def age_scope(cutoff = nil)
        cutoff ||= today - ProjectPercentDone::Settings.history_issue_retention_weeks.weeks
        ProjectPercentDoneSnapshot.official
                                  .joins(:issue_snapshots)
                                  .distinct
                                  .where('period_end < ?', cutoff)
                                  .where(:details_purged_at => nil)
      end

      def inactive_scope
        ids = project_ids_with_details.select do |project_id|
          inactive_since = current_inactive_since(project_id)
          inactive_since && today >= inactive_since + ProjectPercentDone::Settings.history_inactive_grace_weeks.weeks
        end
        ProjectPercentDoneSnapshot.joins(:issue_snapshots).distinct.where(:project_id => ids, :details_purged_at => nil)
      end

      def delete_for_inactive_projects
        total = 0
        grace_days = ProjectPercentDone::Settings.history_inactive_grace_weeks.weeks
        project_ids_with_details.each do |project_id|
          inactive_since = current_inactive_since(project_id)
          next unless inactive_since
          next if today < inactive_since + grace_days

          total += purge_snapshots(
            ProjectPercentDoneSnapshot.where(:project_id => project_id, :details_purged_at => nil)
          )
        end
        total
      end

      def project_ids_with_details
        ProjectPercentDoneSnapshot.joins(:issue_snapshots).distinct.pluck(:project_id)
      end

      def current_inactive_since(project_id)
        states = ProjectPercentDoneSnapshot.weekly_official
                                           .where(:project_id => project_id)
                                           .order(:period_end => :desc)
                                           .pluck(:period_end, :project_state)
        return nil unless states.first && %w[closed archived].include?(states.first.last)

        consecutive = states.take_while { |_period_end, state| %w[closed archived].include?(state) }
        consecutive.last.first
      end

      def purge_snapshots(scope)
        total = 0
        scope.find_each(:batch_size => BATCH_SIZE) do |snapshot|
          deleted = snapshot.issue_snapshots.delete_all
          snapshot.update_columns(:details_purged_at => Time.zone.now, :updated_at => Time.zone.now)
          total += deleted
        end
        total
      end
    end
  end
end
