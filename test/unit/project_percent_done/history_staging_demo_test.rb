require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::StagingDemoTest < ActiveSupport::TestCase
  def test_refuses_non_staging_host
    error = assert_raises(ArgumentError) do
      ProjectPercentDone::History::StagingDemo.new(
        :action => 'preview',
        :confirmation => 'STAGING_DEMO_HISTORY',
        :host_name => 'redmine.gcr.bg'
      ).call
    end

    assert_includes error.message, 'Refusing non-staging host'
  end

  def test_refuses_without_exact_confirmation
    assert_raises(ArgumentError) do
      ProjectPercentDone::History::StagingDemo.new(
        :action => 'seed',
        :confirmation => 'yes',
        :host_name => 'redminestaging.gcr.bg'
      ).call
    end
  end

  def test_seed_creates_demo_history_and_cleanup_removes_only_history
    client_field = ProjectCustomField.create!(
      :name => 'Required demo client',
      :field_format => 'string',
      :is_required => true,
      :is_for_all => true
    )
    type_field = ProjectCustomField.create!(
      :name => 'Required demo project type',
      :field_format => 'list',
      :possible_values => ['Internal', 'External'],
      :multiple => true,
      :is_required => true,
      :is_for_all => true
    )
    date_field = ProjectCustomField.create!(
      :name => 'Required demo start date',
      :field_format => 'date',
      :is_required => true,
      :is_for_all => true
    )
    end_date_field = ProjectCustomField.create!(
      :name => 'Required demo end date',
      :field_format => 'date',
      :is_required => true,
      :is_for_all => true
    )
    previous_settings = Setting.plugin_redmine_project_percent_done
    Setting.plugin_redmine_project_percent_done = ProjectPercentDone::Settings::DEFAULTS.merge(
      'history_project_type_custom_field_id' => type_field.id.to_s,
      'history_project_type_values' => ['Internal'],
      'history_project_start_custom_field_id' => date_field.id.to_s,
      'history_project_planned_end_custom_field_id' => end_date_field.id.to_s
    )
    service = lambda do |action|
      ProjectPercentDone::History::StagingDemo.new(
        :action => action,
        :confirmation => 'STAGING_DEMO_HISTORY',
        :host_name => 'redminestaging.gcr.bg',
        :today => Date.new(2026, 7, 16)
      ).call
    end

    seeded = service.call('seed')

    assert_equal 'ppd-history-test', seeded.project.identifier
    assert_equal 14, seeded.snapshots
    assert_equal 66, seeded.issue_snapshots
    assert_equal 15, seeded.runs
    assert_equal 'Synthetic staging history created: live 60%, 200 estimated hours, 132 reported hours.', seeded.message
    assert_equal 'STAGING DEMO', seeded.project.custom_value_for(client_field).value
    assert_equal ['Internal'], seeded.project.custom_values.where(:custom_field_id => type_field.id).pluck(:value)
    assert_equal '2026-04-19', seeded.project.custom_value_for(date_field).value
    assert_equal '2026-06-28', seeded.project.custom_value_for(end_date_field).value
    assert_equal 6, Issue.where(:project_id => seeded.project.id).count
    assert_equal 200.to_d, Issue.where(:project_id => seeded.project.id).sum(:estimated_hours)
    assert_equal 15, TimeEntry.where(:project_id => seeded.project.id).count
    assert_equal 132.to_d, TimeEntry.where(:project_id => seeded.project.id).sum(:hours)

    live = ProjectPercentDone::ProjectProgressCalculator.new(seeded.project, :mode => :details).call
    latest = ProjectPercentDoneSnapshot.official.where(:project_id => seeded.project.id).latest_first.first
    assert_equal 60, live.percent_done
    assert_equal live.percent_done, latest.display_percent_done
    assert_in_delta live.raw_percent_done, latest.raw_percent_done.to_f, 0.0001
    assert_equal 200.to_d, latest.known_estimated_hours
    assert_equal 100.to_d, latest.estimate_coverage_percent
    assert_equal 132.to_d, latest.spent_hours_total
    assert_equal 4.to_d, latest.hours_before_start
    assert_equal 116.to_d, latest.hours_within_plan
    assert_equal 12.to_d, latest.hours_after_planned_end
    assert_equal 6, latest.issue_snapshots.count
    assert_in_delta latest.raw_percent_done.to_f,
                    latest.issue_snapshots.sum(:weighted_value).to_f / latest.total_weight.to_f * 100,
                    0.0001
    active_snapshots = ProjectPercentDoneSnapshot.official
                                                 .where(:project_id => seeded.project.id, :project_state => 'active')
                                                 .order(:period_end)
    assert_equal [7, 12, 20, 26, 31, 36, 42, 46, 51, 55, 60],
                 active_snapshots.pluck(:display_percent_done).map(&:to_i)
    active_snapshots.each do |snapshot|
      aggregate = snapshot.issue_snapshots.sum(:weighted_value).to_f / snapshot.total_weight.to_f * 100
      assert_in_delta snapshot.raw_percent_done.to_f, aggregate, 0.0001
    end
    assert ProjectPercentDoneSnapshot.where(:project_id => seeded.project.id, :project_state => 'closed').exists?
    assert ProjectPercentDoneSnapshot.where(:project_id => seeded.project.id, :project_state => 'out_of_scope').exists?
    assert ProjectPercentDone::History::Forecast.new(seeded.project).call.available?

    ProjectPercentDoneCollectionRun.where(:source => 'staging_test').first.update!(:source => 'admin')
    reseeded = service.call('seed')
    assert_equal 14, reseeded.snapshots
    assert_equal 66, reseeded.issue_snapshots
    assert_equal 14, ProjectPercentDoneSnapshot.where(:project_id => seeded.project.id).count
    assert_equal 15, ProjectPercentDoneCollectionRun.where(:source => 'staging_test').count
    assert_equal 6, Issue.where(:project_id => seeded.project.id).count
    assert_equal 15, TimeEntry.where(:project_id => seeded.project.id).count

    cleaned = service.call('cleanup')

    assert_equal 14, cleaned.snapshots
    assert_equal 66, cleaned.issue_snapshots
    assert_equal 15, cleaned.runs
    assert Project.exists?(seeded.project.id)
    assert_equal 0, ProjectPercentDoneSnapshot.where(:project_id => seeded.project.id).count
    assert_equal 6, Issue.where(:project_id => seeded.project.id).count
    assert_equal 15, TimeEntry.where(:project_id => seeded.project.id).count

    seeded.project.update!(:name => 'Not the protected demo project')
    error = assert_raises(RuntimeError) { service.call('seed') }
    assert_includes error.message, 'is not the protected demo project'
  ensure
    Setting.plugin_redmine_project_percent_done = previous_settings if defined?(previous_settings)
  end
end
