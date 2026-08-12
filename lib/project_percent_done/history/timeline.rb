module ProjectPercentDone
  module History
    class Timeline
      Entry = Struct.new(:period_end, :state, :snapshot, :run_status, keyword_init: true) do
        def active?
          state == 'active' && snapshot && snapshot.display_percent_done.present?
        end
      end

      attr_reader :project, :selection, :today, :period_type

      def initialize(project, selection: nil, today: nil, period_type: 'weekly')
        @project = project
        @period_type = %w[weekly monthly].include?(period_type.to_s) ? period_type.to_s : 'weekly'
        @selection = selection.presence || ProjectPercentDone::Settings.history_default_period
        @today = today || Time.zone.today
      end

      def entries
        return [] unless bounds

        snapshots = snapshot_scope.where(:period_end => bounds).index_by(&:period_end)
        first_snapshot = snapshot_scope.order(:period_end => :asc).first
        observed_start = first_snapshot.try(:project_start_date) || current_project_start_date
        runs = ProjectPercentDoneCollectionRun.where(:target_period_end => bounds).latest_first.group_by(&:target_period_end)
        period_dates(bounds.begin, bounds.end).map do |date|
          snapshot = snapshots[date]
          run = runs[date].try(:first)
          state = snapshot.try(:project_state) || virtual_state(date, first_snapshot, observed_start, run)
          Entry.new(:period_end => date, :state => state, :snapshot => snapshot, :run_status => run.try(:status))
        end
      end

      def options
        values = period_span_options + [
          [I18n.t(:label_project_percent_done_history_current_quarter), 'current_quarter'],
          [I18n.t(:label_project_percent_done_history_current_year), 'current_year'],
          [I18n.t(:label_project_percent_done_history_all), 'all']
        ]
        available_years.each do |year|
          values << ["#{year} (#{date_label(Date.new(year, 1, 1), Date.new(year, 12, 31))})", "calendar:#{year}:year"]
          1.upto(4) do |quarter|
            start_date = Date.new(year, ((quarter - 1) * 3) + 1, 1)
            end_date = (start_date >> 3) - 1
            values << ["Q#{quarter} #{year} (#{date_label(start_date, end_date)})", "calendar:#{year}:q#{quarter}"]
          end
        end
        if ProjectPercentDone::Settings.history_reporting_year == 'fiscal'
          available_fiscal_years.each do |year|
            start_date = Date.new(year, ProjectPercentDone::Settings.history_fiscal_year_start_month, 1)
            values << ["FY#{year} (#{date_label(start_date, (start_date >> 12) - 1)})", "fiscal:#{year}:year"]
            1.upto(4) do |quarter|
              quarter_start = start_date >> ((quarter - 1) * 3)
              values << ["FY#{year} Q#{quarter} (#{date_label(quarter_start, (quarter_start >> 3) - 1)})", "fiscal:#{year}:q#{quarter}"]
            end
          end
        end
        values
      end

      def selected
        fallback = monthly? ? '12' : ProjectPercentDone::Settings.history_default_period
        options.any? { |_label, value| value == selection } ? selection : fallback
      end

      private

      def bounds
        @bounds ||= begin
          end_date = latest_completed_period_end
          case selected
          when /\A(13|26|52|104)\z/
            weeks = selected.to_i
            (end_date - (weeks - 1).weeks)..end_date
          when /\A(6|12|24)\z/
            months = selected.to_i
            ((end_date << (months - 1)).beginning_of_month..end_date)
          when 'all'
            minimum = snapshot_scope.minimum(:period_end)
            minimum ? minimum..end_date : nil
          when 'current_quarter'
            current_named_bounds('quarter')
          when 'current_year'
            current_named_bounds('year')
          when /\A(calendar):(\d{4}):(year|q[1-4])\z/
            named_bounds(Regexp.last_match(2).to_i, 1, Regexp.last_match(3))
          when /\A(fiscal):(\d{4}):(year|q[1-4])\z/
            named_bounds(Regexp.last_match(2).to_i, ProjectPercentDone::Settings.history_fiscal_year_start_month, Regexp.last_match(3))
          else
            default_bounds(end_date)
          end
        end
      end

      def named_bounds(year, start_month, part)
        start_date = Date.new(year, start_month, 1)
        if part == 'year'
          start_date..((start_date >> 12) - 1)
        else
          quarter_start = start_date >> ((part.delete_prefix('q').to_i - 1) * 3)
          quarter_start..((quarter_start >> 3) - 1)
        end
      end

      def current_named_bounds(part)
        start_month = ProjectPercentDone::Settings.history_reporting_year == 'fiscal' ?
                        ProjectPercentDone::Settings.history_fiscal_year_start_month : 1
        year = today.month < start_month ? today.year - 1 : today.year
        return named_bounds(year, start_month, 'year') if part == 'year'

        fiscal_month_index = (today.year * 12 + today.month) - (year * 12 + start_month)
        named_bounds(year, start_month, "q#{(fiscal_month_index / 3) + 1}")
      end

      def sundays(start_date, end_date)
        first = start_date + ((7 - start_date.wday) % 7)
        dates = []
        while first <= [end_date, today - today.wday].min
          dates << first
          first += 7.days
        end
        dates
      end

      def month_ends(start_date, end_date)
        date = start_date.end_of_month
        dates = []
        while date <= end_date
          dates << date
          date = (date + 1.day).end_of_month
        end
        dates
      end

      def available_years
        years = snapshot_scope.pluck(:period_end).compact.map(&:year)
        (years + [today.year]).uniq.sort.reverse
      end

      def available_fiscal_years
        month = ProjectPercentDone::Settings.history_fiscal_year_start_month
        snapshot_scope.pluck(:period_end).compact.map do |date|
          date.month < month ? date.year - 1 : date.year
        end.push(today.month < month ? today.year - 1 : today.year).uniq.sort.reverse
      end

      def date_label(start_date, end_date)
        "#{I18n.l(start_date)} - #{I18n.l(end_date)}"
      end

      def virtual_state(date, first_snapshot, observed_start, run)
        return 'disabled' if run.try(:status) == 'disabled'

        if first_snapshot.nil? || date < first_snapshot.period_end
          return 'planned_not_started' if observed_start && date < observed_start
          return 'not_observed'
        end
        'missing'
      end

      def current_project_start_date
        field = ProjectPercentDone::Settings.history_project_start_custom_field
        return nil unless field

        value = project.custom_field_value(field)
        value.is_a?(Date) ? value : Date.iso8601(value.to_s)
      rescue ArgumentError
        nil
      end

      def monthly?
        period_type == 'monthly'
      end

      def snapshot_scope
        scope = monthly? ? ProjectPercentDoneSnapshot.monthly_official : ProjectPercentDoneSnapshot.weekly_official
        scope.where(:project_id => project.id)
      end

      def period_dates(start_date, end_date)
        monthly? ? month_ends(start_date, end_date) : sundays(start_date, end_date)
      end

      def latest_completed_period_end
        completed = monthly? ? today.beginning_of_month - 1.day : today - today.wday
        latest_snapshot_period_end = snapshot_scope.maximum(:period_end)
        latest_snapshot_period_end && latest_snapshot_period_end > completed ? latest_snapshot_period_end : completed
      end

      def default_bounds(end_date)
        monthly? ? ((end_date << 11).beginning_of_month..end_date) : ((end_date - 51.weeks)..end_date)
      end

      def period_span_options
        if monthly?
          [['6 months', '6'], ['12 months', '12'], ['24 months', '24']]
        else
          [['13 weeks', '13'], ['26 weeks', '26'], ['52 weeks', '52'], ['104 weeks', '104']]
        end
      end
    end
  end
end
