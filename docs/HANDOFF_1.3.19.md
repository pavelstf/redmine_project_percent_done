# Handoff: Project Percent Done 1.3.19

## Status

`production-approved` on 2026-10-11.

This release extends `ProjectPercentDone::PublicApi::V1` with optional
issue-level evidence for Project Progress History while preserving the default
backward-compatible result shape.

## Scope

- Added optional `include_evidence: true` support to
  `ProjectPercentDone::PublicApi::V1.calculate`.
- Default `calculate(:project => project)` remains issue-row-free and backward
  compatible.
- Evidence mode returns the agreed result shape with:
  - project-level progress fields;
  - grouped `metrics`;
  - `provider_metadata` including `evidence_schema_version = "1.0"`;
  - scalar `issue_evidence` rows suitable for Project Progress History
    persistence.
- Bumped plugin version to `1.3.19`.
- Added public API documentation and regression coverage.

## Package Evidence

- Source branch: `main`.
- Release commit: `99db8af`.
- Release tag: `v1.3.19`.
- Staging package:
  `release_packages/redmine_project_percent_done-1.3.19-staging-20261011-evidence-api.zip`
  - SHA-256:
    `E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11`
  - size: `338725` bytes
  - archive root: `redmine_project_percent_done/`
- Production package:
  `release_packages/redmine_project_percent_done-1.3.19-production-20261011-evidence-api.zip`
  - SHA-256:
    `E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11`
  - size: `338725` bytes
  - byte-for-byte identical to the staging-approved package.

## Validation

- Focused Public API V1 test passed:
  `18 runs`, `172 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed before and after the version bump:
  `153 runs`, `867 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Staging validation passed on 2026-10-11:
  - UI smoke checks passed.
  - Project Progress History evidence write validation persisted issue rows.
  - Recent staging snapshots confirmed `source_version=1.3.19`,
    `evidence_schema=1.0`, and issue evidence rows.
- Production validation passed on 2026-10-11:
  - Production install script ended with
    `SUCCESS: PPD 1.3.19 and PPH 0.2.2 installed on production`.
  - UI smoke checks passed with no observed HTTP 500 errors.
  - Project Progress History production Run ID `84` created `54` daily
    operational snapshots with `0` failed or unavailable.
  - Production DB verification confirmed snapshot IDs `2249` through `2258`
    include `source_version=1.3.19`, `evidence_schema=1.0`, and issue rows.

## Release State

- Final state: `production-approved`.
- Branch and tag were pushed to GitHub.
- Local `release_packages/` ZIP artifacts remain intentionally untracked.

## Continuation Notes

- Current plugin ID and folder are both `redmine_project_percent_done`.
- Project Percent Done remains the owner of live/current Project % Done
  calculation.
- Project Progress History consumes this plugin through the public API only.
- The `2026-10-11` weekly official timeline row may show `missing` on
  2026-10-11 because the daily operational snapshot exists but weekly official
  promotion is due on the next capture day.
