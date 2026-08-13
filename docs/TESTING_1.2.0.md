# Testing Log: Project Percent Done 1.2.0

## Runtime

- Redmine: 6.1.2
- Shared runtime: `C:\RedmineTestRuntimes\redmine-6.1.2`
- Plugin runtime declaration: `.redmine-test.yml`
- Test database migration `001` applied successfully.

The standard rake wrapper was repaired with the shared runtime setup script,
but Rails 7.2's extensionless `rails` child process selected the system Ruby on
Windows. Tests were therefore executed with the runtime's pinned Ruby and
Bundler directly, loading each plugin test file in the declared Redmine runtime.

## Focused Results

- Plan metrics, forecast, timeline, settings validation, and collector combined:
  20 runs, 78 assertions, 0 failures, 0 errors, 0 skips.
- Timeline includes explicit `planned_not_started`, `not_observed`, and
  pre-first-snapshot `disabled` state coverage.
- Plan metrics cover valid plans, future starts, observed date changes,
  single-boundary classification, and reported-time buckets.
- Forecast coverage includes positive projection, minimum/consecutive sample
  guards, gaps, and not-yet-started plans.
- Subject renderer, including the blank-legacy run-level digest default: 4 runs,
  8 assertions, 0 failures, 0 errors, 0 skips.
- Settings validator: 3 runs, 7 assertions, 0 failures, 0 errors, 0 skips.
- Snapshot collector: 5 runs, 20 assertions, 0 failures, 0 errors, 0 skips.
- Project controller: 3 runs, 10 assertions, 0 failures, 0 errors, 0 skips.
- Notifier: 3 runs, 10 assertions, 0 failures, 0 errors, 0 skips.
- Admin controller: 2 runs, 8 assertions, 0 failures, 0 errors, 0 skips.
- Settings controller, including dynamic project-type values, numeric and subject
  legacy defaults, chart/email visibility, non-nested diagnostic actions, and a
  real successful settings POST: 7 runs, 36 assertions, 0 failures, 0 errors, 0 skips.
- Project selector: 3 runs, 9 assertions; settings validator: 5 runs, 13
  assertions. Both cover single-value list support and non-list rejection.
- Dedicated history route/controller rendering: controller 5 runs, 25
  assertions. Calculation details exclude history, history controls target the
  new route, and the empty official-history notice is rendered.
- Project selector 5 runs, 13 assertions and collector 6 runs, 23 assertions;
  untracked closed projects are skipped while tracked closed projects remain
  eligible for state markers.
- Coherent staging demo generator: 3 runs, 59 assertions. Coverage verifies six
  phase issues, 200 estimated hours, 132 real time-entry hours, a 60% live and
  latest result, estimate coverage, plan-boundary hour totals, issue-weight
  aggregation for every active snapshot, cleanup, and idempotent reseeding. It
  also verifies migration from a normal `admin` run in the dedicated demo
  project and refusal when the protected project identity is changed.
- Production shadow visibility gate: settings 4 runs, 34 assertions; project
  controller 8 runs, 35 assertions; overview hook 1 run, 2 assertions. Coverage
  verifies hidden default, invalid-value fallback, administrator-only visibility,
  project-access visibility, direct history URL protection, and hook/menu link
  suppression unless history display is explicitly allowed.

## Full Suite

- Command strategy: all `test/**/*_test.rb` files loaded in one process with
  pinned Ruby and Bundler from the shared runtime.
- Result: **88 runs, 430 assertions, 0 failures, 0 errors, 0 skips**.
- Final seed: `57184`.
- Final test execution time: 13.089047 seconds.
- Migration `001` was reverted and reapplied successfully against the shared
  test database before the focused and full green suites.

## Static and UI Checks

- Ruby syntax: all `app`, `lib`, `db`, and `test` Ruby files passed.
- ERB syntax: all plugin ERB templates compiled successfully.
- YAML: all locale files loaded successfully.
- EN/BG parity: 235 plugin keys checked with matching interpolation placeholders.
- `git diff --check`: passed.
- Real Redmine server: test environment started and `/login` returned HTTP 200.
- Controller render coverage verified both settings and project history pages.
- Automated browser screenshots remain a staging QA item: the local Codex
  runtime had no `npx`, and its bundled `playwright` package lacked
  `playwright-core`. No runtime dependency was downloaded solely for this check.
