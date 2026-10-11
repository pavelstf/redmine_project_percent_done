# Public API V1

## Purpose

`ProjectPercentDone::PublicApi::V1` is a versioned, in-process API for Redmine
plugins that need aggregate project progress and estimate-coverage data.

It is not a REST authorization mechanism. By default it exposes no issue
records, issue rows, or issue IDs. Callers that explicitly request calculation
evidence receive per-issue scalar evidence rows intended for trusted in-process
provider integrations such as Project Progress History. Live calculation creates
no settings, cache rows, or other persistence. Historical methods read official
snapshots captured by this plugin.

## Versions

| Version | Value |
|---|---|
| Plugin release | `1.3.17` |
| Public contract | `1.0` |
| Historical contract | `1.0` |
| Calculation algorithm | `1.1` |

The algorithm version identifies calculation semantics independently from the
plugin release. Fields may be added compatibly to V1, but breaking a field's
meaning requires a new public API namespace.

## Loading

The namespace is loaded by `lib/project_percent_done.rb` during normal Redmine
plugin initialization. It does not depend on controller loading or the REST API
setting.

## Capabilities

```ruby
capabilities = ProjectPercentDone::PublicApi::V1.capabilities
```

`Capabilities` is immutable and provides:

- `contract_name`
- `contract_version`
- `plugin_version`
- `algorithm_version`
- `calculation_mode`
- `persistence_mode`
- `issue_scope`
- `non_progress_status_scope`
- `non_progress_status_ids`
- `non_progress_tracker_scope`
- `non_progress_tracker_ids`
- `closed_issue_mode`
- `unestimated_issue_mode`
- `hours_weighted`
- `supports_raw_percent_done`
- `supports_estimate_coverage`

`hours_weighted` is false only for `equal_weight_all`. Settings are effective,
normalized values at call time.

## Live Calculation

```ruby
result = ProjectPercentDone::PublicApi::V1.calculate(:project => project)
```

The argument must be a persisted `Project` (subclasses are accepted). `nil`,
other object types, and unpersisted projects raise `ArgumentError`. Database
and programming errors are allowed to propagate to the consumer.

`Result` is immutable and provides:

```text
progress_available
unavailable_reason
raw_percent_done
display_percent_done
all_project_issue_count
eligible_issue_count
estimated_eligible_issue_count
unestimated_eligible_issue_count
included_issue_count
excluded_parent_issue_count
excluded_non_progress_issue_count
excluded_non_progress_estimated_hours
excluded_non_progress_applied_weight
non_progress_status_scope
non_progress_status_ids
non_progress_tracker_scope
non_progress_tracker_ids
non_progress_status_names
non_progress_tracker_names
ignored_unestimated_issue_count
known_estimated_hours
imputed_weight
total_applied_weight
estimate_coverage_percent
known_weight_percent
issue_scope
closed_issue_mode
unestimated_issue_mode
hours_weighted
warnings
```

A valid `0%` has `progress_available == true`. When progress is unavailable,
both percentage values are `nil`; `unavailable_reason` is
`no_eligible_issues` or `no_usable_weight`.

## Optional Calculation Evidence

Trusted in-process consumers can request issue-level calculation evidence:

```ruby
result = ProjectPercentDone::PublicApi::V1.calculate(
  :project => project,
  :include_evidence => true
)

payload = result.to_h
```

When `include_evidence` is omitted or false, the result shape is unchanged and
does not include issue evidence. When true, the result includes the normal
project-level fields plus:

```text
project_id
metrics
provider_metadata
issue_evidence
```

`metrics` contains grouped aggregate values for snapshot consumers, including
`total_spent_hours`, issue counts, estimate counts, weights, and
`known_weight_percent`.

`provider_metadata` includes:

```text
evidence_schema_version
contract_name
contract_version
plugin_version
algorithm_version
calculation_mode
issue_scope
closed_issue_mode
unestimated_issue_mode
hours_weighted
non_progress_status_scope
non_progress_status_ids
non_progress_status_names
non_progress_tracker_scope
non_progress_tracker_ids
non_progress_tracker_names
```

Each `issue_evidence` row contains scalar fields only:

```text
issue_id
project_id
subject
status_id
status_name
tracker_id
tracker_name
assigned_to_id
assigned_to_login
assigned_to_firstname
assigned_to_lastname
assigned_to_display_name
assigned_to_mail
done_ratio
estimated_hours
spent_hours
applied_weight
included_in_progress
exclusion_reason
parent_id
is_parent
children_count
is_closed
closed_on
notes
```

`done_ratio` is the effective value used by the calculation. For included rows,
`exclusion_reason` is `"none"`. For excluded rows it is a stable reason string
such as `"parent_issue_excluded"`, `"non_progress_status"`,
`"non_progress_tracker"`, `"non_progress_status_and_tracker"`,
`"unestimated_issue_ignored"`, or `"not_in_calculation_scope"`. `notes`
contains string markers for calculation adjustments, for example closed issues
treated as 100% or status-default done ratio usage.

## Counts and Coverage

All issue counts are for issues belonging directly to the project.
They use the plugin's project-wide calculation scope and are not filtered by
the current user's issue visibility. The public API exposes aggregate values
only; per-issue visibility filtering applies to the Redmine UI detail tables
and diagnostic CSV row exports.

- Eligible counts are measured after leaf-scope parent exclusion and before
  non-progress status/tracker exclusion and missing-estimate handling.
- `excluded_non_progress_issue_count` counts each excluded direct leaf issue
  once, even when both status and tracker match.
- Positive `estimated_hours` is estimated; missing, zero, or negative is
  unestimated.
- Included issues have a positive applied weight.
- Ignored unestimated issues remain in eligible coverage counts.

```text
estimate_coverage_percent =
  estimated_eligible_issue_count / eligible_issue_count * 100
```

The value is `nil` when there are no eligible issues. It measures estimate
presence by issue count, not measured-hours coverage.

`known_weight_percent` is available only when the configured calculation has
meaningful hours-based weighting and a usable denominator:

```text
known_estimated_hours / total_applied_weight * 100
```

## Stable Warning Codes

- `no_issues`
- `no_eligible_issues`
- `no_usable_weight`
- `unestimated_issues`
- `all_issues_unestimated`

## Historical Capabilities

```ruby
history = ProjectPercentDone::PublicApi::V1.history_capabilities
```

`HistoryCapabilities` is immutable and provides:

```text
contract_name
contract_version
history_contract_version
plugin_version
algorithm_version
history_supported
history_enabled
supported_period_types
default_period_type
supports_official_snapshots
supports_monthly_snapshots
supports_progress_at
calculation_mode
persistence_mode
```

Historical persistence mode is `snapshots`. Supported period types are `weekly`
and `monthly`; the default integration period is `monthly`.

## Historical Snapshots

```ruby
latest = ProjectPercentDone::PublicApi::V1.latest_official_snapshot(
  :project => project,
  :period_type => :monthly
)

snapshot = ProjectPercentDone::PublicApi::V1.official_snapshot_for(
  :project => project,
  :period_type => :monthly,
  :period_end => Date.new(2026, 7, 31)
)

snapshots = ProjectPercentDone::PublicApi::V1.official_snapshots_between(
  :project => project,
  :period_type => :monthly,
  :from => Date.new(2026, 1, 1),
  :to => Date.new(2026, 12, 31)
)
```

Monthly official snapshots are created automatically whenever historical
collection is enabled. There is no separate monthly toggle. Weekly and monthly
official snapshots can share the same `period_end`; callers must always specify
or inspect `period_type`.

`HistorySnapshotResult` is immutable and provides:

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
settings_snapshot
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

`settings_snapshot` is an alias for `calculation_settings`. New snapshots store
the configured `non_progress_status_ids`, `non_progress_tracker_scope`, and
`non_progress_tracker_ids`, plus status/tracker display metadata for audit after
future renames. Existing
snapshots are read as stored and are not rewritten when settings change.

A valid historical `0%` has `progress_available == true`. Missing progress is
represented by an immutable unavailable result object, not by raising an
exception.

## Progress At

```ruby
result = ProjectPercentDone::PublicApi::V1.progress_at(
  :project => project,
  :date => Date.new(2026, 12, 31)
)
```

For the default monthly mode, the API uses `date.end_of_month` as the official
snapshot period. If that month is not complete at call time, the result is
unavailable with `period_not_completed`. If the month is complete but the
official monthly snapshot is missing, the result is unavailable with
`snapshot_missing`.

`progress_at` does not fall back to weekly snapshots or live calculation.

Historical unavailable reasons include:

- `period_not_completed`
- `snapshot_missing`
- `project_closed`
- `project_archived`
- `project_out_of_scope`
- `progress_unavailable`
- `no_eligible_issues`
- `no_usable_weight`

## Defensive Hash Copies

Public value objects provide `to_h`. The returned hash, nested hashes, and
arrays are defensive copies containing public scalar, string, symbol, hash, and
array values only.

```ruby
payload = result.to_h
payload[:warnings] << :local_only
# result.warnings is unchanged
```

## Compatibility and Performance

The default live public calculation uses the calculator's summary mode, preloads
required status data, does not build issue breakdown rows, and does not include
subprojects. Evidence mode uses the calculator's details mode to build scalar
issue evidence rows for direct project issues only. Historical methods read
plugin-owned official snapshots only. Existing HTML and REST behavior remains
independent of this API.

Representative staging runtimes must be recorded during release acceptance;
they cannot be established from the standalone plugin source tree.
