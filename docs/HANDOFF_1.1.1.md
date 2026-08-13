# Handoff: Project Percent Done 1.1.1

Date: 2026-07-10
Updated: 2026-07-15

## Summary

Version `1.1.1` is a UX-only patch that adds localized help icons to the
Administration plugin settings UI.

## Behavior

- Every setting in `Administration → Plugins → Redmine Project Percent Done →
  Configure` has a compact help icon.
- Help text is available in English and Bulgarian.
- Help icons use custom tooltips through `data-tooltip`, not native `title`,
  preventing duplicate tooltip display.
- Tooltips support mouse hover, keyboard focus, tap/click, Escape, resize, and
  scroll dismissal.

## Compatibility

- Public API V1 remains unchanged.
- Calculation behavior remains unchanged.
- REST behavior remains unchanged.
- `ProjectPercentDone::ALGORITHM_VERSION` remains `1.0`.
- No database migrations were added.

## Deployment Notes

The patch adds plugin stylesheet assets under:

```text
assets/stylesheets/project_percent_done.css
```

Staging deployment should copy plugin assets to:

```text
public/plugin_assets/redmine_project_percent_done/stylesheets
```

Use the generated `1.1.1` staging runbook for SuperHosting/cPanel staging.

Package:

```text
redmine_project_percent_done-1.1.1-staging-20260710.zip
```

SHA-256:

```text
A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388
```

Staging was confirmed OK by the user on 2026-07-10.

Production package:

```text
redmine_project_percent_done-1.1.1-production-20260710.zip
```

The Production package is a byte-for-byte copy of the accepted Staging package
and has the same SHA-256:

```text
A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388
```

Use `docs/PRODUCTION_RUNBOOK_1.1.1.md` for Production deployment.

## Release State

Version `1.1.1` is production-approved.

The user confirmed on 2026-07-15 that version `1.1.1` is installed on both
GCR staging and GCR production and everything works as expected.
