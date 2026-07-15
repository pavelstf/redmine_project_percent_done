# Staging Runbook: Project Percent Done 1.1.0

## Target

GCR Redmine staging: `https://www.redminestaging.gcr.bg`

Action: update or first install from a staging-only ZIP.

The plugin has no migrations and no plugin asset directories. The standard
plugin migration command is retained as a deployment sanity check.

## ZIP File

```text
redmine_project_percent_done-1.1.0-staging-20260701.zip
```

SHA-256:

```text
A68EE28370864D2A6AB598638BFE5E1A666DFB2605BCAB966F18738AA9571D4C
```

## Upload To

```text
/home/gcrbgcaa/redminestaging/plugins/redmine_project_percent_done-1.1.0-staging-20260701.zip
```

## Expected Version

```text
1.1.0
```

## Commands To Paste

```bash
clear
set -eo pipefail

TARGET_ENV="staging"
PLUGIN_NAME="redmine_project_percent_done"
PLUGIN_ID="redmine_project_percent_done"
ZIP_FILE="redmine_project_percent_done-1.1.0-staging-20260701.zip"
EXPECTED_VERSION="1.1.0"
EXPECTED_SHA256="A68EE28370864D2A6AB598638BFE5E1A666DFB2605BCAB966F18738AA9571D4C"

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redminestaging/3.2"
UPLOAD_DIR="$REDMINE_ROOT/plugins"
BACKUP_DIR="$REDMINE_ROOT/plugins"
STAMP="$(date +%Y%m%d-%H%M%S)"

echo "== Activating Ruby virtualenv =="
source "$VENV_PATH/bin/activate"
set -u

echo "== Checking uploaded ZIP and SHA-256 =="
test -f "$UPLOAD_DIR/$ZIP_FILE"
echo "$EXPECTED_SHA256  $UPLOAD_DIR/$ZIP_FILE" | sha256sum -c -

echo "== Verifying ZIP structure =="
ZIP_LIST="/tmp/${PLUGIN_NAME}-zip-list-${STAMP}.txt"
unzip -Z1 "$UPLOAD_DIR/$ZIP_FILE" > "$ZIP_LIST"
grep -Fxq "redmine_project_percent_done/init.rb" "$ZIP_LIST"
grep -Fxq "redmine_project_percent_done/lib/project_percent_done/public_api/v1.rb" "$ZIP_LIST"

echo "== Current installed version, if any =="
if [ -f "$REDMINE_ROOT/plugins/$PLUGIN_NAME/init.rb" ]; then
  cd "$REDMINE_ROOT"
  RAILS_ENV=production bundle exec rails runner "puts Redmine::Plugin.find(:$PLUGIN_ID).version" || true
else
  echo "Plugin is not currently installed."
fi

echo "== Creating backup if plugin exists =="
mkdir -p "$BACKUP_DIR"
if [ -d "$REDMINE_ROOT/plugins/$PLUGIN_NAME" ]; then
  tar -czf "$BACKUP_DIR/${PLUGIN_NAME}-${TARGET_ENV}-backup-${STAMP}.tar.gz" -C "$REDMINE_ROOT/plugins" "$PLUGIN_NAME"
  echo "Backup: $BACKUP_DIR/${PLUGIN_NAME}-${TARGET_ENV}-backup-${STAMP}.tar.gz"
fi

echo "== Extracting ZIP to temporary directory =="
TMP_DIR="/tmp/${PLUGIN_NAME}-${STAMP}"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
unzip -q "$UPLOAD_DIR/$ZIP_FILE" -d "$TMP_DIR"
test -f "$TMP_DIR/$PLUGIN_NAME/init.rb"
test -f "$TMP_DIR/$PLUGIN_NAME/lib/project_percent_done/public_api/v1.rb"

echo "== Installing plugin =="
rm -rf "$REDMINE_ROOT/plugins/$PLUGIN_NAME"
cp -a "$TMP_DIR/$PLUGIN_NAME" "$REDMINE_ROOT/plugins/$PLUGIN_NAME"

echo "== Running standard plugin migration check =="
cd "$REDMINE_ROOT"
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

echo "== Restarting Redmine via Passenger =="
touch tmp/restart.txt

echo "== Verifying installed version =="
INSTALLED_VERSION="$(RAILS_ENV=production bundle exec rails runner "print Redmine::Plugin.find(:$PLUGIN_ID).version")"
test "$INSTALLED_VERSION" = "$EXPECTED_VERSION"
echo "Installed version: $INSTALLED_VERSION"

echo "== Running Public API provider checks =="
RAILS_ENV=production bundle exec rails runner 'api = ProjectPercentDone::PublicApi::V1; capabilities = api.capabilities; abort "wrong contract" unless capabilities.contract_name == "project_percent_done" && capabilities.contract_version == "1.0"; abort "wrong plugin version" unless capabilities.plugin_version == "1.1.0"; abort "wrong algorithm version" unless capabilities.algorithm_version == "1.0"; project = Project.order(:id).first or abort "no staging project available"; started = Process.clock_gettime(Process::CLOCK_MONOTONIC); result = api.calculate(:project => project); elapsed_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000.0; abort "issue details exposed" if result.to_h.keys.any? { |key| key.to_s.include?("issue_id") }; puts capabilities.to_h.inspect; puts result.to_h.inspect; puts format("project_id=%d elapsed_ms=%.2f", project.id, elapsed_ms)'

echo "== Recent error check =="
grep -n -E "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" log/production.log | tail -n 80 || true

echo "== Cleanup temporary extraction =="
rm -rf "$TMP_DIR"
rm -f "$ZIP_LIST"
```

## Rollback Commands

Replace `<backup-file-name>` with the backup filename printed by the install
block.

```bash
clear
set -eo pipefail

TARGET_ENV="staging"
PLUGIN_NAME="redmine_project_percent_done"
PLUGIN_ID="redmine_project_percent_done"

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redminestaging/3.2"
BACKUP_FILE="$REDMINE_ROOT/plugins/<backup-file-name>.tar.gz"

echo "== Activating Ruby virtualenv =="
source "$VENV_PATH/bin/activate"
set -u

echo "== Checking backup file =="
test -f "$BACKUP_FILE"

echo "== Restoring plugin from backup =="
cd "$REDMINE_ROOT"
rm -rf "plugins/$PLUGIN_NAME"
tar -xzf "$BACKUP_FILE" -C plugins
test -f "plugins/$PLUGIN_NAME/init.rb"

echo "== Running plugin migrations after rollback =="
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

echo "== Restarting Redmine via Passenger =="
touch tmp/restart.txt

echo "== Verifying restored version =="
RAILS_ENV=production bundle exec rails runner "puts Redmine::Plugin.find(:$PLUGIN_ID).version"

echo "== Recent error check =="
grep -n -E "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" log/production.log | tail -n 80 || true
```

## Manual Validation Checklist

- Confirm Administration → Plugins reports version `1.1.0`.
- Confirm project overview, sidebar, and details values are unchanged for the
  same project and settings.
- If REST is enabled, confirm its field set and display percentage are
  unchanged.
- Compare UI, REST, Public API display value, and Public API raw value for
  projects with complete, 80–99%, 50–79%, below-50%, and zero estimate
  coverage.
- Include projects with parent/subtask structures, closed issues with
  incomplete recorded done ratio, status-derived done ratio, and many issues.
- Record eligible/estimated/unestimated counts, known/imputed/total weight,
  warnings, and elapsed time for every representative project.
- Confirm ignored unestimated issues remain in eligible coverage counts.
- Confirm `equal_weight_all` reports `hours_weighted == false` and
  `known_weight_percent == nil`.
- Confirm the browser and REST permissions behave exactly as before.
- Review `/home/gcrbgcaa/redminestaging/log/production.log` after each check.
- Do not promote these ZIP bytes to production until the acceptance matrix is
  complete and explicitly approved.
