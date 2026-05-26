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

Version 1.0.2 does not create database tables or run migrations, so rollback does not require database changes.

## Shared Hosting Notes

On shared hosting, make sure commands run inside the same Ruby environment used by Redmine.

Check:

```bash
which ruby
which bundle
echo "$GEM_HOME"
```

If the hosting provider uses a Ruby virtual environment, activate it before running Redmine commands.
