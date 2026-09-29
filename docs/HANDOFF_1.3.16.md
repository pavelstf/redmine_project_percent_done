# Handoff: Project Percent Done 1.3.16

## Status

`packaged-production` on 2026-09-29.

This is a narrow CSV hardening release for Project Percent Done. It extends the
diagnostic CSV formula-neutralization rule added in `1.3.15` so that string
values beginning with tab or carriage-return characters are also prefixed before
export. Calculation semantics, Public API V1 contract, historical contract, and
calculation algorithm version are unchanged.

## Scope

- Escaped diagnostic CSV string values that begin with tab or carriage-return
  characters by prefixing them with a single quote.
- Kept the existing CSV protection for `=`, `+`, `-`, and `@` prefixes.
- Bumped plugin version to `1.3.16`.
- Public API V1 documentation now reports plugin release `1.3.16`; public
  contract remains `1.0`, historical contract remains `1.0`, and algorithm
  remains `1.1`.

## Package Evidence

- Source commit:
  `84015a3 Release project percent done 1.3.16`
- Staging package:
  `release_packages/redmine_project_percent_done-1.3.16-staging-20260929.zip`
  - SHA-256:
    `4DE7551031777FDCA8B96CA3857C54486D351B2CAF9C2E0A4589554073E5ADA2`
  - size: `268825` bytes
  - archive root: `redmine_project_percent_done/`
- Package inspection confirmed:
  - `redmine_project_percent_done/lib/project_percent_done.rb` contains
    `PLUGIN_VERSION = '1.3.16'`;
  - no `.git`, `.agents`, `.codex`, `tmp`, or `release_packages` entries are
    present in the archive.
- Production package:
  `release_packages/redmine_project_percent_done-1.3.16-production-20260929.zip`
  - SHA-256:
    `4DE7551031777FDCA8B96CA3857C54486D351B2CAF9C2E0A4589554073E5ADA2`
  - size: `268825` bytes
  - byte-for-byte identical to the staging-approved package.

## Validation

- Ruby syntax checks passed for:
  - `app/controllers/project_percent_done_controller.rb`;
  - `test/functional/project_percent_done_controller_test.rb`;
  - `test/unit/project_percent_done/public_api_v1_test.rb`.
- Focused Public API V1 test passed:
  `16 runs`, `128 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Initial parallel focused controller test hit SQLite `database is locked`
  because the Public API test was using the same shared runtime database.
- Sequential focused controller rerun passed:
  `16 runs`, `127 assertions`, `0 failures`, `0 errors`, `0 skips`.
- `git diff --check` passed with expected Windows LF/CRLF warnings only.
- Full Redmine 6.1.2 plugin suite passed:
  `140 runs`, `765 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Staging was confirmed OK by the user on 2026-09-29 after manual checks:
  version `1.3.16`, Project % Done page, included/not-included sections, CSV
  export, filtered CSV row sets and filenames, UTF-8/Cyrillic CSV handling, and
  formula-like subject escaping.
- Staging CSV formula check showed the expected quoted CSV field with doubled
  internal quotes and a leading apostrophe:
  `8289,"'=HYPERLINK(""http://example.test"");",В изчакване,0.00%,,Unestimated issue ignored by plugin setting`
- Staging log review from the provided output showed asset compilation INFO
  lines including `plugin_assets/redmine_project_percent_done`, no plugin 500s
  or stack traces, and only unrelated staging sendmail delivery errors for the
  fake `redmine-staging@example.invalid` sender.

## Release State

- Current state: `packaged-production`.
- Branch at package preparation: `main`.
- Production package bytes are identical to the user-approved staging package.
- Local `release_packages/` ZIP artifacts remain intentionally untracked.

## Remaining Backlog

- `QAPPD1312-002`: decide whether aggregate calculations may include
  private/invisible issues, or whether aggregates should be scoped to the
  current user's issue visibility. This remains a product/permission design
  decision.

## Continuation Notes

- Do not confuse this plugin with Project Contribution or Project TimeShift.
  Current plugin ID and folder are both `redmine_project_percent_done`.
- If a new installable package is prepared in a future chat, always include the
  concrete copy/paste install/update script with the package handoff.
