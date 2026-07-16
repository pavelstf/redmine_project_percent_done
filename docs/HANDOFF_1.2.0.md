# Handoff: Project Percent Done 1.2.0

## Status

`staging-approved` on 2026-07-16. Production promotion has not started.

## Deliverables

- Package: `redmine_project_percent_done-1.2.0-staging-20260716-r17.zip`
- Size: `195334` bytes
- SHA-256: `4500639E28B49402982B4E256951B9BD09A88094DF2860FDFB1C4D3657ADA43F`
- Archive root: `redmine_project_percent_done/`
- Runbook: `docs/STAGING_RUNBOOK_1.2.0.md`
- Specification: `docs/HISTORICAL_PROGRESS_SNAPSHOTS_SPEC.md`
- Test evidence: `docs/TESTING_1.2.0.md`
- Source branch: `codex/project-percent-done-history-v1`

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
- Aggregate access follows current project visibility; historical issue rows
  and purge are system-administrator-only.
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

- Full Redmine 6.1.2 plugin suite: **85 runs, 414 assertions, 0 failures, 0
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
- Add the daily cPanel cron only after initial configuration and manual capture
  validation.
- Do not enable collection until a valid list project type field and at
  least one current value are selected.

## Next Session

- Decide whether to promote the exact staging-approved `r17` bytes to a
  production package; do not rebuild the ZIP for that promotion.
- Configure and observe the daily `5 0 * * *` cron in staging if it has not yet
  been added, including one real Sunday promotion and its digest email.
- Keep CSV and history REST API deferred until the snapshot model has completed
  its agreed stabilization period.
- Discuss the still-open aggregate project-history deletion policy before
  implementing automatic aggregate retention.
