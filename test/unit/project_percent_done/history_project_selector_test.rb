require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::ProjectSelectorTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_matches_when_any_multi_value_intersects_the_configured_values
    custom_field = create_project_type_custom_field
    set_project_custom_field_values(test_project, custom_field, %w[Internal External])

    with_project_percent_done_settings(
      'history_enabled' => '1',
      'history_project_type_custom_field_id' => custom_field.id.to_s,
      'history_project_type_values' => ['External']
    ) do
      selector = ProjectPercentDone::History::ProjectSelector.new

      assert selector.ready?
      assert selector.in_scope?(test_project)
      assert_equal %w[Internal External], selector.values_for(test_project)
    end
  end

  def test_matches_single_value_list_custom_field
    custom_field = ProjectCustomField.create!(
      :name => "Single project type #{SecureRandom.hex(3)}",
      :field_format => 'list',
      :possible_values => %w[Internal External],
      :multiple => false,
      :is_for_all => true
    )
    set_project_custom_fields(test_project, custom_field => 'Internal')

    with_project_percent_done_settings(
      'history_project_type_custom_field_id' => custom_field.id.to_s,
      'history_project_type_values' => ['Internal']
    ) do
      selector = ProjectPercentDone::History::ProjectSelector.new

      assert selector.ready?
      assert selector.in_scope?(test_project)
      assert_equal ['Internal'], selector.values_for(test_project)
    end
  end

  def test_rejects_non_list_custom_field
    custom_field = create_project_date_custom_field

    with_project_percent_done_settings(
      'history_project_type_custom_field_id' => custom_field.id.to_s,
      'history_project_type_values' => ['Internal']
    ) do
      selector = ProjectPercentDone::History::ProjectSelector.new

      refute selector.ready?
      assert_includes selector.validation_errors, 'project_type_custom_field_not_list'
    end
  end

  def test_projects_excludes_untracked_closed_project
    custom_field = create_project_type_custom_field
    set_project_custom_field_values(test_project, custom_field, ['Internal'])
    test_project.update!(:status => Project::STATUS_CLOSED)

    with_project_percent_done_settings(
      'history_project_type_custom_field_id' => custom_field.id.to_s,
      'history_project_type_values' => ['Internal']
    ) do
      refute_includes ProjectPercentDone::History::ProjectSelector.new.projects, test_project
    end
  end

  def test_projects_keeps_previously_tracked_closed_project_for_state_markers
    custom_field = create_project_type_custom_field
    set_project_custom_field_values(test_project, custom_field, ['Internal'])
    ProjectPercentDoneSnapshot.create!(
      :project => test_project,
      :snapshot_kind => 'operational',
      :captured_at => Time.zone.local(2026, 7, 12, 12, 0),
      :project_state => 'active'
    )
    test_project.update!(:status => Project::STATUS_CLOSED)

    with_project_percent_done_settings(
      'history_project_type_custom_field_id' => custom_field.id.to_s,
      'history_project_type_values' => ['Internal']
    ) do
      assert_includes ProjectPercentDone::History::ProjectSelector.new.projects, test_project
    end
  end
end
