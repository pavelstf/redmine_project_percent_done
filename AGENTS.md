# Repository Instructions

## Redmine Plugin Tests

Use the shared `redmine-plugin-test-runtime` Codex skill and read
`.redmine-test.yml` before running tests.

Before reporting that full Redmine tests are unavailable:

1. Use the declared Redmine version and shared runtime.
2. Run `scripts/setup_redmine_test_runtime.ps1` when the runtime, plugin link,
   or dependencies are missing.
3. Run focused tests during development and the complete plugin suite before
   release, handoff, or declaring work complete.
4. Apply pending test database migrations unless intentionally skipped for a
   known-current database.
5. Report exact runs, assertions, failures, errors, and skips.

Do not create or commit a Redmine checkout, portable Ruby, bundled gems,
SQLite databases, logs, or temporary runtime files in this repository.
