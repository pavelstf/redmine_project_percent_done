# Project Percent Done 1.3.3 Testing Notes

## Scope

Version 1.3.3 is a production hotfix for the monthly history status banner.

When monthly history starts after a previous month is already past its expected
capture date, the project history page no longer reports the first missing
month as overdue if the project has no monthly snapshots yet. It now waits for
the current month-end snapshot. Once monthly history has started for a project,
later monthly gaps are still reported as overdue.

## Automated Verification

Focused monthly status test:

```powershell
.\scripts\run_redmine_plugin_tests.ps1 -TestFiles test/unit/project_percent_done/history_monthly_status_test.rb
```

Result:

```text
107 runs, 513 assertions, 0 failures, 0 errors, 0 skips
```

Full plugin test suite:

```powershell
.\scripts\run_redmine_plugin_tests.ps1
```

Result:

```text
107 runs, 513 assertions, 0 failures, 0 errors, 0 skips
```

Known note: the shared Redmine test runtime emits constant redefinition
warnings because the plugin is loaded both from the workspace and the runtime
plugin link. The test result itself is clean.

## Manual Production Check

After installing 1.3.3, open:

```text
Project -> Progress history
```

For a project with no monthly history yet, the monthly banner should say that
the next monthly period end is the current month-end and that the expected
capture is the first day of the next month. It should not show an overdue
warning for the month before monthly collection was introduced.
