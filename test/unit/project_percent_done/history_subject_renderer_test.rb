require File.expand_path('../../test_helper', __dir__)

class ProjectPercentDone::History::SubjectRendererTest < ActiveSupport::TestCase
  include ProjectPercentDoneTestSupport

  def test_replaces_known_placeholders_and_preserves_unknown_ones
    run = build_run('successful')
    with_project_percent_done_settings(
      'history_email_subject_template' => 'Progress %{status} %{snapshot_count} %{unknown}'
    ) do
      subject = ProjectPercentDone::History::SubjectRenderer.new(run).render
      assert_equal 'Progress successful 3 %{unknown}', subject
    end
  end

  def test_blank_saved_template_uses_run_level_digest_default
    run = build_run('successful')
    expected = "[Redmine] Progress digest | #{I18n.l(run.started_at.to_date)} | " \
               "period #{I18n.l(run.target_period_end)} | official | successful"

    with_project_percent_done_settings('history_email_subject_template' => '') do
      assert_equal expected, ProjectPercentDone::History::SubjectRenderer.new(run).render
    end
  end

  def test_rejects_header_injection_and_limits_rendered_subject
    refute ProjectPercentDone::History::SubjectRenderer.valid_template?("Subject\r\nBcc: x@example.test")
    with_project_percent_done_settings('history_email_subject_template' => ('x' * 250)) do
      assert_equal 200, ProjectPercentDone::History::SubjectRenderer.new(build_run('successful')).render.length
    end
  end

  def test_test_and_recovery_prefixes_are_applied
    with_project_percent_done_settings('history_email_subject_template' => 'Progress') do
      subject = ProjectPercentDone::History::SubjectRenderer.new(build_run('recovery')).render(:test => true)
      assert_includes subject, I18n.t(:project_percent_done_history_mail_subject_test_prefix)
      assert_includes subject, I18n.t(:project_percent_done_history_mail_subject_recovery_prefix)
    end
  end

  private

  def build_run(status)
    ProjectPercentDoneCollectionRun.new(
      :source => 'test', :status => status, :snapshot_type => 'official',
      :target_period_end => Date.new(2026, 7, 12), :started_at => Time.zone.local(2026, 7, 13),
      :snapshots_created => 3
    )
  end
end
