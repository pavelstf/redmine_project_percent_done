# Handoff: Project Percent Done 1.3.14

## Status

`production-approved` on 2026-09-24.

This is a focused UI polish release for Project Percent Done. It includes the
validated 1.3.13 all-excluded diagnostics fix plus the diagnostic UI refinements
requested after staging review.

Staging was approved by the user on 2026-09-24. Production was approved by the
user on 2026-09-24 after installing the production package.

## Scope

- Restyled calculation detail quick filters to follow the Project Risk
  dashboard pill/tab visual pattern:
  - rounded pill badges;
  - semantic colors;
  - active selection ring;
  - per-filter count bubbles.
- Added server-rendered quick-filter counts for included and not-included issue
  tables.
- Improved not-included combined non-progress filtering so issues excluded by
  both status and tracker appear under both quick filters.
- Extended `Subject` left alignment to historical issue detail tables.
- Kept the Project Contribution-style collapsible section pattern already in
  place for the included and not-included issue sections.
- Bumped plugin version to `1.3.14`.
- Bumped CSS cache busters to `1.3.14-r1`.

## Package Evidence

- Staging package:
  `release_packages/redmine_project_percent_done-1.3.14-staging-20260924-r2.zip`
  - SHA-256:
    `FFF1ABFA0E3DC316C8933A2363A33816FFDF5666090DAD88EC2F174420615CA2`
  - size: `287251` bytes
  - archive root: `redmine_project_percent_done/`
- Package inspection confirmed:
  - `redmine_project_percent_done/lib/project_percent_done.rb` contains
    `PLUGIN_VERSION = '1.3.14'`;
  - no `.git`, `.agents`, `.codex`, `tmp`, or `release_packages` entries are
    present in the archive.
- Production package:
  `release_packages/redmine_project_percent_done-1.3.14-production-20260924.zip`
  - SHA-256:
    `FFF1ABFA0E3DC316C8933A2363A33816FFDF5666090DAD88EC2F174420615CA2`
  - size: `287251` bytes
  - byte-for-byte identical to the staging-approved package.

## Validation

- Ruby syntax checks passed for:
  - `lib/project_percent_done.rb`;
  - `test/functional/project_percent_done_controller_test.rb`;
  - `test/unit/project_percent_done/public_api_v1_test.rb`.
- ERB compile checks passed for touched settings/show/history views.
- Locale YAML parse checks passed for `config/locales/*.yml`.
- `git diff --check` passed with expected Windows LF/CRLF warnings only.
- Redmine runtime focused tests were not run in this pass because the current
  approval policy rejected escalated access to the shared Redmine test runtime.
- Staging was confirmed OK by the user on 2026-09-24 after installing
  `1.3.14`.
- Production was confirmed OK by the user on 2026-09-24 after installing
  `1.3.14`.

## Release State

- Final state: `production-approved`.
- Branch at closeout: `main`.
- Production package bytes are identical to the user-approved staging package.

## Staging QA Focus

- Confirm included/not-included quick filters render as rounded pill badges
  with count bubbles.
- Confirm active quick filter state is visually clear.
- Confirm quick filters still filter rows correctly.
- Confirm rows excluded by both non-progress status and tracker appear under
  both quick filters.
- Confirm `Subject` remains left-aligned in:
  - included issue table;
  - not-included issue table;
  - historical issue detail table.
- Confirm no new CSS asset routing errors after upload, asset precompile, and
  Passenger restart.
