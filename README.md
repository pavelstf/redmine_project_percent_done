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
- Optionally stores daily operational and official weekly progress snapshots.
- Shows weekly history on a dedicated project tab as a gap-aware graph and paginated table.
- Supports project-type scope, aggregate/detail retention, diagnostics, and email reports.
- Can collect production history in shadow mode while hiding project history pages from users.
- Tracks observed changes to optional project start and planned end custom dates.
- Highlights pre-start and post-end time entries and provides guarded calendar-day forecasts.

## Compatibility

| Component | Supported target |
|---|---|
| Redmine | 5.x, 6.x |
| Primary target | Redmine 6.1.2 |
| Ruby | Follows the installed Redmine version |
| Rails | Follows the installed Redmine version |
| Database | MariaDB/MySQL, PostgreSQL, SQLite where supported by Redmine |

Version 1.2.0 adds plugin-owned tables for collection runs, project snapshots,
and optional issue snapshots. Existing Redmine tables are not modified.

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

Version 1.2.0 requires the standard plugin migration command. The history
feature remains disabled by default after upgrade.

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

Administration settings include compact help icons with localized English and
Bulgarian guidance. The help tooltips support mouse hover, keyboard focus, and
tap without using native `title` tooltips, avoiding duplicate tooltip display.

Historical progress settings include:

- master enable switch, disabled by default;
- project-only or project-and-issue detail;
- history visibility: hidden from project UI, administrators only, or visible according to project access;
- single-value or multi-value list project type field and eligible values;
- optional date custom fields for project start and planned end;
- 0-3 day official-snapshot recovery tolerance;
- 13-520 week issue-detail retention and 0-52 week inactive grace;
- rolling, calendar, and fiscal display defaults;
- optional TO/BCC email reports with safe subject placeholders;
- administrator diagnostics, preview, manual capture, test email, and project purge.

Configured plan dates are analytical inputs, not collection prerequisites. Each
snapshot preserves the observed values and source field identity, so later edits
produce an auditable observed history. V1 uses calendar days and records direct
project time entries as before-start, within-plan, after-end, or unclassified.
Forecasts appear only when at least four consecutive active official weekly
points form a positive trend; they remain shadow indicators and never alter the
live calculation.

Run the collector once per day. It retains one operational backup per project
and promotes the closest eligible capture to the official Sunday period:

```bash
cd /path/to/redmine
RAILS_ENV=production bundle exec rake redmine:project_percent_done:snapshots
```

Configured notification email is sent according to the history email settings
when the run creates, promotes, repairs, or records a reportable state. The rake
task is independent from project history visibility, so production can start
collecting data with history hidden from project users.

Example cron entry for 00:05 server time:

```cron
5 0 * * * cd /path/to/redmine && RAILS_ENV=production bundle exec rake redmine:project_percent_done:snapshots >> log/project_percent_done_snapshots.log 2>&1
```

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

## Public Integration API

Version 1.1.0 provides a versioned in-process aggregate API for other Redmine
plugins. It is loaded during normal plugin initialization and does not depend
on the optional REST endpoint:

```ruby
capabilities = ProjectPercentDone::PublicApi::V1.capabilities
result = ProjectPercentDone::PublicApi::V1.calculate(:project => project)

result.progress_available
result.raw_percent_done
result.display_percent_done
result.estimate_coverage_percent
```

The API is live and non-persistent. It returns immutable value objects with
aggregate counts and weights only; it does not expose issues or issue IDs.
See [Public API V1](docs/PUBLIC_API_V1.md) for the complete contract.

## Security Note

The project percentage is calculated from all issues in the project, regardless of the current user's issue visibility.

The details page shows issue rows only for issues visible to the current user. The final percentage and totals still represent the entire project and all applicable issues.

Historical aggregate graph/table access is controlled by the history visibility
setting. The default is hidden from project UI, which allows production shadow
collection. When enabled for users, access still follows current project
visibility. Historical issue rows and irreversible per-project purge are
restricted to Redmine system administrators.

## Performance

Version 1.2.0 keeps live calculation for all existing UI and API surfaces.
History collection is an optional background workflow and does not replace it.

To reduce request overhead:

- overview and sidebar use a lightweight summary calculation;
- overview and sidebar share a per-request calculation result;
- the detailed breakdown is calculated only when the details page is opened.

For very large Redmine installations, future versions may add persistent caching or background recalculation.

## Protected staging demo history

The staging-only `redmine:project_percent_done:staging_demo` task can create 16
weeks of synthetic history in the private `ppd-history-test` project. It
requires `CONFIRM=STAGING_DEMO_HISTORY`, verifies the configured staging host,
marks its runs as `staging_test`, refuses non-demo history, and supports
`ACTION=preview`, `ACTION=seed`, and `ACTION=cleanup`. Cleanup keeps the demo
project and its six `[PPD DEMO]` issues but removes all generated history.
Each seed recreates six coherent project phases with 200 estimated hours, 132
reported hours, and a live/latest historical result of about 60%. Every active
project snapshot is derived from its stored issue rows; plan dates and reported
hours are also written to the demo project so the live and historical views
remain consistent.
Snapshots created in this dedicated private project by normal admin or cron
collection are also replaced on the next seed. The task still refuses a renamed
project or any project containing tasks without the `[PPD DEMO]` prefix.

## Cron configuration

When historical collection is enabled, Administration displays a generated
daily rake command and a complete hosting cron command for the current Redmine
root, Rails environment, and detected Ruby virtual environment. The recommended
schedule is `5 0 * * *`. The daily collector also applies issue-detail
retention, so a separate cleanup cron is not required.

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
- [Public API V1](docs/PUBLIC_API_V1.md)
- [Historical progress snapshots V1 specification](docs/HISTORICAL_PROGRESS_SNAPSHOTS_SPEC.md)
- [Deployment notes](docs/DEPLOYMENT.md)
- [Release checklist](docs/RELEASE.md)
- [Changelog](CHANGELOG.md)
- [Contributing](CONTRIBUTING.md)
- [Security policy](SECURITY.md)

## License

Released under the MIT License. See [LICENSE](LICENSE).
