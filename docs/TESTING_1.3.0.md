# Testing Log: Project Percent Done 1.3.0

## Runtime

- Redmine: 6.1.2
- Shared runtime: `C:\RedmineTestRuntimes\redmine-6.1.2`
- Plugin runtime declaration: `.redmine-test.yml`
- Plugin migration `002` was applied to the shared test database with
  `redmine:plugins:migrate NAME=redmine_project_percent_done`.

The shared runtime emits duplicate constant warnings because the plugin is
loaded through the runtime link and the workspace path. These warnings are
known runtime noise when the suite completes successfully.

## Focused Results

- Snapshot collector:
  `8 runs, 36 assertions, 0 failures, 0 errors, 0 skips`.
  Coverage includes direct weekly promotion, monthly promotion on the first day
  of a new month, weekly/monthly official snapshots sharing the same
  `period_end`, operational rotation, tolerance guards, idempotent same-day
  execution, and untracked closed-project exclusion.
- Public API V1:
  `15 runs, 103 assertions, 0 failures, 0 errors, 0 skips`.
  Coverage includes unchanged live capabilities/calculation behavior,
  historical capabilities, completed-month `progress_at`, valid historical
  `0%`, missing monthly snapshots without weekly fallback, incomplete-month
  `period_not_completed`, and ordered monthly history.
- Timeline:
  `5 runs, 11 assertions, 0 failures, 0 errors, 0 skips`.
  Coverage verifies that monthly snapshots do not appear in the weekly project
  history UI.
- Forecast:
  `4 runs, 13 assertions, 0 failures, 0 errors, 0 skips`.
  Coverage verifies that monthly snapshots do not feed the weekly forecast
  sample.

## Full Suite

- Command:

```powershell
& "$HOME\.codex\skills\redmine-plugin-test-runtime\scripts\run_redmine_plugin_tests.ps1" -SkipDatabasePrepare
```

- Result: **97 runs, 469 assertions, 0 failures, 0 errors, 0 skips**.
- Final seed: `39951`.
- Final test execution time: 24.034912 seconds.

## Static Checks

- `git diff --check`: passed, with only expected Windows LF/CRLF warnings.

## Notes

- The first focused collector run failed before migration `002` was applied to
  the shared test database. After applying the plugin migration, the focused and
  full suites passed.
