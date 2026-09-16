# Staging Runbook: Project Percent Done 1.3.0

## Release State

Staging candidate prepared on 2026-08-12. Version `1.3.0` adds monthly official
historical snapshots and an in-process historical Public API.

## Package

- File: `redmine_project_percent_done-1.3.0-staging-20260812.zip`
- Local path: `C:\Codex Projects\Project Percent Done Plugin\redmine_project_percent_done-1.3.0-staging-20260812.zip`
- Upload to: `/home/gcrbgcaa/redminestaging/plugins/redmine_project_percent_done-1.3.0-staging-20260812.zip`
- Size: `222565` bytes
- SHA-256: `10F17EF999908378B030FF8C2F9EB905384546B0C71708D32F0CCDE058006F74`
- Required archive root: `redmine_project_percent_done/`

Upload the ZIP through cPanel/File Manager before starting. Do not upload it
inside the active plugin directory.

## 1. Install Or Update

```bash
clear
set -eo pipefail

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redminestaging/3.2"
PLUGIN_ID="redmine_project_percent_done"
ZIP_FILE="redmine_project_percent_done-1.3.0-staging-20260812.zip"
EXPECTED_SHA="10F17EF999908378B030FF8C2F9EB905384546B0C71708D32F0CCDE058006F74"
EXPECTED_VERSION="1.3.0"
STAMP="$(date +%Y%m%d-%H%M%S)"

ZIP_PATH="$REDMINE_ROOT/plugins/$ZIP_FILE"
WORK_DIR="$REDMINE_ROOT/plugins/.${PLUGIN_ID}-install-$STAMP"
BACKUP_DIR="$REDMINE_ROOT/plugins/backups/$PLUGIN_ID"
PREVIOUS_DIR="$BACKUP_DIR/${PLUGIN_ID}.previous-$STAMP"
ARCHIVE_BACKUP="$BACKUP_DIR/${PLUGIN_ID}-pre-1.3.0-$STAMP.tar.gz"
ZIP_LIST="/tmp/${PLUGIN_ID}-zip-list-$STAMP.txt"

cleanup() {
  rm -f "$ZIP_LIST"
  if test -d "$WORK_DIR"; then
    rm -rf "$WORK_DIR"
  fi
}
trap cleanup EXIT

echo "== Activating staging Ruby environment =="
source "$VENV_PATH/bin/activate"
set -u
cd "$REDMINE_ROOT"

echo "== Verifying package =="
test -f "$ZIP_PATH"
ACTUAL_SHA="$(sha256sum "$ZIP_PATH" | awk '{print toupper($1)}')"
printf 'Expected SHA: %s\nActual SHA:   %s\n' "$EXPECTED_SHA" "$ACTUAL_SHA"
test "$ACTUAL_SHA" = "$EXPECTED_SHA"

unzip -Z1 "$ZIP_PATH" > "$ZIP_LIST"
ARCHIVE_ROOT="$(head -1 "$ZIP_LIST" | cut -d/ -f1)"
printf 'Archive root: %s\n' "$ARCHIVE_ROOT"
test "$ARCHIVE_ROOT" = "$PLUGIN_ID"

echo "== Extracting package =="
mkdir -p "$WORK_DIR"
unzip -q "$ZIP_PATH" -d "$WORK_DIR"
test -f "$WORK_DIR/$PLUGIN_ID/init.rb"
grep -F "PLUGIN_VERSION = '$EXPECTED_VERSION'" \
  "$WORK_DIR/$PLUGIN_ID/lib/project_percent_done.rb"

echo "== Creating plugin backup =="
mkdir -p "$BACKUP_DIR"
if test -d "plugins/$PLUGIN_ID"; then
  tar -czf "$ARCHIVE_BACKUP" -C plugins "$PLUGIN_ID"
  test -s "$ARCHIVE_BACKUP"
  echo "Archive backup: $ARCHIVE_BACKUP"
  mv "plugins/$PLUGIN_ID" "$PREVIOUS_DIR"
  echo "Rollback directory: $PREVIOUS_DIR"
else
  echo "No existing plugin directory; treating as first installation."
fi

echo "== Installing plugin code =="
mv "$WORK_DIR/$PLUGIN_ID" "plugins/$PLUGIN_ID"
rmdir "$WORK_DIR"

echo "== Running plugin migrations =="
RAILS_ENV=production bundle exec rake \
  redmine:plugins:migrate NAME="$PLUGIN_ID"

echo "== Publishing stylesheets =="
if test -d "plugins/$PLUGIN_ID/assets/stylesheets"; then
  mkdir -p "public/plugin_assets/$PLUGIN_ID/stylesheets"
  cp -a "plugins/$PLUGIN_ID/assets/stylesheets/." \
    "public/plugin_assets/$PLUGIN_ID/stylesheets/"
fi

echo "== Restarting Passenger =="
touch tmp/restart.txt

echo "== Validating plugin, schema, and APIs =="
RAILS_ENV=production bundle exec rails runner '
  plugin = Redmine::Plugin.find(:redmine_project_percent_done)
  abort("version mismatch: #{plugin.version}") unless plugin.version.to_s == "1.3.0"

  connection = ActiveRecord::Base.connection
  required_tables = %w[
    project_percent_done_collection_runs
    project_percent_done_snapshots
    project_percent_done_issue_snapshots
  ]
  missing_tables = required_tables.reject { |table| connection.data_source_exists?(table) }
  abort("missing tables: #{missing_tables.join(", ")}") if missing_tables.any?

  columns = connection.columns(:project_percent_done_snapshots).map(&:name)
  abort("missing period_type") unless columns.include?("period_type")

  api = ProjectPercentDone::PublicApi::V1
  live = api.capabilities
  history = api.history_capabilities
  abort("wrong live contract") unless live.contract_version.to_s == "1.0"
  abort("history unsupported") unless history.history_supported
  abort("monthly unsupported") unless history.supported_period_types.include?(:monthly)

  project = Project.active.first
  if project
    result = api.progress_at(:project => project, :date => Date.today)
    abort("expected incomplete current month") unless result.unavailable_reason == :period_not_completed
  end

  puts "plugin_version=#{plugin.version}"
  puts "history_enabled=#{ProjectPercentDone::Settings.history_enabled?}"
  puts "history_visibility=#{ProjectPercentDone::Settings.history_visibility}"
  puts "live_public_api=#{live.contract_version}"
  puts "history_public_api=#{history.history_contract_version}"
  puts "period_type_column=ok"
'

echo "== Running cleanup dry-run =="
DRY_RUN=1 RAILS_ENV=production bundle exec rake \
  redmine:project_percent_done:cleanup

echo "== Recent errors =="
grep -n -E \
  "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" \
  log/production.log | tail -n 80 || true

echo "== Recent plugin backups =="
ls -lt "$BACKUP_DIR" | head -20

echo "INSTALLATION COMPLETED SUCCESSFULLY"
echo "Settings:"
echo "https://www.redminestaging.gcr.bg/settings/plugin/redmine_project_percent_done"
```

## 2. Manual Staging Checks

- Open Administration -> Plugins and confirm version `1.3.0`.
- Open plugin settings and confirm historical collection settings are preserved.
- Confirm existing weekly project history still renders and does not show
  monthly rows.
- Run a manual snapshot from the diagnostic block if desired; the run should
  still send digest email according to the configured notification settings.
- Use Rails runner to inspect monthly API behavior after at least one completed
  monthly snapshot exists.

## 3. Rollback Code Only

Use the `Rollback directory` printed by the install script.

```bash
clear
set -eo pipefail

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redminestaging/3.2"
PLUGIN_ID="redmine_project_percent_done"
ROLLBACK_DIR="/home/gcrbgcaa/redminestaging/plugins/backups/redmine_project_percent_done/PASTE_PREVIOUS_DIR_HERE"
STAMP="$(date +%Y%m%d-%H%M%S)"

source "$VENV_PATH/bin/activate"
set -u
cd "$REDMINE_ROOT"

test -d "$ROLLBACK_DIR"
test -f "$ROLLBACK_DIR/init.rb"

if test -d "plugins/$PLUGIN_ID"; then
  mv "plugins/$PLUGIN_ID" "plugins/backups/$PLUGIN_ID/${PLUGIN_ID}.failed-1.3.0-$STAMP"
fi
mv "$ROLLBACK_DIR" "plugins/$PLUGIN_ID"
touch tmp/restart.txt

RAILS_ENV=production bundle exec rails runner \
  "puts Redmine::Plugin.find(:redmine_project_percent_done).version"

grep -n -E \
  "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" \
  log/production.log | tail -n 80 || true
```

Rollback restores the previous code only. It intentionally keeps the plugin
history tables and the new `period_type` column unless a separate database
restore is explicitly chosen.
