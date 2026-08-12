# Changelog

All notable changes to this project are documented in this file.

The format follows the spirit of Keep a Changelog, and this project uses semantic versioning.

## [1.3.0] - 2026-08-12

### Added

- Monthly official project progress snapshots are now captured automatically
  whenever historical collection is enabled.
- Weekly and monthly official snapshots can coexist for the same `period_end`
  by using the new snapshot `period_type`.
- Historical in-process Public API methods under
  `ProjectPercentDone::PublicApi::V1`:
  - `history_capabilities`
  - `latest_official_snapshot`
  - `official_snapshot_for`
  - `official_snapshots_between`
  - `progress_at`
- Immutable historical API result objects with explicit unavailable reasons,
  including `period_not_completed` and `snapshot_missing`.
- Tests for monthly promotion, weekly/monthly coexistence, weekly UI isolation,
  forecast isolation, valid historical `0%`, and no weekly/live fallback.

### Changed

- Existing weekly history UI, timeline options, plan-change comparisons, and
  forecast calculations explicitly use weekly official snapshots only.
- Public API documentation now covers both live calculation and historical
  snapshot contracts.

### Compatibility

- Existing live calculation, REST response, and
  `ProjectPercentDone::PublicApi::V1.calculate` remain unchanged.
- Existing official history rows are migrated to `period_type = weekly`.
- Adds migration `002` to extend the plugin-owned snapshot table and uniqueness
  boundary.
- CSV and REST history exports remain deferred.

## [1.2.0] - 2026-07-16

### Added

- Optional daily operational and official weekly project progress snapshots.
- Project-type scope using a configurable single-value or multi-value list project custom field.
- Project-only or project-and-issue detail levels with age and inactive-project retention.
- Recovery of missed Sunday periods from the nearest operational snapshot within a 0-3 day tolerance.
- Gap-aware project history graph, paginated table, rolling/calendar/fiscal filters, and browser-local preferences.
- System-administrator-only historical issue details and per-project purge.
- Collection runs, diagnostics, preview, manual capture, cleanup dry-run, and test email actions.
- TO/BCC email reports, three notification levels, safe configurable subjects, disabled/recovery reporting, and delivery status.
- Daily snapshot, cleanup, and guarded project-purge rake tasks.
- English and Bulgarian help for all history settings and irreversible actions.
- Optional project start and planned end date custom fields, captured with field provenance in every snapshot.
- Calendar-day plan phases, elapsed-plan variance, and reported-time buckets before, within, and after the observed plan.
- First-observed and changed-plan markers, explicit pre-collection gaps, and guarded linear completion forecasts.
- Immediate loading of project-type values when the administrator changes the selected custom field.
- Rendering of blank or missing numeric settings with their documented defaults for legacy saved configurations.
- Chart and email settings visibility tied to the historical collection switch, with theme-resistant hidden styling.
- Run-level digest subject default with execution date, official period end, snapshot type, and run status; blank legacy subject settings receive the same default in the admin form.
- Valid settings submission restored by replacing nested diagnostic forms with independent Redmine POST actions; successful history-setting persistence now has controller coverage.
- Dedicated project history page and `Progress history` project-menu tab, keeping calculation details focused on the live result and its rationale.
- Clear no-official-snapshots notice and context-appropriate chart/change control labels on the project history page.
- Initial collection now skips old closed or archived projects that were never tracked; lightweight state markers remain for projects closed or archived after tracking began.
- Project menu entries now use Redmine's `view_project` permission, and history is also linked directly from the overview/sidebar progress block and calculation page.
- Hook-rendered overview/sidebar links now receive history availability as an explicit local, avoiding helper-context failures on project pages.
- Repeated same-day snapshot runs now keep numeric counters and finish successfully instead of recording per-project `TypeError` failures.
- Calculation and history actions now select their own Redmine project-menu items explicitly, so the active tab matches the displayed page.
- Protected staging-only demo-history rake task with preview, repeatable seed, and cleanup modes for graph, table, state, issue-detail, plan-change, anomaly, and forecast validation.
- The staging demo project now satisfies required project custom fields using defaults, allowed options, or format-appropriate synthetic values.
- Administration now shows generated daily snapshot rake and full cron commands, schedule guidance, detected runtime context, and copy controls when historical collection is enabled.
- The recommended daily collection example now runs at 00:05 (`5 0 * * *`).
- Reworked staging demo data into a coherent 60% project scenario: six phase-based issues, 200 estimated hours, 132 real time-entry hours, aligned plan dates, and project snapshots calculated from their issue-detail weights.
- The staging demo generator now safely absorbs snapshots created for its dedicated private demo project by normal admin or cron runs, while retaining strict project-name and demo-issue ownership checks.
- Historical collection visibility is now separate from collection enablement, with a default hidden mode for production shadow data collection, plus administrator-only and project-access display modes.

### Compatibility

- Existing live calculation, REST response, and Public API V1 contracts are unchanged.
- History is disabled by default.
- Adds three plugin-owned database tables through migration `001`.
- Plan dates are optional analysis inputs and never block snapshot collection.
- Forecasts are shadow indicators only; they do not change the live percentage or stored source data.
- CSV and REST history exports remain deferred.

## [1.1.1] - 2026-07-10

### Added

- Administration plugin settings now show accessible help icons for every
  setting, with concise English and Bulgarian guidance.
- Minimal settings help tooltip styling and keyboard/focus/tap behavior,
  aligned with the Budget Risk Monitor / Risk Monitor Pro help UX.

### Compatibility

- No calculation, REST, Public API V1, or Risk Monitor integration contract
  changes.
- No database migrations were added.

## [1.1.0] - 2026-07-01

### Added

- Versioned in-process public API at `ProjectPercentDone::PublicApi::V1`.
- Immutable capabilities and calculation result value objects.
- Raw and display progress values with explicit availability diagnostics.
- Eligible, estimated, unestimated, included, excluded-parent, and ignored counts.
- Estimate-presence coverage, known estimated hours, imputed weight, total
  applied weight, and known-weight percentage.
- Public API contract tests and settings normalization tests.

### Changed

- Centralized and normalized allowed calculation setting values.
- Exposed independent plugin, public contract, and calculation algorithm versions.

### Compatibility

- Existing UI and REST field names and meanings are unchanged.
- Calculation remains live, direct-project-only, and non-persistent.
- No database migrations were added.

## [1.0.2] - 2026-05-26

### Added

- Initial stable release.
- Project completion calculation based on issue `% Done`.
- Weighted calculation using issue estimates.
- Leaf issue calculation mode to avoid parent/child double counting.
- Configurable closed issue handling.
- Configurable unestimated issue handling.
- Project overview display.
- Project sidebar display.
- Optional project tab with calculation details.
- Optional REST API endpoint.
- Included and not included issue counters with filtered issue links.
- Calculation details page with formula, totals, included issue table, excluded issue table, reasons, and notes.
- Permission-aware details rendering for issue rows.
- English and Bulgarian translations.
- English fallback locale files for Redmine built-in locales.
- Summary/details calculation modes for better performance.
- Per-request memoization for project overview/sidebar rendering.

### Security

- The details page hides issue rows that are not visible to the current user.
- The UI documents that the final project percentage is calculated from all project issues, regardless of issue visibility.

### Notes

- Version 1.0.2 has no database migrations.
