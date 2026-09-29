# Handoff: Project Percent Done 1.3.17

## Status

`production-approved` on 2026-09-29.

This release resolves `QAPPD1312-002` as a transparency change while preserving
the existing project-wide aggregate semantics. The Project % Done aggregate
remains a single all-project "project truth"; calculation detail rows and CSV
row exports remain limited to issues visible to the current user.

## Scope

- Added an always-visible calculation-details summary showing how many included
  and not-included issue detail rows the current user can view.
- Clarified diagnostic CSV link tooltips so users know exports include only
  issue rows visible to their account.
- Added controller coverage proving private/invisible issue rows are hidden
  from detail tables and CSV exports while the aggregate remains project-wide.
- Bumped plugin version to `1.3.17`.
- Public API V1 documentation now reports plugin release `1.3.17`; public
  contract remains `1.0`, historical contract remains `1.0`, and algorithm
  remains `1.1`.

## Package Evidence

- Source state:
  local working tree, pending release commit.
- Staging package:
  `release_packages/redmine_project_percent_done-1.3.17-staging-20260929.zip`
  - SHA-256:
    `B2453CF01EE5EF906364567E66DCD0216C4D8B0105D27133C53039FACAA5F058`
  - size: `314869` bytes
  - archive root: `redmine_project_percent_done/`
- Package inspection confirmed:
  - `redmine_project_percent_done/lib/project_percent_done.rb` contains
    `PLUGIN_VERSION = '1.3.17'`;
  - no `.git`, `.agents`, `.codex`, `tmp`, or `release_packages` entries are
    present in the archive.
- Production package:
  `release_packages/redmine_project_percent_done-1.3.17-production-20260929.zip`
  - SHA-256:
    `B2453CF01EE5EF906364567E66DCD0216C4D8B0105D27133C53039FACAA5F058`
  - size: `314869` bytes
  - byte-for-byte identical to the staging-approved package.

## Validation

- Ruby syntax checks passed for:
  - `app/controllers/project_percent_done_controller.rb`;
  - `test/functional/project_percent_done_controller_test.rb`;
  - `test/unit/project_percent_done/public_api_v1_test.rb`.
- Locale YAML load check passed for `config/locales/*.yml`.
- Focused controller test passed:
  `17 runs`, `148 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused Public API V1 test passed:
  `16 runs`, `128 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `141 runs`, `786 assertions`, `0 failures`, `0 errors`, `0 skips`.
- `git diff --check` passed with expected Windows LF/CRLF warnings only.
- Staging was confirmed OK by the user on 2026-09-29 after manual checks of the
  details page visibility summary and CSV tooltip behavior.
- Production was confirmed OK by the user on 2026-09-29 after installing
  `1.3.17`.

## Release State

- Final state: `production-approved`.
- Branch at package preparation: `main`.
- Production package bytes are identical to the user-approved staging package.
- Local `release_packages/` ZIP artifacts remain intentionally untracked.
- Release commit/tag/push are still pending explicit user request.

## Remaining Backlog

- Optional: decide whether CSV formula neutralization should be expanded beyond
  the current prefix set in any future follow-up, if new spreadsheet-safety
  requirements appear.

## Continuation Notes

- Do not confuse this plugin with Project Contribution or Project TimeShift.
  Current plugin ID and folder are both `redmine_project_percent_done`.
- If a new installable package is prepared in a future chat, always include the
  concrete copy/paste install/update script with the package handoff.
