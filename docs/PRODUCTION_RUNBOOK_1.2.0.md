# Production Runbook: Project Percent Done 1.2.0

Date prepared: 2026-07-21

Production status: confirmed OK by the user on 2026-07-21.

Target: GCR Redmine production (`https://redmine.gcr.bg`)

Action: update from uploaded ZIP

Version `1.2.0` is installed and working on GCR production. Historical
collection, automatic cron collection, and digest email are configured.
Project history visibility is currently limited to Redmine system
administrators.

## ZIP File

Upload this ZIP file:

```text
redmine_project_percent_done-1.2.0-production-20260721.zip
```

Upload it to:

```text
/home/gcrbgcaa/redmine/plugins/redmine_project_percent_done-1.2.0-production-20260721.zip
```

Expected SHA-256:

```text
C16800F8B9B5193F54C158CFD64711FD4FF171312DE7F7380138E97DD65947A5
```

Size: `213171` bytes

Archive root: `redmine_project_percent_done/`

## Promotion Basis

The production package is a byte-for-byte copy of the staging-approved package:

```text
redmine_project_percent_done-1.2.0-staging-20260721-r18.zip
```

Both files have the same SHA-256:

```text
C16800F8B9B5193F54C158CFD64711FD4FF171312DE7F7380138E97DD65947A5
```

## Discovery Notes

- Plugin folder: `redmine_project_percent_done`
- Redmine plugin id: `redmine_project_percent_done`
- Version: `1.2.0`
- Database migrations: migration `001`, three plugin-owned history tables
- Assets: `assets/stylesheets/project_percent_done.css`
- Production Redmine root: `/home/gcrbgcaa/redmine`
- Production Ruby virtualenv: `/home/gcrbgcaa/rubyvenv/redmine612build/3.2`

## Current Production Configuration

- Historical collection: configured by the administrator.
- Cron: configured for automatic data collection.
- Digest email: configured by the administrator.
- History visibility: administrators only.
- CSV and history REST API: deferred.

## Validation Commands

Use this block if production needs to be checked again after deployment:

```bash
clear
set -Ee -o pipefail
trap 'rc=$?; echo "ERROR at line $LINENO (exit $rc)"; exit $rc' ERR

REDMINE_ROOT="/home/gcrbgcaa/redmine"
VENV_PATH="/home/gcrbgcaa/rubyvenv/redmine612build/3.2"
PLUGIN_ID="redmine_project_percent_done"
EXPECTED_VERSION="1.2.0"

echo "== Activating production Ruby environment =="
source "$VENV_PATH/bin/activate"
set -u
cd "$REDMINE_ROOT"

echo "== Validating plugin =="
RAILS_ENV=production bundle exec rails runner '
  plugin = Redmine::Plugin.find(:redmine_project_percent_done)
  abort("version mismatch: #{plugin.version}") unless plugin.version.to_s == "1.2.0"

  required_tables = %w[
    project_percent_done_collection_runs
    project_percent_done_snapshots
    project_percent_done_issue_snapshots
  ]

  missing = required_tables.reject { |table| ActiveRecord::Base.connection.data_source_exists?(table) }
  abort("missing tables: #{missing.join(", ")}") if missing.any?

  puts "plugin_version=#{plugin.version}"
  puts "history_enabled=#{ProjectPercentDone::Settings.history_enabled?}"
  puts "history_visibility=#{ProjectPercentDone::Settings.history_visibility}"
  puts "history_email_enabled=#{ProjectPercentDone::Settings.history_email_enabled?}"
  puts "tables=ok"
'

echo "== Recent collection runs =="
RAILS_ENV=production bundle exec rails runner '
  ProjectPercentDoneCollectionRun.order(:started_at => :desc).limit(5).each do |run|
    puts [
      "id=#{run.id}",
      "source=#{run.source}",
      "status=#{run.status}",
      "snapshot_type=#{run.snapshot_type}",
      "started_at=#{run.started_at}",
      "processed=#{run.projects_processed}",
      "succeeded=#{run.projects_succeeded}",
      "created=#{run.snapshots_created}",
      "promoted=#{run.snapshots_promoted}",
      "email_status=#{run.email_status}"
    ].join(" ")
  end
'

echo "== Recent errors =="
grep -n -E "Completed 500|FATAL|ERROR|Exception|NoMethodError|NameError|ActionView|LoadError|SyntaxError" \
  log/production.log | tail -n 80 || true
```

## Rollback Notes

Ordinary rollback restores the previous plugin directory but keeps plugin
history tables and captured data. Destructive database rollback requires a
separate production database backup and should not be done merely to revert
code.

The installation script printed the backup directory and archive path, usually:

```text
/home/gcrbgcaa/redmine/plugins/backups/redmine_project_percent_done/
```

Use the exact backup path printed during installation.

