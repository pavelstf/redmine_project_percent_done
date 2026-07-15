# Staging Acceptance: Project Percent Done 1.1.1

Date: 2026-07-10

Environment: GCR Redmine staging (`https://www.redminestaging.gcr.bg`)

Package:
`redmine_project_percent_done-1.1.1-staging-20260710.zip`

SHA-256:
`A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388`

## Status

**PASS.**

The user confirmed that staging validation is OK. Version `1.1.1` is accepted
for Production promotion.

## Scope

Version `1.1.1` is a UX-only patch over `1.1.0`:

- adds compact help icons to every Administration plugin setting;
- adds localized English and Bulgarian help text;
- follows the Budget Risk Monitor / Risk Monitor Pro custom tooltip UX;
- avoids native `title` help tooltips, preventing duplicate tooltip display;
- adds one stylesheet asset:
  `assets/stylesheets/project_percent_done.css`.

## Compatibility

- Public API V1 remains unchanged.
- Calculation behavior remains unchanged.
- REST behavior remains unchanged.
- `ProjectPercentDone::ALGORITHM_VERSION` remains `1.0`.
- No database migrations were added.

## Production Promotion

Production package:
`redmine_project_percent_done-1.1.1-production-20260710.zip`

The Production package is a byte-for-byte copy of the accepted Staging package.
Both packages have SHA-256:
`A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388`.

## Production Status

**PASS.**

The user confirmed on 2026-07-15 that version `1.1.1` is installed and working
as expected on both GCR staging and GCR production.
