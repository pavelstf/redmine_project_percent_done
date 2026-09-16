# Project Percent Done Historical API Integration Brief

Version: `1.3.4`

Date: 2026-08-12

Audience: developers integrating another Redmine plugin with Project Percent
Done historical progress data.

## Executive Summary

Project Percent Done now exposes a versioned in-process historical API under
`ProjectPercentDone::PublicApi::V1`. Downstream plugins should use this public
API instead of reading Project Percent Done tables directly.

The integration target for bonus-cap, contribution, or forecasting consumers is
the official monthly snapshot. Weekly snapshots remain available for charting
and project-level history, but the default historical integration period is
monthly.

The live calculation API added in earlier releases is unchanged.

## Public Contract

```ruby
ProjectPercentDone::PublicApi::V1
```

Contract versions:

| Item | Value |
|---|---|
| Public contract | `1.0` |
| Historical contract | `1.0` |
| Plugin release | `1.3.4` |
| Algorithm version | `1.0` |

Consumers should check capabilities at runtime and fail closed if the expected
historical contract is unavailable.

```ruby
capabilities = ProjectPercentDone::PublicApi::V1.history_capabilities

raise "Project Percent Done history is not supported" unless capabilities.history_supported
raise "Project Percent Done history is disabled" unless capabilities.history_enabled
raise "Monthly snapshots are required" unless capabilities.supports_monthly_snapshots
```

Expected capability values in this release:

```ruby
{
  :contract_name => "project_percent_done",
  :contract_version => "1.0",
  :history_contract_version => "1.0",
  :plugin_version => "1.3.4",
  :algorithm_version => "1.0",
  :history_supported => true,
  :history_enabled => true_or_false,
  :supported_period_types => [:weekly, :monthly],
  :default_period_type => :monthly,
  :supports_official_snapshots => true,
  :supports_monthly_snapshots => true,
  :supports_progress_at => true,
  :calculation_mode => "snapshot",
  :persistence_mode => "snapshots"
}
```

## Snapshot Model

Historical data is persisted by Project Percent Done as official snapshots.
Consumers do not need to know table names or indexes.

Supported period types:

- `:weekly`: official Sunday period snapshots;
- `:monthly`: official calendar month-end snapshots.

Monthly official snapshots are created automatically whenever historical
collection is enabled. There is no separate monthly enable switch.

Weekly and monthly snapshots may share the same `period_end`, for example when
the last day of a month is Sunday. Consumers must always pass and inspect
`period_type`.

## Recommended Integration: Progress for a Date

For most downstream integrations, use `progress_at`.

```ruby
result = ProjectPercentDone::PublicApi::V1.progress_at(
  :project => project,
  :date => Date.new(2026, 7, 31)
)
```

Default behavior:

- uses monthly snapshots;
- maps the input date to `date.end_of_month`;
- returns unavailable for the current/incomplete month;
- returns unavailable when the completed monthly snapshot is missing;
- does not fall back to weekly snapshots;
- does not fall back to live calculation.

This is intentional. Missing monthly history must be handled explicitly by the
consumer instead of silently mixing periods or current live data.

Example handling:

```ruby
result = ProjectPercentDone::PublicApi::V1.progress_at(
  :project => project,
  :date => Date.new(2026, 7, 15)
)

if result.progress_available
  percent = result.display_percent_done
else
  Rails.logger.info(
    "No Project Percent Done history for project #{project.identifier}: " \
    "#{result.unavailable_reason}"
  )
end
```

Unavailable reasons relevant to monthly integration:

- `:period_not_completed`
- `:snapshot_missing`
- `:project_closed`
- `:project_archived`
- `:project_out_of_scope`
- `:progress_unavailable`
- `:no_eligible_issues`
- `:no_usable_weight`

A valid `0%` snapshot has `progress_available == true`. Do not treat zero as
missing.

## Direct Snapshot Lookups

Latest official snapshot:

```ruby
latest = ProjectPercentDone::PublicApi::V1.latest_official_snapshot(
  :project => project,
  :period_type => :monthly
)
```

Specific official snapshot:

```ruby
snapshot = ProjectPercentDone::PublicApi::V1.official_snapshot_for(
  :project => project,
  :period_type => :monthly,
  :period_end => Date.new(2026, 7, 31)
)
```

Range of official snapshots:

```ruby
snapshots = ProjectPercentDone::PublicApi::V1.official_snapshots_between(
  :project => project,
  :period_type => :monthly,
  :from => Date.new(2026, 1, 1),
  :to => Date.new(2026, 12, 31)
)
```

Range results are ordered by `period_end` ascending.

## Historical Result Fields

Historical methods return immutable `HistorySnapshotResult` objects. Use
readers or `to_h`.

Key fields for downstream analytics:

```text
project_id
period_type
period_end
captured_at
project_state
progress_available
unavailable_reason
display_percent_done
raw_percent_done
estimate_coverage_percent
warnings
snapshot_source
timing
deviation_seconds
algorithm_version
plugin_version
calculation_settings
all_project_issue_count
eligible_issue_count
included_issue_count
not_included_issue_count
estimated_issue_count
unestimated_issue_count
estimated_eligible_issue_count
unestimated_eligible_issue_count
excluded_parent_issue_count
ignored_unestimated_issue_count
known_estimated_hours
total_weight
imputed_weight
```

`display_percent_done` is the rounded percentage used by the plugin UI.
`raw_percent_done` preserves the more precise source value.

`snapshot_source`, `timing`, and `deviation_seconds` explain whether an official
snapshot was captured directly or promoted from an operational backup after a
missed run.

`calculation_settings` stores the Project Percent Done settings observed at
snapshot time, so downstream consumers can explain historical changes even if
current settings later differ.

## Live API Remains Separate

Live current progress is still available:

```ruby
live = ProjectPercentDone::PublicApi::V1.calculate(:project => project)
```

This remains non-persistent and uses the current project data. Historical
consumers should not mix `calculate` with monthly history unless the business
rule explicitly says to use current live progress.

## Security and Access Notes

This is an in-process Redmine plugin API, not a REST authorization layer. A
consumer plugin is responsible for enforcing its own UI/controller permissions.

The historical API exposes aggregate project values only. It does not expose
issue rows, issue IDs, issue subjects, time-entry rows, users, or comments.

## Operational Requirements

For monthly history to be available:

1. Project Percent Done must be installed and initialized.
2. Historical collection must be enabled.
3. The project must be active and in the configured history scope when captured.
4. The daily rake collector must run, normally at `00:05`.
5. The requested month must be complete.

Recommended daily cron:

```cron
5 0 * * * cd /path/to/redmine && RAILS_ENV=production bundle exec rake redmine:project_percent_done:snapshots >> log/project_percent_done_snapshots.log 2>&1
```

Collection visibility can be hidden from Redmine project users while snapshots
continue to accumulate. This supports production shadow collection before a
customer-facing rollout.

## Integration Do and Do Not

Do:

- call `history_capabilities` before relying on historical methods;
- use `progress_at` for monthly business calculations;
- handle unavailable results explicitly;
- store the returned `period_end`, `algorithm_version`, and `plugin_version`
  with downstream derived results if auditability matters;
- specify `period_type` whenever looking up snapshots directly.

Do not:

- read Project Percent Done tables directly;
- assume monthly history exists before collection was enabled;
- treat missing monthly history as `0%`;
- fall back to weekly snapshots or live calculation unless a separate business
  requirement explicitly defines that behavior;
- assume `display_percent_done == nil` means zero.

## Minimal Consumer Adapter Example

```ruby
module ContributionProgressProvider
  module_function

  def monthly_progress(project, month)
    capabilities = ProjectPercentDone::PublicApi::V1.history_capabilities
    return unavailable(:history_not_supported) unless capabilities.history_supported
    return unavailable(:history_disabled) unless capabilities.history_enabled
    return unavailable(:monthly_not_supported) unless capabilities.supports_monthly_snapshots

    result = ProjectPercentDone::PublicApi::V1.progress_at(
      :project => project,
      :date => month.end_of_month
    )

    return result if result.progress_available

    unavailable(result.unavailable_reason, result)
  end

  def unavailable(reason, result = nil)
    {
      :progress_available => false,
      :reason => reason,
      :period_end => result.try(:period_end)
    }
  end
end
```

## Current Release State

`1.3.4` keeps the same historical API contract as `1.3.3` and adds a
fresh-install migration safety fix.

Migration smoke validation:

```text
fresh_install=ok
upgrade=ok
```

Full shared Redmine 6.1.2 test runtime validation:

```text
110 runs, 527 assertions, 0 failures, 0 errors, 0 skips
```

Previous `1.3.3` staging installation was confirmed on 2026-08-12 with:

```text
plugin_version=1.3.3
history_enabled=true
monthly_status_state=waiting
monthly_next_period_end=2026-09-30
monthly_expected_capture_date=2026-10-01
```
