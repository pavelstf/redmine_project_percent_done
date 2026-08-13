redmine_root = ENV.fetch('REDMINE_ROOT', Dir.pwd)
require File.expand_path('test/test_helper', redmine_root)
require 'securerandom'

module ProjectPercentDoneTestSupport
  private

  def with_project_percent_done_settings(settings)
    previous_settings = Setting.plugin_redmine_project_percent_done
    Setting.plugin_redmine_project_percent_done = ProjectPercentDone::Settings::DEFAULTS.merge(settings)
    yield
  ensure
    Setting.plugin_redmine_project_percent_done = previous_settings
  end

  def test_project
    @test_project ||= Project.create!(
      :name => "Project Percent Done Test #{SecureRandom.hex(4)}",
      :identifier => "ppd-test-#{SecureRandom.hex(4)}",
      :is_public => true
    )
  end

  def test_tracker
    @test_tracker ||= Tracker.first || Tracker.create!(:name => "Task")
  end

  def open_status
    @open_status ||= IssueStatus.where(:is_closed => false).first || IssueStatus.create!(:name => "Open")
  end

  def closed_status
    @closed_status ||= IssueStatus.where(:is_closed => true).first || IssueStatus.create!(:name => "Closed", :is_closed => true)
  end

  def issue_priority
    @issue_priority ||= IssuePriority.where(:is_default => true).first || IssuePriority.first || IssuePriority.create!(:name => "Normal")
  end

  def issue_author
    @issue_author ||= User.find_by_login('admin') || User.first
  end

  def create_test_issue(attributes = {})
    Issue.create!(
      {
        :project => test_project,
        :tracker => test_tracker,
        :status => open_status,
        :priority => issue_priority,
        :author => issue_author,
        :subject => "Progress test issue #{SecureRandom.hex(4)}",
        :done_ratio => 0
      }.merge(attributes)
    )
  end

  def create_project_type_custom_field(values = %w[Internal External])
    ProjectCustomField.create!(
      :name => "Project type #{SecureRandom.hex(3)}",
      :field_format => 'list',
      :possible_values => values,
      :multiple => true,
      :is_for_all => true
    )
  end

  def create_project_date_custom_field(name = nil)
    ProjectCustomField.create!(
      :name => name || "Project date #{SecureRandom.hex(3)}",
      :field_format => 'date',
      :is_for_all => true
    )
  end

  def set_project_custom_field_values(project, custom_field, values)
    project.custom_field_values = { custom_field.id.to_s => Array(values) }
    project.save!
    project.reload
  end

  def set_project_custom_fields(project, values)
    project.custom_field_values = values.each_with_object({}) do |(field, value), result|
      result[field.id.to_s] = value
    end
    project.save!
    project.reload
  end
end
