# Production Runbook: Project Percent Done 1.1.1

Date prepared: 2026-07-10

Production status: confirmed OK by the user on 2026-07-15.

Target: GCR Redmine production (`https://redmine.gcr.bg`)

Action: update from uploaded ZIP

Version `1.1.1` is installed and working as expected on both GCR staging and
GCR production.

## ZIP File

Upload this ZIP file:

```text
redmine_project_percent_done-1.1.1-production-20260710.zip
```

Upload it to:

```text
/home/gcrbgcaa/redmine/plugins/redmine_project_percent_done-1.1.1-production-20260710.zip
```

Expected SHA-256:

```text
A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388
```

## Expected Version

```text
1.1.1
```

## Promotion Basis

The Production package is a byte-for-byte copy of the staging-approved package
`redmine_project_percent_done-1.1.1-staging-20260710.zip`.

Both files have the same SHA-256:
`A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388`.

Version `1.1.1` is a UX-only patch over `1.1.0`. Public API V1, calculation
behavior, REST behavior, and the Risk Monitor integration contract are
unchanged. `ProjectPercentDone::ALGORITHM_VERSION` remains `1.0`.

Discovery notes:

- Plugin folder: `redmine_project_percent_done`
- Redmine plugin id: `redmine_project_percent_done`
- Version: `1.1.1`
- Database migrations: none
- Assets: `assets/stylesheets/project_percent_done.css`

## Commands To Paste

Run this after uploading the Production ZIP into `/home/gcrbgcaa/redmine/plugins`.

```bash
clear
set -eo pipefail

TARGET_ENV="production"
PLUGIN_NAME="redmine_project_percent_done"
PLUGIN_ID="redmine_project_percent_done"
ZIP_FILE="redmine_project_percent_done-1.1.1-production-20260710.zip"
EXPECTED_VERSION="1.1.1"
EXPECTED_SHA256="A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388"

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
grep -Fx "$PLUGIN_NAME/app/views/settings/_project_percent_done_settings.html.erb" "$ZIP_LIST"
grep -Fx "$PLUGIN_NAME/assets/stylesheets/project_percent_done.css" "$ZIP_LIST"
grep -Fx "$PLUGIN_NAME/config/locales/en.yml" "$ZIP_LIST"
grep -Fx "$PLUGIN_NAME/config/locales/bg.yml" "$ZIP_LIST"

echo "== Extracting ZIP to temporary directory =="
TMP_DIR="/tmp/${PLUGIN_NAME}-${TARGET_ENV}-${STAMP}"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
unzip -q "$UPLOAD_DIR/$ZIP_FILE" -d "$TMP_DIR"

echo "== Verifying extracted package version and help UI files =="
test -f "$TMP_DIR/$PLUGIN_NAME/init.rb"
test -f "$TMP_DIR/$PLUGIN_NAME/lib/project_percent_done.rb"
test -f "$TMP_DIR/$PLUGIN_NAME/lib/project_percent_done/public_api/v1.rb"
test -f "$TMP_DIR/$PLUGIN_NAME/assets/stylesheets/project_percent_done.css"
grep -n "version ProjectPercentDone::PLUGIN_VERSION" "$TMP_DIR/$PLUGIN_NAME/init.rb"
grep -n "PLUGIN_VERSION = '$EXPECTED_VERSION'" "$TMP_DIR/$PLUGIN_NAME/lib/project_percent_done.rb"
grep -n "ALGORITHM_VERSION = '1.0'" "$TMP_DIR/$PLUGIN_NAME/lib/project_percent_done.rb"
grep -n "ppd-setting-help" "$TMP_DIR/$PLUGIN_NAME/app/views/settings/_project_percent_done_settings.html.erb"
if grep -n "title=" "$TMP_DIR/$PLUGIN_NAME/app/views/settings/_project_percent_done_settings.html.erb"; then
  echo "ERROR: settings help UI must not use native title tooltips."
  exit 1
else
  echo "No native title tooltip in settings partial."
fi

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

echo "== Verifying copied stylesheet asset =="
test -f "public/plugin_assets/$PLUGIN_NAME/stylesheets/project_percent_done.css"

echo "== Restarting Redmine via Passenger =="
touch tmp/restart.txt

echo "== Final Rails runner verification =="
RAILS_ENV=production bundle exec rails runner '
plugin = Redmine::Plugin.find(:redmine_project_percent_done)
abort("version mismatch: #{plugin.version}") unless plugin.version.to_s == "1.1.1"
abort("ProjectPercentDone::PublicApi::V1 missing") unless defined?(ProjectPercentDone::PublicApi::V1)
abort("algorithm mismatch: #{ProjectPercentDone::ALGORITHM_VERSION}") unless ProjectPercentDone::ALGORITHM_VERSION == "1.0"
help_keys = %i[
  label_project_percent_done_setting_help
  help_project_percent_done_display_overview
  help_project_percent_done_display_sidebar
  help_project_percent_done_display_project_tab
  help_project_percent_done_enable_rest_api
  help_project_percent_done_issue_scope
  help_project_percent_done_closed_issue_mode
  help_project_percent_done_unestimated_issue_mode
  help_project_percent_done_rounding_mode
]
[:en, :bg].each do |locale|
  help_keys.each do |key|
    value = I18n.t(key, :locale => locale, :default => "")
    abort("missing #{locale}.#{key}") if value.to_s.empty?
  end
end
caps = ProjectPercentDone::PublicApi::V1.capabilities.to_h
expected = {
  :contract_name => "project_percent_done",
  :contract_version => "1.0",
  :plugin_version => "1.1.1",
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
puts "algorithm_version=#{ProjectPercentDone::ALGORITHM_VERSION}"
puts "help_keys_checked=#{help_keys.size}"
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

Run only if Production validation fails and the previous plugin directory must
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

echo "== Restoring plugin assets if present =="
if [ -d "plugins/$PLUGIN_NAME/assets/stylesheets" ]; then
  mkdir -p "public/plugin_assets/$PLUGIN_NAME/stylesheets"
  cp -a "plugins/$PLUGIN_NAME/assets/stylesheets/." "public/plugin_assets/$PLUGIN_NAME/stylesheets/"
fi

echo "== Restarting Redmine via Passenger =="
touch tmp/restart.txt

echo "== Rollback version check =="
RAILS_ENV=production bundle exec rails runner "puts Redmine::Plugin.find(:$PLUGIN_ID).version"

echo "== Recent production.log error check =="
grep -n -E "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" log/production.log | tail -n 120 || true
```

## Manual Validation Checklist

After the install block completes, return these output sections for validation:

- SHA-256 line ending in `OK`
- `Backup: ...redmine_project_percent_done-production-backup-<timestamp>.tar.gz`
- version checks:
  - `version ProjectPercentDone::PLUGIN_VERSION`
  - `PLUGIN_VERSION = '1.1.1'`
  - `ALGORITHM_VERSION = '1.0'`
- `No native title tooltip in settings partial.`
- stylesheet asset check success
- migration command output
- Rails runner output:
  - `plugin_version=1.1.1`
  - `public_api_v1=constant`
  - `algorithm_version=1.0`
  - `help_keys_checked=9`
  - `capabilities={...}`
- final `Recent production.log error check` block

Manual browser validation:

- Open Administration → Plugins → Redmine Project Percent Done → Configure.
- Confirm every setting has a compact help icon.
- Confirm hover/focus/tap shows one tooltip, not two.
- Confirm keyboard focus reaches the help icons and Escape closes the tooltip.
- Confirm the settings form layout remains compact.
