# Public API V1

## Purpose

`ProjectPercentDone::PublicApi::V1` is a versioned, in-process API for Redmine
plugins that need aggregate project progress and estimate-coverage data.

It is not a REST authorization mechanism. It exposes no issue records, issue
rows, or issue IDs. Calculation is live and creates no settings, cache rows, or
other persistence.

## Versions

| Version | Value |
|---|---|
| Plugin release | `1.1.0` |
| Public contract | `1.0` |
| Calculation algorithm | `1.0` |

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
- `closed_issue_mode`
- `unestimated_issue_mode`
- `hours_weighted`
- `supports_raw_percent_done`
- `supports_estimate_coverage`

`hours_weighted` is false only for `equal_weight_all`. Settings are effective,
normalized values at call time.

## Calculation

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

## Counts and Coverage

All issue counts are for issues belonging directly to the project.

- Eligible counts are measured after leaf-scope parent exclusion and before
  missing-estimate handling.
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

## Defensive Hash Copies

Both value objects provide `to_h`. The returned hash and arrays are defensive
copies containing public scalar, string, symbol, and array values only.

```ruby
payload = result.to_h
payload[:warnings] << :local_only
# result.warnings is unchanged
```

## Compatibility and Performance

The public calculation uses the calculator's summary mode, preloads required
status data, does not build issue breakdown rows, and does not include
subprojects. Existing HTML and REST behavior remains independent of this API.

Representative staging runtimes must be recorded during release acceptance;
they cannot be established from the standalone plugin source tree.
