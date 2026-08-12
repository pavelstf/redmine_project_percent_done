# Staging Runbook: Project Percent Done 1.3.2

Staging candidate prepared on 2026-08-12. Version `1.3.2` fixes display of
monthly snapshots created through a future-dated staging simulation run.

## Package

- File: `redmine_project_percent_done-1.3.2-staging-20260812.zip`
- Local path: `C:\Codex Projects\Project Percent Done Plugin\redmine_project_percent_done-1.3.2-staging-20260812.zip`
- Upload to: `/home/gcrbgcaa/redminestaging/plugins/redmine_project_percent_done-1.3.2-staging-20260812.zip`
- SHA-256: `A880B97AEA4B6929DFC4B4C009F049EED60C85C4C81A624F9A7D645CA81CA8E8`

## Manual Checks

- Open a project that received a simulated monthly snapshot for `2026-08-31`.
- Open `Progress history`.
- Select `Period type = Monthly` and `Period = All history`.
- Confirm the table and chart include `2026-08-31`.
- Confirm the Monthly snapshots status no longer reports `2026-08-31` as the
  next pending period after that snapshot already exists.
