require File.expand_path('../test_helper', __dir__)

class ProjectPercentDoneHooksTest < ActionController::TestCase
  tests ProjectsController
  include ProjectPercentDoneTestSupport

  def setup
    @request.session[:user_id] = 1
  end

  def test_project_overview_hook_renders_history_link_without_plugin_helper_context
    with_project_percent_done_settings(
      'display_overview' => '1',
      'history_enabled' => '1',
      'history_visibility' => 'project_access'
    ) do
      get :show, :params => { :id => test_project.identifier }

      assert_response :success
      assert_select "a[href=\"#{project_percent_done_history_path(:project_id => test_project.identifier)}\"]",
                    :text => I18n.t(:label_project_percent_done_history_tab)
    end
  end

  def test_hook_passes_latest_snapshot_groups_to_dashboard_partial
    older_operational = ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'operational',
      :period_type => 'weekly',
      :captured_at => Time.zone.local(2026, 8, 12, 0, 5),
      :project_state => 'active',
      :display_percent_done => 40
    )
    latest_operational = ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'operational',
      :period_type => 'weekly',
      :captured_at => Time.zone.local(2026, 8, 13, 0, 5),
      :project_state => 'active',
      :display_percent_done => 42
    )
    official_weekly = ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'official',
      :period_type => 'weekly',
      :period_end => Date.new(2026, 8, 9),
      :captured_at => Time.zone.local(2026, 8, 10, 0, 5),
      :project_state => 'active',
      :display_percent_done => 41
    )
    official_monthly = ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'official',
      :period_type => 'monthly',
      :period_end => Date.new(2026, 7, 31),
      :captured_at => Time.zone.local(2026, 8, 1, 0, 5),
      :project_state => 'active',
      :display_percent_done => 42
    )

    fake_controller = Object.new
    captured_locals = nil
    fake_controller.define_singleton_method(:render_to_string) do |options|
      captured_locals = options[:locals]
      ''
    end

    ProjectPercentDone::Hooks.send(:new).send(
      :render_project_percent_done_partial,
      { :controller => fake_controller, :project => test_project },
      'hooks/project_percent_done/sidebar'
    )

    refute_equal older_operational, captured_locals[:latest_snapshots][:operational]
    assert_equal latest_operational, captured_locals[:latest_snapshots][:operational]
    assert_equal official_weekly, captured_locals[:latest_snapshots][:official_weekly]
    assert_equal official_monthly, captured_locals[:latest_snapshots][:official_monthly]
  end

  def test_hook_skips_latest_snapshot_group_lookup_when_history_table_is_missing
    fake_controller = Object.new
    captured_locals = nil
    fake_controller.define_singleton_method(:render_to_string) do |options|
      captured_locals = options[:locals]
      ''
    end

    connection = ActiveRecord::Base.connection
    singleton_class = class << connection; self; end
    singleton_class.alias_method :original_data_source_exists?, :data_source_exists?
    singleton_class.define_method(:data_source_exists?) { |_table_name| false }

    begin
      ProjectPercentDone::Hooks.send(:new).send(
        :render_project_percent_done_partial,
        { :controller => fake_controller, :project => test_project },
        'hooks/project_percent_done/sidebar'
      )
    ensure
      singleton_class.alias_method :data_source_exists?, :original_data_source_exists?
      singleton_class.remove_method :original_data_source_exists?
    end

    assert_equal({}, captured_locals[:latest_snapshots])
  end

  def test_dashboard_partial_renders_snapshot_freshness_groups
    operational_snapshot = ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'operational',
      :period_type => 'weekly',
      :captured_at => Time.zone.local(2026, 8, 13, 0, 5),
      :project_state => 'active',
      :display_percent_done => 42
    )
    weekly_snapshot = ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'official',
      :period_type => 'weekly',
      :period_end => Date.new(2026, 8, 9),
      :captured_at => Time.zone.local(2026, 8, 10, 0, 5),
      :project_state => 'active',
      :display_percent_done => 42
    )
    result = ProjectPercentDone::ProjectProgressCalculator.new(test_project, :mode => :summary).call

    html = @controller.send(
      :render_to_string,
      :partial => 'hooks/project_percent_done/sidebar',
      :locals => {
        :project => test_project,
        :result => result,
        :history_available => false,
        :latest_snapshots => {
          :operational => operational_snapshot,
          :official_weekly => weekly_snapshot,
          :official_monthly => nil
        }
      }
    )

    assert_includes html, 'ppd-snapshot-freshness'
    assert_includes html, I18n.t(:label_project_percent_done_latest_operational_snapshot)
    assert_includes html, I18n.t(:label_project_percent_done_snapshot_backup)
    assert_includes html, I18n.t(:label_project_percent_done_latest_official_weekly_snapshot)
    assert_includes html, I18n.t(:label_project_percent_done_latest_official_monthly_snapshot)
    assert_includes html, I18n.t(:label_project_percent_done_no_official_monthly_snapshot_yet)
  end
end
