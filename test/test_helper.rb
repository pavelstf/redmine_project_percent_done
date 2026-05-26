require File.expand_path('../../../test/test_helper', __FILE__)
require 'securerandom'

module ProjectPercentDoneTestSupport
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
end
