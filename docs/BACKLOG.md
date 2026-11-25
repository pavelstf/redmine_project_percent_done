# Project Percent Done backlog

Current as of 2026-11-25 after staging and production approval of 1.3.20 r3-text.
QA defects PPD-01..08, R-01..03 and the obsolete parent note are closed.

## PPD-N-01 — distinguish invalid hierarchy from excluded parents

- Status: deferred; future implementation, not part of the accepted 1.3.20 r2
  staging payload. Requested by the owner on 2026-11-25.
- Priority: low, diagnostic clarity. Origin: informative N-01 in
  `QA reports/QA_Report_redmine_project_percent_done_1.3.20-r2.md`.
- Current behavior: incomplete NULL lft/rgt is safely excluded, but reported
  as `parent_issue_excluded` and included in `excluded_parent_issue_count`.
  This does not change calculated progress or cause an exception.
- Proposed behavior: distinct `invalid_hierarchy` reason and a clearly defined
  counter for invalid rows, separate from genuine excluded parents. Keep the
  direct-project/global-leaf scope, eligible denominator and weighted result
  unchanged. Do not automatically repair source hierarchy.
- Coordinate summary/details, CSV, public API aggregate counters, evidence,
  EN/BG labels and fallback, help/docs and downstream PB/PPH interpretation.
  Review contract/evidence/algorithm versioning before changing public meanings;
  preserve historic snapshots and their original provenance.
- Acceptance: all three NULL combinations; mixed and invalid-only projects;
  genuine same-project/cross-project parents; summary/details/API/evidence/CSV
  counter reconciliation; Overview remains available; existing valid-data
  percentages and history unchanged. Run focused and full Redmine regressions.

## PPD-OPS-01 — verify the next scheduled PPH capture

- Status: pending observation, not an identified PPD defect. Priority: medium.
- Check the next naturally scheduled snapshot records PPD 1.3.20/algorithm 1.2,
  complete evidence and the intended Europe/Sofia target period. Existing
  snapshot #4893 predates the upgrade. Do not rewrite history or backfill merely
  to close this check. Scheduling and history belong to the PPH project.

## PPD-CSV-01 — optional extension of formula-prefix neutralization

- Status: optional, low priority; carried forward from docs/HANDOFF_1.3.17.md.
- Decide whether additional leading characters (e.g. tab/CR) need neutralizing
  if spreadsheet safety requirements expand. Review current prefix handling
  first; do not infer a confirmed vulnerability from this optional item.

## PPD-PERF-01 — representative large-project performance measurements

- Status: deferred measurement, low priority; tracked from docs/QA_1.3.20.md.
- Measure overview/details/API/evidence on representative deployed data and
  record issue count and timing. Consider persistent caching/background
  recalculation only if measurements justify it (README future enhancement).

These are future work or outstanding observations, not open release blockers.
