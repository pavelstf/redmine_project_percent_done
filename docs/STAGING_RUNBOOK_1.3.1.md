# Staging Runbook: Project Percent Done 1.3.1

Staging candidate prepared on 2026-08-12. Version `1.3.1` adds monthly snapshot
visibility on the project history page and monthly information in the collection
digest email. No database migration is required beyond the existing 1.3.0
schema.

## Package

- File: `redmine_project_percent_done-1.3.1-staging-20260812.zip`
- Local path: `C:\Codex Projects\Project Percent Done Plugin\redmine_project_percent_done-1.3.1-staging-20260812.zip`
- Upload to: `/home/gcrbgcaa/redminestaging/plugins/redmine_project_percent_done-1.3.1-staging-20260812.zip`
- SHA-256: `79FC192BA4EA230DCAB6A2CB45FA085E62C927DC619568526F7E47A008D589A6`

## Manual Checks

- Administration -> Plugins shows version `1.3.1`.
- The existing weekly Progress history view still opens by default.
- On a project with monthly official snapshots, Progress history -> Period type
  -> Monthly shows month-end rows in the graph and table.
- In Monthly mode, the weekly forecast block is not displayed.
- The Monthly snapshots notice shows the next monthly period end, expected
  capture date, days remaining, or overdue/disabled state.
- A collection digest email includes a Monthly snapshots section. When the run
  creates monthly snapshots it summarizes the actual monthly rows for that run;
  otherwise it reports the next/overdue/disabled monthly status.
