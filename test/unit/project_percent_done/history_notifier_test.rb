require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::NotifierTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  setup do
    ActionMailer::Base.deliveries.clear
  end

  teardown do
    ActionMailer::Base.deliveries.clear
  end

  def test_bcc_notification_hides_configured_recipients
    with_email_settings do
      run = create_run('successful', :snapshot_type => 'official', :snapshots_promoted => 1)
      assert ProjectPercentDone::History::Notifier.new(run).deliver
      message = ActionMailer::Base.deliveries.last

      assert_equal %w[a@example.test b@example.test], message.bcc
      assert_equal [Mail::Address.new(Setting.mail_from).address], message.to
      assert_equal 'sent', run.reload.email_status
    end
  end

  def test_weekly_only_does_not_send_successful_operational_result
    with_email_settings do
      run = create_run('successful', :snapshot_type => 'operational', :snapshots_created => 1)
      refute ProjectPercentDone::History::Notifier.new(run).deliver
      assert_empty ActionMailer::Base.deliveries
    end
  end

  def test_disabled_notification_is_sent_at_most_once_for_a_period
    with_email_settings do
      first = create_run('disabled')
      second = create_run('disabled')
      assert ProjectPercentDone::History::Notifier.new(first).deliver
      refute ProjectPercentDone::History::Notifier.new(second).deliver
      assert_equal 1, ActionMailer::Base.deliveries.size
    end
  end

  def test_collection_digest_includes_monthly_snapshot_summary
    with_email_settings do
      run = create_run('successful', :snapshot_type => 'official', :snapshots_promoted => 2)
      create_monthly_snapshot(run, test_project, 40, 'active')
      create_monthly_snapshot(run, Project.create!(:name => 'Another PPD Test', :identifier => "ppd-mail-#{SecureRandom.hex(3)}"), 60, 'closed')

      assert ProjectPercentDone::History::Notifier.new(run).deliver
      body = ActionMailer::Base.deliveries.last.body.decoded

      assert_includes body, I18n.t(:label_project_percent_done_history_monthly_snapshots)
      assert_includes body, '2026-07-31'
      assert_includes body, '40% / 60% / 50.00%'
      assert_includes body, "#{I18n.t(:label_project_percent_done_history_state_active)}=1"
      assert_includes body, "#{I18n.t(:label_project_percent_done_history_state_closed)}=1"
    end
  end

  private

  def with_email_settings(&block)
    with_project_percent_done_settings(
      {
        'history_email_enabled' => '1',
        'history_email_notification_level' => 'weekly_only',
        'history_email_recipient_mode' => 'bcc',
        'history_email_recipients' => 'a@example.test, b@example.test'
      },
      &block
    )
  end

  def create_run(status, attributes = {})
    ProjectPercentDoneCollectionRun.create!(
      {
        :source => 'test', :status => status, :target_period_end => Date.new(2026, 7, 12),
        :started_at => Time.zone.local(2026, 7, 13), :completed_at => Time.zone.local(2026, 7, 13, 0, 1)
      }.merge(attributes)
    )
  end

  def create_monthly_snapshot(run, project, percent, state)
    ProjectPercentDoneSnapshot.create!(
      :project => project,
      :collection_run => run,
      :officialized_by_run => run,
      :snapshot_kind => 'official',
      :period_type => 'monthly',
      :period_end => Date.new(2026, 7, 31),
      :captured_at => Time.zone.local(2026, 8, 1, 0, 15),
      :project_state => state,
      :display_percent_done => percent
    )
  end
end
