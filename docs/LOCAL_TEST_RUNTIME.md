# Local Redmine Test Runtime

This plugin uses the shared `redmine-plugin-test-runtime` Codex skill. Its
test profile is declared in `.redmine-test.yml`.

## Setup

```powershell
powershell -ExecutionPolicy Bypass -File scripts/setup_redmine_test_runtime.ps1
```

The skill creates or reuses `C:\RedmineTestRuntimes\redmine-6.1.2` by default,
links this plugin, installs the test dependencies, and selects a dedicated
SQLite database for `redmine_project_percent_done`.

Set `REDMINE_TEST_RUNTIME_ROOT` to use another shared runtime root. Keep the
runtime outside this repository and prefer a path without spaces.

## Run Tests

Run the complete suite:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_redmine_plugin_tests.ps1
```

Run one test file:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/run_redmine_plugin_tests.ps1 `
  -Test "plugins/redmine_project_percent_done/test/unit/project_percent_done/project_progress_calculator_test.rb"
```

The runner applies pending Redmine migrations unless
`-SkipDatabasePrepare` is passed. Report exact runs, assertions, failures,
errors, and skips when handing work over.

Do not commit Redmine checkouts, portable Ruby, bundled gems, SQLite
databases, logs, or temporary runtime files.
