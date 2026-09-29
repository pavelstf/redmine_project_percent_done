# Project Percent Done Provider Handoff

## Purpose

This document defines the future role of `redmine_project_percent_done` after
Progress History is split into `redmine_project_progress_history`.

Project Percent Done remains the owner of live Project % Done calculation.
It should become the first progress provider for the new history plugin.

It should not remain the long-term owner of historical collection, history UI,
history cron, retention, forecast, or history notifications.

## Current Baseline

- Plugin id: `redmine_project_percent_done`
- Current production version: `1.3.17`
- Release commit: `2c7c56c Release project percent done 1.3.17`
- Release tag: `v1.3.17`
- Production state: `production-approved` on 2026-09-29
- Public API: `ProjectPercentDone::PublicApi::V1`
- Public contract: `1.0`
- Historical contract: `1.0`
- Calculation algorithm: `1.1`

## Long-Term Role

Project Percent Done owns:

- current project progress calculation;
- calculation settings that affect current progress;
- Project % Done display surfaces;
- calculation details and diagnostic CSV for current progress;
- `ProjectPercentDone::PublicApi::V1`;
- provider adapter data consumed by Project Progress History.

Project Percent Done should not own long-term:

- snapshot collection;
- historical storage ownership;
- history tab/page;
- history charts/timeline;
- historical retention;
- forecast;
- monthly status/digest/notifier;
- history cron commands;
- history diagnostics;
- generic provider registry.

## Provider Contract Expectations

The Project Percent Done provider adapter should use the existing public API:

```ruby
ProjectPercentDone::PublicApi::V1.capabilities
ProjectPercentDone::PublicApi::V1.calculate(:project => project)
```

The adapter should expose enough metadata for Project Progress History to store
traceable snapshots:

- provider id, for example `project_percent_done`;
- source plugin id, `redmine_project_percent_done`;
- source plugin version;
- public contract version;
- calculation algorithm version;
- progress availability;
- raw percent done;
- display percent done;
- estimate coverage metrics;
- issue scope and calculation setting metadata;
- warning codes.

Project Percent Done must keep its public API stable. Breaking a field's meaning
requires a new public API namespace or a clearly versioned compatibility layer.

## Coexistence Behavior

When `redmine_project_progress_history` is not installed:

- Project Percent Done may keep legacy history behavior during the transition.
- Existing production installs remain compatible.

When `redmine_project_progress_history` is installed and enabled:

- Project Percent Done should not show a duplicate history tab.
- Project Percent Done should not run or advertise legacy history cron
  collection.
- Project Percent Done should not write snapshots for the provider/project pair
  owned by the new plugin.
- Project Percent Done should not expose conflicting history settings as the
  active owner.
- Project Percent Done should show clear admin guidance where legacy history
  settings are replaced by the new plugin.

Detection should be defensive. Do not assume every install has the new plugin.
Do not fail live Project % Done calculation when the new history plugin is
missing, disabled, or misconfigured.

## Legacy Storage

The first split release uses legacy history tables without table rename.

This is intentional and safe:

- no destructive migration in the first release;
- no data copy in the first release;
- existing accumulated history remains readable;
- rollback does not require restoring renamed tables.

During this phase, table names may still contain `project_percent_done` even
when runtime history ownership has moved to Project Progress History. Treat this
as legacy storage compatibility, not as a sign that Project Percent Done should
continue owning history behavior.

## Required Inventory Before Code Changes

Before implementing the split, inventory all history-related items in this repo:

- `ProjectPercentDone::History::*` modules;
- history-related controllers/actions;
- history routes;
- history views and partials;
- history helpers;
- history assets;
- history settings and admin settings sections;
- snapshot migrations and models;
- rake tasks and cron command helpers;
- history tests;
- history locale keys;
- history docs and runbooks.

For each item, classify it as:

- stays in Project Percent Done;
- moves to Project Progress History;
- becomes provider/API boundary;
- remains as legacy compatibility/deprecation.

## Project Percent Done Change Phases

### Phase PPD-0 - Inventory Only

No behavior changes. Produce a concrete map of all history surfaces.

### Phase PPD-1 - Provider Adapter Hardening

Ensure `ProjectPercentDone::PublicApi::V1` exposes everything the history
provider adapter needs without depending on internal calculator classes.

Do not change calculation semantics.

### Phase PPD-2 - New Plugin Detection

Add safe detection for `redmine_project_progress_history`.

Detection must not break when the new plugin is absent.

### Phase PPD-3 - Delegation Guards

When the new plugin owns history:

- hide or delegate Project Percent Done legacy history menu items;
- suppress legacy history cron entry points;
- mark legacy settings as delegated or inactive;
- prevent duplicate snapshot writes.

### Phase PPD-4 - Deprecation Cleanup

After the new plugin is production-approved and rollback risk is understood,
consider removing legacy history code from Project Percent Done.

Do not do this in the first split release.

## Test Requirements

Test both install modes:

- Project Percent Done alone;
- Project Percent Done plus Project Progress History.

Minimum expectations:

- live Project % Done still works without the new plugin;
- `ProjectPercentDone::PublicApi::V1` remains compatible;
- provider adapter returns stable metadata;
- no duplicate history tab when the new plugin owns history;
- no duplicate cron snapshot writes;
- existing snapshot rows remain readable;
- legacy tables are not dropped or renamed;
- rollback preserves data.

Run focused tests during development and the full plugin suite before release.
Record exact test counts in `TESTING_LOG.md`.

## Safety Rules

- No destructive migrations in the first split release.
- No table rename in the first split release.
- No double snapshot writers.
- No duplicate menu tabs.
- No change to current progress calculation semantics.
- No package handoff without a concrete copy/paste install/update script.

## Future Clean Schema Split

If the new history plugin is production-approved and a clean physical schema is
still desired, plan a separate release to introduce `project_progress_history_*`
tables.

That release must use copy/verify/switch semantics rather than blind deletion.
It must include backup, row counts, rollback, and staging approval before
production.
