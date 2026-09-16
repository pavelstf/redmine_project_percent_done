module ProjectPercentDone
  module History
    class SubjectRenderer
      MAX_LENGTH = 200
      PLACEHOLDER_PATTERN = /%\{([a-z_]+)\}/.freeze

      class << self
        def valid_template?(template)
          value = template.to_s
          value.present? && value !~ /[\r\n\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/
        end
      end

      attr_reader :run

      def initialize(run)
        @run = run
      end

      def render(test: false)
        template = ProjectPercentDone::Settings.history_email_subject_template
        template = I18n.t(:project_percent_done_history_mail_subject_default) unless self.class.valid_template?(template)
        rendered = template.gsub(PLACEHOLDER_PATTERN) do |match|
          replacements.fetch(Regexp.last_match(1), match)
        end
        rendered = rendered.gsub(/\s+/, ' ').strip[0, MAX_LENGTH]
        rendered = "#{I18n.t(:project_percent_done_history_mail_subject_test_prefix)} #{rendered}" if test
        rendered = "#{I18n.t(:project_percent_done_history_mail_subject_recovery_prefix)} #{rendered}" if run.respond_to?(:status) && run.status == 'recovery'
        rendered[0, MAX_LENGTH]
      end

      private

      def replacements
        {
          'date' => format_date(run.started_at.to_date),
          'period_end' => run.target_period_end ? format_date(run.target_period_end) : '-',
          'status' => run.status.to_s,
          'snapshot_type' => run.snapshot_type.presence || 'operational',
          'captured_at' => I18n.l(run.started_at),
          'deviation' => maximum_deviation,
          'snapshot_count' => run.snapshots_created.to_i.to_s,
          'active_count' => state_count('active').to_s,
          'closed_count' => state_count('closed').to_s,
          'archived_count' => state_count('archived').to_s,
          'out_of_scope_count' => state_count('out_of_scope').to_s,
          'issue_snapshot_count' => run.issue_snapshots_created.to_i.to_s,
          'deleted_detail_count' => run.details_deleted.to_i.to_s,
          'recovered_count' => run.projects_recovered.to_i.to_s
        }
      end

      def state_count(state)
        return 0 unless run.persisted?

        ProjectPercentDoneSnapshot.where(:collection_run_id => run.id, :project_state => state).count
      end

      def maximum_deviation
        return '0m' unless run.persisted?

        seconds = ProjectPercentDoneSnapshot.where(:officialized_by_run_id => run.id).maximum(:deviation_seconds)
        return '0m' unless seconds

        minutes = (seconds.to_i / 60.0).round
        minutes >= 1440 ? "#{(minutes / 1440.0).round(1)}d" : "#{minutes}m"
      end

      def format_date(date)
        I18n.l(date)
      rescue I18n::ArgumentError
        date.iso8601
      end
    end
  end
end
