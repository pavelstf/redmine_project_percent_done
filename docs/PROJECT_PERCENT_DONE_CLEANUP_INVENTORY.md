# Project Percent Done Cleanup Inventory

Date: 2026-10-07

This inventory captures the safe cleanup boundary after
`redmine_project_progress_history` became the production owner of progress
history.

## Current State

- Plugin id: `redmine_project_percent_done`
- Working version: `1.3.18`
- `main` matches `origin/main` at `255a537 Document Project Percent Done waiting state`
- The working tree contains the in-progress 1.3.18 coexistence cleanup.
- `redmine_project_percent_done` remains the source of truth for the current
  Project % Done value and `ProjectPercentDone::PublicApi::V1`.

## Must Stay

- Current calculation code:
  - `ProjectPercentDone::ProjectProgressCalculator`
  - `ProjectPercentDone::Settings` calculation options
  - `ProjectPercentDone::CalculationResult`
  - included/not-included calculation diagnostics and CSV exports
- Current UI:
  - project overview percentage widget
  - project sidebar percentage widget
  - Project % Done details tab/page
  - optional JSON/REST details endpoint
- Public provider surface:
  - `ProjectPercentDone::PublicApi::V1.capabilities`
  - `ProjectPercentDone::PublicApi::V1.calculate`
  - existing V1 result/capability fields and versions
- Calculation locale keys, docs, and tests.

## Must Stay Temporarily As Coexistence Guard

- `ProjectPercentDone::History::Coexistence`
- guarded `Settings.history_enabled?`
- guarded `Settings.history_available_for_project?`
- guarded `Settings.history_email_enabled?`
- settings-save sanitizer that preserves legacy history settings but forces
  legacy history/email enable flags off while Project Progress History owns
  history
- admin action guard in `ProjectPercentDoneAdminController`
- rake guards for legacy snapshot, cleanup, purge, and staging-demo tasks
- snapshot collector early return when Project Progress History owns history
- coexistence regression tests.

## Hidden Or Disabled In UI When Project Progress History Owns History

- legacy history project tab/menu
- legacy history route visibility through `history_available_for_project?`
- legacy admin history controls:
  - preview
  - manual capture
  - test email
  - purge
- legacy settings controls:
  - collection enablement
  - project-type scope
  - plan-date fields
  - retention
  - display defaults
  - collection email
  - cron command guidance
  - diagnostics
- dashboard/sidebar legacy snapshot freshness lines.

## Deprecated But Not Removed Yet

These remain for compatibility when Project Percent Done is installed without
Project Progress History, and for rollback/read-only transition safety:

- legacy history routes and `ProjectPercentDoneController#history`
- legacy history views and helpers
- legacy snapshot models:
  - `ProjectPercentDoneSnapshot`
  - `ProjectPercentDoneIssueSnapshot`
  - `ProjectPercentDoneCollectionRun`
- legacy `ProjectPercentDone::History::*` implementation modules:
  - snapshot collector
  - timeline
  - retention cleaner
  - notifier
  - monthly status/digest
  - forecast
  - plan metrics
  - staging demo
  - settings validator
  - cron command
- legacy history mailer and mail views
- historical Public API V1 methods:
  - `history_capabilities`
  - `latest_official_snapshot`
  - `official_snapshot_for`
  - `official_snapshots_between`
  - `progress_at`
- legacy migrations and existing `project_percent_done_*` history tables.

## Future Cleanup After Another Release Cycle

- Decide whether to keep or remove legacy Project Percent Done history mode
  when Project Progress History is not installed.
- Retire legacy history routes/controllers/views after rollback risk is low.
- Remove legacy collector/notifier/retention/forecast/monthly modules only
  after Project Progress History has carried production history through another
  stable release cycle.
- Plan physical cleanup of old `project_percent_done_*` history source tables
  only as a separate maintenance operation with fresh backups, staging
  rehearsal, row-count verification, rollback steps, and explicit approval.

## Safe Cleanup Plan

1. Keep all database tables and migrations untouched.
2. Keep `ProjectPercentDone::PublicApi::V1` contract unchanged.
3. Keep live Project % Done calculation behavior unchanged.
4. When Project Progress History owns history, replace Project Percent Done
   history settings with a delegation notice.
5. Suppress legacy history links, snapshot freshness, cron guidance,
   diagnostics, and admin actions under the coexistence guard.
6. Preserve legacy settings values for rollback, while forcing old enable flags
   off on guarded saves.
7. Cover coexistence behavior with focused tests, then run the full Redmine
   6.1.2 plugin suite before handoff.
