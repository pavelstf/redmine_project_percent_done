require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::SettingsValidatorTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_enabled_collection_requires_list_field_and_current_values
    field = create_project_type_custom_field(%w[Internal External])
    result = validator(
      'history_enabled' => '1',
      'history_project_type_custom_field_id' => field.id.to_s,
      'history_project_type_values' => ['Removed']
    )
    assert_includes result.errors, 'project_type_values_stale'
  end

  def test_enabled_collection_accepts_single_value_list_field
    field = ProjectCustomField.create!(
      :name => "Single project type #{SecureRandom.hex(3)}",
      :field_format => 'list',
      :possible_values => %w[Internal External],
      :multiple => false,
      :is_for_all => true
    )

    result = validator(
      'history_enabled' => '1',
      'history_project_type_custom_field_id' => field.id.to_s,
      'history_project_type_values' => ['Internal']
    )

    assert_empty result.errors
  end

  def test_enabled_email_requires_valid_recipients_and_safe_subject
    result = validator(
      'history_email_enabled' => '1',
      'history_email_recipients' => 'valid@example.test, not-an-address',
      'history_email_subject_template' => "Unsafe\nSubject"
    )
    assert_includes result.errors, 'email_recipients_invalid'
    assert_includes result.errors, 'email_subject_invalid'
  end

  def test_recipient_duplicates_are_normalized
    with_project_percent_done_settings('history_email_recipients' => 'a@example.test, a@example.test, b@example.test') do
      assert_equal %w[a@example.test b@example.test], ProjectPercentDone::Settings.history_email_recipients
    end
  end

  def test_optional_plan_fields_must_be_distinct_date_fields_when_selected
    date_field = create_project_date_custom_field
    result = validator(
      'history_project_start_custom_field_id' => date_field.id.to_s,
      'history_project_planned_end_custom_field_id' => date_field.id.to_s
    )
    assert_includes result.errors, 'plan_date_fields_must_differ'

    list_field = create_project_type_custom_field
    result = validator('history_project_start_custom_field_id' => list_field.id.to_s)
    assert_includes result.errors, 'project_start_custom_field_must_be_date'
  end

  private

  def validator(settings)
    ProjectPercentDone::History::SettingsValidator.new(settings).call
  end
end
