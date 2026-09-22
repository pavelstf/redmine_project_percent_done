# Handoff: Project Percent Done 1.3.12

## Status

`production-approved` on 2026-09-16.

This release completes the Project Percent Done side of the non-progress scope
work needed before Project Contribution can add matching contribution
exclusions. Project Percent Done remains standalone and does not depend on
Project Contribution.

Handoff prepared on 2026-09-22.

## Scope

- Added `Non-progress tracker choices` with:
  - `No tracker exclusions`;
  - `All trackers`.
- Tracker-based exclusions now have an explicit scope. When scope is `none`,
  saved tracker IDs are ignored and progress scope is unchanged.
- Preserved legacy behavior for settings saved before the tracker scope key
  existed: if tracker IDs are present and `non_progress_tracker_scope` is
  absent, the effective scope is `all`.
- Added `non_progress_tracker_scope` to:
  - live REST/API metadata;
  - Public API V1 capabilities and result objects;
  - historical settings snapshots.
- Kept existing status exclusion behavior, list diagnostics, foldable detail
  sections, CSV links, and table padding from the 1.3.7-1.3.11 work.
- Bumped plugin version to `1.3.12`.

## Package Evidence

- Staging package:
  `release_packages/redmine_project_percent_done-1.3.12-staging-20260916.zip`
  - SHA-256:
    `B621DB93624D222EEE91441E01C6EDCF5C1CF1274CAB20852962385EC22EBC47`
  - size: `276834` bytes
- Production package:
  `release_packages/redmine_project_percent_done-1.3.12-production-20260916.zip`
  - SHA-256:
    `BA6E998B1A69EB3C8B2C8F7A0B5956A8FCACA238199D49FB22BB9E165B1EE563`
  - size: `276834` bytes
- Archive root: `redmine_project_percent_done/`
- The staging and production packages were built from the same source state,
  but they are separate archives and are not byte-for-byte identical.

## Validation

- Syntax checks for touched Ruby code and tests passed.
- Locale YAML parse checks passed for `config/locales/en.yml` and
  `config/locales/bg.yml`.
- ERB compile checks passed for touched settings/show/API views.
- Focused settings test passed:
  `9 runs`, `49 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused calculator test passed:
  `24 runs`, `96 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused Public API V1 test passed:
  `16 runs`, `128 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused history snapshot collector test passed:
  `10 runs`, `44 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused settings controller test passed after applying plugin migrations in
  the shared local Redmine test DB:
  `7 runs`, `60 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Focused project percent done controller test passed:
  `12 runs`, `97 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `133 runs`, `718 assertions`, `0 failures`, `0 errors`, `0 skips`.
- `git diff --check` passed with only expected Windows LF/CRLF warnings.
- Staging installation was confirmed OK by the user.
- Production installation was confirmed OK by the user.

## Git State

- Branch: `codex/project-percent-done-history-v1`
- Remote tracking branch: `origin/codex/project-percent-done-history-v1`
- Last pushed commit before this handoff file:
  `e3a29e8 Release project percent done 1.3.12`
- That commit is pushed to GitHub.
- Current local dirty state when this handoff was created:
  - this handoff file is new;
  - `release_packages/` remains untracked locally.
- Release ZIP files are intentionally ignored by `.gitignore`.
- Old untracked staging runbook scripts under `release_packages/` were not
  committed because they are unrelated local artifacts from earlier 1.3.7/1.3.8
  work.

## Operational Notes

- GCR staging Redmine root:
  `/home/gcrbgcaa/redminestaging`
- GCR staging virtualenv:
  `/home/gcrbgcaa/rubyvenv/redminestaging/3.2`
- GCR production Redmine root:
  `/home/gcrbgcaa/redmine`
- GCR production virtualenv:
  `/home/gcrbgcaa/rubyvenv/redmine612build/3.2`
- Production validation commands must run from `/home/gcrbgcaa/redmine` with
  `RAILS_ENV=production` and `bundle exec rails runner -e production ...`.
  Running `rails runner` from `~` or without the production env can incorrectly
  load development and fail on missing `listen`.

## Notes For Next Session

- Development for Project Percent Done 1.3.12 is complete for today.
- If repository archival is desired, commit this handoff file separately or amend
  it into a follow-up documentation commit.
- Project Contribution can now add matching settings such as
  `Non-contributing closed statuses` and optionally `Non-contributing trackers`
  without reading Project Percent Done internals. It should use the public
  metadata/API contract rather than a direct dependency.
- For GCR, keep Project Percent Done and Project Contribution exclusion settings
  synchronized operationally, including status `Отпаднала` and any agreed
  non-progress trackers.
