# Handoff: Project Percent Done 1.3.4

## Status

`implemented-local` on 2026-08-12.

This patch fixes a migration-chain issue found after the 1.3.3 closeout:
current migration `001` already creates `period_type`, while migration `002`
also tried to add it unconditionally.

## Scope

- Migration `002` now checks whether `project_percent_done_snapshots.period_type`
  already exists before adding it.
- Existing rows are explicitly backfilled to `weekly` when the column exists but
  contains `NULL` or blank values.
- The old unique index on `project_id + period_end` is removed only when present.
- The new unique index on `project_id + period_type + period_end` is added only
  when missing.
- Rollback remains guarded with `index_exists?` and `column_exists?`.
- No historical data is deleted.
- Historical API behavior is unchanged from `1.3.3`; the current integration
  brief is `docs/API_INTEGRATION_BRIEF_1.3.4.md`.

## Expected Scenarios

Fresh install of the current plugin:

1. Migration `001` creates `period_type` with default `weekly`.
2. Migration `001` creates the new uniqueness index on
   `project_id + period_type + period_end`.
3. Migration `002` sees both already exist and skips duplicate creation.

Upgrade from older history schema:

1. Migration `001` has already run in the old deployment without `period_type`.
2. Migration `002` adds `period_type` with default `weekly`.
3. Existing snapshot rows receive `period_type = weekly`.
4. The old unique index on `project_id + period_end` is replaced by
   `project_id + period_type + period_end`.

## Validation

- Focused migration/API tests passed:
  `110 runs`, `527 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Real migration smoke check passed through
  `scripts/check_period_type_migrations.ps1`:
  `fresh_install=ok` and `upgrade=ok`.
- Full Redmine 6.1.2 plugin suite passed:
  `110 runs`, `527 assertions`, `0 failures`, `0 errors`, `0 skips`.
