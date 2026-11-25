# Redmine Project Percent Done 1.3.20

QA candidate **r2 (2026-11-25)**, algorithm 1.2, public contract 1.0, evidence schema 1.0.
Requires an existing Redmine host; the validated local target is Redmine 6.1.2.
Ruby/Rails/gems follow that host. This directory is the runtime payload; source,
tests, CI and developer documentation are supplied in the separate source ZIP.

## Install into an isolated QA host

Activate the host Ruby environment first and back up the QA database. This
script refuses an existing plugin directory. For an update, stop the QA app and
move the previous plugin directory outside plugins/ before running it; keep it
and the DB backup for recovery. Never overlay old/new code.

```bash
set -euo pipefail
REDMINE_ROOT=/absolute/path/to/qa-redmine
QA_ZIP=/absolute/path/to/redmine_project_percent_done-1.3.20-install-20261125-r2.zip
cd "$REDMINE_ROOT"
test -f Gemfile
test -f config/database.yml
test ! -e plugins/redmine_project_percent_done
unzip -q "$QA_ZIP" -d plugins
bundle check
RAILS_ENV=production bundle exec rake redmine:plugins:migrate NAME=redmine_project_percent_done
mkdir -p public/plugin_assets/redmine_project_percent_done/stylesheets
cp -a plugins/redmine_project_percent_done/assets/stylesheets/. public/plugin_assets/redmine_project_percent_done/stylesheets/
mkdir -p tmp
touch tmp/restart.txt
```

Here production names the Rails environment of the isolated QA host, not a
deployment instruction for a live server. Substitute the actual host environment
if different. Restart its service if it does not use Passenger/restart.txt.
Prepare missing dependencies through the host's normal Redmine setup process.

Administration → Plugins must show version 1.3.20. Overview/sidebar default on;
the menu tab defaults off, but details HTML/CSV is accessible while any of these
three locations is enabled. REST defaults off separately.

Only direct-project global leaves contribute. A parent is excluded even if all
children belong to another project. Cross-project children are never imported.
Floor/ceil now round the exact weighted result; old snapshots are not rewritten.
Incomplete NULL hierarchy bounds are safely excluded, without repairing source data.

The separate Project Progress History plugin is optional. When it owns history,
PPD's legacy history UI/collector/email/actions remain guarded. Do not configure
competing PPD/PPH collectors. In-process evidence may contain private/contact
data; consumers must enforce authorization before showing or exporting it.

## Rollback

Restore previous code and stylesheets, then restart. Keep history tables/data.
Migration 002 down intentionally refuses before modifying the schema. A database
restoration is a separate maintenance operation; do not drop history tables or
run plugin down/purge commands as an ordinary code rollback.
