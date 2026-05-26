# Changelog

All notable changes to this project are documented in this file.

The format follows the spirit of Keep a Changelog, and this project uses semantic versioning.

## [1.0.0] - 2026-05-26

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

- Version 1.0.0 has no database migrations.
