# Handoff: Project Percent Done 1.3.0

## Status

`staging-candidate` prepared on 2026-08-12 for monthly official historical
snapshots and the in-process historical Public API.

## Deliverables

- Package: `redmine_project_percent_done-1.3.0-staging-20260812.zip`
- Size: `222565` bytes
- SHA-256: `10F17EF999908378B030FF8C2F9EB905384546B0C71708D32F0CCDE058006F74`
- Archive root: `redmine_project_percent_done/`
- Runbook: `docs/STAGING_RUNBOOK_1.3.0.md`
- Specification: `docs/HISTORICAL_PROGRESS_SNAPSHOTS_SPEC.md`
- Public API documentation: `docs/PUBLIC_API_V1.md`
- Test evidence: `docs/TESTING_1.3.0.md`
- Source branch: `codex/project-percent-done-history-v1`

## Implemented

- Added snapshot `period_type` with `weekly` and `monthly` values.
- Migrated existing official and operational rows to default `weekly` period
  type and changed the official uniqueness boundary to
  `project_id + period_type + period_end`.
- The daily collector now promotes due weekly and monthly official snapshots.
  Monthly snapshots are automatic when historical collection is enabled.
- Weekly and monthly official snapshots can coexist for the same `period_end`.
- Existing weekly timeline, history page, plan metrics, diagnostics, and
  forecasts explicitly read weekly official snapshots.
- Added immutable historical Public API value objects and methods:
  `history_capabilities`, `latest_official_snapshot`,
  `official_snapshot_for`, `official_snapshots_between`, and `progress_at`.
- `progress_at` uses completed monthly snapshots by default and does not fall
  back to weekly snapshots or live calculation.

## Verification

- Full Redmine 6.1.2 plugin suite:
  **97 runs, 469 assertions, 0 failures, 0 errors, 0 skips**.
- Focused tests cover monthly promotion, weekly/monthly same-period coexistence,
  weekly UI isolation, forecast isolation, valid historical `0%`, and missing
  monthly snapshots without fallback.
- `git diff --check` passed.

## Deployment Notes

- Migration `002` adds `project_percent_done_snapshots.period_type` and updates
  the snapshot uniqueness index.
- Existing history is retained. Existing official rows become weekly rows by
  default.
- Ordinary rollback should restore the previous plugin directory and keep
  plugin history tables/data in place.
- Historical collection visibility remains controlled by the existing
  production shadow/admin/project-access setting.

## Next Session

- Validate staging installation, migration `002`, and historical API runner
  checks.
- Trigger a manual collection on staging around a controlled date or inspect
  seeded data after the first real monthly period.
- Coordinate the downstream Project Contribution integration against
  `ProjectPercentDone::PublicApi::V1` instead of direct table reads.
