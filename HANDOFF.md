# Project Handoff

## Current continuation state — 2026-11-25 / QA 1.3.20 r2

This section supersedes the historical continuation records below.

- R-01..R-03 from repeat QA are addressed: NULL hierarchy bounds are safely
  excluded; source text is LF with a Git policy; historical 1.3.19 changelog
  restored. No data repair or historical snapshot rewrite was performed.
- Plugin/algorithm remain 1.3.20/1.2. Build identifier: r2, dated 2026-11-25.
- Branch codex/qa-1.3.20; local immutable QA ref `qa-v1.3.20-r2` identifies
  the tested implementation. Resolve its exact commit from Git or the package
  manifest. QA ref is separate from production release approval.
- Focused R-01 regression suite: 8 runs, 199 assertions, 0 failures/errors/skips.
  Full suite: 165 runs, 1084 assertions, 0 failures/errors/skips, exit 0.
  Details are recorded in TESTING_LOG.md and the bundle.
- Rebuild: `python scripts/build_qa_package.py --ref qa-v1.3.20-r2` after the
  complete suite log/exitcode and benchmark exist in output/qa/1.3.20-r2/.
  Builder reads committed Git blobs, requires LF source and workspace equality,
  checks successful test process status and fixes ZIP entry timestamps/modes.
- Previous ZIPs and QA input PDFs are preserved. Generated logs/artifacts remain
  ignored; input `QA reports/` remains untracked and outside the QA commit.
- No remote push, server deployment or production tag is part of this task.
- Environment-specific staging gates from docs/QA_1.3.20.md remain pending.

## Current continuation state — 2026-11-24 / QA 1.3.20

This section supersedes the older continuation and relocation records below.

- Branch `codex/qa-1.3.20`, based on `6c76e30`; implementation is local and
  uncommitted. Do not infer a release commit/tag from the base hash.
- Plugin 1.3.20, algorithm 1.2, public contract 1.0, evidence schema 1.0.
- PPD-01..08 remediation and acceptance criteria: `docs/QA_1.3.20.md`.
- User explicitly approved excluding all parents, including cross-project
  parents. Exact Rational aggregation fixes floor/ceil without arbitrary epsilon.
  Evidence hierarchy is consistent; direct-project row scope is preserved.
- Legacy history remains intact. Migration 002 down refuses before changing
  schema/data; ordinary rollback restores code/assets and retains tables.
- Focused QA tests: 6 runs / 172 assertions; full suite: 162 runs / 1054 assertions;
  both 0 failures, 0 errors, 0 skips, exit 0. See TESTING_LOG.md.
- QA bundle builder: `scripts/build_qa_package.py`. Runtime-only install ZIP
  and full source ZIP are separate, with per-file hashes and a working snapshot
  digest. Private ignored files and input QA reports are not packaged.
- QA input PDF remains untracked in `QA reports/`; do not remove it or stage
  it incidentally. Generated logs/packages remain ignored.
- Synthetic CPU performance improved for large datasets; MySQL/MariaDB,
  actual PB/PPH, deployed UI, SMTP/cron and real-project performance are still
  explicit staging/re-QA gates. No server deployment has been performed.
- No automatic commit/push/tag is part of this QA preparation request.

## Current continuation state — 2026-11-17

This section supersedes the pre-relocation record below. That record is retained
as historical evidence; its old paths, outstanding migration steps, documentation
warnings, and instructions to leave this file uncommitted no longer describe the
current checkout.

- Checkout: `C:\Codex Projects\Redmine Development\Redmine Project Percent Done Plugin`.
- Branch: `main`; source baseline: `42bfd605a9b42a9d4fac6a4f167a95ed34d2537a`.
  The current documentation closeout is a subsequent commit; inspect Git for its
  final hash. The remote baseline was verified before closeout.
- Plugin `1.3.19`, public contract `1.0`, algorithm `1.1`, evidence schema `1.0`.
  No application code, version, deployment, or release-tag changes in this session.
- Shared Redmine 6.1.2 plugin junction now targets this checkout. Setup reused
  Ruby 3.3.11 and Bundler 2.5.22, without installing dependencies.
- Full suite from this location, with normal database preparation:
  **153 runs, 867 assertions, 0 failures, 0 errors, 0 skips**, exit code 0,
  41.582332 seconds. Duplicate-constant warnings did not prevent success.
- Static checks passed: 61 Ruby/Rake/RSB files, 50 locale YAML files, manifest,
  10 ERB templates, and repository PowerShell scripts.
- README and Public API documentation now describe opt-in evidence and the
  exact PPH coexistence conditions. Local documentation links were checked.
- Both 1.3.19 staging/production ZIPs remain local and ignored, 338725 bytes
  each, matching SHA-256
  `E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11`.
- Removed the temporary 1.3.19 package staging after verifying all 183 files
  byte-for-byte against the preserved production ZIP. Approved release ZIPs
  and private ignored context files remain local. Browser output is ignored.
  No runtime belongs in this repo.
- User authorized cleanup, committing this handoff and documentation, and
  pushing to the existing GitHub repository. No new release is being created.

Read `AGENTS.md`, `.redmine-test.yml`, `docs/HANDOFF_1.3.19.md`, and
`docs/PUBLIC_API_V1.md` before continuing. Keep suites sequential on the shared
SQLite runtime. No code work is currently in progress. Legacy history/table
removal remains deferred; history UX work belongs in the separate PPH repo and
requires inspecting its current state first. No server was revalidated here.

## Historical pre-relocation record

The remainder was written before the move and is not the current task list.

# Project Handoff and Windows Relocation (historical)

Prepared: 2026-11-17 (Europe/Sofia). Scope: this Project Percent Done checkout.

## 1. Project Overview

Redmine Project Percent Done (PPD), plugin ID/folder
`redmine_project_percent_done`, calculates current project completion from issue
done ratios and configurable weights. It provides overview/sidebar widgets,
calculation details, CSV diagnostics, an optional REST endpoint, and an in-process
public API for other plugins. The primary test target is Redmine 6.1.2; broader
Redmine 5.x/6.x compatibility is a documented aim, not a fresh certification.

Technology: Ruby, Rails through the host Redmine installation, ActiveRecord,
ERB, CSS, locale YAML, PowerShell test wrappers, and Redmine test infrastructure.
There is no standalone application server/build in this checkout; it is loaded
by Redmine. SQLite is used by the shared local test setup; deployment databases
belong to their Redmine environments.

Important directories:

- `init.rb`: Redmine registration, permissions/settings, version registration.
- `lib/project_percent_done.rb`: plugin identity/version and initialization.
- `lib/project_percent_done/`: calculator, settings, public API and legacy history.
- `lib/tasks/`: guarded rake tasks, including legacy history operations.
- `app/`: controllers, views, models, helpers, hooks and mail-related surfaces.
- `assets/`: plugin CSS and other browser assets.
- `config/`: routes/locales and other plugin configuration.
- `db/migrate/`: plugin-owned legacy history schema migrations.
- `test/`: unit and functional regression tests.
- `scripts/`: shared-runtime wrappers and migration check helper.
- `docs/`: calculation/API documentation, cleanup inventory, release handoffs/runbooks.
- `release_packages/`: ignored local ZIP archives; not restored by cloning Git.
- `tmp/`: ignored package staging material; not required source.
- `output/`: local browser-output directory; review contents before transferring.

## 2. Current Implementation Status

Verified code version: PPD `1.3.19`, algorithm `1.1`.

Completed functionality includes weighted live calculation, configurable parent,
closed/unestimated issue behavior, included/excluded diagnostics, issue-visible
detail/CSV rows, English/Bulgarian localization, and public API V1. Calculation
aggregates remain project-wide even when some issues are private to the viewer.

The latest release adds `calculate(:project => project, :include_evidence => true)`.
Its `to_h` provides project ID, availability/progress/coverage, nested `metrics`,
`warnings`, `provider_metadata`, and `issue_evidence`. Evidence includes scalar
issue/status/tracker/assignee fields, weights, inclusion/exclusion, hierarchy,
closure and notes. Evidence schema version is `1.0`. Default calculation retains
its previous shape without issue rows. Treat evidence as trusted in-process data,
not a substitute for authorization when presenting personal/private issue data.

Project Progress History (PPH) is a separate plugin/repository and owns current
history collection/display in the approved GCR deployment. PPD retains legacy
history functionality and coexistence guards for compatibility and rollback.
The companion PPH `0.2.2` integration persisted issue evidence into
`project_progress_history_issue_snapshots`, with extra fields in `notes_json`.

No application implementation is in progress in this checkout. Historical legacy
cleanup is deliberately incomplete; destructive table removal was not approved.
The requested next UX/UI work belongs in the separate PPH project.

## 3. Important Decisions

- PPD owns current progress calculation; PPH consumes the public API and owns
  history. Direct dependence on PPD private calculators/tables was avoided to
  preserve an integration boundary.
- Evidence is opt-in so existing API consumers retain compatible behavior and
  avoid unnecessary issue-row payloads. Replacing the default result shape was
  not chosen.
- Public contract/evidence/algorithm versions are separate from plugin releases.
  Current documented public contract is `1.0`; algorithm remains `1.1`.
- Progress uses direct project issues, not recursively aggregated subprojects.
  Leaf-only scope avoids double counting parents by default.
- Preserve old history settings/tables and coexistence guards. Dropping data or
  re-enabling competing legacy collection is outside this release scope.
- Production ZIPs were byte-for-byte promotions of user-approved staging ZIPs.
- Keep Redmine, Ruby, gems and test databases outside this repository. Run suites
  sequentially against the shared SQLite runtime to avoid lock/table contention.
- History UX changes should respect Redmine styling, avoid a heavy frontend
  framework, and preserve calculation/provider semantics.

## 4. Current Working State

Observed before creating this file:

- Branch: `main`, tracking `origin/main`.
- HEAD: `42bfd605a9b42a9d4fac6a4f167a95ed34d2537a`
  (`Add v1.3.19 release handoff`).
- Read-only remote lookup confirmed the same commit for remote `main`.
- Release implementation commit: `99db8af`; recorded release tag: `v1.3.19`.
- Working tree was clean; no tracked or ordinary untracked changes.
- One registered worktree: `C:/Codex Projects/Project Percent Done Plugin`.
- This task adds root `HANDOFF.md` as an uncommitted document. No branch/history
  changes are authorized for this task. Copy it explicitly if using a fresh clone.

Ignored local material includes `release_packages/`, `tmp/`, `master-prompt.md`,
`REDMINE_HOSTING_CONFIGURATION.md`, and `GITHUB_PUBLISHING_CONTEXT.md`. These
files were not reproduced here; review them privately before migration/sharing.
Git clean status alone does not mean ignored files are backed up remotely.

## 5. Environment and Dependencies

Read `AGENTS.md` and `.redmine-test.yml` first. The manifest specifies plugin
`redmine_project_percent_done` and Redmine `6.1.2`.

The wrappers locate the shared `redmine-plugin-test-runtime` skill via an
environment override, the user's Codex skills directory, or the relative sibling
`../../Codex-Skills/skills/redmine-plugin-test-runtime`. Windows requires working
Ruby, Bundler and the runtime's native dependencies. See that skill for the pinned
Ruby profile and MSYS2/SQLite DLL troubleshooting.

From the new project directory, use:

```powershell
Get-Content AGENTS.md
Get-Content .redmine-test.yml
& .\scripts\setup_redmine_test_runtime.ps1
& .\scripts\run_redmine_plugin_tests.ps1
& .\scripts\run_redmine_plugin_tests.ps1 -Test "plugins/redmine_project_percent_done/test/unit/project_percent_done/public_api_v1_test.rb"
```

Allow normal test DB preparation/migrations. Use `-SkipDatabasePrepare` only for
a known-current database. Run the full suite before subsequent release/handoff.
Do not run multiple plugin suites concurrently against the same test database.

Inside a suitable Redmine root, the equivalent commands are:

```bash
bundle exec rake redmine:plugins:migrate RAILS_ENV=test
bundle exec rake redmine:plugins:test NAME=redmine_project_percent_done RAILS_ENV=test
```

For installation, place/link the checkout at
`<RedmineRoot>/plugins/redmine_project_percent_done`, install dependencies through
the host Redmine bundle, run the standard plugin migrations in the intended
environment, and restart Redmine. For local interactive development, use the
host's configured Rails server (typically `bundle exec rails server` from its
root). This task did not start a server or inspect a local development database.
Use existing deployment runbooks for server-specific production commands.

Relevant environment-variable names only:
`REDMINE_PLUGIN_TEST_SKILL_ROOT`, `REDMINE_TEST_RUNTIME_ROOT`, `MSYS2_PATH`,
`RAILS_ENV`, `REDMINE_ROOT`, `BUNDLE_APP_CONFIG`, `BUNDLE_USER_HOME`,
`BUNDLE_USER_CACHE`, `GEM_HOME`, `GEM_PATH`, `VIRTUAL_ENV`, `PATH`,
`PLUGIN_PATH`, `DATABASE_PATH`, `DRY_RUN`, `PROJECT`, `ACTION`, `CONFIRM`.
The companion history operational workflow also uses `ALL_PROJECTS`,
`PERIOD_TYPE`, `SNAPSHOT_KIND`, and `TRIGGERED_BY`.

## 6. Known Issues, Limitations and Risks

- README still describes older PPD-owned collection/history and aggregate-only
  API behavior. `docs/PUBLIC_API_V1.md` has a stale plugin-release table entry
  `1.3.17`, despite documenting optional evidence. Prefer current code,
  `docs/HANDOFF_1.3.19.md`, `TESTING_LOG.md`, and the coexistence inventory when
  resolving these inconsistencies. No documentation beyond this file was edited.
- In the October PPH UI, Sunday `2026-10-11` appeared as `missing` in weekly
  official history despite a daily operational snapshot existing. Timeline and
  promotion used different same-Sunday cutoffs. Weekly promotion was due on the
  following capture day. This was accepted as a UX issue for PPH follow-up;
  Monday's actual promotion was not verified in this conversation.
- October PPH `0.2.2` is historical context, not a verified current PPH version
  on 2026-11-17. Inspect that repository before beginning its UX work.
- cPanel emitted a Bundler GemNotFound prelude before successful intended Rails
  output. Treat it as nonblocking only when the intended operation demonstrably
  completes. Do not ignore future genuine dependency failures.
- Current shell emits an InitializeDefaultDrives/FileSystem-provider warning.
  Read-only Git/file inspection still succeeded. Test execution evidence for
  this handoff is recorded below; do not infer fresh runtime health from old runs.
- Evidence contains assignee/contact and potentially private issue information;
  preserve appropriate permissions in downstream display/export work.

## 7. Recent Work and Validation Evidence

The earlier conversation implemented PPD optional evidence and companion PPH
consumption/persistence, packaged both, corrected runbook table/signature errors,
validated staging then production, and pushed release/handoff commits.

Recorded October tests (historical successful runs, not reruns on today's date):

- PPD full suite: 153 runs, 867 assertions, 0 failures, 0 errors, 0 skips.
- PPD public API focused suite: 18 runs, 172 assertions, 0 failures, 0 errors,
  0 skips.
- Companion PPH full suite: 141 runs, 907 assertions, 0 failures, 0 errors,
  0 skips. An invalid parallel SQLite run was discarded; sequential runs passed.

User-confirmed production on 2026-10-11: install success, UI without observed
500 errors, PPH Run ID 84 processed 54 projects and created 54 daily operational
snapshots with zero failures/unavailable and notification delivered. Production
snapshot IDs 2249-2258 showed source version `1.3.19`, schema `1.0`, issue rows.
Staging evidence included IDs 2278-2287. These are historical server observations;
no remote deployment/database check was performed for this migration task.

PPD staging and production package names:
`redmine_project_percent_done-1.3.19-staging-20261011-evidence-api.zip` and
`redmine_project_percent_done-1.3.19-production-20261011-evidence-api.zip`.
Recorded size: 338725 bytes each. Recorded SHA-256:
`E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11`.
Both filenames are still present locally. Hashes were not recomputed in this task.

Migration-task test attempt: the shared runner and setup script both failed
during Ruby parsing of the manifest in the sandbox, before any test executed.
The approved external-runtime retry completed successfully on 2026-11-17:
153 runs, 867 assertions, 0 failures, 0 errors, 0 skips (47.363293 seconds).
The runner used normal database preparation, without SkipDatabasePrepare.
Duplicate-constant warnings from other plugins/junction aliases appeared but
the PPD suite completed with exit code zero. A pre-test runtime failure has no
valid run/assertion/failure/skip totals.

## 8. Prioritized Next Steps

1. Copy the project, including this uncommitted file and `.git` if preserving
   local history, to the chosen Windows destination. No destination was specified.
2. Open a new Codex conversation bound to the new directory; read this file,
   `AGENTS.md`, `.redmine-test.yml`, and `docs/HANDOFF_1.3.19.md`.
3. Repoint/recreate external test links and validate the full suite from the new
   location before further development.
4. Check the separate PPH checkout's current branch/version/handoff. Continue
   UX/UI work there: official vs operational explanation, readable status badges,
   progress/summary presentation and clear missing/not-observed states. Begin
   with an audit and plan as requested previously.
5. In a separately authorized PPD documentation task, reconcile stale README/API
   version descriptions with the current integration and coexistence behavior.

## 9. Migration Considerations

Current absolute project path: `C:\Codex Projects\Project Percent Done Plugin`.
The sole Git worktree uses this directory; no linked worktrees were reported.
Keep hidden `.git` when copying; Git metadata should be reviewed after relocation.

Verified external junction:
`C:\RedmineTestRuntimes\redmine-6.1.2\plugins\redmine_project_percent_done`
targets the OLD project path above. Copying this repo does not update that
junction. Inspect the target before testing; use shared setup tooling to repair
the link and verify it now targets the new directory. Never recursively delete
the target source directory when replacing a junction.

The shared runtime, portable Ruby, gems, SQLite test DBs and Codex skills are
external. They are not carried by this repo. Reuse/rebuild them via the shared
skill after relocation; keep them outside the new checkout too. The migration
check helper defaults to `C:\RedmineTestRuntimes\redmine-6.1.2` and may need its
`RuntimeRoot` argument overridden.

Wrapper scripts resolve the project relative to their own location, but skill
discovery depends on the user profile or sibling Codex-Skills layout. Moving to
another computer/user may require installing the shared skill or setting the
documented override variables. Codex workspace permissions/context must also be
re-established by opening the new directory.

The sibling PPH path used earlier was
`C:\Codex Projects\Redmine Project History Plugin`; it is a separate repository,
not a vendored dependency. Migrate it separately if needed. Embedded old paths in
historical docs/runbooks are evidence, not portable installation settings.

Ignored ZIPs/local context files do not appear in a clone. Copy release archives
separately if wanted; generated `tmp/` package staging is optional. No files were
deleted or moved by this task. Review ignored local context files for sensitive
data before transferring them elsewhere. Credentials are deliberately omitted
from this handoff. Production databases, settings, server virtualenvs and cron
are independent of the local checkout and should not be modified for this move.

## 10. Verification Checklist

- Confirm the destination includes `HANDOFF.md`, `AGENTS.md`, source/tests,
  `.redmine-test.yml`, and `.git` if doing a complete directory copy.
- Run `git status --short --branch`, `git log -1 --oneline`, and
  `git worktree list`; expect the recorded HEAD and only intended local changes.
- Check remote URL remains the intended PPD repository:
  `https://github.com/pavelstf/redmine_project_percent_done.git`.
- Verify the test plugin junction resolves to the NEW checkout.
- Resolve shared skill, Ruby/Bundler/native dependencies; run setup if required.
- Run full tests with migrations and record exact totals. Avoid concurrent
  suites sharing the same SQLite runtime.
- If using a local Redmine server, verify registration/version, overview/sidebar,
  calculation details, settings, and public API evidence/default modes.
- Preserve archives deliberately; compare to recorded hashes when copying ZIPs.
- Confirm any PPH checkout independently before undertaking history UI work.

The project is ready for a filesystem copy with the external-link/runtime
qualifications above. This document remains uncommitted by explicit request.
Wait for user confirmation before further work.
