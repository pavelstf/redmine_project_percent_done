# Handoff: Project Percent Done 1.3.6

## Status

`production-approved` on 2026-08-13.

The 1.3.6 patch refines the dashboard snapshot freshness display after the
initial 1.3.5 production rollout showed that a single "last snapshot" line was
ambiguous when the latest row was an operational backup rather than an official
period snapshot.

## Scope

- The project overview and project sidebar widgets now display freshness as
  separate rows:
  - latest operational snapshot;
  - latest official weekly snapshot;
  - latest official monthly snapshot.
- If no official monthly snapshot exists yet, the dashboard explicitly says so.
- The dashboard hook still skips snapshot lookup safely if the history table is
  unavailable during a code-before-migrations deployment window.
- No database schema or historical data changes were introduced in 1.3.6.
- Public API contract remains `1.0`; only the plugin release version changed.

## Package Evidence

- Staging package:
  `release_packages/redmine_project_percent_done-1.3.6-staging-20260813.zip`
- Production package:
  `release_packages/redmine_project_percent_done-1.3.6-production-20260813.zip`
- SHA-256 for both packages:
  `EFCE4F4FE001C2645E53A6FE348319BBF77CF2E513E639B3FED21B074B11B9EF`
- Size for both packages: `273075` bytes
- Archive root: `redmine_project_percent_done/`
- Production package is a byte-for-byte copy of the staging package.

## Validation

- Focused hook/dashboard tests passed:
  `113 runs`, `544 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `113 runs`, `544 assertions`, `0 failures`, `0 errors`, `0 skips`.
- `git diff --check` passed with only expected Windows LF/CRLF warnings.
- Staging installation was confirmed OK by the user.
- Production installation was requested from the staging-approved package, and
  the user then confirmed the work was ready for repository closeout.

## Notes For Next Session

- Release ZIP files are intentionally ignored by Git in this repository.
- The current branch is `codex/project-percent-done-history-v1`.
- The next likely cleanup item is to decide whether historical dashboard
  visibility should eventually be configurable separately from the main history
  page visibility. The current behavior shows freshness rows in the existing
  dashboard widgets when snapshot history exists.
