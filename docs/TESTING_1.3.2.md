# Testing Log: Project Percent Done 1.3.2

Date: 2026-08-12

## Scope

Version `1.3.2` fixes a monthly history UI edge case found during staging
simulation. A manual collector run with a future simulated timestamp can create
an official monthly snapshot whose `period_end` is after the current Redmine
calendar month. The digest reported that row correctly, but the Monthly history
timeline capped visible month ends at the current real completed month and hid
the simulated snapshot.

Fixes:

- Monthly timeline now extends through the latest stored official monthly
  snapshot when that snapshot is newer than the current completed month.
- Monthly status moves to the month after the latest stored snapshot instead of
  reporting a next period that has already been captured.

## Automated Tests

Focused command:

```powershell
.\scripts\run_redmine_plugin_tests.ps1 -TestFiles test/unit/project_percent_done/history_timeline_test.rb,test/unit/project_percent_done/history_monthly_status_test.rb
```

Focused result:

- `106 runs`
- `509 assertions`
- `0 failures`
- `0 errors`
- `0 skips`

Full command:

```powershell
.\scripts\run_redmine_plugin_tests.ps1
```

Full result:

- `106 runs`
- `509 assertions`
- `0 failures`
- `0 errors`
- `0 skips`

