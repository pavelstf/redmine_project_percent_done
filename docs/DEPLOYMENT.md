# Deployment Notes

## Install From Git

```bash
cd /path/to/redmine/plugins
git clone <repository-url> redmine_project_percent_done
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
touch tmp/restart.txt
```

## Install From Release Archive

Extract the release archive into:

```text
REDMINE_ROOT/plugins/redmine_project_percent_done
```

Then run:

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
touch tmp/restart.txt
```

## Rollback

Remove the plugin directory and restart Redmine:

```bash
cd /path/to/redmine
rm -rf plugins/redmine_project_percent_done
touch tmp/restart.txt
```

Version 1.1.0 does not create database tables or run migrations, so rollback
does not require database changes. To roll back an upgrade, restore the
previous plugin directory from backup and restart Redmine.

## Shared Hosting Notes

On shared hosting, make sure commands run inside the same Ruby environment used by Redmine.

Check:

```bash
which ruby
which bundle
echo "$GEM_HOME"
```

If the hosting provider uses a Ruby virtual environment, activate it before running Redmine commands.

## Assets

Version 1.1.1 adds a small stylesheet for Administration settings help icons:

```text
assets/stylesheets/project_percent_done.css
```

On shared hosting deployments, copy plugin stylesheets into Redmine public
plugin assets after replacing the plugin directory:

```bash
mkdir -p public/plugin_assets/redmine_project_percent_done/stylesheets
cp -a plugins/redmine_project_percent_done/assets/stylesheets/. public/plugin_assets/redmine_project_percent_done/stylesheets/
```

## GCR Production Promotion 1.1.0

The GCR Production package prepared on 2026-07-10 is:

```text
redmine_project_percent_done-1.1.0-production-20260710.zip
```

It is a byte-for-byte copy of the staging-approved package:

```text
redmine_project_percent_done-1.1.0-staging-20260701.zip
```

Both packages have SHA-256:

```text
A68EE28370864D2A6AB598638BFE5E1A666DFB2605BCAB966F18738AA9571D4C
```

Use [Production Runbook 1.1.0](PRODUCTION_RUNBOOK_1.1.0.md) for the
SuperHosting/cPanel Production deployment. Project Percent Done 1.1.0 must be
validated on Production before deploying Risk Monitor Pro 0.2.3, because Risk
Monitor Pro requires Project Percent Done `>= 1.1.0` and
`ProjectPercentDone::PublicApi::V1`.

## GCR Production Promotion 1.1.1

The GCR Production package prepared on 2026-07-10 is:

```text
redmine_project_percent_done-1.1.1-production-20260710.zip
```

It is a byte-for-byte copy of the staging-approved package:

```text
redmine_project_percent_done-1.1.1-staging-20260710.zip
```

Both packages have SHA-256:

```text
A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388
```

Use [Production Runbook 1.1.1](PRODUCTION_RUNBOOK_1.1.1.md) for the
SuperHosting/cPanel Production deployment. Version `1.1.1` is a UX-only patch
over `1.1.0`; Public API V1 and calculation behavior remain unchanged.

Production was confirmed OK by the user on 2026-07-15. Version `1.1.1` is
installed and working as expected on both GCR staging and GCR production.
