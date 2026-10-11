# Production Runbook: PPD 1.3.19 + PPH 0.2.2 Evidence API

Deploy the staging-approved Project Percent Done evidence API and Project
Progress History consumer changes to GCR production.

## Packages

- `redmine_project_percent_done-1.3.19-production-20261011-evidence-api.zip`
  - Size: `338725`
  - SHA-256: `E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11`
  - Byte-for-byte copy of the staging-approved ZIP.
- `redmine_project_progress_history-0.2.2-production-20261011-ppd-evidence.zip`
  - Size: `163989`
  - SHA-256: `7657E42DA5E105B52666938CCD3566A386387BA6073B88A60F16C0895CDC08A2`
  - Byte-for-byte copy of the staging-approved ZIP.

Install order matters: deploy Project Percent Done first, then Project Progress
History.

## Target

- Redmine root: `/home/gcrbgcaa/redmine`
- Ruby venv: `/home/gcrbgcaa/rubyvenv/redmine612build/3.2`
- Upload directory: `/home/gcrbgcaa/redmine/plugins`
- Production URL: `https://redmine.gcr.bg`

Upload both ZIP files to `/home/gcrbgcaa/redmine/plugins` before running the
install/update script.

## Install Or Update

```bash
clear
set -eo pipefail

TARGET_ENV="production"
REDMINE_ROOT="/home/gcrbgcaa/redmine"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redmine612build/3.2"
STAMP="$(date +%Y%m%d-%H%M%S)"

PPD_PLUGIN="redmine_project_percent_done"
PPH_PLUGIN="redmine_project_progress_history"
PPD_ID="redmine_project_percent_done"
PPH_ID="redmine_project_progress_history"
PPD_VERSION="1.3.19"
PPH_VERSION="0.2.2"
PPD_ZIP="$REDMINE_ROOT/plugins/redmine_project_percent_done-1.3.19-production-20261011-evidence-api.zip"
PPH_ZIP="$REDMINE_ROOT/plugins/redmine_project_progress_history-0.2.2-production-20261011-ppd-evidence.zip"
PPD_SHA="E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11"
PPH_SHA="7657E42DA5E105B52666938CCD3566A386387BA6073B88A60F16C0895CDC08A2"

cd "$REDMINE_ROOT"
source "$VENV_PATH/bin/activate"
set -u

echo "== Check uploaded ZIP files =="
test -f "$PPD_ZIP"
test -f "$PPH_ZIP"
sha256sum -c <<EOF
$PPD_SHA  $PPD_ZIP
$PPH_SHA  $PPH_ZIP
EOF

echo "== Current installed versions, if any =="
for plugin in "$PPD_PLUGIN" "$PPH_PLUGIN"; do
  if [ -f "$REDMINE_ROOT/plugins/$plugin/init.rb" ]; then
    echo "$plugin:"
    grep -n "version" "$REDMINE_ROOT/plugins/$plugin/init.rb" || true
  else
    echo "$plugin is not currently installed."
  fi
done

echo "== Backup current plugin folders =="
for plugin in "$PPD_PLUGIN" "$PPH_PLUGIN"; do
  if [ -d "$REDMINE_ROOT/plugins/$plugin" ]; then
    backup="$REDMINE_ROOT/plugins/${plugin}-${TARGET_ENV}-backup-$STAMP.tar.gz"
    tar -czf "$backup" -C "$REDMINE_ROOT/plugins" "$plugin"
    printf '%s\n' "$backup" > "$REDMINE_ROOT/plugins/${plugin}-${TARGET_ENV}-last-backup.txt"
    echo "Backup for $plugin: $backup"
  fi
done

install_plugin() {
  plugin="$1"
  zip_path="$2"
  tmp_dir="/tmp/${plugin}-${TARGET_ENV}-${STAMP}"

  echo "== Install $plugin =="
  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"
  unzip -q "$zip_path" -d "$tmp_dir"

  if [ ! -f "$tmp_dir/$plugin/init.rb" ]; then
    echo "ERROR: Expected $plugin/init.rb inside $zip_path"
    find "$tmp_dir" -maxdepth 3 -type d
    exit 1
  fi

  rm -rf "$REDMINE_ROOT/plugins/$plugin"
  cp -a "$tmp_dir/$plugin" "$REDMINE_ROOT/plugins/$plugin"
  rm -rf "$tmp_dir"
}

install_plugin "$PPD_PLUGIN" "$PPD_ZIP"
install_plugin "$PPH_PLUGIN" "$PPH_ZIP"

echo "== Run migrations =="
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

echo "== Copy plugin assets =="
for plugin in "$PPD_PLUGIN" "$PPH_PLUGIN"; do
  asset_root="$REDMINE_ROOT/plugins/$plugin/assets"

  for public_root in "$REDMINE_ROOT/public/plugin_assets/$plugin" "$REDMINE_ROOT/public/assets/plugin_assets/$plugin"; do
    mkdir -p "$public_root"
    for kind in stylesheets javascripts images; do
      if [ -d "$asset_root/$kind" ]; then
        mkdir -p "$public_root/$kind"
        cp -a "$asset_root/$kind/." "$public_root/$kind/"
      fi
    done
  done
done

echo "== Restart Redmine =="
touch "$REDMINE_ROOT/tmp/restart.txt"

echo "== Contract validation =="
cat > /tmp/pph_production_evidence_contract_check.rb <<'RUBY'
expected = {
  :ppd => '1.3.19',
  :pph => '0.2.2'
}

ppd_plugin = begin Redmine::Plugin.find(:redmine_project_percent_done) rescue nil end
pph_plugin = begin Redmine::Plugin.find(:redmine_project_progress_history) rescue nil end
abort('PPD plugin is not registered') unless ppd_plugin
abort('PPH plugin is not registered') unless pph_plugin

actual_ppd = ppd_plugin.version.to_s
actual_pph = pph_plugin.version.to_s
abort("Unexpected PPD registry version: #{actual_ppd}") unless actual_ppd == expected[:ppd]
abort("Unexpected PPH registry version: #{actual_pph}") unless actual_pph == expected[:pph]

actual_ppd_constant = ProjectPercentDone::PLUGIN_VERSION
actual_pph_constant = ProjectProgressHistory::PLUGIN_VERSION
abort("Unexpected PPD constant version: #{actual_ppd_constant}") unless actual_ppd_constant == expected[:ppd]
abort("Unexpected PPH constant version: #{actual_pph_constant}") unless actual_pph_constant == expected[:pph]

unless ActiveRecord::Base.connection.table_exists?(:project_progress_history_issue_snapshots)
  abort('Missing project_progress_history_issue_snapshots table')
end

project = Project.active.first || Project.first
abort('No project available for contract check') unless project

ppd_result = ProjectPercentDone::PublicApi::V1.calculate(
  :project => project,
  :include_evidence => true
)
ppd_hash = ppd_result.to_h
abort('Missing evidence schema version') unless ppd_hash.dig(:provider_metadata, :evidence_schema_version) == '1.0'
abort('Missing issue_evidence array') unless ppd_hash[:issue_evidence].is_a?(Array)

adapter = ProjectProgressHistory::Providers::ProjectPercentDoneAdapter.new
pph_result = adapter.current_progress(:project => project)
abort('PPH adapter did not expose issue_evidence') unless pph_result.issue_evidence.is_a?(Array)

puts "PPD version: #{actual_ppd}"
puts "PPH version: #{actual_pph}"
puts "Project checked: #{project.id} - #{project.name}"
puts "PPD evidence rows: #{ppd_hash[:issue_evidence].size}"
puts "PPH adapter evidence rows: #{pph_result.issue_evidence.size}"
puts 'Evidence API contract check passed.'
RUBY

RAILS_ENV=production bundle exec rails runner /tmp/pph_production_evidence_contract_check.rb

echo "== Recent error check =="
grep -n -E "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError|redmine_project_percent_done|redmine_project_progress_history" "$REDMINE_ROOT/log/production.log" | tail -n 160 || true

echo "== Recent production backups =="
ls -1t "$REDMINE_ROOT"/plugins/*-${TARGET_ENV}-backup-*.tar.gz 2>/dev/null | head -10 || true

echo "SUCCESS: PPD $PPD_VERSION and PPH $PPH_VERSION installed on $TARGET_ENV"
```

## Optional Evidence Write Validation

Run this only if production may safely create operational daily snapshots and
send notifications now.

```bash
clear
set -eo pipefail

REDMINE_ROOT="/home/gcrbgcaa/redmine"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redmine612build/3.2"

cd "$REDMINE_ROOT"
source "$VENV_PATH/bin/activate"
set -u

CONFIRM=collect ALL_PROJECTS=1 PERIOD_TYPE=daily SNAPSHOT_KIND=operational TRIGGERED_BY=manual_admin \
  bundle exec rake redmine:project_progress_history:collect_snapshots RAILS_ENV=production

cat > /tmp/pph_production_latest_evidence_check.rb <<'RUBY'
require 'json'

snapshots = ProjectProgressHistory::Snapshot.order(:id).last(10)
abort('No PPH snapshots found') if snapshots.empty?

puts 'Latest snapshots:'
snapshots.each do |snapshot|
  metadata = JSON.parse(snapshot.provider_metadata_json.presence || '{}') rescue {}
  issue_count = ProjectProgressHistory::IssueSnapshot.where(:snapshot_id => snapshot.id).count

  puts [
    "snapshot_id=#{snapshot.id}",
    "project_id=#{snapshot.project_id}",
    "period=#{snapshot.period_type}",
    "period_end=#{snapshot.period_end}",
    "kind=#{snapshot.snapshot_kind}",
    "source_version=#{metadata['source_plugin_version'] || metadata[:source_plugin_version]}",
    "evidence_schema=#{metadata['evidence_schema_version'] || metadata[:evidence_schema_version]}",
    "issue_rows=#{issue_count}"
  ].join(' ')
end

latest_with_evidence = snapshots.reverse.find do |snapshot|
  metadata = JSON.parse(snapshot.provider_metadata_json.presence || '{}') rescue {}
  issue_count = ProjectProgressHistory::IssueSnapshot.where(:snapshot_id => snapshot.id).count

  (metadata['source_plugin_version'] == '1.3.19' || metadata[:source_plugin_version] == '1.3.19') &&
    (metadata['evidence_schema_version'] == '1.0' || metadata[:evidence_schema_version] == '1.0') &&
    issue_count.positive?
end

abort('No recent snapshot found with PPD 1.3.19, evidence_schema_version 1.0 and issue evidence rows') unless latest_with_evidence

puts
puts "Evidence persistence verified on snapshot #{latest_with_evidence.id}."
RUBY

RAILS_ENV=production bundle exec rails runner /tmp/pph_production_latest_evidence_check.rb
touch "$REDMINE_ROOT/tmp/restart.txt"

echo "SUCCESS: Production evidence write validation complete."
```

## Rollback

Rollback restores Project Progress History first, then Project Percent Done.
It preserves database tables and settings; it does not run destructive database
rollback.

```bash
clear
set -eo pipefail

TARGET_ENV="production"
REDMINE_ROOT="/home/gcrbgcaa/redmine"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redmine612build/3.2"
PPD_PLUGIN="redmine_project_percent_done"
PPH_PLUGIN="redmine_project_progress_history"

cd "$REDMINE_ROOT"
source "$VENV_PATH/bin/activate"
set -u

restore_plugin() {
  plugin="$1"
  marker="$REDMINE_ROOT/plugins/${plugin}-${TARGET_ENV}-last-backup.txt"
  test -f "$marker"
  backup="$(cat "$marker")"
  echo "Restoring $plugin from $backup"
  test -f "$backup"

  rm -rf "$REDMINE_ROOT/plugins/$plugin"
  tar -xzf "$backup" -C "$REDMINE_ROOT/plugins"
  test -f "$REDMINE_ROOT/plugins/$plugin/init.rb"
}

restore_plugin "$PPH_PLUGIN"
restore_plugin "$PPD_PLUGIN"

bundle exec rake redmine:plugins:migrate RAILS_ENV=production
touch "$REDMINE_ROOT/tmp/restart.txt"

cat > /tmp/pph_production_rollback_version_check.rb <<'RUBY'
ppd_plugin = begin Redmine::Plugin.find(:redmine_project_percent_done) rescue nil end
pph_plugin = begin Redmine::Plugin.find(:redmine_project_progress_history) rescue nil end
abort('PPD plugin is not registered after rollback') unless ppd_plugin
abort('PPH plugin is not registered after rollback') unless pph_plugin
puts "PPD registry version after rollback: #{ppd_plugin.version}"
puts "PPH registry version after rollback: #{pph_plugin.version}"
RUBY

RAILS_ENV=production bundle exec rails runner /tmp/pph_production_rollback_version_check.rb

grep -n -E "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError|redmine_project_percent_done|redmine_project_progress_history" "$REDMINE_ROOT/log/production.log" | tail -n 160 || true

echo "SUCCESS: PPD and PPH rollback restored on production"
```

## Manual Validation Checklist

- Confirm both ZIP files are uploaded to `/home/gcrbgcaa/redmine/plugins`.
- Run the install/update script and verify both SHA checks print `OK`.
- Confirm the script ends with
  `SUCCESS: PPD 1.3.19 and PPH 0.2.2 installed on production`.
- Open `https://redmine.gcr.bg` and verify project progress pages load.
- Verify Project Progress History pages and plugin settings load.
- Run the optional evidence write validation only if production snapshot
  collection and email notifications are acceptable at that moment.
- Keep the printed production backup paths until production is accepted.
