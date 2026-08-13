# Testing Log

## 2026-08-13 - 1.3.6 Dashboard Snapshot Freshness Refinement

- Replaced the single dashboard "last snapshot" line with separated freshness
  rows for latest operational backup, latest official weekly snapshot, and
  latest official monthly snapshot.
- Added an explicit dashboard message when no official monthly snapshot exists
  yet, while preserving the safe no-table guard during code-before-migrations
  deployment windows.
- Focused hook/dashboard check passed:
  `113 runs`, `544 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `113 runs`, `544 assertions`, `0 failures`, `0 errors`, `0 skips`.

## 2026-08-13 - 1.3.5 Dashboard Snapshot Freshness

- Added dashboard freshness information to the project overview and sidebar
  Project % done widgets. When stored history exists, the widgets show the
  latest snapshot capture time, snapshot kind, period type, and period end.
- Added focused hook/partial coverage proving the latest snapshot is passed to
  the dashboard partial and rendered. The hook also skips the lookup safely when
  the snapshot table is not available yet during a code-before-migrations swap.
- Focused hook/dashboard check passed:
  `113 runs`, `537 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `113 runs`, `537 assertions`, `0 failures`, `0 errors`, `0 skips`.
- `git diff --check` passed with only expected Windows LF/CRLF warnings.

## 2026-08-12 - 1.3.4 Fresh-Install Migration Safety

- Reviewed the migration chain and confirmed the issue: current migration `001`
  already creates `project_percent_done_snapshots.period_type`, while migration
  `002` tried to add the same column unconditionally.
- Fixed migration `002` so it is safe in both supported scenarios:
  - fresh install: skip duplicate `period_type` column/index creation when
    `001` already created them;
  - upgrade from pre-period-type history: add `period_type`, backfill existing
    snapshot rows to `weekly`, remove the old uniqueness index, and add the new
    `project_id + period_type + period_end` uniqueness boundary.
- Added focused migration strategy tests that simulate fresh-install and
  upgrade schema shapes without dropping real test tables.
- Added and ran `scripts/check_period_type_migrations.ps1`, which executes the
  real migrations against a temporary SQLite database. Result:
  `fresh_install=ok` and `upgrade=ok`.
- Focused migration/API check passed:
  `110 runs`, `527 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `110 runs`, `527 assertions`, `0 failures`, `0 errors`, `0 skips`.

## 2026-08-12 - 1.3.3 Monthly Initial-Start Status Fix

- Fixed the monthly status banner for installations/projects that have no
  monthly official snapshots yet. The first past monthly period is no longer
  shown as overdue when monthly collection is newly introduced; the status waits
  for the current month-end snapshot.
- Added regression coverage proving that real monthly gaps still become
  overdue after monthly history has started.
- Full Redmine 6.1.2 plugin suite passed:
  `107 runs`, `513 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Prepared production and staging ZIP packages:
  - `redmine_project_percent_done-1.3.3-production-20260812.zip`
  - `redmine_project_percent_done-1.3.3-staging-20260812.zip`
  - SHA-256 for both: `2ABA8D485247F2B4B8FBAE4158BBD3335975FEE5CDD1B5E4004A053DECD0ACDD`
  - size for both: `151592` bytes
  - archive root: `redmine_project_percent_done/`
- Staging was confirmed OK by the user after installation:
  `plugin_version=1.3.3`, `history_enabled=true`,
  `monthly_status_state=waiting`, `monthly_next_period_end=2026-09-30`,
  `monthly_expected_capture_date=2026-10-01`, and no fresh log errors.

## 2026-08-12 - 1.3.0-1.3.2 Historical Public API and Monthly Snapshots

- Added official monthly snapshot support on top of the existing weekly history
  model. Existing official rows migrate to `period_type = weekly`; monthly rows
  use `period_type = monthly`.
- Added historical in-process Public API methods:
  `history_capabilities`, `latest_official_snapshot`,
  `official_snapshot_for`, `official_snapshots_between`, and `progress_at`.
- Added project history period-type selection, monthly table/chart support, and
  monthly digest reporting.
- Fixed the staging simulation edge case where a future-dated monthly snapshot
  was created and emailed but hidden from the monthly table/chart.
- Full-suite results during the 1.3.x cycle were green; detailed per-patch
  evidence is in `docs/TESTING_1.3.0.md`, `docs/TESTING_1.3.1.md`,
  `docs/TESTING_1.3.2.md`, and `docs/TESTING_1.3.3.md`.

## 2026-07-16 - 1.2.0 Historical Progress V1

- Implemented optional daily operational and weekly official history with
  project/issue detail levels, retention, diagnostics, email, and graph/table UI.
- Added observed project start/planned-end date history, calendar plan phases,
  reported-time boundary analysis, explicit pre-collection gaps, and guarded
  shadow forecasts.
- Applied migration `001` in the shared Redmine 6.1.2 test runtime.
- Focused plan/history suite passed: `20 runs`, `78 assertions`, `0 failures`,
  `0 errors`, `0 skips`.
- Full suite passed: `65 runs`, `277 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Staging regression fixed: project-type values now load immediately when the
  selected custom field changes, without an intermediate save.
- Focused settings test passed: `3 runs`, `13 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Post-fix full suite passed: `66 runs`, `281 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Second staging feedback fixed: legacy settings now render the numeric defaults,
  and the email section follows the historical collection switch.
- Focused settings suite passed: `6 runs`, `25 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Final full suite passed: `69 runs`, `293 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Hardened the staging fix for persisted blank values and Redmine theme CSS;
  both chart and email sections now follow the history switch.
- Focused settings checks: `6 runs`, `26 assertions`; final full suite:
  `69 runs`, `294 assertions`, all green.
- Added the run-level digest subject default and blank-legacy fallback. Focused
  settings checks passed with `6 runs`, `28 assertions`; subject renderer checks
  passed with `4 runs`, `8 assertions`.
- Final full suite passed: `70 runs`, `297 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Fixed staging settings submission: diagnostic `button_to` helpers had emitted
  nested forms that broke the enclosing Redmine settings form in browsers.
  Diagnostic controls now use independent POST action links.
- Focused settings controller: `7 runs`, `36 assertions`, all green. Final full
  suite: `71 runs`, `305 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Removed the unnecessary multi-value-only restriction for the project-type
  custom field. Both single-value and multi-value list fields are supported;
  non-list fields remain rejected.
- Focused selector/validator/settings checks passed with `3/9`, `5/13`, and
  `7/36`. Final full suite: `73 runs`, `310 assertions`, all green.
- Split historical progress into a dedicated project route/page/tab, added a
  clear no-official-snapshots state, and removed admin-only "Initial" wording
  from project controls.
- Initial collection now excludes untracked closed/archived projects while
  retaining state-marker processing for previously tracked projects.
- Focused controller/selector/collector checks passed with `5/25`, `5/13`, and
  `6/23`. Final full suite: `78 runs`, `332 assertions`, all green.
- Fixed hidden project-menu items by assigning Redmine's `view_project`
  permission. Added direct history links to the overview/sidebar progress block
  and calculation page. Focused controller checks passed with `6 runs`, `28
  assertions`; final full suite passed with `79 runs`, `335 assertions`, all green.
- Fixed the staging 500 caused by calling a plugin helper from Redmine's generic
  hook view context; history availability is now passed as a render local.
- Fixed same-day idempotent collection returning boolean `false` into an integer
  counter. Focused hook and collector tests passed with `1/2` and `6/26`; final
  full suite passed with `80 runs`, `342 assertions`, all green.
- Fixed project-menu focus by assigning action-specific menu items to the
  calculation and history actions. Focused controller checks passed with `6
  runs`, `32 assertions`; final full suite passed with `80 runs`, `344
  assertions`, all green.
- Added a staging-host-guarded demo-history generator with preview, idempotent
  seed, cleanup, foreign-history refusal, 16 weekly periods, state/gap samples,
  issue details, plan changes, time anomalies, and forecast-ready points.
- Focused demo generator checks passed with `3 runs`, `23 assertions`; final
  full suite passed with `83 runs`, `367 assertions`, all green.
- Added Project Risk-style Administration cron guidance with a generated rake
  command, full hosting command, runtime detection, copy controls, and the
  recommended daily `5 0 * * *` schedule. Focused checks passed with `9 runs`,
  `47 assertions`; final full suite passed with `85 runs`, `378 assertions`.
- Reworked the protected staging demo into a coherent project model with six
  phase-based issues, 200 estimated hours, 132 real reported hours, and a live
  result of 60%. Every active project snapshot is derived from its issue-detail
  weights, and repeated seeding replaces the same demo work items without
  duplication. The generator now also absorbs snapshots created in its strictly
  identified private demo project by normal admin or cron runs, while refusing
  renamed projects and foreign issues. Focused checks passed with `3 runs`, `59
  assertions`; final full suite passed with `85 runs`, `414 assertions`.
- Ruby, ERB, YAML, EN/BG parity, and `git diff --check` passed.
- Prepared staging package:
  `redmine_project_percent_done-1.2.0-staging-20260716-r17.zip`.
- Package size: `195334` bytes.
- SHA-256:
  `4500639E28B49402982B4E256951B9BD09A88094DF2860FDFB1C4D3657ADA43F`.
- Release state: `staging-approved` on 2026-07-16. The user confirmed the `r17`
  installation and the protected seed result: 14 project snapshots, 66 issue
  snapshots, 15 collection runs, 60% live progress, 200 estimated hours, and
  132 reported hours. Production promotion remains pending.
- Detailed evidence: `docs/TESTING_1.2.0.md`.

## 2026-07-10 - 1.1.1 Administration Settings Help UI

Prepared Project Percent Done `1.1.1` as a UX consistency patch for the
Administration → Plugins → Project Percent Done settings page.

Scope:

- added help icons to every administrative setting;
- added concise English and Bulgarian help copy;
- followed the Budget Risk Monitor / Risk Monitor Pro help UX model:
  `button.icon-help`, custom `data-tooltip`, hover/focus/tap support, Escape to
  close, and no native `title` tooltip on help buttons;
- added minimal plugin stylesheet for compact help icons and tooltip styling;
- did not change calculation behavior, REST output, Public API V1, algorithm
  version, or Risk Monitor integration contract.

Validation notes:

- local static checks completed:
  - `ruby -c init.rb`
  - Ruby syntax check for `lib`, `app`, and `test`
  - YAML parsing for every locale file
  - ERB compile for every `.erb` view
  - `ruby -c app/views/project_percent_done/show.api.rsb`
  - EN/BG help locale parity check: 8 help keys
  - settings partial check confirmed help buttons use `data-tooltip` and no
    native `title=`
  - `git diff --check` reported no whitespace errors, only Windows LF/CRLF
    warnings
- staging package prepared:
  - `redmine_project_percent_done-1.1.1-staging-20260710.zip`
  - SHA-256:
    `A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388`
- staging was confirmed OK by the user on 2026-07-10;
- production package prepared as a byte-for-byte copy of the accepted staging
  package:
  - `redmine_project_percent_done-1.1.1-production-20260710.zip`
  - SHA-256:
    `A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388`
- production was confirmed OK by the user on 2026-07-15; version `1.1.1`
  is installed and working as expected on both GCR staging and GCR production;
- added a repeatable local Redmine 6.1.2 test runtime with portable Ruby
  3.3.11, SQLite, plugin-specific test databases, and reusable setup/runner
  parameters for other plugin repositories;
- extracted the runtime logic into the installed `redmine-plugin-test-runtime`
  skill and published it in `pavelstf/Codex-Skills` at commit `43ef12a`;
- moved the prepared runtime to the shared location
  `C:\RedmineTestRuntimes\redmine-6.1.2` and verified the repository wrappers
  without environment overrides;
- full Redmine plugin suite passed on 2026-07-15:
  - `28 runs`
  - `130 assertions`
  - `0 failures`
  - `0 errors`
  - `0 skips`
- the Windows junction/subst execution emits non-fatal duplicate constant
  warnings because the same plugin files are visible through physical and
  mapped paths; the suite result is green.
