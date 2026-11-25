# Run only through the matching production shell scripts, inside the Rails runner.
require 'json'
require 'digest'
require 'fileutils'

# ASSET_REFRESH_BEGIN
module PpdDeploymentAssets
  def self.refresh(root)
    source = File.join(root, 'plugins/redmine_project_percent_done/assets')
    files = Dir.glob(File.join(source, '**', '*')).select { |path| File.file?(path) }
    raise 'Source assets missing' if files.empty?
    count = 0
    files.each do |file|
      relative = file.delete_prefix(source + '/')
      ['public/plugin_assets/redmine_project_percent_done',
       'public/assets/plugin_assets/redmine_project_percent_done'].each_with_index do |base, index|
        base_path = File.join(root, base)
        next if index == 1 && !File.directory?(base_path)
        destination = File.join(base_path, relative)
        FileUtils.mkdir_p(File.dirname(destination))
        real_directory = File.realpath(File.dirname(destination))
        raise 'Asset directory escapes production root' unless real_directory.start_with?(File.realpath(root) + '/')
        raise 'Unexpected asset symlink' if File.symlink?(destination)
        FileUtils.cp(file, destination, :preserve => true)
        expected = Digest::SHA256.file(file).hexdigest
        raise 'Asset copy mismatch' unless Digest::SHA256.file(destination).hexdigest == expected
        count += 1
        next unless File.extname(file) == '.css' && index == 1
        stem = File.basename(file, '.css')
        Dir.glob(File.join(File.dirname(destination), stem + '-*.css')).each do |compiled|
          raise 'Unexpected compiled asset symlink' if File.symlink?(compiled)
          FileUtils.cp(file, compiled, :preserve => true)
          raise 'Compiled asset mismatch' unless Digest::SHA256.file(compiled).hexdigest == expected
          count += 1
        end
      end
    end
    count
  end
end
# ASSET_REFRESH_END

def verify_runtime!(root)
  # Verify every installed file against the original accepted QA manifest.
  manifest = JSON.parse(File.read(Rails.root.join('plugins/redmine_project_percent_done/QA_MANIFEST.json')))
  abort 'Wrong QA source commit' unless manifest['source_commit'] == 'f763c1723d9e586261c5beff9bbd19f1e7270b80'
  abort 'Wrong QA ref' unless manifest['source_ref'] == 'qa-v1.3.20-r2'
  manifest.fetch('files').each do |name, expected|
    abort 'Unexpected manifest path' unless name.start_with?('redmine_project_percent_done/') && !name.split('/').include?('..')
    path = Rails.root.join('plugins', name)
    abort "Installed checksum mismatch: #{name}" unless Digest::SHA256.file(path).hexdigest.upcase == expected
  end
end

root = '/home/gcrbgcaa/redmine'
abort 'Wrong Rails root/environment' unless Rails.root.realpath.to_s == root && Rails.env.production?
mode = ENV.fetch('PPD_DEPLOY_MODE')
abort 'Invalid mode' unless %w[before after rollback assets].include?(mode)
plugin = Redmine::Plugin.find(:redmine_project_percent_done)
puts "ENVIRONMENT mode=#{mode} Redmine=#{Redmine::VERSION} Ruby=#{RUBY_VERSION} Rails=#{Rails.version} PPD=#{plugin.version}"
[:redmine_project_budget, :redmine_project_progress_history].each do |id|
  companion = begin
    Redmine::Plugin.find(id)
  rescue Redmine::PluginNotFound
    nil
  end
  puts "COMPANION #{id}=#{companion ? companion.version : 'not installed'}"
end
if defined?(ProjectBudget::Settings)
  puts "PB_UI_PROGRESS_ENABLED=#{ProjectBudget::Settings.new.progress_enabled?}"
end
connection = ActiveRecord::Base.connection
version = Redmine::Plugin::Migrator.current_version(plugin)
abort "Expected recorded PPD migration 2, found #{version}; inspect schema before retrying" unless version == 2
%w[project_percent_done_collection_runs project_percent_done_snapshots project_percent_done_issue_snapshots].each do |table|
  abort "Missing legacy table #{table}; no automatic repair attempted" unless connection.data_source_exists?(table)
end
abort 'Missing period_type' unless connection.column_exists?(:project_percent_done_snapshots, :period_type)
index = connection.indexes(:project_percent_done_snapshots).find { |item| item.name == 'idx_ppd_snapshots_project_period' }
abort 'Unexpected snapshot unique index' unless index && index.unique && index.columns == %w[project_id period_type period_end]

if mode == 'rollback'
  abort 'Restore version mismatch' unless plugin.version.to_s == ENV.fetch('PPD_ROLLBACK_VERSION')
  puts "ROLLBACK_VERSION_OK=#{plugin.version}"
  exit
end

api = ProjectPercentDone::PublicApi::V1
caps = api.capabilities
abort 'Unexpected public API contract' unless caps.contract_name == 'project_percent_done' && caps.contract_version == '1.0'
if mode == 'assets'
  abort 'Wrong PPD version/algorithm for assets' unless plugin.version.to_s == '1.3.20' && caps.algorithm_version == '1.2'
  verify_runtime!(root)
  puts "ASSETS_OK verified_copies=#{PpdDeploymentAssets.refresh(root)}"
  exit
end

baseline_path = ENV.fetch('PPD_BASELINE')
abort 'Unexpected baseline path' unless baseline_path.start_with?(root + '/plugins/redmine_project_percent_done-production-before-')
settings_digest = Digest::SHA256.hexdigest(Setting.plugin_redmine_project_percent_done.to_json)

if mode == 'before'
  # Aggregate-only baseline: never persist issue subjects/contact/evidence data.
  cross_ids = Issue.joins('INNER JOIN issues ppd_child ON ppd_child.parent_id = issues.id')
                   .where('ppd_child.project_id <> issues.project_id').distinct.pluck(:project_id)
  ids = (cross_ids + Project.active.order(:id).limit(3).pluck(:id)).uniq
  rows = Project.where(:id => ids).order(:id).map do |project|
    result = api.calculate(:project => project)
    {:project_id => project.id, :raw => result.raw_percent_done, :display => result.display_percent_done}
  end
  abort 'No projects available for before/after API validation; code was not replaced' if rows.empty?
  baseline = {:version => plugin.version.to_s, :algorithm => caps.algorithm_version,
              :settings_sha256 => settings_digest, :projects => rows}
  File.open(baseline_path, 'w', 0600) { |file| file.write(JSON.pretty_generate(baseline)) }

  # Pass the DB password via the child environment, never shell text or argv.
  config = ActiveRecord::Base.connection_db_config.configuration_hash
  abort 'Production backup supports MySQL/MariaDB only' unless %w[mysql mysql2].include?(config[:adapter].to_s)
  dump = ENV.fetch('PPD_DUMP_BIN')
  backup = ENV.fetch('PPD_DB_BACKUP')
  abort 'Unexpected DB backup path' unless backup.start_with?(root + '/plugins/redmine_project_percent_done-production-db-backup-')
  options = ['--single-transaction', '--quick', '--skip-lock-tables', '--no-tablespaces',
             "--user=#{config.fetch(:username)}"]
  options << "--host=#{config[:host]}" if config[:host]
  options << "--port=#{config[:port]}" if config[:port]
  options << "--socket=#{config[:socket]}" if config[:socket]
  options << config.fetch(:database)
  File.open(backup, 'wb', 0600) do |file|
    pid = Process.spawn({'MYSQL_PWD' => config[:password].to_s}, dump, *options, :out => file)
    _, status = Process.wait2(pid)
    abort 'Database backup failed; plugin code was not replaced' unless status.success?
  end
  abort 'Empty DB backup' unless File.size?(backup)
  puts "BEFORE_OK version=#{plugin.version} algorithm=#{caps.algorithm_version} projects=#{rows.size}"
  exit
end

abort 'Wrong PPD version' unless plugin.version.to_s == '1.3.20' && ProjectPercentDone::PLUGIN_VERSION == '1.3.20'
abort 'Wrong algorithm' unless caps.algorithm_version == '1.2'
baseline = JSON.parse(File.read(baseline_path))
abort 'PPD settings changed; inspect before acceptance' unless baseline.fetch('settings_sha256') == settings_digest
if ProjectPercentDone::History::Coexistence.progress_history_plugin_active?
  abort 'Legacy PPD collection/email guard failed' if ProjectPercentDone::Settings.history_enabled? || ProjectPercentDone::Settings.history_email_enabled?
  puts 'PPD_LEGACY_HISTORY_GUARD_OK'
end

verify_runtime!(root)

baseline.fetch('projects').each do |old|
  project = Project.find(old.fetch('project_id'))
  result = api.calculate(:project => project)
  payload = api.calculate(:project => project, :include_evidence => true).to_h
  abort 'Evidence schema mismatch' unless payload.dig(:provider_metadata, :evidence_schema_version) == '1.0'
  abort 'Evidence algorithm mismatch' unless payload.dig(:provider_metadata, :algorithm_version) == '1.2'
  abort 'Evidence/default progress mismatch' unless payload[:raw_percent_done] == result.raw_percent_done
  abort 'Invalid evidence rows' unless payload[:issue_evidence].is_a?(Array)
  puts "PROJECT #{project.id}: raw #{old['raw'].inspect} -> #{result.raw_percent_done.inspect}; display #{old['display'].inspect} -> #{result.display_percent_done.inspect}"
  if defined?(ProjectBudget::ProgressProvider)
    provider = ProjectBudget::ProgressProvider.new
    abort 'Project Budget provider incompatible' unless provider.compatible?
    budget_progress = provider.percent(project)
    expected = result.raw_percent_done
    abort 'Project Budget progress mismatch' unless (expected.nil? && budget_progress.nil?) ||
      (!expected.nil? && !budget_progress.nil? && (budget_progress.to_f - expected).abs < 1e-9)
    puts "PB_PROVIDER_OK project=#{project.id}"
  end
  if defined?(ProjectProgressHistory::Providers::ProjectPercentDoneAdapter)
    adapter_result = ProjectProgressHistory::Providers::ProjectPercentDoneAdapter.new.current_progress(:project => project)
    abort 'PPH progress mismatch' unless adapter_result.raw_percent_done == result.raw_percent_done
    abort 'PPH evidence unavailable' unless adapter_result.issue_evidence.is_a?(Array)
    puts "PPH_PROVIDER_OK project=#{project.id} evidence_rows=#{adapter_result.issue_evidence.size}"
  end
end
puts "AFTER_OK version=#{plugin.version} algorithm=#{caps.algorithm_version} settings_preserved=true"
puts 'No capture, backfill, email or cron operation was requested.'
