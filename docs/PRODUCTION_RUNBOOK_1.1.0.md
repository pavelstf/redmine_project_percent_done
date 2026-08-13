# Production Runbook: Project Percent Done 1.1.0

Date prepared: 2026-07-10

Target: GCR Redmine production (`https://redmine.gcr.bg`)

Package to upload:
`redmine_project_percent_done-1.1.0-production-20260710.zip`

Upload to:
`/home/gcrbgcaa/redmine/plugins/redmine_project_percent_done-1.1.0-production-20260710.zip`

Expected SHA-256:
`A68EE28370864D2A6AB598638BFE5E1A666DFB2605BCAB966F18738AA9571D4C`

Expected plugin version:
`1.1.0`

## Promotion Basis

The production package is a byte-for-byte copy of the staging-approved package
`redmine_project_percent_done-1.1.0-staging-20260701.zip`.

Both files have the same SHA-256:
`A68EE28370864D2A6AB598638BFE5E1A666DFB2605BCAB966F18738AA9571D4C`.

Staging 1.1.0 is approved in
`docs/STAGING_ACCEPTANCE_1.1.0.md`.

Risk Monitor Pro 0.2.3 production deployment depends on Project Percent Done
`>= 1.1.0` and `ProjectPercentDone::PublicApi::V1`.

Discovery notes:

- Plugin folder: `redmine_project_percent_done`
- Redmine plugin id: `redmine_project_percent_done`
- Version: `1.1.0`
- Database migrations: none in this package
- Plugin assets: none in this package; guarded asset-copy commands are kept
  in the runbook for safe shared-hosting consistency

## Commands To Paste

Run this after uploading the production ZIP into
`/home/gcrbgcaa/redmine/plugins`.

```bash
clear
set -eo pipefail

TARGET_ENV="production"
PLUGIN_NAME="redmine_project_percent_done"
PLUGIN_ID="redmine_project_percent_done"
ZIP_FILE="redmine_project_percent_done-1.1.0-production-20260710.zip"
EXPECTED_VERSION="1.1.0"
EXPECTED_SHA256="A68EE28370864D2A6AB598638BFE5E1A666DFB2605BCAB966F18738AA9571D4C"

REDMINE_ROOT="/home/gcrbgcaa/redmine"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redmine612build/3.2"
UPLOAD_DIR="$REDMINE_ROOT/plugins"
BACKUP_DIR="$REDMINE_ROOT/plugins"
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="$BACKUP_DIR/${PLUGIN_NAME}-${TARGET_ENV}-backup-${STAMP}.tar.gz"
LAST_BACKUP_FILE="$BACKUP_DIR/${PLUGIN_NAME}-${TARGET_ENV}-last-backup.txt"

echo "== Activating Ruby virtualenv =="
source "$VENV_PATH/bin/activate"
set -u

echo "== Checking uploaded ZIP and SHA-256 =="
test -f "$UPLOAD_DIR/$ZIP_FILE"
printf "%s  %s\n" "$EXPECTED_SHA256" "$UPLOAD_DIR/$ZIP_FILE" | sha256sum -c -

echo "== Current installed version, if any =="
if [ -f "$REDMINE_ROOT/plugins/$PLUGIN_NAME/init.rb" ]; then
  grep -n "version" "$REDMINE_ROOT/plugins/$PLUGIN_NAME/init.rb" || true
  grep -n "PLUGIN_VERSION" "$REDMINE_ROOT/plugins/$PLUGIN_NAME/lib/project_percent_done.rb" || true
else
  echo "Plugin is not currently installed."
fi

echo "== Verifying ZIP structure =="
ZIP_LIST="/tmp/${PLUGIN_NAME}-zip-list-${STAMP}.txt"
unzip -Z1 "$UPLOAD_DIR/$ZIP_FILE" > "$ZIP_LIST"
grep -Fx "$PLUGIN_NAME/init.rb" "$ZIP_LIST"
grep -Fx "$PLUGIN_NAME/lib/project_percent_done.rb" "$ZIP_LIST"
grep -Fx "$PLUGIN_NAME/lib/project_percent_done/public_api/v1.rb" "$ZIP_LIST"
grep -Fx "$PLUGIN_NAME/lib/project_percent_done/public_api/v1/capabilities.rb" "$ZIP_LIST"
grep -Fx "$PLUGIN_NAME/lib/project_percent_done/public_api/v1/result.rb" "$ZIP_LIST"

echo "== Extracting ZIP to temporary directory =="
TMP_DIR="/tmp/${PLUGIN_NAME}-${TARGET_ENV}-${STAMP}"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
unzip -q "$UPLOAD_DIR/$ZIP_FILE" -d "$TMP_DIR"

echo "== Verifying extracted package version and Public API files =="
test -f "$TMP_DIR/$PLUGIN_NAME/init.rb"
test -f "$TMP_DIR/$PLUGIN_NAME/lib/project_percent_done.rb"
test -f "$TMP_DIR/$PLUGIN_NAME/lib/project_percent_done/public_api/v1.rb"
grep -n "version ProjectPercentDone::PLUGIN_VERSION" "$TMP_DIR/$PLUGIN_NAME/init.rb"
grep -n "PLUGIN_VERSION = '$EXPECTED_VERSION'" "$TMP_DIR/$PLUGIN_NAME/lib/project_percent_done.rb"

echo "== Creating backup if current plugin exists =="
mkdir -p "$BACKUP_DIR"
if [ -d "$REDMINE_ROOT/plugins/$PLUGIN_NAME" ]; then
  tar -czf "$BACKUP_FILE" -C "$REDMINE_ROOT/plugins" "$PLUGIN_NAME"
  printf "%s\n" "$BACKUP_FILE" > "$LAST_BACKUP_FILE"
  echo "Backup: $BACKUP_FILE"
else
  echo "No existing plugin directory; rollback by backup will not be available."
  rm -f "$LAST_BACKUP_FILE"
fi

echo "== Replacing plugin directory =="
rm -rf "$REDMINE_ROOT/plugins/$PLUGIN_NAME"
cp -a "$TMP_DIR/$PLUGIN_NAME" "$REDMINE_ROOT/plugins/$PLUGIN_NAME"

echo "== Running plugin migrations =="
cd "$REDMINE_ROOT"
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

echo "== Copying plugin assets if present =="
if [ -d "plugins/$PLUGIN_NAME/assets/stylesheets" ]; then
  mkdir -p "public/plugin_assets/$PLUGIN_NAME/stylesheets"
  cp -a "plugins/$PLUGIN_NAME/assets/stylesheets/." "public/plugin_assets/$PLUGIN_NAME/stylesheets/"
fi

if [ -d "plugins/$PLUGIN_NAME/assets/javascripts" ]; then
  mkdir -p "public/plugin_assets/$PLUGIN_NAME/javascripts"
  cp -a "plugins/$PLUGIN_NAME/assets/javascripts/." "public/plugin_assets/$PLUGIN_NAME/javascripts/"
fi

if [ -d "plugins/$PLUGIN_NAME/assets/images" ]; then
  mkdir -p "public/plugin_assets/$PLUGIN_NAME/images"
  cp -a "plugins/$PLUGIN_NAME/assets/images/." "public/plugin_assets/$PLUGIN_NAME/images/"
fi

echo "== Restarting Redmine via Passenger =="
touch tmp/restart.txt

echo "== Final Rails runner verification =="
RAILS_ENV=production bundle exec rails runner '
plugin = Redmine::Plugin.find(:redmine_project_percent_done)
abort("version mismatch: #{plugin.version}") unless plugin.version.to_s == "1.1.0"
abort("ProjectPercentDone::PublicApi::V1 missing") unless defined?(ProjectPercentDone::PublicApi::V1)
caps = ProjectPercentDone::PublicApi::V1.capabilities.to_h
expected = {
  :contract_name => "project_percent_done",
  :contract_version => "1.0",
  :plugin_version => "1.1.0",
  :algorithm_version => "1.0",
  :calculation_mode => "live",
  :persistence_mode => "none",
  :supports_raw_percent_done => true,
  :supports_estimate_coverage => true
}
expected.each do |key, expected_value|
  actual_value = caps[key]
  abort("capability #{key} mismatch: #{actual_value.inspect}") unless actual_value == expected_value
end
puts "plugin_version=#{plugin.version}"
puts "public_api_v1=#{defined?(ProjectPercentDone::PublicApi::V1)}"
puts "capabilities=#{caps.inspect}"
'

echo "== Recent production.log tail =="
tail -n 120 log/production.log

echo "== Recent production.log error check =="
grep -n -E "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" log/production.log | tail -n 120 || true

echo "== Done =="
echo "Production package installed. If needed, rollback backup path is stored in:"
echo "$LAST_BACKUP_FILE"
```

## Rollback Commands

Run only if production validation fails and the previous plugin directory must
be restored from the backup generated by the install block.

```bash
clear
set -eo pipefail

TARGET_ENV="production"
PLUGIN_NAME="redmine_project_percent_done"
PLUGIN_ID="redmine_project_percent_done"

REDMINE_ROOT="/home/gcrbgcaa/redmine"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redmine612build/3.2"
LAST_BACKUP_FILE="$REDMINE_ROOT/plugins/${PLUGIN_NAME}-${TARGET_ENV}-last-backup.txt"

echo "== Activating Ruby virtualenv =="
source "$VENV_PATH/bin/activate"
set -u

echo "== Reading backup file generated during install =="
test -f "$LAST_BACKUP_FILE"
BACKUP_FILE="$(cat "$LAST_BACKUP_FILE")"
test -f "$BACKUP_FILE"
echo "Backup: $BACKUP_FILE"

echo "== Restoring plugin from backup =="
cd "$REDMINE_ROOT"
rm -rf "plugins/$PLUGIN_NAME"
tar -xzf "$BACKUP_FILE" -C plugins

echo "== Running plugin migrations after rollback =="
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

echo "== Restarting Redmine via Passenger =="
touch tmp/restart.txt

echo "== Rollback version check =="
RAILS_ENV=production bundle exec rails runner "puts Redmine::Plugin.find(:$PLUGIN_ID).version"

echo "== Recent production.log tail =="
tail -n 120 log/production.log

echo "== Recent production.log error check =="
grep -n -E "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" log/production.log | tail -n 120 || true
```

## Manual Validation Checklist

After the install block completes, return the following output for validation:

- SHA-256 line ending in `OK`
- `Backup: ...redmine_project_percent_done-production-backup-<timestamp>.tar.gz`
- `grep` lines showing:
  - `version ProjectPercentDone::PLUGIN_VERSION`
  - `PLUGIN_VERSION = '1.1.0'`
- migration command output
- Rails runner output:
  - `plugin_version=1.1.0`
  - `public_api_v1=constant`
  - full `capabilities={...}` hash
- the final `Recent production.log error check` block

Expected capabilities core contract:

```ruby
{
  :contract_name=>"project_percent_done",
  :contract_version=>"1.0",
  :plugin_version=>"1.1.0",
  :algorithm_version=>"1.0",
  :calculation_mode=>"live",
  :persistence_mode=>"none",
  :supports_raw_percent_done=>true,
  :supports_estimate_coverage=>true
}
```

