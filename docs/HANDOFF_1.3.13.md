# Handoff: Project Percent Done 1.3.13

## Status

`packaged-staging` on 2026-09-23.

This is a focused follow-up for the Project Percent Done plugin only. It
addresses QA finding `QAPPD1312-001` from the 1.3.12 QA report.

Production promotion is pending staging QA approval.

## Scope

- Fixed the all-excluded non-progress diagnostic branch in
  `ProjectPercentDone::ProjectProgressCalculator`.
- When every eligible leaf issue is excluded by non-progress status and/or
  tracker rules, calculation details now still populate not-included issue
  rows and reasons.
- The diagnostic `excluded_non_progress_applied_weight` now uses the same
  fallback estimate weighting used by normal diagnostic row building.
- Calculation semantics are unchanged:
  - percent remains `0`;
  - warning remains `no_eligible_issues`;
  - no excluded issue contributes to the progress numerator or denominator.
- Public API V1 documentation and tests now report plugin version `1.3.13`.
- CSS cache busters were bumped to `1.3.13-r1`.

## Package Evidence

- Staging QA package:
  `release_packages/redmine_project_percent_done-1.3.13-staging-20260923.zip`
  - SHA-256:
    `4EE45CACE42A178285812A4E1524F5230F8BE2C5541082C2E37D44213A588499`
  - size: `282660` bytes
  - archive root: `redmine_project_percent_done/`
- Package inspection confirmed:
  - `redmine_project_percent_done/lib/project_percent_done.rb` contains
    `PLUGIN_VERSION = '1.3.13'`;
  - no `.git`, `.agents`, `.codex`, `tmp`, or `release_packages` entries are
    present in the archive.

## Validation

- Ruby syntax checks passed for:
  - `init.rb`;
  - `lib/project_percent_done.rb`;
  - `lib/project_percent_done/project_progress_calculator.rb`;
  - `test/unit/project_percent_done/project_progress_calculator_test.rb`;
  - `test/unit/project_percent_done/public_api_v1_test.rb`.
- ERB compile checks passed for touched settings/show views.
- Locale YAML parse checks passed for `config/locales/*.yml`.
- `git diff --check` passed with expected Windows LF/CRLF warnings only.
- Focused calculator test passed:
  `27 runs`, `113 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused controller test passed:
  `12 runs`, `97 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused Public API V1 test passed:
  `16 runs`, `128 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused history snapshot collector test passed after rerunning sequentially:
  `10 runs`, `44 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `136 runs`, `735 assertions`, `0 failures`, `0 errors`, `0 skips`.

## QA Focus

- Re-test `QAPPD1312-001` with details enabled:
  - configure status-only exclusions where every direct leaf issue is excluded;
  - configure tracker-only exclusions where every direct leaf issue is excluded;
  - configure combined status and tracker exclusions where every direct leaf
    issue is excluded.
- Confirm the UI details page shows not-included diagnostic rows and reasons.
- Confirm the not-included CSV contains the same excluded issues and reasons.
- Confirm history issue snapshots preserve not-included rows for the
  all-excluded case.
- Confirm the project percent remains `0%` with `no_eligible_issues`, and that
  excluded work is not counted into included totals.

## Known Notes

- `QAPPD1312-002` from the QA report is treated as existing behavior/design
  unless we decide separately to make aggregate issue counts visibility-aware.
- `QAPPD1312-003` is a CSV hardening observation, not part of this 1.3.13
  scope.
