# Handoff: Project Percent Done 1.2.0

## Status

`production-approved` on 2026-07-21. The user confirmed the production
installation is OK, automatic collection and digest email are configured, and
project history is currently visible only to administrators.

## Deliverables

- Package: `redmine_project_percent_done-1.2.0-staging-20260721-r18.zip`
- Size: `213171` bytes
- SHA-256: `C16800F8B9B5193F54C158CFD64711FD4FF171312DE7F7380138E97DD65947A5`
- Production package: `redmine_project_percent_done-1.2.0-production-20260721.zip`
- Production package is byte-for-byte identical to the staging-approved `r18`
  package and has the same size/SHA-256.
- Archive root: `redmine_project_percent_done/`
- Runbook: `docs/STAGING_RUNBOOK_1.2.0.md`
- Production runbook: `docs/PRODUCTION_RUNBOOK_1.2.0.md`
- Specification: `docs/HISTORICAL_PROGRESS_SNAPSHOTS_SPEC.md`
- Test evidence: `docs/TESTING_1.2.0.md`
- Source branch: `codex/project-percent-done-history-v1`

Release-only handoff and staging runbook files are not embedded in the ZIP so
their package checksum metadata remains stable.

## Implemented V1

- Optional daily operational and weekly official snapshots, off by default.
- Single-value or multi-value list project type scope, active/state handling, missed-Sunday recovery,
  provenance, locking, idempotency, and per-project transaction isolation.
- Indefinite aggregate history and configurable issue-detail retention/grace.
- Admin settings/help, validation, diagnostics, preview, manual capture, test
  email, cleanup dry-run, and guarded project purge.
- Configurable TO/BCC email reports and safe subject placeholders, with one
  run-level digest subject containing execution date, period end, snapshot type,
  and status by default.
- Dedicated progress-history project tab with a gap-aware graph, paginated
  table, rolling/calendar/fiscal periods, exact
  values, change modes, and browser-local preferences.
- Aggregate access is now gated by configurable history visibility: hidden by
  default for production shadow collection, administrators only, or project
  access. Historical issue rows and purge are system-administrator-only.
- Optional observed start/end custom dates, calendar plan phases, plan-change
  history, time-entry boundary anomalies, explicit pre-collection gaps, and
  guarded shadow forecasts.
- Protected staging-only demo task that seeds and cleans a dedicated private
  project with representative chart, table, gap, state, plan, and forecast data.
  Its six project phases contain 200 estimated hours and 132 real time entries;
  the issue weights produce a consistent 60% live and latest snapshot result.
- Project Risk-style Administration cron guidance with generated rake/full
  commands, detected runtime context, schedule explanation, and copy controls.

CSV and history REST API remain deferred until the model is stable, as agreed.

## Verification

- Full Redmine 6.1.2 plugin suite: **88 runs, 430 assertions, 0 failures, 0
  errors, 0 skips**.
- Staging feedback fixed: project-type values load immediately when the custom
  field changes; blank legacy numeric values render as defaults; and chart/email
  settings follow the history switch; blank legacy subject settings render the
  run-level digest default; diagnostic actions no longer create nested forms that
  break Apply; project-type selection accepts both single-value and multi-value
  list fields; history is separated from calculation details; untracked closed
  projects are excluded from initial collection; the demo generator satisfies
  required project custom fields; cron guidance is generated in Administration
  when history is enabled, with the daily example set to 00:05.
- The user confirmed successful `r17` installation and protected demo seeding
  on staging: 14 project snapshots, 66 issue snapshots, 15 collection runs,
  60% live progress, 200 estimated hours, and 132 reported hours.
- New `r18` package adds production shadow visibility gating and is locally
  verified by the full suite: 88 runs, 430 assertions, 0 failures.
- The user confirmed successful production installation on 2026-07-21.
- The user configured automatic data collection and digest email on production.
- Production history visibility is currently set to administrators only.
- Ruby, ERB, YAML, EN/BG placeholder parity, and whitespace checks passed.
- ZIP root and embedded plugin version verified.
- Local Redmine test server reached HTTP 200 and controller render tests cover
  settings/history pages and regular-user privacy.

Automated screenshots were not produced locally because the available Codex
runtime had no `npx` and its bundled `playwright` lacked `playwright-core`.
Desktop/mobile visual evidence is therefore explicitly included in the staging
acceptance checklist rather than claimed as completed.

## Deployment Notes

- Migration `001` creates three plugin-owned tables.
- Ordinary rollback restores the previous plugin directory but retains history
  tables; destructive database rollback requires the pre-deployment DB backup.
- Copy plugin stylesheets to `public/plugin_assets` on GCR shared hosting.
- Daily cPanel cron is configured on production.
- Do not enable collection until a valid list project type field and at
  least one current value are selected.

## Next Session

- Observe the first production cron runs and digest emails, especially the first
  real Sunday official promotion.
- Keep production history restricted to administrators until enough real data
  has been reviewed.
- Keep CSV and history REST API deferred until the snapshot model has completed
  its agreed stabilization period.
- Discuss the still-open aggregate project-history deletion policy before
  implementing automatic aggregate retention.
