clear
# Run with bash: this script uses Bash arrays and process substitution.
set -Eeo pipefail
PHASE='Ruby environment activation'
trap 'status=$?; printf "ERROR: staging install phase=%s line=%s exit=%s\n" "$PHASE" "$LINENO" "$status" >&2; exit "$status"' ERR
umask 077
ROOT=/home/gcrbgcaa/redminestaging
PLUGIN=redmine_project_percent_done
ZIP_NAME=redmine_project_percent_done-1.3.20-staging-20261125-r2.zip
EXPECTED_SHA=FA3B218167DAEC4996486BB22D6D0F1D0B5FFC3CC0952DCFD2C1F1B923B60F67
echo 'STEP: Ruby environment activation (operator revision op3)'
# cPanel activation contains probes that need not individually return zero.
# Keep errexit suppression scoped to activation; require its final status.
if source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate; then
  echo 'VENV_ACTIVATED'
else
  status=$?
  printf 'ERROR: Ruby environment activation failed, exit=%s\n' "$status" >&2
  exit "$status"
fi
set -u
PHASE='staging root and user'
echo "STEP: $PHASE"
cd "$ROOT"
test "$(pwd -P)" = "$ROOT"
test "$(id -un)" = gcrbgcaa
PHASE='required commands'
echo "STEP: $PHASE"
for command in sha256sum unzip tar gzip realpath ruby bundle; do command -v "$command" >/dev/null; done
DUMP_BIN="$(command -v mariadb-dump || command -v mysqldump)"
test -n "$DUMP_BIN"
PHASE='package checksum and size'
echo "STEP: $PHASE"
ZIP="$ROOT/plugins/$ZIP_NAME"
test -f "$ZIP"
test "$(sha256sum "$ZIP" | awk '{print toupper($1)}')" = "$EXPECTED_SHA"
test "$(wc -c < "$ZIP" | tr -d '[:space:]')" = 169409
guard_path() {
  case "$(realpath -m -- "$1")" in "$ROOT"/*) ;; *) echo "Unsafe staging path: $1" >&2; exit 1;; esac
}
for path in "$ROOT/plugins/$PLUGIN" "$ROOT/public/plugin_assets/$PLUGIN" "$ROOT/public/assets/plugin_assets/$PLUGIN"; do
  PHASE="path guard: $path"
  guard_path "$path"
  test ! -L "$path"
done
test -f "$ROOT/plugins/$PLUGIN/init.rb"
PHASE='Ruby and Bundler dependency check'
echo "STEP: $PHASE"
test "$(command -v ruby)" = /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/ruby
ruby --version
bundle check
if [ "${1:-}" = --preflight-only ]; then
  echo 'SUCCESS: staging preflight passed; no deployment or database backup performed'
  exit 0
fi
PHASE='temporary extraction and version check'
echo "STEP: $PHASE"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)-$$"
WORK="$(mktemp -d /tmp/ppd-staging-1.3.20-r2.XXXXXXXX)"
trap 'status=$?; if [ "$status" -ne 0 ]; then printf "FAILED: staging install stopped. Work directory: %s\nUse the supplied rollback script if code was replaced.\n" "$WORK" >&2; fi' EXIT
# Self-contained check: never resolve a helper against the caller's cwd.
CHECK="$WORK/ppd-staging-check.rb"
cat > "$CHECK" <<'PPD_RUBY'
# Run only through the matching staging shell scripts, inside the Rails runner.
require 'json'
require 'digest'

root = '/home/gcrbgcaa/redminestaging'
abort 'Wrong Rails root/environment' unless Rails.root.realpath.to_s == root && Rails.env.production?
mode = ENV.fetch('PPD_STAGE_MODE')
abort 'Invalid mode' unless %w[before after rollback].include?(mode)
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
baseline_path = ENV.fetch('PPD_BASELINE')
abort 'Unexpected baseline path' unless baseline_path.start_with?(root + '/plugins/redmine_project_percent_done-staging-before-')
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
  abort 'Staging backup supports MySQL/MariaDB only' unless %w[mysql mysql2].include?(config[:adapter].to_s)
  dump = ENV.fetch('PPD_DUMP_BIN')
  backup = ENV.fetch('PPD_DB_BACKUP')
  abort 'Unexpected DB backup path' unless backup.start_with?(root + '/plugins/redmine_project_percent_done-staging-db-backup-')
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

# Verify every installed file against the original accepted QA manifest.
manifest = JSON.parse(File.read(Rails.root.join('plugins/redmine_project_percent_done/QA_MANIFEST.json')))
abort 'Wrong QA source commit' unless manifest['source_commit'] == 'f763c1723d9e586261c5beff9bbd19f1e7270b80'
abort 'Wrong QA ref' unless manifest['source_ref'] == 'qa-v1.3.20-r2'
manifest.fetch('files').each do |name, expected|
  abort 'Unexpected manifest path' unless name.start_with?('redmine_project_percent_done/') && !name.split('/').include?('..')
  path = Rails.root.join('plugins', name)
  abort "Installed checksum mismatch: #{name}" unless Digest::SHA256.file(path).hexdigest.upcase == expected
end

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
PPD_RUBY
unzip -q "$ZIP" -d "$WORK/extract"
test -f "$WORK/extract/$PLUGIN/init.rb"
grep -Fq "PLUGIN_VERSION = '1.3.20'" "$WORK/extract/$PLUGIN/lib/project_percent_done.rb"
grep -Fq "ALGORITHM_VERSION = '1.2'" "$WORK/extract/$PLUGIN/lib/project_percent_done.rb"

BACKUP="$ROOT/plugins/${PLUGIN}-staging-backup-$STAMP.tar.gz"
ASSET_BACKUP="$ROOT/plugins/${PLUGIN}-staging-assets-backup-$STAMP.tar.gz"
DB_BACKUP="$ROOT/plugins/${PLUGIN}-staging-db-backup-$STAMP.sql"
BASELINE="$ROOT/plugins/${PLUGIN}-staging-before-$STAMP.json"
BEFORE_LOG="$ROOT/plugins/${PLUGIN}-staging-before-$STAMP.log"
AFTER_LOG="$ROOT/plugins/${PLUGIN}-staging-after-$STAMP.log"
PHASE='baseline and database backup'
echo "STEP: $PHASE"
PPD_STAGE_MODE=before PPD_BASELINE="$BASELINE" PPD_DUMP_BIN="$DUMP_BIN" PPD_DB_BACKUP="$DB_BACKUP" \
  RAILS_ENV=production bundle exec rails runner "$CHECK" | tee "$BEFORE_LOG"
grep -Fq 'BEFORE_OK version=' "$BEFORE_LOG"
test -s "$BASELINE"
test -s "$DB_BACKUP"
gzip "$DB_BACKUP"
gzip -t "$DB_BACKUP.gz"
PHASE='code and asset backups'
echo "STEP: $PHASE"
tar -czf "$BACKUP" -C "$ROOT/plugins" "$PLUGIN"
tar -tzf "$BACKUP" >/dev/null
ASSET_PATHS=()
for path in "public/plugin_assets/$PLUGIN" "public/assets/plugin_assets/$PLUGIN"; do
  if [ -d "$ROOT/$path" ]; then ASSET_PATHS+=("$path"); fi
done
if [ "${#ASSET_PATHS[@]}" -gt 0 ]; then
  tar -czf "$ASSET_BACKUP" -C "$ROOT" "${ASSET_PATHS[@]}"
else
  tar -czf "$ASSET_BACKUP" -T /dev/null
fi
tar -tzf "$ASSET_BACKUP" >/dev/null
ruby -rjson -e 'puts JSON.parse(File.read(ARGV.fetch(0))).fetch("version")' "$BASELINE" > "$BACKUP.version"
printf '%s\n' "$BACKUP" > "$ROOT/plugins/${PLUGIN}-staging-last-backup.txt"
echo "Code backup: $BACKUP"
echo "Assets backup: $ASSET_BACKUP"
echo "Database backup: $DB_BACKUP.gz"
echo "Before comparison: $BASELINE"
LOG_START=0
if [ -f log/production.log ]; then LOG_START="$(wc -l < log/production.log)"; fi

PHASE='code replacement and migrations'
echo "STEP: $PHASE"
mv "$ROOT/plugins/$PLUGIN" "$WORK/previous-plugin"
mv "$WORK/extract/$PLUGIN" "$ROOT/plugins/$PLUGIN"
RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME="$PLUGIN"
PHASE='plugin asset refresh'
echo "STEP: $PHASE"
for kind in stylesheets javascripts images; do
  source_dir="$ROOT/plugins/$PLUGIN/assets/$kind"
  if [ -d "$source_dir" ]; then
    mkdir -p "$ROOT/public/plugin_assets/$PLUGIN/$kind"
    cp -a "$source_dir/." "$ROOT/public/plugin_assets/$PLUGIN/$kind/"
    fingerprint_dir="$ROOT/public/assets/plugin_assets/$PLUGIN/$kind"
    if [ -d "$fingerprint_dir" ]; then
      cp -a "$source_dir/." "$fingerprint_dir/"
      # Refresh only existing fingerprinted copies of this plugin's CSS.
      if [ "$kind" = stylesheets ]; then
        shopt -s nullglob
        for css in "$source_dir"/*.css; do
          stem="$(basename "$css" .css)"
          for compiled in "$fingerprint_dir/$stem-"*.css; do cp -a "$css" "$compiled"; done
        done
        shopt -u nullglob
      fi
    fi
  fi
done
touch "$ROOT/tmp/restart.txt"
PHASE='installed API and manifest verification'
echo "STEP: $PHASE"
PPD_STAGE_MODE=after PPD_BASELINE="$BASELINE" RAILS_ENV=production bundle exec rails runner "$CHECK" | tee "$AFTER_LOG"
grep -Fxq 'AFTER_OK version=1.3.20 algorithm=1.2 settings_preserved=true' "$AFTER_LOG"
echo 'New log error lines (review these, including unrelated-plugin errors):'
if [ -f log/production.log ]; then
  tail -n "+$((LOG_START + 1))" log/production.log | grep -iE 'Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|LoadError|SyntaxError' || true
fi
echo 'Recent code backups:'
find "$ROOT/plugins" -maxdepth 1 -type f -name "${PLUGIN}-staging-backup-*.tar.gz" -printf '%T@ %p\n' | sort -nr | head -n 5 || true
PHASE='temporary cleanup'
case "$WORK" in /tmp/ppd-staging-1.3.20-r2.*) rm -rf -- "$WORK";; *) exit 1;; esac
trap - ERR EXIT
echo 'SUCCESS: redmine_project_percent_done 1.3.20 r2 installed and API-verified on staging'
