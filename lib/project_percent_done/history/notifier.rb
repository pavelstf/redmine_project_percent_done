module ProjectPercentDone
  module History
    class Notifier
      attr_reader :run

      def initialize(run)
        @run = run
      end

      def deliver
        return false unless ProjectPercentDone::Settings.history_email_enabled?
        return false unless reportable?

        validation = SettingsValidator.new.call
        if validation.errors.any? { |error| error.start_with?('email_') }
          run.update!(:email_status => 'failed')
          return false
        end

        recipients = ProjectPercentDone::Settings.history_email_recipients
        ProjectPercentDoneHistoryMailer.collection_notification(
          User.anonymous,
          run,
          recipients,
          ProjectPercentDone::Settings.history_email_recipient_mode,
          SubjectRenderer.new(run).render
        ).deliver_now
        run.update!(
          :email_status => 'sent',
          :email_recipient_count => recipients.size
        )
        true
      rescue StandardError => error
        Rails.logger.error("[ProjectPercentDone] History email failed: #{error.class}: #{error.message}")
        run.update_columns(:email_status => 'failed', :updated_at => Time.zone.now) if run.persisted?
        false
      end

      def self.deliver_test
        validation = SettingsValidator.new.call
        email_errors = validation.errors.select { |error| error.start_with?('email_') }
        raise ArgumentError, email_errors.join(', ') if email_errors.any?

        run = ProjectPercentDoneCollectionRun.new(
          :source => 'test_email',
          :status => 'successful',
          :snapshot_type => 'official',
          :target_period_end => Time.zone.today,
          :started_at => Time.zone.now,
          :projects_processed => 3,
          :projects_succeeded => 3,
          :snapshots_created => 3
        )
        recipients = ProjectPercentDone::Settings.history_email_recipients
        ProjectPercentDoneHistoryMailer.test_notification(
          User.anonymous,
          run,
          recipients,
          ProjectPercentDone::Settings.history_email_recipient_mode,
          SubjectRenderer.new(run).render(:test => true)
        ).deliver_now
      end

      private

      def reportable?
        return weekly_disabled_due? if run.status == 'disabled'

        level = ProjectPercentDone::Settings.history_email_notification_level
        official = run.snapshot_type == 'official' || run.status == 'recovery'
        problem = %w[partial failed recovery].include?(run.status)
        material = run.snapshots_created.to_i.positive? || run.snapshots_promoted.to_i.positive? ||
                   run.details_deleted.to_i.positive? || problem
        return false unless material

        case level
        when 'every_execution'
          true
        when 'weekly_plus_problems'
          official || problem
        else
          official || official_attempt_problem?
        end
      end

      def official_attempt_problem?
        return false unless %w[partial failed].include?(run.status) && run.target_period_end

        first_attempt_date = run.target_period_end + 1.day
        last_attempt_date = first_attempt_date + ProjectPercentDone::Settings.history_promotion_tolerance_days.days
        run.started_at.to_date.between?(first_attempt_date, last_attempt_date)
      end

      def weekly_disabled_due?
        !ProjectPercentDoneCollectionRun.where(
          :target_period_end => run.target_period_end,
          :status => 'disabled',
          :email_status => 'sent'
        ).where.not(:id => run.id).exists?
      end
    end
  end
end
