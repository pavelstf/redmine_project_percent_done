# Testing Log: Project Percent Done 1.3.1

Date: 2026-08-12

## Scope

Version `1.3.1` adds project-history UI support for monthly snapshots and adds
monthly snapshot information to the collection digest email.

Covered changes:

- project history period type selector: Weekly or Monthly;
- monthly timeline entries based on month-end official snapshots;
- weekly forecast hidden in Monthly mode;
- monthly status notice with next period end, expected capture date, days
  remaining, overdue, and disabled states;
- collection digest monthly section summarizing actual monthly rows created by
  the run, or reporting the next/overdue/disabled monthly status;
- plugin version bump to `1.3.1`.

## Automated Tests

Command:

```powershell
.\scripts\run_redmine_plugin_tests.ps1
```

Result:

- `104 runs`
- `503 assertions`
- `0 failures`
- `0 errors`
- `0 skips`

Notes:

- The shared Redmine 6.1.2 runtime prints known constant redefinition warnings
  because the plugin is linked into the test runtime and loaded from the working
  copy. They were present before this change and did not affect assertions.
