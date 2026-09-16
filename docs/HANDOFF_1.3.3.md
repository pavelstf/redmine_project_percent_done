# Handoff: Project Percent Done 1.3.3

## Status

`staging-approved` on 2026-08-12.

The release finalizes the 1.3.x historical API/monthly snapshot cycle and fixes
the monthly status banner for projects that have no monthly history yet.

## Branch

```text
codex/project-percent-done-history-v1
```

## Deliverables

- Staging package:
  `release_packages/redmine_project_percent_done-1.3.3-staging-20260812.zip`
- Production package:
  `release_packages/redmine_project_percent_done-1.3.3-production-20260812.zip`
- SHA-256 for both:
  `2ABA8D485247F2B4B8FBAE4158BBD3335975FEE5CDD1B5E4004A053DECD0ACDD`
- Size for both: `151592` bytes
- Archive root: `redmine_project_percent_done/`
- Plugin id: `redmine_project_percent_done`
- Public API documentation: `docs/PUBLIC_API_V1.md`
- Integration brief for downstream developers:
  `docs/API_INTEGRATION_BRIEF_1.3.3.md`
- Specification: `docs/HISTORICAL_PROGRESS_SNAPSHOTS_SPEC.md`
- Test evidence: `docs/TESTING_1.3.3.md` and `TESTING_LOG.md`

The ZIP files are local deployment artifacts and remain ignored by Git.

## Implemented in the 1.3.x Cycle

- Added `period_type` to project snapshots.
- Existing official snapshot rows are migrated to `weekly`.
- Official uniqueness now includes `project_id + period_type + period_end`.
- Monthly official snapshots are created automatically whenever historical
  collection is enabled.
- Weekly and monthly official snapshots can coexist for the same `period_end`.
- Project history UI supports weekly/monthly period type selection.
- Monthly history table/chart displays monthly official rows.
- Monthly UI status reports next period, expected capture date, days remaining,
  disabled state, and overdue state.
- Monthly status does not report the first already-past month as overdue when
  no monthly history exists yet.
- Digest email includes a monthly section with either actual monthly rows from
  the run or the next/overdue/disabled monthly status.
- Historical in-process Public API added:
  `history_capabilities`, `latest_official_snapshot`,
  `official_snapshot_for`, `official_snapshots_between`, and `progress_at`.
- `progress_at` defaults to monthly, requires a completed month, and never
  falls back to weekly or live calculation.

## Validation

Local full Redmine 6.1.2 plugin suite:

```text
107 runs, 513 assertions, 0 failures, 0 errors, 0 skips
```

Staging user-confirmed validation:

```text
plugin_version=1.3.3
history_enabled=true
monthly_status_state=waiting
monthly_next_period_end=2026-09-30
monthly_expected_capture_date=2026-10-01
monthly_days_remaining=50
Fresh log tail: no errors
```

Known test-runtime note: the shared Windows Redmine runtime emits duplicate
constant warnings because the plugin is visible through both the workspace path
and the runtime plugin link. The suite result is green.

## Production State

A production ZIP for 1.3.3 was prepared with the same bytes as the staging ZIP.
This handoff does not mark production as approved because the final explicit
confirmation recorded here is for staging.

Earlier production collection is configured in shadow/admin-only mode. The
1.3.3 code path is compatible with that model.

## Downstream API Guidance

The downstream Project Contribution or bonus-cap plugin should use
`ProjectPercentDone::PublicApi::V1.progress_at` for monthly progress values.

It should not read Project Percent Done tables directly and should not fall
back to weekly or live values unless a separate business rule explicitly
defines that behavior.

See `docs/API_INTEGRATION_BRIEF_1.3.3.md` for the handoff-ready integration
summary.

## Deferred

- Historical CSV export.
- Historical REST API.
- Business-day calendar mode.
- Separate holiday/calendar provider plugin.
- Any downstream consumer implementation outside this plugin.
