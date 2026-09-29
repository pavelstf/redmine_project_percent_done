# Progress History Split Handover

## Status

Planning handover for splitting the Progress History functionality out of
`redmine_project_percent_done` into a separate Redmine plugin:
`redmine_project_progress_history`.

Current production baseline:

- `redmine_project_percent_done` version `1.3.17`
- release commit: `2c7c56c Release project percent done 1.3.17`
- remote tag: `v1.3.17`
- production state: `production-approved` on 2026-09-29

New project repository:

- `https://github.com/pavelstf/redmine_project_progress_history.git`

This document is the cross-project handover for both development streams:

- Project Percent Done: `redmine_project_percent_done`
- Project Progress History: `redmine_project_progress_history`

## Execution Tracker

Use this tracker as the shared process state until the two plugins have their
own project-specific trackers.

| Step | Status | Notes |
|---|---|---|
| Approve split direction | Done | Project Percent Done remains live progress owner; Project Progress History becomes history owner. |
| Approve safe first-release strategy | Done | Use `Safe Adoption First`; no destructive migration or table rename in the first split release. |
| Create cross-project handover docs | Done | `PROGRESS_HISTORY_SPLIT_HANDOVER.md` and `PROGRESS_HISTORY_PROVIDER_HANDOFF.md` prepared in the Project Percent Done repo. |
| Commit and push handover docs | Done | Pushed to `main`; no release tag required for documentation-only handover. |
| Create separate Project Progress History project | Done | GitHub repo created: `https://github.com/pavelstf/redmine_project_progress_history.git`; plugin id: `redmine_project_progress_history`. |
| Phase 0 inventory/design | Pending | Inventory all history-related code before implementation. |
| Approve detailed split plan | Pending | Must happen after inventory, before moving/scaffolding behavior. |
| Phase 1 scaffold/provider API | Pending | New plugin skeleton and generic provider registry/API. |
| Phase 2 adopt legacy history behavior | Pending | New plugin adopts history behavior using legacy tables. |
| Phase 3 Project Percent Done coexistence guard | Pending | Disable/delegate old history surface when new plugin owns history. |
| Staging validation | Pending | Prove no data loss, no double writes, no duplicate tabs. |
| Production closeout | Pending | Packages, install scripts, approvals, commits/tags per release rules. |

## Strategic Goal

Separate live progress calculation from historical progress ownership.

`redmine_project_percent_done` remains the source of truth for the current
Project % Done value and exposes it through its stable Public API V1.

`redmine_project_progress_history` becomes the owner of persistent historical
progress:

- snapshots;
- history tab/page;
- charts and timeline;
- cron collection;
- retention;
- forecasts;
- monthly status, digest, and notifications;
- history settings;
- diagnostics related to historical collection.

The two plugins must integrate through APIs rather than shared calculation
internals.

## Approved Architecture Decisions

- New plugin name: `redmine_project_progress_history`.
- Use a generic provider registry/API in the history plugin.
- Project Percent Done is the first provider through an adapter around
  `ProjectPercentDone::PublicApi::V1`.
- The first split release follows `Safe Adoption First`.
- The first split release uses the existing legacy history tables without table
  rename.
- Destructive migrations are forbidden in the first split release.
- Production history preservation is mandatory. Zero data loss is a hard
  requirement.
- The new plugin initially preserves the existing history tab/UX behavior as
  closely as possible.
- Project Percent Done must auto-disable or delegate its legacy history surface
  when Project Progress History is installed and enabled.
- The two plugins must not both write snapshots for the same provider/project
  at the same time.

## Non-Goals For The First Split Release

- Do not rename history tables to `project_progress_history_*`.
- Do not drop legacy history tables.
- Do not backfill or reconstruct periods before historical collection was
  enabled.
- Do not redesign the history UI beyond what is needed for ownership transfer.
- Do not change Project Percent Done calculation semantics.
- Do not break `ProjectPercentDone::PublicApi::V1`.
- Do not make Project Percent Done depend on the history plugin for live
  calculation.

## Plugin Responsibilities

| Area | Project Percent Done | Project Progress History |
|---|---|---|
| Current progress calculation | Owns | Consumes through provider API |
| Project Percent Done Public API V1 | Owns | Consumes through adapter |
| Provider registry | Registers or exposes first provider | Owns generic provider registry contract |
| Snapshot storage | Legacy compatibility only during transition | Owns runtime history storage |
| History tab/page | Legacy only; delegated/disabled when new plugin owns history | Owns |
| Charts/timeline | Moves out | Owns |
| Cron collection | Legacy only; disabled/delegated when new plugin owns history | Owns |
| Retention | Moves out | Owns |
| Forecast/monthly status/digest/notifier | Moves out | Owns |
| History settings | Legacy only; delegated/disabled when new plugin owns history | Owns |
| Other providers | No generic provider registry ownership | Supports future providers |

## API Layers

### Project Percent Done Public API

Existing API:

```ruby
ProjectPercentDone::PublicApi::V1.calculate(:project => project)
```

Purpose:

- returns the current project-wide progress aggregate;
- exposes no issue rows or issue IDs;
- keeps calculation semantics owned by Project Percent Done;
- remains stable for existing integrations.

### Project Progress History Provider API

New API owned by `redmine_project_progress_history`.

Purpose:

- defines how history providers register themselves;
- lets the history plugin ask a provider for current metrics;
- supports future providers beyond Project Percent Done;
- records provider metadata in snapshots.

Initial provider metadata should include:

- `provider_id`;
- provider display name;
- provider contract version;
- source plugin id and version;
- calculation or algorithm version when available;
- supported metric keys;
- progress availability and warning codes.

Initial Project Percent Done provider adapter should read from:

```ruby
ProjectPercentDone::PublicApi::V1.capabilities
ProjectPercentDone::PublicApi::V1.calculate(:project => project)
```

## Storage Strategy

First release: `Safe Adoption First`.

The new history plugin adopts the existing legacy tables in-place. This avoids
data movement in the first production rollout and protects accumulated history.

The current legacy schema is allowed to keep its existing names during this
phase, even when the runtime owner becomes `redmine_project_progress_history`.

Future release: optional `Clean Schema Split`.

Only after the new plugin is production-approved, consider copying or renaming
legacy tables to `project_progress_history_*` tables. That future phase must
have its own migration plan, backup plan, verification queries, rollback plan,
and staging approval.

## Coexistence Rules

Supported runtime states:

- Only Project Percent Done installed:
  legacy history behavior remains available as in version `1.3.17`.
- Both plugins installed and Project Progress History enabled:
  Project Progress History owns history UI, settings, cron, diagnostics, and
  snapshot writes.
- Both plugins installed but Project Progress History disabled:
  behavior must be explicit and tested. Prefer no automatic double writes.

Hard rules:

- Never allow duplicate cron writes from both plugins.
- Never show duplicate history tabs for the same project.
- Never let settings from both plugins control the same history behavior at the
  same time without a clear precedence rule.
- Never run destructive migrations as part of the first split release.

## Phased Plan

### Phase 0 - Inventory And Design

No code changes.

Inventory all history-related surfaces in the existing plugin:

- Ruby modules/classes;
- controllers;
- routes;
- views and partials;
- helpers;
- assets;
- settings;
- database migrations and table ownership;
- rake tasks and cron commands;
- tests;
- locale keys;
- docs and runbooks.

Classify each item:

- stays in `redmine_project_percent_done`;
- moves to `redmine_project_progress_history`;
- becomes provider/API boundary;
- remains as legacy compatibility/deprecation.

### Phase 1 - Scaffold New Plugin And Provider API

Create `redmine_project_progress_history`.

Add:

- plugin registration;
- generic provider registry;
- provider capability/result objects;
- settings skeleton;
- admin settings skeleton;
- cron command skeleton;
- test skeleton;
- docs describing the provider contract.

No production history ownership transfer yet.

### Phase 2 - Clone And Adopt History Behavior

Move or clone current history behavior into the new plugin while preserving the
existing UX and legacy table names.

The new plugin should own:

- snapshot collection;
- history page;
- charts/timeline;
- retention;
- diagnostics;
- monthly status/digest/notifier;
- forecast logic.

Project Percent Done provider adapter supplies current progress metrics through
the approved API path.

### Phase 3 - Coexistence Guard In Project Percent Done

Add compatibility behavior in `redmine_project_percent_done`:

- detect `redmine_project_progress_history`;
- disable/delegate legacy history menu when the new plugin owns history;
- disable/delegate legacy history cron/settings paths when needed;
- show clear admin guidance instead of conflicting controls.

The live Project % Done details page and Public API V1 remain available.

### Phase 4 - Staging Validation

Validate both plugin states:

- Project Percent Done alone still works.
- Both plugins installed with new history plugin enabled:
  - only one history tab;
  - only one cron writer;
  - existing snapshots visible;
  - no data loss;
  - settings precedence is clear;
  - provider API resolves Project Percent Done metrics.

Validation must include snapshot counts before/after install and cron dry-run or
preview checks before any production write path is trusted.

### Phase 5 - Production-Safe Closeout

Use staging-approved packages only.

For each plugin package:

- record SHA-256 and size;
- include copy/paste install/update script;
- include rollback script;
- record production confirmation;
- tag releases only after approval.

### Future Phase - Clean Schema Split

Optional, post-approval only.

Possible goal:

- introduce `project_progress_history_*` tables;
- copy and verify all legacy rows;
- switch read/write paths;
- preserve rollback route;
- deprecate old table names.

This is intentionally not part of the first split release.

## Risk Register

- Double writes:
  both plugins could collect snapshots. Must be blocked by coexistence guard and
  tested cron ownership.
- Duplicate menu tabs:
  both plugins could add history tabs. Must be blocked by menu guards.
- Settings drift:
  two admin panels could configure conflicting retention/visibility/collection
  settings. New plugin ownership and old plugin delegation must be explicit.
- Table ownership confusion:
  first release uses legacy names while ownership moves. Docs and code comments
  must make this intentional.
- Rollback:
  plugin rollback must not destroy or rewrite snapshot rows.
- Provider API versioning:
  snapshots must record provider id and versions so future providers can
  coexist.
- Project visibility:
  history visibility settings must remain explicit and tested.
- Existing production data:
  any operation touching historical rows must include count comparisons and
  backup guidance.

## Testing Strategy

Use the shared Redmine 6.1.2 test runtime.

Minimum test groups:

- provider registry unit tests;
- Project Percent Done provider adapter tests;
- snapshot collector tests using provider result fixtures;
- history page rendering tests;
- settings ownership/coexistence tests;
- cron command tests proving only one writer owns collection;
- migration tests proving first release does not drop or rename legacy tables;
- rollback-safe tests where existing snapshots remain readable.

Before declaring a release complete:

- run focused tests for changed areas;
- run the complete plugin suites for all affected plugins;
- record exact runs/assertions/failures/errors/skips.

## New Project Bootstrap Prompt

Use this when creating the new project/chat:

```text
I want to create a new Redmine plugin project:
redmine_project_progress_history

This plugin is being split out from:
C:\Codex Projects\Project Percent Done Plugin

Read the handover first:
- docs/PROGRESS_HISTORY_SPLIT_HANDOVER.md
- docs/PROGRESS_HISTORY_PROVIDER_HANDOFF.md
- docs/PUBLIC_API_V1.md
- docs/HISTORICAL_PROGRESS_SNAPSHOTS_SPEC.md
- docs/HANDOFF_1.3.17.md

Do not start by writing production code. First make an inventory and a phased
implementation plan.

Approved architecture:
- Project Percent Done remains the source of truth for current project progress.
- Project Progress History owns snapshots, history UI, cron, retention,
  forecast, monthly status/digest/notifier, settings, and diagnostics.
- The new plugin must define a generic provider registry/API.
- Project Percent Done is the first provider through
  ProjectPercentDone::PublicApi::V1.
- First release is Safe Adoption First.
- First release uses legacy history tables without renaming them.
- Destructive migrations are forbidden in the first release.
- Zero data loss is mandatory.
- Coexistence must prevent double writes, duplicate menu tabs, and conflicting
  settings.

When preparing any installable package, always include the concrete copy/paste
install/update script in the same response.
```

## Project Percent Done Follow-Up Prompt

Use this when continuing work in the existing plugin:

```text
Continue work in:
C:\Codex Projects\Project Percent Done Plugin

Current production baseline:
- redmine_project_percent_done 1.3.17
- release commit 2c7c56c
- tag v1.3.17
- production-approved on 2026-09-29

Read:
- AGENTS.md
- docs/PROGRESS_HISTORY_SPLIT_HANDOVER.md
- docs/PROGRESS_HISTORY_PROVIDER_HANDOFF.md
- docs/PUBLIC_API_V1.md
- docs/HANDOFF_1.3.17.md

Goal:
Prepare Project Percent Done to become the first provider for
redmine_project_progress_history and to delegate/disable legacy history behavior
when the new plugin is installed and enabled.

Do not change calculation semantics or break ProjectPercentDone::PublicApi::V1.
Do not make destructive migrations.
Do not package without also providing a concrete copy/paste install/update
script.
```
