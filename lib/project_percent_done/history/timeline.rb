module ProjectPercentDone
  module History
    class Timeline
      Entry = Struct.new(:period_end, :state, :snapshot, :run_status, keyword_init: true) do
        def active?
          state == 'active' && snapshot && snapshot.display_percent_done.present?
        end
      end

      attr_reader :project, :selection, :today

      def initialize(project, selection: nil, today: nil)
        @project = project
        @selection = selection.presence || ProjectPercentDone::Settings.history_default_period
        @today = today || Time.zone.today
      end

      def entries
        return [] unless bounds

        snapshots = ProjectPercentDoneSnapshot.official.where(:project_id => project.id, :period_end => bounds).index_by(&:period_end)
        first_snapshot = ProjectPercentDoneSnapshot.official.where(:project_id => project.id).order(:period_end => :asc).first
        observed_start = first_snapshot.try(:project_start_date) || current_project_start_date
        runs = ProjectPercentDoneCollectionRun.where(:target_period_end => bounds).latest_first.group_by(&:target_period_end)
        sundays(bounds.begin, bounds.end).map do |date|
          snapshot = snapshots[date]
          run = runs[date].try(:first)
          state = snapshot.try(:project_state) || virtual_state(date, first_snapshot, observed_start, run)
          Entry.new(:period_end => date, :state => state, :snapshot => snapshot, :run_status => run.try(:status))
        end
      end

      def options
        values = [
          ['13 weeks', '13'], ['26 weeks', '26'], ['52 weeks', '52'], ['104 weeks', '104'],
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
        options.any? { |_label, value| value == selection } ? selection : ProjectPercentDone::Settings.history_default_period
      end

      private

      def bounds
        @bounds ||= begin
          last_sunday = today - today.wday
          case selected
          when /\A(13|26|52|104)\z/
            weeks = selected.to_i
            (last_sunday - (weeks - 1).weeks)..last_sunday
          when 'all'
            minimum = ProjectPercentDoneSnapshot.official.where(:project_id => project.id).minimum(:period_end)
            minimum ? minimum..last_sunday : nil
          when 'current_quarter'
            current_named_bounds('quarter')
          when 'current_year'
            current_named_bounds('year')
          when /\A(calendar):(\d{4}):(year|q[1-4])\z/
            named_bounds(Regexp.last_match(2).to_i, 1, Regexp.last_match(3))
          when /\A(fiscal):(\d{4}):(year|q[1-4])\z/
            named_bounds(Regexp.last_match(2).to_i, ProjectPercentDone::Settings.history_fiscal_year_start_month, Regexp.last_match(3))
          else
            (last_sunday - 51.weeks)..last_sunday
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

      def available_years
        years = ProjectPercentDoneSnapshot.official.where(:project_id => project.id).pluck(:period_end).compact.map(&:year)
        (years + [today.year]).uniq.sort.reverse
      end

      def available_fiscal_years
        month = ProjectPercentDone::Settings.history_fiscal_year_start_month
        ProjectPercentDoneSnapshot.official.where(:project_id => project.id).pluck(:period_end).compact.map do |date|
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
    end
  end
end
