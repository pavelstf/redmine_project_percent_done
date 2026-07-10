# Changelog

All notable changes to this project are documented in this file.

The format follows the spirit of Keep a Changelog, and this project uses semantic versioning.

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
