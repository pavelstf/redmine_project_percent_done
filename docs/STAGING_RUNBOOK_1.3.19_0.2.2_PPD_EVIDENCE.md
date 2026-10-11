# Staging Runbook: PPD 1.3.19 + PPH 0.2.2 Evidence API

This runbook deploys the Project Percent Done evidence API and the Project Progress
History consumer changes to GCR staging.

## Packages

- `redmine_project_percent_done-1.3.19-staging-20261011-evidence-api.zip`
  - Size: `338725`
  - SHA-256: `E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11`
- `redmine_project_progress_history-0.2.2-staging-20261011-ppd-evidence.zip`
  - Size: `163989`
  - SHA-256: `7657E42DA5E105B52666938CCD3566A386387BA6073B88A60F16C0895CDC08A2`

Install order matters: deploy Project Percent Done first, then Project Progress
History.

## Target

- Redmine root: `/home/gcrbgcaa/redminestaging`
- Ruby venv: `/home/gcrbgcaa/rubyvenv/redminestaging/3.2`
- Upload directory: `/home/gcrbgcaa/redminestaging/plugins`

Upload both ZIP files to the upload directory before running the script.

## Install Or Update

```bash
clear
set -eo pipefail

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redminestaging/3.2"
STAMP="$(date +%Y%m%d-%H%M%S)"

PPD_PLUGIN="redmine_project_percent_done"
PPH_PLUGIN="redmine_project_progress_history"
PPD_ZIP="$REDMINE_ROOT/plugins/redmine_project_percent_done-1.3.19-staging-20261011-evidence-api.zip"
PPH_ZIP="$REDMINE_ROOT/plugins/redmine_project_progress_history-0.2.2-staging-20261011-ppd-evidence.zip"
PPD_SHA="E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11"
PPH_SHA="7657E42DA5E105B52666938CCD3566A386387BA6073B88A60F16C0895CDC08A2"

cd "$REDMINE_ROOT"
source "$VENV_PATH/bin/activate"
set -u

sha256sum -c <<EOF
$PPD_SHA  $PPD_ZIP
$PPH_SHA  $PPH_ZIP
EOF

for plugin in "$PPD_PLUGIN" "$PPH_PLUGIN"; do
  if [ -d "$REDMINE_ROOT/plugins/$plugin" ]; then
    backup="$REDMINE_ROOT/plugins/${plugin}-staging-backup-$STAMP.tar.gz"
    tar -czf "$backup" -C "$REDMINE_ROOT/plugins" "$plugin"
    printf '%s\n' "$backup" > "$REDMINE_ROOT/plugins/${plugin}-staging-last-backup.txt"
    echo "Backed up $plugin to $backup"
  fi
done

install_plugin() {
  plugin="$1"
  zip_path="$2"
  tmp_dir="/tmp/${plugin}-${STAMP}"

  rm -rf "$tmp_dir"
  mkdir -p "$tmp_dir"
  unzip -q "$zip_path" -d "$tmp_dir"
  test -f "$tmp_dir/$plugin/init.rb"

  rm -rf "$REDMINE_ROOT/plugins/$plugin"
  mv "$tmp_dir/$plugin" "$REDMINE_ROOT/plugins/$plugin"
  rm -rf "$tmp_dir"
}

install_plugin "$PPD_PLUGIN" "$PPD_ZIP"
install_plugin "$PPH_PLUGIN" "$PPH_ZIP"

bundle exec rake redmine:plugins:migrate RAILS_ENV=production

for plugin in "$PPD_PLUGIN" "$PPH_PLUGIN"; do
  asset_root="$REDMINE_ROOT/plugins/$plugin/assets"
  public_root="$REDMINE_ROOT/public/plugin_assets/$plugin"
  mkdir -p "$public_root"
  for kind in stylesheets javascripts images; do
    if [ -d "$asset_root/$kind" ]; then
      mkdir -p "$public_root/$kind"
      cp -a "$asset_root/$kind/." "$public_root/$kind/"
    fi
  done
done

touch "$REDMINE_ROOT/tmp/restart.txt"

cat > /tmp/pph_evidence_contract_check.rb <<'RUBY'
expected = {
  :ppd => '1.3.19',
  :pph => '0.2.2'
}

actual_ppd = ProjectPercentDone::PLUGIN_VERSION
actual_pph = ProjectProgressHistory::PLUGIN_VERSION
abort("Unexpected PPD version: #{actual_ppd}") unless actual_ppd == expected[:ppd]
abort("Unexpected PPH version: #{actual_pph}") unless actual_pph == expected[:pph]

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

puts "PPD evidence rows: #{ppd_hash[:issue_evidence].size}"
puts "PPH adapter evidence rows: #{pph_result.issue_evidence.size}"
puts 'Evidence API contract check passed.'
RUBY

RAILS_ENV=production bundle exec rails runner /tmp/pph_evidence_contract_check.rb

echo "Recent Redmine log errors, if any:"
tail -n 300 "$REDMINE_ROOT/log/production.log" | grep -iE "error|exception|trace" || true

echo "Recent staging backups:"
ls -1t "$REDMINE_ROOT"/plugins/*-staging-backup-*.tar.gz 2>/dev/null | head -10 || true

echo "Staging install complete: PPD 1.3.19 + PPH 0.2.2 evidence API."
```

## Optional Evidence Write Validation

Run this only if staging can safely create an operational snapshot now.

```bash
clear
set -eo pipefail

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redminestaging/3.2"

cd "$REDMINE_ROOT"
source "$VENV_PATH/bin/activate"

CONFIRM=collect ALL_PROJECTS=1 PERIOD_TYPE=daily SNAPSHOT_KIND=operational TRIGGERED_BY=manual_admin \
  bundle exec rake redmine:project_progress_history:collect_snapshots RAILS_ENV=production

cat > /tmp/pph_issue_snapshot_check.rb <<'RUBY'
snapshot = ProjectProgressHistory::Snapshot.order(:id).last
abort('No project progress snapshot found') unless snapshot

count = ProjectProgressHistory::IssueSnapshot.where(:snapshot_id => snapshot.id).count
abort("Latest snapshot #{snapshot.id} has no issue evidence rows") if count <= 0

puts "Latest snapshot: #{snapshot.id}"
puts "Issue evidence rows: #{count}"
RUBY

RAILS_ENV=production bundle exec rails runner /tmp/pph_issue_snapshot_check.rb
touch "$REDMINE_ROOT/tmp/restart.txt"

echo "Evidence write validation complete."
```

## Rollback

Rollback restores Project Progress History first, then Project Percent Done.

```bash
clear
set -eo pipefail

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redminestaging/3.2"
PPD_PLUGIN="redmine_project_percent_done"
PPH_PLUGIN="redmine_project_progress_history"

cd "$REDMINE_ROOT"
source "$VENV_PATH/bin/activate"

restore_plugin() {
  plugin="$1"
  marker="$REDMINE_ROOT/plugins/${plugin}-staging-last-backup.txt"
  test -f "$marker"
  backup="$(cat "$marker")"
  test -f "$backup"

  rm -rf "$REDMINE_ROOT/plugins/$plugin"
  tar -xzf "$backup" -C "$REDMINE_ROOT/plugins"
  test -f "$REDMINE_ROOT/plugins/$plugin/init.rb"
  echo "Restored $plugin from $backup"
}

restore_plugin "$PPH_PLUGIN"
restore_plugin "$PPD_PLUGIN"

bundle exec rake redmine:plugins:migrate RAILS_ENV=production
touch "$REDMINE_ROOT/tmp/restart.txt"

RAILS_ENV=production bundle exec rails runner "puts ProjectPercentDone::PLUGIN_VERSION; puts ProjectProgressHistory::PLUGIN_VERSION"

echo "Rollback complete."
```

## Manual Checklist

- Confirm both ZIP files are uploaded to `/home/gcrbgcaa/redminestaging/plugins`.
- Run the install script and verify SHA checks pass before files are replaced.
- Confirm the contract check prints `Evidence API contract check passed.`
- Open staging and verify project progress pages load normally.
- If snapshot collection is safe, run the optional evidence write validation.
- Keep backup paths printed by the script until staging is accepted.
