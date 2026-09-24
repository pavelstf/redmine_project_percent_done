# Handoff: Project Percent Done 1.3.15

## Status

`production-approved` on 2026-09-24.

This is a CSV hardening and CSV usability release for Project Percent Done. It
was built after `1.3.14` production approval and keeps calculation semantics,
the public API contract, and the calculation algorithm version unchanged.

Staging was approved by the user on 2026-09-24. Production was approved by the
user on 2026-09-24 after manual checks and production log review.

## Scope

- Escaped formula-like string values in included and not-included diagnostic
  CSV exports by prefixing fields that begin with `=`, `+`, `-`, or `@`.
- Updated included and not-included diagnostic CSV exports to follow the active
  table filters.
- Added sanitized filter suffixes to diagnostic CSV filenames when a quick,
  status, secondary, or search filter is active.
- Kept unfiltered CSV filename shape backward-compatible.
- Added `data-ppd-csv-*` wiring so the browser CSV links track the current
  visible filter state.
- Bumped plugin version to `1.3.15`.
- Public API V1 documentation now reports plugin release `1.3.15`; public
  contract remains `1.0`, historical contract remains `1.0`, and algorithm
  remains `1.1`.
- Recorded the reusable CSV filename/filter rule in the
  `redmine-plugin-engineering-practices` skill and mirrored it in the local
  `Codex-Skills` source.

## Package Evidence

- Staging package:
  `release_packages/redmine_project_percent_done-1.3.15-staging-20260924.zip`
  - SHA-256:
    `340E0401F82299A36852BE856A3B7FA547D022A23FF5AFD7FE51EDF364416F8C`
  - size: `299417` bytes
  - archive root: `redmine_project_percent_done/`
- Package inspection confirmed:
  - `redmine_project_percent_done/lib/project_percent_done.rb` contains
    `PLUGIN_VERSION = '1.3.15'`;
  - no `.git`, `.agents`, `.codex`, `tmp`, or `release_packages` entries are
    present in the archive.
- Production package:
  `release_packages/redmine_project_percent_done-1.3.15-production-20260924.zip`
  - SHA-256:
    `340E0401F82299A36852BE856A3B7FA547D022A23FF5AFD7FE51EDF364416F8C`
  - size: `299417` bytes
  - byte-for-byte identical to the staging-approved package.

## Validation

- Ruby syntax checks passed for:
  - `lib/project_percent_done.rb`;
  - `app/controllers/project_percent_done_controller.rb`;
  - `test/functional/project_percent_done_controller_test.rb`.
- Focused controller test passed:
  `16 runs`, `119 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused Public API V1 test passed:
  `16 runs`, `128 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `140 runs`, `757 assertions`, `0 failures`, `0 errors`, `0 skips`.
- `git diff --check` passed with expected Windows LF/CRLF warnings only.
- Staging was confirmed OK by the user on 2026-09-24 after installing
  `1.3.15`.
- Production was confirmed OK by the user on 2026-09-24 after installing
  `1.3.15`.
- Production log review showed normal `ProjectPercentDoneController#show`
  HTML/CSV requests and no plugin-related 500s, exceptions, or stack traces in
  the provided output.

## Release State

- Final state: `production-approved`.
- Branch at closeout: `main`.
- Release tag requested: `v1.3.15`.
- Production package bytes are identical to the user-approved staging package.
- Local `release_packages/` ZIP artifacts remain intentionally untracked.

## Remaining Backlog

- `QAPPD1312-002`: decide whether aggregate calculations may include
  private/invisible issues, or whether aggregates should be scoped to the
  current user's issue visibility. This is a product/permission design decision.
- Optional future hardening: extend CSV formula neutralization to tab/CR-prefixed
  strings if the same broader rule from Project Contribution is desired here.

## Continuation Notes

- Do not confuse this plugin with Project Contribution or Project TimeShift.
  Current plugin ID and folder are both `redmine_project_percent_done`.
- If a new installable package is prepared in a future chat, always include the
  concrete copy/paste install/update script with the package handoff.
- CSV exports that are affected by UI or server filters must export the same
  filtered row set and include deterministic sanitized filter suffixes in the
  downloaded filename.
