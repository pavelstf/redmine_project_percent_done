# Staging Runbook: Project Percent Done 1.2.0

## Release State

`r18` staging candidate prepared on 2026-07-21 after adding production shadow
history visibility. It is not production-approved.

## Package

- File: `redmine_project_percent_done-1.2.0-staging-20260721-r18.zip`
- Local path: `C:\Codex Projects\Project Percent Done Plugin\redmine_project_percent_done-1.2.0-staging-20260721-r18.zip`
- Upload to: `/home/gcrbgcaa/redminestaging/plugins/redmine_project_percent_done-1.2.0-staging-20260721-r18.zip`
- Size: `213171` bytes
- SHA-256: `C16800F8B9B5193F54C158CFD64711FD4FF171312DE7F7380138E97DD65947A5`
- Required archive root: `redmine_project_percent_done/`

Upload the ZIP through cPanel/File Manager before starting. Do not upload it
inside the active plugin directory.
This runbook and the handoff document are release-only files and are not
embedded inside the ZIP, so the checksum above remains stable.

## 1. Session And Package Verification

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
set -u

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
PLUGIN_ID="redmine_project_percent_done"
ZIP_FILE="redmine_project_percent_done-1.2.0-staging-20260721-r18.zip"
EXPECTED_SHA="C16800F8B9B5193F54C158CFD64711FD4FF171312DE7F7380138E97DD65947A5"
EXPECTED_VERSION="1.2.0"
STAMP="$(date +%Y%m%d-%H%M%S)"

cd "$REDMINE_ROOT"
test -f "plugins/$ZIP_FILE"
ACTUAL_SHA="$(sha256sum "plugins/$ZIP_FILE" | awk '{print toupper($1)}')"
printf 'Expected: %s\nActual:   %s\n' "$EXPECTED_SHA" "$ACTUAL_SHA"
test "$ACTUAL_SHA" = "$EXPECTED_SHA"
ZIP_LIST="/tmp/${PLUGIN_ID}-zip-list-$STAMP.txt"
unzip -Z1 "plugins/$ZIP_FILE" > "$ZIP_LIST"
sed -n '1,20p' "$ZIP_LIST"
ARCHIVE_ROOT="$(sed -n '1p' "$ZIP_LIST" | cut -d/ -f1)"
rm -f "$ZIP_LIST"
test "$ARCHIVE_ROOT" = "$PLUGIN_ID"
```

Stop if the checksum or archive root differs.

## 2. Backups

Create both plugin and database backups before migration. Obtain the staging
database credentials from `config/database.yml`; do not paste passwords into
the shell history when avoidable.

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
set -u

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
PLUGIN_ID="redmine_project_percent_done"
STAMP="$(date +%Y%m%d-%H%M%S)"
cd "$REDMINE_ROOT"

mkdir -p "plugins/backups/$PLUGIN_ID"
if test -d "plugins/$PLUGIN_ID"; then
  tar -czf "plugins/backups/$PLUGIN_ID/${PLUGIN_ID}-pre-1.2.0-$STAMP.tar.gz" \
    -C plugins "$PLUGIN_ID"
fi

RAILS_ENV=production bundle exec rails runner '
  c = ActiveRecord::Base.connection_db_config.configuration_hash
  puts "adapter=#{c[:adapter]} database=#{c[:database]} host=#{c[:host]} user=#{c[:username]}"
'
```

For MariaDB/MySQL, run the dump with the values printed above:

```bash
clear
REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
STAMP="$(date +%Y%m%d-%H%M%S)"
cd "$REDMINE_ROOT"
mkdir -p plugins/backups/redmine_project_percent_done
mysqldump --single-transaction --routines --triggers \
  -h DB_HOST -u DB_USER -p DB_NAME \
  > "plugins/backups/redmine_project_percent_done/redmine-staging-pre-ppd-1.2.0-$STAMP.sql"
test -s "plugins/backups/redmine_project_percent_done/redmine-staging-pre-ppd-1.2.0-$STAMP.sql"
```

## 3. Extract And Swap

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
set -u

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
PLUGIN_ID="redmine_project_percent_done"
ZIP_FILE="redmine_project_percent_done-1.2.0-staging-20260721-r18.zip"
STAMP="$(date +%Y%m%d-%H%M%S)"
WORK_DIR="plugins/.${PLUGIN_ID}-install-$STAMP"
cd "$REDMINE_ROOT"

mkdir -p "$WORK_DIR"
unzip -q "plugins/$ZIP_FILE" -d "$WORK_DIR"
test -f "$WORK_DIR/$PLUGIN_ID/init.rb"
grep -F "PLUGIN_VERSION = '1.2.0'" "$WORK_DIR/$PLUGIN_ID/lib/project_percent_done.rb"

if test -d "plugins/$PLUGIN_ID"; then
  mkdir -p "plugins/backups/$PLUGIN_ID"
  mv "plugins/$PLUGIN_ID" "plugins/backups/$PLUGIN_ID/${PLUGIN_ID}.previous-$STAMP"
fi
mv "$WORK_DIR/$PLUGIN_ID" "plugins/$PLUGIN_ID"
rmdir "$WORK_DIR"
```

Keep the `.previous-*` directory under `plugins/backups/$PLUGIN_ID` until
staging acceptance and rollback expiry. Never leave a second directory with an
`init.rb` directly under `plugins/`, because Redmine would try to load it.

## 4. Migrate And Publish Assets

Migration `001` creates only plugin-owned collection run, project snapshot, and
issue snapshot tables. The history feature remains disabled by default.

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
set -u

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
PLUGIN_ID="redmine_project_percent_done"
cd "$REDMINE_ROOT"

RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME="$PLUGIN_ID"

# One-time staging correction after the earlier r7 trial run. It removes only
# non-official closed/archived operational rows for projects that have never
# had an active snapshot. Official history and active-project history remain.
RAILS_ENV=production bundle exec rails runner '
  model = ProjectPercentDoneSnapshot
  project_ids = model.operational
    .where(:project_state => %w[closed archived])
    .distinct
    .pluck(:project_id)
  removed = 0
  project_ids.each do |project_id|
    next if model.where(:project_id => project_id, :project_state => "active").exists?
    next if model.official.where(:project_id => project_id).exists?
    model.operational
      .where(:project_id => project_id, :project_state => %w[closed archived])
      .find_each do |snapshot|
        snapshot.destroy!
        removed += 1
      end
  end
  puts "removed_initial_state_only_operational_snapshots=#{removed}"
'

if test -d "plugins/$PLUGIN_ID/assets/stylesheets"; then
  mkdir -p "public/plugin_assets/$PLUGIN_ID/stylesheets"
  cp -a "plugins/$PLUGIN_ID/assets/stylesheets/." \
    "public/plugin_assets/$PLUGIN_ID/stylesheets/"
fi

touch tmp/restart.txt
```

## 5. Structural Validation

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
set -u

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
cd "$REDMINE_ROOT"

RAILS_ENV=production bundle exec rails runner '
  plugin = Redmine::Plugin.find(:redmine_project_percent_done)
  abort("version mismatch: #{plugin.version}") unless plugin.version.to_s == "1.2.0"
  required = %w[
    project_percent_done_collection_runs
    project_percent_done_snapshots
    project_percent_done_issue_snapshots
  ]
  missing = required.reject { |table| ActiveRecord::Base.connection.data_source_exists?(table) }
  abort("missing tables: #{missing.join(", ")}") if missing.any?
  puts "plugin_version=#{plugin.version}"
  puts "history_enabled=#{ProjectPercentDone::Settings.history_enabled?}"
  puts "history_visibility=#{ProjectPercentDone::Settings.history_visibility}"
  puts "tables=ok"
'

DRY_RUN=1 RAILS_ENV=production bundle exec rake redmine:project_percent_done:cleanup
tail -n 120 /home/gcrbgcaa/redminestaging/log/production.log
```

Expected initial `history_enabled=false` and `history_visibility=hidden`.
Existing live project percentage, REST, and Public API V1 behavior must remain
unchanged.

## 6. Configure And Preview

Open:

`https://www.redminestaging.gcr.bg/settings/plugin/redmine_project_percent_done`

As a system administrator:

1. Confirm the new Historical progress, display defaults, email, and diagnostic
   sections render without overlap.
2. Select the single-value or multi-value list project custom field used for project type and save.
3. Reopen settings, select one or more eligible project types, and save.
4. Select optional `date` custom fields for project start and planned end. Use
   two different fields; leaving either blank must not block collection.
5. Keep detail level at `Project aggregates only` for the first staging run,
   unless issue-detail validation is explicitly required.
6. Keep `History visibility` at `Hidden from all users` for production shadow
   validation. Switch it temporarily only when validating the project history UI.
7. Leave email disabled for the first data capture; configure and test it
   separately afterward.
8. Click **Preview scope** and confirm the project/issue estimate is plausible.
9. Enable historical collection and save.
10. Click **Create due snapshot now** once.

With hidden visibility, first confirm that one eligible project's separate
`Progress history` project tab/link and direct history URL are not available to
project users while diagnostics show snapshot activity. Then temporarily switch
visibility to `Visible according to project access` for UI validation and confirm:

- graph and table show exact weekly values;
- the live `Project Percent Done` calculation page no longer contains the history table;
- the no-official-snapshots notice is clear before the first weekly point;
- active/state/gap markers are distinct;
- promoted points show timing/deviation;
- 13/26/52/104, calendar quarter/year, and fiscal choices show exact dates;
- system admin can expand issue rows only when detail collection is enabled;
- a regular user sees aggregate history but never historical issue subjects;
- browser-local range/chart/change choices survive reload for that user.
- the table shows the observed start/end values, elapsed-plan position, reported
  hours, and first-observed marker;
- changing either configured plan date creates a change marker in the next
  snapshot without rewriting earlier snapshots;
- time reported before start or after planned end is shown as an anomaly with
  the concrete hours preserved;
- periods between an already-started project's start date and its first
  snapshot are marked `not observed`, not fabricated as zero progress;
- forecasts appear only with four consecutive active official weekly points
  and remain absent for gaps, non-positive trends, or future project starts.

## 7. Seed Protected Demo History

The task below creates synthetic history only in the dedicated private project
`ppd-history-test`. It refuses production hosts, requires the exact confirmation
token, and refuses to overwrite history that was not created by this task.

Preview the action first:

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
set -u
cd /home/gcrbgcaa/redminestaging
ACTION=preview CONFIRM=STAGING_DEMO_HISTORY RAILS_ENV=production \
  bundle exec rake redmine:project_percent_done:staging_demo
```

Create or recreate the demonstration history:

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
set -u
cd /home/gcrbgcaa/redminestaging
ACTION=seed CONFIRM=STAGING_DEMO_HISTORY RAILS_ENV=production \
  bundle exec rake redmine:project_percent_done:staging_demo
```

Open:

`https://www.redminestaging.gcr.bg/projects/ppd-history-test/percent_done/history`

The generated 16-week timeline includes active, closed, out-of-scope,
collection-disabled, and missing periods; exact percentages and changes; plan
date changes; reported-time anomalies; issue details; and enough consecutive
active points to exercise the forecast. The task recreates six meaningful
project phases with 200 estimated hours and 132 actual time-entry hours. The
latest and live calculation should both display 60%, with 100% estimate
coverage. Every active aggregate point is calculated from its issue-detail
weights instead of using an unrelated hardcoded percentage.
Snapshots produced in this dedicated private project by normal admin or cron
runs are replaced by the next seed. The task still refuses a renamed project or
any task without the `[PPD DEMO]` prefix.

Remove all synthetic history after testing while keeping the private project
and its six labelled demo issues available for another run:

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
set -u
cd /home/gcrbgcaa/redminestaging
ACTION=cleanup CONFIRM=STAGING_DEMO_HISTORY RAILS_ENV=production \
  bundle exec rake redmine:project_percent_done:staging_demo
```

## 8. Email Validation

Configure valid comma-separated staging recipients, choose TO or BCC, and click
**Send test email**. Confirm `[TEST]` (or localized equivalent), no issue
subjects, correct recipient visibility, and a diagnostics link. Then validate
the selected notification level with a controlled manual capture.

## 9. Daily Cron

Use the generated command shown in the plugin's Administration settings or the
equivalent command below. Run once per day after midnight in the server timezone;
00:05 is the recommended starting point. The collector keeps one daily
operational backup and promotes the nearest eligible capture to the Sunday
official period. It also applies issue-detail retention, so no separate cleanup
cron is needed.

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
cd /home/gcrbgcaa/redminestaging
RAILS_ENV=production bundle exec rake redmine:project_percent_done:snapshots \
  >> /home/gcrbgcaa/redminestaging/log/project_percent_done_snapshots.log 2>&1
```

cPanel schedule fields:

```text
Minute: 5
Hour: 0
Day: *
Month: *
Weekday: *
```

After the first cron execution, verify both plugin diagnostics and:

```bash
clear
tail -n 120 /home/gcrbgcaa/redminestaging/log/project_percent_done_snapshots.log
tail -n 120 /home/gcrbgcaa/redminestaging/log/production.log
```

## 10. Rollback

Disable/remove the new cron entry first. Ordinary application rollback keeps
the plugin tables so captured history is not destroyed.

```bash
clear
source /home/gcrbgcaa/rubyvenv/redminestaging/3.2/bin/activate
set -u

REDMINE_ROOT="/home/gcrbgcaa/redminestaging"
PLUGIN_ID="redmine_project_percent_done"
cd "$REDMINE_ROOT"

ls -dt "plugins/backups/$PLUGIN_ID/${PLUGIN_ID}.previous-"* | head
PREVIOUS_DIR="plugins/backups/redmine_project_percent_done/redmine_project_percent_done.previous-REPLACE_WITH_STAMP"
test -d "$PREVIOUS_DIR"

mkdir -p "plugins/backups/$PLUGIN_ID"
mv "plugins/$PLUGIN_ID" "plugins/backups/$PLUGIN_ID/${PLUGIN_ID}.failed-$(date +%Y%m%d-%H%M%S)"
mv "$PREVIOUS_DIR" "plugins/$PLUGIN_ID"

if test -d "plugins/$PLUGIN_ID/assets/stylesheets"; then
  mkdir -p "public/plugin_assets/$PLUGIN_ID/stylesheets"
  cp -a "plugins/$PLUGIN_ID/assets/stylesheets/." \
    "public/plugin_assets/$PLUGIN_ID/stylesheets/"
fi

touch tmp/restart.txt
```

Validate the restored plugin version and live percentage pages. Do not run a
down migration during ordinary rollback. Only restore the pre-deployment SQL
backup when a complete database rollback is explicitly required and accepted;
that discards all staging database changes made after the dump.

## 11. Acceptance Evidence

Record:

- deployed package SHA-256 and version;
- migration output and table check;
- settings/diagnostics screenshots;
- preview and first manual/cron run counters;
- aggregate history screenshots at desktop/mobile widths;
- regular-user issue-detail access check;
- TO/BCC test email headers and subject;
- relevant log excerpts;
- final decision: accepted, rejected, or accepted with follow-up items.
