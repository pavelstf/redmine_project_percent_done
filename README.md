# Redmine Project Percent Done

Redmine Project Percent Done calculates an absolute project completion percentage from issue `% Done` values and issue weights.

The plugin is designed for Redmine 6.1.x and aims to remain compatible with Redmine 5.x.

## Features

- Calculates project `% done` from issues in the current project.
- Uses weighted progress based on `estimated_hours`.
- Excludes parent issues by default to avoid double counting.
- Supports configurable handling for closed issues.
- Supports configurable handling for issues without estimates.
- Shows the result in project overview and/or project sidebar.
- Optional project tab with calculation details.
- Optional REST API endpoint.
- Explains the calculation with included and excluded issue tables.
- Supports English and Bulgarian translations.
- Provides fallback English translations for the Redmine built-in locale set.

## Compatibility

| Component | Supported target |
|---|---|
| Redmine | 5.x, 6.x |
| Primary target | Redmine 6.1.2 |
| Ruby | Follows the installed Redmine version |
| Rails | Follows the installed Redmine version |
| Database | MariaDB/MySQL, PostgreSQL, SQLite where supported by Redmine |

The plugin has no database migrations in version 1.0.2.

## Installation

Clone or extract the plugin into the Redmine plugins directory:

```bash
cd /path/to/redmine/plugins
git clone <repository-url> redmine_project_percent_done
```

The final directory must be:

```text
REDMINE_ROOT/plugins/redmine_project_percent_done
```

Then restart Redmine:

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
touch tmp/restart.txt
```

Open:

```text
Administration -> Plugins -> Redmine Project Percent Done -> Configure
```

## Upgrade

Replace the plugin directory with the new version and restart Redmine:

```bash
cd /path/to/redmine
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
touch tmp/restart.txt
```

Version 1.0.2 does not require database migration, but running the standard Redmine plugin migration command is safe.

## Default Behavior

- Each project is calculated independently.
- Subprojects are not included.
- Calculation is live.
- Only leaf issues are included by default.
- Parent issues are excluded when they have child issues in the same project.
- Closed issues are treated as `100%` by default.
- Issues without estimates use the average estimate by default.

## Calculation Formula

```text
Project % done =
  sum((effective issue % done / 100) x applied weight)
  / sum(applied weight)
  x 100
```

See [docs/CALCULATION.md](docs/CALCULATION.md) for the full behavior.

## Settings

Display locations:

- Project overview
- Project sidebar
- Project tab
- REST API endpoint

Calculation settings:

- Issue scope: leaf issues only
- Closed issue handling:
  - Treat closed issues as `100%`
  - Use issue `% done`
- Unestimated issue handling:
  - Use average estimate
  - Use weight `1`
  - Ignore unestimated issues
  - Use equal weight for all issues
- Rounding:
  - Nearest integer
  - Round down
  - Round up

## REST API

Enable the REST API endpoint in plugin settings, then request:

```http
GET /projects/:project_id/percent_done.json
```

Example response:

```json
{
  "project_percent_done": {
    "project_id": 12,
    "project_identifier": "example",
    "percent_done": 67,
    "raw_percent_done": 66.6667,
    "issue_count": 12,
    "not_included_issue_count": 3,
    "estimated_issue_count": 8,
    "unestimated_issue_count": 4,
    "total_weight": 42.5,
    "closed_issue_mode": "treat_as_100",
    "unestimated_issue_mode": "use_average_estimate",
    "calculation_mode": "live",
    "warnings": []
  }
}
```

## Security Note

The project percentage is calculated from all issues in the project, regardless of the current user's issue visibility.

The details page shows issue rows only for issues visible to the current user. The final percentage and totals still represent the entire project and all applicable issues.

## Performance

Version 1.0.2 uses live calculation.

To reduce request overhead:

- overview and sidebar use a lightweight summary calculation;
- overview and sidebar share a per-request calculation result;
- the detailed breakdown is calculated only when the details page is opened.

For very large Redmine installations, future versions may add persistent caching or background recalculation.

## Testing

The plugin tests are intended to run inside a Redmine test environment:

```bash
cd /path/to/redmine
RAILS_ENV=test bundle exec rake redmine:plugins:test NAME=redmine_project_percent_done
```

For a single test file:

```bash
RAILS_ENV=test bundle exec rake test TEST=plugins/redmine_project_percent_done/test/unit/project_percent_done/project_progress_calculator_test.rb
```

## Documentation

- [Calculation behavior](docs/CALCULATION.md)
- [Deployment notes](docs/DEPLOYMENT.md)
- [Release checklist](docs/RELEASE.md)
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## License

Released under the MIT License. See [LICENSE](LICENSE).
