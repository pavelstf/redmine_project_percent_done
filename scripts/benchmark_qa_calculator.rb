# CPU-only synthetic comparison; does not boot Redmine or touch a database.
require 'benchmark'
require_relative '../lib/project_percent_done/settings'
require_relative '../lib/project_percent_done/calculation_result'
require_relative '../lib/project_percent_done/issue_breakdown_row'
require_relative '../lib/project_percent_done/project_progress_calculator'

settings = ProjectPercentDone::Settings.singleton_class
{
  :issue_scope => 'leaf_issues_only', :unestimated_issue_mode => 'use_average_estimate',
  :rounding_mode => 'nearest_integer', :treat_closed_issues_as_100? => false,
  :non_progress_status_ids => [], :non_progress_tracker_ids => [],
  :non_progress_statuses => [], :non_progress_trackers => []
}.each { |name, value| settings.define_method(name) { value } }

baseline = IO.popen(['git', 'show', '6c76e30:lib/project_percent_done/project_progress_calculator.rb'], &:read)
abort 'Cannot load 1.3.19 baseline' unless $?.success?
eval(baseline.sub('class ProjectProgressCalculator', 'class QaBaselineCalculator'), TOPLEVEL_BINDING, '1.3.19-baseline')
issue_type = Struct.new(:id, :parent_id, :lft, :rgt, :status_id, :tracker_id, :done_ratio, :estimated_hours, :status)
classes = [ProjectPercentDone::QaBaselineCalculator, ProjectPercentDone::ProjectProgressCalculator]
classes.each { |klass| klass.define_method(:project_issues) { @qa_issues } }
puts "Synthetic CPU-only benchmark, #{RUBY_DESCRIPTION}"
puts '25% same-project parents, 75% leaves, fractional estimates. Median of 3 calls.'
puts 'No DB, SQL loading, Rails request, PPH or deployed-host latency is measured.'
puts 'issues,mode,baseline_1.3.19_ms,current_1.3.20_ms'
[2_000, 10_000, 20_000].each do |count|
  issues = Array.new(count) do |index|
    id = index + 1
    parent = index % 4 == 0
    issue_type.new(id, parent ? nil : id - index % 4, id * 2,
                   id * 2 + (parent ? 7 : 1), 1, 1, 70, (id % 2 == 0 ? 0.1 : 0.2), nil)
  end
  [:summary, :details].each do |mode|
    outputs = []
    timings = classes.map do |klass|
      runs = Array.new(3) do
        calculator = klass.new(nil, :mode => mode)
        calculator.instance_variable_set(:@qa_issues, issues)
        result = nil
        elapsed = Benchmark.realtime { result = calculator.call }
        outputs << [result.percent_done, result.issue_count, result.excluded_parent_issue_count]
        elapsed * 1000
      end
      runs.sort[1]
    end
    abort 'Synthetic behavior mismatch' unless outputs.uniq.size == 1
    puts "#{count},#{mode},#{timings.map { |value| format('%.3f', value) }.join(',')}"
  end
end
