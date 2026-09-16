require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::CronCommandTest < ActiveSupport::TestCase
  def test_builds_rake_and_full_commands_for_current_environment
    command = ProjectPercentDone::History::CronCommand.new(
      :rails_root => '/home/example/redmine staging',
      :rails_env => 'production',
      :virtual_env => '/home/example/rubyvenv/redmine staging/3.2'
    )

    assert_equal '5 0 * * *', ProjectPercentDone::History::CronCommand::SCHEDULE_EXAMPLE
    assert_equal(
      'bundle exec rake redmine:project_percent_done:snapshots RAILS_ENV=production',
      command.rake_command
    )
    assert_equal(
      "/bin/bash -lc 'source /home/example/rubyvenv/redmine\\ staging/3.2/bin/activate && cd /home/example/redmine\\ staging && bundle exec rake redmine:project_percent_done:snapshots RAILS_ENV=production >> log/project_percent_done_snapshots.log 2>&1'",
      command.full_command
    )
    assert command.virtual_env_detected?
  end

  def test_builds_usable_command_without_virtual_environment
    command = ProjectPercentDone::History::CronCommand.new(
      :rails_root => '/home/example/redmine',
      :rails_env => 'production',
      :virtual_env => ''
    )

    assert_equal(
      "/bin/bash -lc 'cd /home/example/redmine && bundle exec rake redmine:project_percent_done:snapshots RAILS_ENV=production >> log/project_percent_done_snapshots.log 2>&1'",
      command.full_command
    )
    refute command.virtual_env_detected?
  end
end
