class ProjectPercentDoneHistoryMailer < Mailer
  def collection_notification(_language_user, run, recipients, recipient_mode, subject)
    prepare(run)
    mail(mail_headers(recipients, recipient_mode).merge(:subject => subject)) { |format| format.text }
  end

  def test_notification(_language_user, run, recipients, recipient_mode, subject)
    prepare(run)
    @test_message = true
    mail(mail_headers(recipients, recipient_mode).merge(:subject => subject)) { |format| format.text }
  end

  private

  def prepare(run)
    @run = run
    @errors = run.respond_to?(:errors_list) ? run.errors_list : []
    root = Redmine::Utils.relative_url_root.to_s
    @diagnostics_url = "#{Setting.protocol}://#{Setting.host_name}#{root}/settings/plugin/#{ProjectPercentDone::PLUGIN_ID}"
  end

  def mail_headers(recipients, recipient_mode)
    if recipient_mode == 'to'
      { :to => recipients }
    else
      { :to => Setting.mail_from, :bcc => recipients }
    end
  end
end
