# Project Percent Done Continuation Prompt

Use this prompt to start a new Codex chat in the Project Percent Done project
after work continues in the separate Project Progress History project.

```text
Искам да продължим работата по Redmine plugin-а Project Percent Done:

Repo:
C:\Codex Projects\Project Percent Done Plugin

Plugin:
redmine_project_percent_done

НЕ Project Contribution.
НЕ Project TimeShift.

Първо прочети:
- AGENTS.md
- docs/PROGRESS_HISTORY_SPLIT_HANDOVER.md
- docs/PROGRESS_HISTORY_PROVIDER_HANDOFF.md
- docs/PROJECT_PERCENT_DONE_CONTINUATION_PROMPT.md
- docs/PUBLIC_API_V1.md
- docs/HANDOFF_1.3.17.md
- TESTING_LOG.md
- CHANGELOG.md

Current baseline:
- `redmine_project_percent_done` version `1.3.17`
- production-approved on 2026-09-29
- release commit: `2c7c56c Release project percent done 1.3.17`
- release tag: `v1.3.17`
- latest handover tracking commit: check current `main`
- Project Percent Done remains the source of truth for live Project % Done.
- Project Progress History work continues separately in:
  https://github.com/pavelstf/redmine_project_progress_history.git

Current state of this Project Percent Done repo:
- Waiting/provider-readiness state.
- Do not implement coexistence guards or provider adapter changes until the
  Phase 0 inventory/design from the Project Progress History project is
  available and approved.
- The next Project Percent Done work is expected to be one of:
  1. review the Phase 0 inventory/design from `redmine_project_progress_history`;
  2. harden or extend `ProjectPercentDone::PublicApi::V1` only if the approved
     provider plan requires it;
  3. add safe detection/delegation/coexistence guards only after the new plugin
     plan is approved.

Approved architecture:
- `redmine_project_percent_done` keeps live calculation and Public API V1.
- `redmine_project_progress_history` owns snapshots, history UI, cron,
  retention, forecast, monthly status/digest/notifier, settings, and diagnostics.
- The new history plugin defines a generic provider registry/API.
- Project Percent Done is the first provider through
  `ProjectPercentDone::PublicApi::V1`.
- First split release uses Safe Adoption First.
- First split release uses legacy history tables without rename.
- Destructive migrations are forbidden.
- Zero data loss is mandatory.
- Coexistence must prevent double writes, duplicate tabs, conflicting settings,
  and cron conflicts.

Task for this chat:
First report the current tracker state from
`docs/PROGRESS_HISTORY_SPLIT_HANDOVER.md`.

Then wait for or review the Phase 0 inventory/design output from the separate
Project Progress History project. Do not make behavior/code changes until I
explicitly approve the next Project Percent Done implementation step.

Important rule:
When preparing a new installable package, always include a concrete copy/paste
install/update script in the same response.
```
