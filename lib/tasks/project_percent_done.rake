namespace :redmine do
  namespace :project_percent_done do
    desc 'Capture daily operational and due official project progress snapshots'
    task :snapshots => :environment do
      result = ProjectPercentDone::History::SnapshotCollector.new(:source => 'cron').call
      run = result.run
      puts "Status: #{run.status}"
      puts "Projects processed: #{run.projects_processed}"
      puts "Projects succeeded: #{run.projects_succeeded}"
      puts "Projects failed: #{run.projects_failed}"
      puts "Project snapshots created: #{run.snapshots_created}"
      puts "Project snapshots promoted: #{run.snapshots_promoted}"
      puts "Issue snapshots created: #{run.issue_snapshots_created}"
      puts "Issue snapshot details deleted: #{run.details_deleted}"
      puts "Failures: #{run.errors_list.size}"
    end

    desc 'Delete issue snapshot details outside the configured retention policy'
    task :cleanup => :environment do
      if ENV['DRY_RUN'].to_s == '1'
        puts 'Dry run: cleanup was not executed.'
        puts "Issue detail retention weeks: #{ProjectPercentDone::Settings.history_issue_retention_weeks}"
        puts "Inactive project grace weeks: #{ProjectPercentDone::Settings.history_inactive_grace_weeks}"
        puts "Issue snapshot details eligible for deletion: #{ProjectPercentDone::History::RetentionCleaner.new.preview_count}"
      else
        deleted = ProjectPercentDone::History::RetentionCleaner.new.call
        puts "Issue snapshot details deleted: #{deleted}"
      end
    end


    desc 'Purge all snapshot history for one project (PROJECT=identifier, DRY_RUN=1 by default)'
    task :purge_project => :environment do
      identifier = ENV['PROJECT'].to_s
      abort 'PROJECT=identifier is required' if identifier.blank?
      project = Project.find_by_identifier(identifier)
      abort "Project not found: #{identifier}" unless project
      snapshots = ProjectPercentDoneSnapshot.where(:project_id => project.id)
      details = ProjectPercentDoneIssueSnapshot.joins(:snapshot).where(
        :project_percent_done_snapshots => { :project_id => project.id }
      ).count
      puts "Project: #{project.identifier}"
      puts "Project snapshots: #{snapshots.count}"
      puts "Issue snapshots: #{details}"
      if ENV['DRY_RUN'].to_s != '0'
        puts 'Dry run: no records deleted. Set DRY_RUN=0 to confirm irreversible deletion.'
      else
        snapshots.destroy_all
        puts 'History deleted.'
      end
    end

    desc 'Preview, seed, or clean protected staging demo history (ACTION=preview|seed|cleanup)'
    task :staging_demo => :environment do
      result = ProjectPercentDone::History::StagingDemo.new(
        :action => ENV.fetch('ACTION', 'preview'),
        :confirmation => ENV['CONFIRM']
      ).call
      puts "Action: #{result.action}"
      puts "Project: #{result.project.try(:identifier) || ProjectPercentDone::History::StagingDemo::PROJECT_IDENTIFIER}"
      puts "Project snapshots: #{result.snapshots}"
      puts "Issue snapshots: #{result.issue_snapshots}"
      puts "Collection runs: #{result.runs}"
      puts result.message
    end
  end
end
