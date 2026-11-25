# Testing Log

## 2026-11-25 - r3-text production accepted and repository closeout

- User confirms successful production installation and UI OK. Supplied output:
  TEXT_FIX_OK build=r3-text locales=50, ASSETS_OK verified_copies=2,
  AFTER_OK version=1.3.20 algorithm=1.2 settings_preserved=true and final SUCCESS.
  PB/PPH provider checks passed on 8/9/10/19. Production backup suffix
  20261125T103847Z-2862087; original DB/code/assets backups retained on server.
- Screenshots: corrected global-parent note; project one 40% / PB 40.0%,
  5 included/0 excluded, zero budget; project two 30% / PB 29.7%,
  364 included/214 excluded. Owner explicitly states two different projects.
- Both staging and production r3-text are accepted. No app/test changes during
  closeout; full suite evidence remains 165 runs/1084 assertions/0 failures/
  0 errors/0 skips and 40 packaged operator checks. No remote deployment by agent.
- Consolidated deferred work in docs/BACKLOG.md; preserved accepted packages
  and ignored local build/test output rather than deleting release evidence.

## 2026-11-25 - r3-text staging accepted

- User supplied complete staging installation output and confirmed UI OK.
  BEFORE_OK 1.3.20/1.2, TEXT_FIX_OK build=r3-text locales=50, ASSETS_OK,
  AFTER_OK settings_preserved=true and final staging SUCCESS confirmed.
  PB 0.1.8/PPH 0.7.2 provider checks passed for projects 8/9/10/19;
  baseline raw/display unchanged and legacy history guard passed.
- Backups use suffix 20261125T103325Z-2836617. Production r3-text has not yet
  been confirmed installed. Existing production r2 remains previously verified.

## 2026-11-25 - r3-text deployment packages

- Built staging/production handoffs using scripts/build_textfix_deployment.py.
  Compared to immutable r2: exactly 50 locale-note replacements and manifest;
  verified workspace app/lib/db/assets/config/init match the runtime payload.
  Both environments contain identical runtime bytes, SHA256
  0C531E9EAC90267121DA3AC4CC1B5CE0F7BF3CA05A8BE5CE8DFACAD1D48656EA, 170069 bytes.
- Reused the immediately preceding full Redmine test result for these same
  runtime files: 165 runs/1084 assertions/0 failures/0 errors/0 skips.
- Final archived install/rollback workflows: staging 10/10 and production
  10/10 from existing 1.3.19, repeated staging 10/10 and production 10/10 from
  existing 1.3.20 (40 checks). Includes correct-root refusal, checksum/activation/
  DB/migration/assets/after-check failures and code/assets rollback. Rails/DB
  commands mocked; real Linux files/tar/gzip/Ruby FileUtils; no remote execution.
- All four generated scripts passed Bash syntax; ZIP integrity/runtime identity
  and checksum metadata verified. Package sizes/hashes in HANDOFF and
  output/textfix-r3/packages.json. Existing accepted archives remain unchanged.
- Script build verification marker: TEXT_FIX_OK build=r3-text locales=50.
  New build awaits staging then production validation; no deployment by agent.

## 2026-11-25 - Production evidence and Calculation details text follow-up

- User production output confirms upgrade 1.3.19/1.1 -> 1.3.20/1.2,
  BEFORE_OK, ASSETS_OK verified_copies=2, AFTER_OK settings_preserved=true,
  full runtime manifest verification and final SUCCESS. Backups have suffix
  20261125T100650Z-2656142. No new matching application errors printed.
- PB 0.1.8 and PPH 0.7.2 providers passed on projects 8/9/10/19; legacy PPD
  collector guard passed. Two real-project UI checks: DI-221 88% vs PB 87.9%,
  22 included/1 excluded/1996h; DI-249 40% vs PB 40.0%, 5/0/40h and zero budget.
  Existing snapshot #4893 opens with complete evidence; next new capture pending.
- Updated parent-exclusion note in all 50 locale files: children's project does
  not affect parent exclusion. EN/BG and compatibility English stay consistent.
  All 50 YAML files parsed successfully; note content and LF endings verified.
- Focused controller suite: seed 19018, 17 runs, 148 assertions, 0 failures,
  0 errors, 0 skips. Default database migrations enabled.
- Initial full run: 165 runs, 1084 assertions, 1 failure, 0 errors, 0 skips.
  NULL-coordinate overview test created its 70% fixture before setting
  issue_done_ratio=issue_field, allowing status-derived defaults to overwrite it.
  Moved existing setting scope before fixture creation; no application change.
- Focused hooks suite after fix: seed 41875, 6 runs, 24 assertions, 0 failures,
  0 errors, 0 skips. Default database migrations enabled.
- Full repeat seed 36713 and diagnostic repeat each still had 165 runs,
  1084 assertions, 1 failure, 0 errors, 0 skips. Diagnostics established that
  calculation was 70.0 and display enabled, but Redmine's cached hook list
  omitted PPD. Fixture setup alone was not the complete cause/fix.
- Hooks test setup now rebuilds the global listener-instance cache using
  Redmine::Hook.clear_listeners_instances; retained failure diagnostics report
  display state, actual calculator value and registered listeners.
- FINAL full suite: seed 10852, 165 runs, 1084 assertions, 0 failures,
  0 errors, 0 skips (26.899554s). Skipped redundant database preparation only
  for this final run; migrations had completed in preceding runs on this same
  database, with no schema changes. Log: text-fix-full-verified.log.
- Logs: output/production-1.3.20-r2/text-fix-focused.log, text-fix-full.log,
  text-fix-hooks.log and text-fix-full-final.log. Shared Redmine 6.1.2 runtime.
- Text correction is local only; accepted deployment ZIPs are immutable and
  have not been regenerated. No deployment, commit or push for this follow-up.

## 2026-11-25 - Staging acceptance and production operator p1

- Owner accepted staging after successful FileUtils asset finish; screenshots
  confirmed PPD 84% and PB 83.7% on the same real project. Zero-budget progress
  was also visible. Previous pending-staging entries are historical.
- Production runtime promoted byte-for-byte from accepted staging ZIP:
  169409 bytes, SHA-256 FA3B218167DAEC4996486BB22D6D0F1D0B5FFC3CC0952DCFD2C1F1B923B60F67.
  No application changes; existing full-suite result remains 165 runs,
  1084 assertions, 0 failures, 0 errors, 0 skips. Suite not rerun for operator docs.
- Production handoff ZIP p1: 128792 bytes,
  SHA-256 797C8F8A6AEA69A008AC41F02711B8630A0E92417768A71E1B044E4A0DEB3387.
- Ran scripts/staging/test_operator_workflow.py --target production --archive
  against the final production handoff ZIP using WSL Ubuntu-22.04.
  All 10 workflow checks passed: cwd-changing activation/relative preflight;
  relative and absolute install plus full rollback; checksum failure;
  baseline/DB failure; migration failure plus rollback; after-check failure plus
  rollback; activation failure; asset failure plus rollback; wrong physical root.
- Fixtures mock Rails/DB, and use actual Linux filesystem, tar/gzip and Ruby
  FileUtils assets logic; no remote command or live DB validation was performed.
- Both production scripts passed Bash -n; canonical embedded helper passed
  Ruby -c. Builder verified LF endings, exact embedded helpers, canonical
  production paths, absence of /dev/fd/process substitution/cwd-based helper,
  runtime identity and archive content hashes. git diff --check passed.
- Artifact evidence: output/production-1.3.20-r2/package_evidence.json.
  Live production terminal output and HTTP/UI acceptance remain pending.

## 2026-11-25 - Received op3 staging execution evidence

- User log confirms before 1.3.19/algorithm 1.1 and after 1.3.20/1.2 on Redmine
  6.1.2, Ruby 3.2.11, Rails 7.2.3. Backups were created. AFTER_OK confirms runtime
  manifest hashes, PPD settings preservation and API/evidence checks passed.
- PB/PPH provider reads matched on projects 8/9/10/19 (only 8 had available 0%;
  no positive-progress sample). These checks are not UI integration acceptance.
- Two operator issues found: process substitution under restricted /dev/fd
  during fingerprint CSS refresh, and a one-line rescue expression that printed
  companions as missing even when found. The later SUCCESS does not erase the
  asset error. Runtime PPD calculation code is not changed by these issues.
- Local scripts now avoid process substitution and use a multiline registry
  lookup. Standalone finish script refreshes/hash-checks assets through FileUtils,
  preserves original code rollback pointer and checks actual registry/API state.
- Four asset-copy regressions passed (standard/compiled/fingerprinted, no compiled
  tree, unsafe symlink refusal, missing source refusal), plus found/missing
  registry output verified using a stub registry. Finish Bash/Ruby syntax passed.
- Manual acceptance checklist: docs/STAGING_SMOKE_1.3.20_R2.md. No agent remote
  operation or staging acceptance claim; user finish/UI checks remain pending.

## 2026-11-25 - Staging operator revision op3

- Re-read gcr-redmine-environments and the full gcr-redmine-plugin-runbooks
  discovery/templates/troubleshooting references before revising the scripts.
- Exact op2 line 29 was `test -f "$CHECK"`. SCRIPT_DIR was resolved from a
  relative BASH_SOURCE after cd to Redmine root, so the helper was looked up
  outside plugins/. The complete sandbox reproduced the same line-29 failure
  while the helper was present in plugins/. Earlier activation-only tests did
  not exercise that filesystem transition.
- Install/rollback are now self-contained and write identical quoted Ruby
  verifiers into their private /tmp work directories. They have no SCRIPT_DIR
  dependency. Runtime ZIP and QA tag remain unchanged.
- Nine Linux/WSL sandbox workflow checks passed: exact legacy reproduction;
  preflight with activation changing cwd; complete relative/plugins and absolute/
  home install plus code/asset rollback; checksum refusal; baseline/DB failure
  refusal; migration/after-check failures followed by rollback; activation failure.
  Native filesystem/tar/gzip were exercised, unzip used Python's ZIP extraction,
  and host identity/Ruby/Rails/DB commands were mocked. No remote operation.
- Bash parsing and embedded Ruby syntax checked separately. Operator checksums,
  LF payload, manifest and unchanged runtime checksum are verified at packaging.
- This is operator-flow coverage, not proof of real GCR MySQL or Rails execution.

## 2026-11-25 - Staging operator revision op2

- Server read-only diagnostics confirmed canonical root/user, every uploaded
  file, runtime SHA/size, dump tools and Bundler dependencies. Venv activation
  returned 0 when sourced in an if condition, despite RubyGems warnings.
- Scoped conditional venv activation now requires the final activation status;
  all subsequent checks keep errexit/pipefail. Both install/rollback scripts
  report phase, line and exit code from an early ERR trap. Install progress and
  a preflight-only mode were added; runtime bytes are unchanged.
- Six local Bash-prefix regression checks passed: reproduce the old failure
  on an intermediate activation probe, successful conditional activation for
  install/rollback, fail-fast diagnostics for subsequent errors in each, and
  refusal of an actual activation failure. No DB/deployment code was executed.
- Bash syntax checks passed. The op2 operator archive has fresh checksums;
  original operator and accepted plugin ZIPs remain unchanged. Remote root
  cause is an inference from the diagnostic/errexit difference, not a claim to
  have inspected the server's activation file.

## 2026-11-25 - Staging package/runbook handoff

- Runtime promoted byte-for-byte from accepted r2 install ZIP: 169409 bytes,
  SHA-256 FA3B218167DAEC4996486BB22D6D0F1D0B5FFC3CC0952DCFD2C1F1B923B60F67.
- Runtime manifest and every runtime file hash verified. No application code
  changed; existing 165 runs / 1084 assertions / 0 failures/errors/skips remains
  the runtime test evidence. Full suite was not repeated for operator docs.
- Install/rollback scripts passed Bash syntax checks; Rails verification helper
  passed Ruby syntax checking. These checks do not certify execution on GCR.
- Operator archive has per-member hashes, LF text, a SHA256SUMS file and the
  staging runtime ZIP. No remote deployment or DB operation was executed locally.
- N-01 recorded as deferred PPD-N-01 in docs/BACKLOG.md; no runtime change.

## 2026-11-25 - 1.3.20 QA build r2 (R-01..R-03)

- Fixed nil lft/rgt leaf evaluation without repairing source hierarchy. Added
  actual test DB NULL combinations, mixed/invalid-only project cases, API/evidence
  and real Overview HTTP coverage. Normal-data algorithm remains 1.2.
- Focused regression run: `8 runs`, `199 assertions`, `0 failures`, `0 errors`,
  `0 skips`, exit 0 (4.220883 seconds).
- Complete Redmine 6.1.2 suite with normal test DB preparation:
  `165 runs`, `1084 assertions`, `0 failures`, `0 errors`, `0 skips`, exit 0
  (18.463325 seconds). Known junction duplicate-constant warnings are non-fatal.
- Normalized 159 source text files; independent audit of all 191 source text
  files found zero CR bytes. Git now enforces text=auto/eol=lf. Binary input QA
  reports, ignored local context, generated logs and prior ZIPs were untouched.
- Syntax/locale checks passed: 63 Ruby/Rake/RSB files including benchmark tool,
  50 locale roots, EN/BG key parity, 10 ERB templates and Python build tools.
- Restored the 1.3.19 changelog entry from its historical release handoff.
- Local QA ref qa-v1.3.20-r2 identifies the committed build source. Build script
  reads Git blobs, verifies workspace/ref identity and LF-only text, requires
  successful complete test exit status, records test-log hash and fixes ZIP
  metadata for reproducible archives. Package hashes are emitted in the external
  output/qa/1.3.20-r2/package-verification.json and manifests.
- Fresh CPU-only 20,000-issue benchmark: summary 415.772ms -> 97.325ms;
  details 1398.218ms -> 195.247ms versus 1.3.19. No SQL/DB latency claim.
- QA source commit/tag are local. No push, deployment or production promotion.
  MySQL/MariaDB, deployed UI, actual PB/PPH, SMTP/cron and real-project performance
  remain environment-specific staging gates.

## 2026-11-24 - 1.3.20 repeat QA remediation

- Implemented PPD-01..08 from the QA report; user approved excluding every
  parent regardless of child project. Algorithm 1.2; public contract/evidence
  schema remain 1.0. Stored snapshots are not rewritten.
- Focused QA regressions: `6 runs`, `172 assertions`, `0 failures`, `0 errors`,
  `0 skips`, exit 0 (3.746918 seconds).
- Complete Redmine 6.1.2 suite with normal test DB preparation:
  `162 runs`, `1054 assertions`, `0 failures`, `0 errors`, `0 skips`, exit 0
  (17.889307 seconds). Admin flash and real SQLite schema/data-preservation
  regressions are included. Known duplicate-constant warnings were non-fatal.
- Ruby/Rake/RSB syntax, ERB compilation, 50 locale root checks and EN/BG key
  parity passed. Standalone packaging/benchmark scripts checked separately.
- Synthetic calculator benchmark: median of three, 25% parents, fractional
  estimates, no DB/SQL/request measurement. At 20,000 issues summary changed
  from 387.500ms to 89.881ms; details from 1422.086ms to 196.195ms. At 2,000
  issues Rational arithmetic added roughly 2ms summary / 4ms details.
- Install/source/outer QA ZIPs are separate and independently manifested and
  verified by scripts/build_qa_package.py. Package evidence is generated under
  output/qa/1.3.20/package-verification.json, without a source-commit claim for
  uncommitted changes. Base commit is recorded separately from snapshot hash.
- MySQL/MariaDB, deployed UI, actual PB/PPH integration, SMTP/cron and real
  representative-project performance remain staging/re-QA gates, not local claims.
- No new production deployment, release tag, commit or push in this task.

## 2026-11-17 - Relocation validation and documentation closeout

- Repointed the external Redmine 6.1.2 plugin junction to the relocated checkout.
- Shared setup reused Ruby 3.3.11 and Bundler 2.5.22; no gems were installed.
- Full suite with normal test database preparation, exit code 0:
  `153 runs`, `867 assertions`, `0 failures`, `0 errors`, `0 skips` in
  `41.582332` seconds. Known duplicate-constant warnings were non-fatal.
- Static checks passed for 61 Ruby/Rake/RSB files, 50 locale YAML files, the test
  manifest, 10 ERB templates, and repository PowerShell scripts.
- README and Public API V1 documentation were reconciled with 1.3.19 evidence
  and coexistence behavior. Documentation-only changes do not alter the tested
  application code. Local links and Markdown fences were checked.
- Existing 1.3.19 staging/production archives were rehashed: both 338725 bytes,
  SHA-256 `E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11`.
- No new package, version, tag, or server deployment was created.

## 2026-10-11 - Public API V1 Optional Issue Evidence

- Extended `ProjectPercentDone::PublicApi::V1.calculate` with optional
  `include_evidence: true` support for Project Progress History provider
  consumption.
- Default `calculate(:project => project)` result shape remains issue-row-free
  and backward compatible.
- Evidence mode returns project metadata, grouped metrics, provider metadata,
  and scalar `issue_evidence` rows for direct project issues.
- Bumped `redmine_project_percent_done` plugin version from `1.3.18` to
  `1.3.19` for the staging evidence API build.
- No database migrations, cron behavior, snapshot collection, history tab, or
  current Project % Done calculation semantics were changed.
- Focused Redmine 6.1.2 validation through the shared
  `redmine-plugin-test-runtime`:
  - Public API V1 test:
    `18 runs`, `172 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed after the final evidence-scope
  adjustment:
  `153 runs`, `867 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed again after the `1.3.19` version
  bump:
  `153 runs`, `867 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Staging package created and inspected:
  `release_packages/redmine_project_percent_done-1.3.19-staging-20261011-evidence-api.zip`.
  Package size: `338725` bytes. SHA-256:
  `E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11`.
  Package inspection confirmed a single `redmine_project_percent_done/`
  top-level directory with `init.rb`, version `1.3.19`, and no `.git`,
  `.codex`, `.agents`, `release_packages`, `tmp`, `log`, `vendor`, or
  `.bundle` entries.
- User-run staging validation completed successfully on GCR staging:
  - UI smoke test passed for project progress, Project Progress History pages,
    and plugin settings pages.
  - PPH evidence write validation created daily operational snapshots for
    `2026-10-11`.
  - Read-only DB verification confirmed recent snapshots with
    `source_version=1.3.19`, `evidence_schema=1.0`, and issue evidence rows
    persisted, including snapshot IDs `2278` through `2287`.
- Production package promoted byte-for-byte from the staging-approved package:
  `release_packages/redmine_project_percent_done-1.3.19-production-20261011-evidence-api.zip`.
  Package size: `338725` bytes. SHA-256:
  `E419160AFEC56D458DFC8E95E596A80410FD3BCD6CED67A133C7D6A0F35F4C11`.
- User-run production validation completed successfully on GCR production:
  - Production install script ended with
    `SUCCESS: PPD 1.3.19 and PPH 0.2.2 installed on production`.
  - UI smoke test passed for project pages and Project Progress History pages;
    no HTTP 500 errors were observed.
  - Production evidence collection completed successfully with PPH Run ID `84`,
    `54` projects processed, `54` daily operational snapshots created, `0`
    failed or unavailable, and notification email delivered.
  - Read-only DB verification confirmed recent production snapshots with
    `source_version=1.3.19`, `evidence_schema=1.0`, and issue evidence rows
    persisted, including snapshot IDs `2249` through `2258`.
  - The weekly official timeline row for `2026-10-11` may show `missing` on
    `2026-10-11` because the daily operational snapshot is present but the
    weekly official promotion for `2026-10-05` through `2026-10-11` is not due
    until the next capture day.
- Release state: `production-approved`.

## 2026-10-07 - 1.3.18 Staging CSS Asset Hotfix

- Staging validation of
  `redmine_project_percent_done-1.3.18-staging-20261007-cleanup.zip` exposed
  missing Project Percent Done CSS:
  `/assets/plugin_assets/redmine_project_percent_done/project_percent_done-dfa65724.css?v=1.3.14-r1`
  returned `ActionController::RoutingError`.
- The missing stylesheet caused the settings help icons/tooltips, calculation
  details filter chips, and collapsible section buttons to render with native
  browser/Redmine fallback styling.
- Updated the settings and calculation details views to load the stable copied
  plugin asset path:
  `/plugin_assets/redmine_project_percent_done/stylesheets/project_percent_done.css?v=1.3.18-r2`.
- No database migrations, Public API V1 contract changes, current Project %
  Done calculation changes, or cron changes were made.
- Initial parallel focused test attempts hit transient SQLite `database is
  locked` errors in the shared test runtime; sequential reruns passed:
  - settings controller:
    `9 runs`, `77 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - project percent done controller:
    `17 runs`, `148 assertions`, `0 failures`, `0 errors`, `0 skips`.

## 2026-10-07 - 1.3.18 Project Percent Done Cleanup Inventory/UI Delegation

- Confirmed repository scope is `redmine_project_percent_done`; no work was
  done in Project Contribution or Project TimeShift.
- Inventoried remaining Project Percent Done history surfaces and recorded the
  cleanup boundary in `docs/PROJECT_PERCENT_DONE_CLEANUP_INVENTORY.md`.
- Kept Project Percent Done as source of truth for the current Project % Done
  value and `ProjectPercentDone::PublicApi::V1`.
- No destructive migrations were added or run; old `project_percent_done_*`
  history tables remain archived in place.
- Extended the coexistence cleanup so, while Project Progress History owns
  history:
  - legacy dashboard/sidebar snapshot freshness rows are suppressed;
  - legacy history email enablement reads disabled;
  - old history settings remain represented by the delegation notice instead of
    appearing as Project Percent Done-owned controls.
- Focused Redmine 6.1.2 validation through the shared
  `redmine-plugin-test-runtime`:
  - coexistence guard test:
    `4 runs`, `6 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - hook/dashboard cleanup test:
    `5 runs`, `21 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - settings controller test:
    `9 runs`, `77 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - admin controller test:
    `3 runs`, `9 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - snapshot collector test:
    `11 runs`, `53 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - settings test:
    `10 runs`, `51 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - Public API V1 test:
    `16 runs`, `128 assertions`, `0 failures`, `0 errors`, `0 skips`.
- First full-suite attempt exposed a stale shared test DB missing legacy history
  tables (`project_percent_done_snapshots` and
  `project_percent_done_collection_runs`): `151 runs`, `480 assertions`,
  `0 failures`, `64 errors`, `0 skips`.
- Re-ran `scripts/setup_redmine_test_runtime.ps1` from the shared
  `redmine-plugin-test-runtime` skill to restore the Redmine 6.1.2 runtime
  wiring/test database state.
- Final full Redmine 6.1.2 plugin suite passed:
  `151 runs`, `823 assertions`, `0 failures`, `0 errors`, `0 skips`.
- No package or deployment artifact was prepared.

## 2026-10-01 - 1.3.18 Project Progress History Coexistence Guard

- Added a defensive coexistence guard for `redmine_project_progress_history`
  ownership of historical progress behavior.
- Project Percent Done continues to own the live Project % Done calculation and
  `ProjectPercentDone::PublicApi::V1`.
- When Project Progress History is active, Project Percent Done suppresses old
  history ownership surfaces:
  - history availability/settings;
  - admin preview/capture/test-email/purge endpoints;
  - cron/rake snapshot, cleanup, purge, and staging-demo paths;
  - snapshot collector writes.
- Settings saves sanitize old `history_enabled` and `history_email_enabled`
  flags to `0` while Project Progress History owns history behavior.
- Hidden historical settings are preserved during guarded settings saves so
  rollback and transition validation do not lose the previous configuration.
- Local Redmine 6.1.2 validation:
  - focused coexistence test:
    `4 runs`, `6 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - focused settings test:
    `10 runs`, `51 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - focused snapshot collector test:
    `11 runs`, `53 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - focused settings controller test:
    `9 runs`, `77 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - focused admin controller test initially hit transient SQLite
    `database is locked` during fixture loading; rerun passed:
    `3 runs`, `9 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - full Redmine 6.1.2 plugin suite passed:
    `150 runs`, `821 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Staging package candidate update:
  - bumped plugin version to `1.3.18` for the coexistence guard build;
  - updated the Public API test to assert the exported plugin version against
    `ProjectPercentDone::PLUGIN_VERSION`;
  - post-bump full Redmine 6.1.2 plugin suite passed:
    `150 runs`, `821 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Prepared staging package:
  `redmine_project_percent_done-1.3.18-staging-20261001.zip`.
- Package size: `322576` bytes.
- SHA-256:
  `0E4F0F37DB66E0646024CC9F65E860EFB073DAFA6F03237E7193ADBC2A6DB043`.
- Package inspection confirmed a single `redmine_project_percent_done`
  top-level folder, `init.rb`, `179` archive entries, and no `.git`,
  `.agents`, `.codex`, `tmp`, `log`, `.bundle`, `vendor/bundle`, or
  `release_packages` entries.
- Split staging companion package prepared:
  `redmine_project_progress_history-0.1.0-staging-20261001.zip`.
- Companion package SHA-256:
  `51094452B2678764B68264FBF7F79866570BE2407FB3A66D041B62432437472A`.

## 2026-09-29 - 1.3.17 Project Truth Visibility Transparency

- Preserved the existing all-project aggregate semantics for Project % done.
- Added an always-visible calculation-details summary showing how many included
  and not-included issue detail rows the current user can view.
- Clarified diagnostic CSV link tooltips so users know exports include only
  issue rows visible to their account.
- Bumped plugin version to `1.3.17`; calculation algorithm and public API
  contract versions remain unchanged.
- Local validation:
  - `ruby -c app/controllers/project_percent_done_controller.rb` -> OK;
  - `ruby -c test/functional/project_percent_done_controller_test.rb` -> OK;
  - `ruby -c test/unit/project_percent_done/public_api_v1_test.rb` -> OK;
  - locale YAML load check for `config/locales/*.yml` -> OK;
  - focused controller test:
    `17 runs`, `148 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - focused Public API V1 test:
    `16 runs`, `128 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - full Redmine 6.1.2 plugin suite passed:
    `141 runs`, `786 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Prepared staging package:
  - `redmine_project_percent_done-1.3.17-staging-20260929.zip`
  - SHA-256:
    `B2453CF01EE5EF906364567E66DCD0216C4D8B0105D27133C53039FACAA5F058`
  - size: `314869` bytes
  - archive root: `redmine_project_percent_done/`
  - package inspection confirmed version `1.3.17` and no `.git`, `.agents`,
    `.codex`, `tmp`, or `release_packages` entries.
- Staging was confirmed OK by the user on 2026-09-29 after manual checks of
  the details page visibility summary and CSV tooltip behavior.
- Prepared production package as a byte-for-byte copy of the approved staging
  package:
  - `redmine_project_percent_done-1.3.17-production-20260929.zip`
  - SHA-256:
    `B2453CF01EE5EF906364567E66DCD0216C4D8B0105D27133C53039FACAA5F058`
  - size: `314869` bytes
  - byte-for-byte identical to
    `redmine_project_percent_done-1.3.17-staging-20260929.zip`.
- Production was confirmed OK by the user on 2026-09-29 after installing
  `1.3.17`.
- Final release state: `production-approved`.

## 2026-09-24 - 1.3.16 CSV Formula Prefix Hardening

- Extended diagnostic CSV formula neutralization to prefix string values that
  begin with tab or carriage-return characters, matching the broader CSV safety
  rule used by Project Contribution.
- Bumped plugin version to `1.3.16`; calculation algorithm and public API
  contract versions remain unchanged.
- Added functional regressions for tab-prefixed included subjects and
  carriage-return-prefixed not-included subjects.
- Local validation:
  - `ruby -c app\controllers\project_percent_done_controller.rb` -> OK;
  - `ruby -c test\functional\project_percent_done_controller_test.rb` -> OK;
  - `ruby -c test\unit\project_percent_done\public_api_v1_test.rb` -> OK;
  - focused Public API V1 test:
    `16 runs`, `128 assertions`, `0 failures`, `0 errors`, `0 skips`;
  - initial parallel focused controller test hit SQLite
    `database is locked` while the Public API test was using the same shared
    runtime database; sequential rerun passed with `16 runs`, `127 assertions`,
    `0 failures`, `0 errors`, `0 skips`;
  - `git diff --check` passed with expected Windows LF/CRLF warnings only;
  - full Redmine 6.1.2 plugin suite passed:
    `140 runs`, `765 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Release commit:
  `84015a3 Release project percent done 1.3.16`.
- Prepared staging package:
  - `redmine_project_percent_done-1.3.16-staging-20260929.zip`
  - SHA-256:
    `4DE7551031777FDCA8B96CA3857C54486D351B2CAF9C2E0A4589554073E5ADA2`
  - size: `268825` bytes
  - archive root: `redmine_project_percent_done/`
  - package inspection confirmed version `1.3.16` and no `.git`, `.agents`,
    `.codex`, `tmp`, or `release_packages` entries.
- Staging was confirmed OK by the user on 2026-09-29 after manual checks:
  version `1.3.16`, Project % Done page, included/not-included sections, CSV
  export, filtered CSV row sets and filenames, UTF-8/Cyrillic CSV handling, and
  formula-like subject escaping.
- Staging CSV formula check showed:
  `8289,"'=HYPERLINK(""http://example.test"");",В изчакване,0.00%,,Unestimated issue ignored by plugin setting`
  which is the expected quoted CSV field with doubled internal quotes and a
  leading apostrophe.
- Staging log review from the provided output showed asset compilation INFO
  lines including `plugin_assets/redmine_project_percent_done`, no plugin 500s
  or stack traces, and only unrelated staging sendmail delivery errors for the
  fake `redmine-staging@example.invalid` sender.
- Prepared production package as a byte-for-byte copy of the approved staging
  package:
  - `redmine_project_percent_done-1.3.16-production-20260929.zip`
  - SHA-256:
    `4DE7551031777FDCA8B96CA3857C54486D351B2CAF9C2E0A4589554073E5ADA2`
  - size: `268825` bytes
  - byte-for-byte identical to
    `redmine_project_percent_done-1.3.16-staging-20260929.zip`.
- Production was confirmed OK by the user on 2026-09-29 after installing
  `1.3.16`.
- Final release state: `production-approved`.

## 2026-09-24 - 1.3.15 CSV Formula Hardening

- Escaped formula-like string values in included and not-included diagnostic
  CSV exports by prefixing values that begin with `=`, `+`, `-`, or `@`.
- Updated included and not-included diagnostic CSV exports to follow the active
  table filters and include sanitized filter suffixes in downloaded filenames.
- Bumped plugin version to `1.3.15`; calculation algorithm and public API
  contract versions remain unchanged.
- Added functional regressions for formula-like `Subject` values in both CSV
  export tables.
- Added functional regressions for filtered CSV row sets and filtered CSV
  filenames in both diagnostic export tables.
- Local validation:
  - focused controller test:
    `16 runs`, `119 assertions`, `0 failures`, `0 errors`, `0 skips`.
  - focused Public API V1 test:
    `16 runs`, `128 assertions`, `0 failures`, `0 errors`, `0 skips`.
  - full Redmine 6.1.2 plugin suite:
    `140 runs`, `757 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Prepared staging package:
  - `redmine_project_percent_done-1.3.15-staging-20260924.zip`
  - SHA-256:
    `340E0401F82299A36852BE856A3B7FA547D022A23FF5AFD7FE51EDF364416F8C`
  - size: `299417` bytes
  - archive root: `redmine_project_percent_done/`
  - package inspection confirmed version `1.3.15` and no `.git`, `.agents`,
    `.codex`, `tmp`, or `release_packages` entries.
- Staging was confirmed OK by the user on 2026-09-24.
- Release state after staging confirmation: `staging-approved`.
- Prepared production package as a byte-for-byte copy of the approved staging
  package:
  - `redmine_project_percent_done-1.3.15-production-20260924.zip`
  - SHA-256:
    `340E0401F82299A36852BE856A3B7FA547D022A23FF5AFD7FE51EDF364416F8C`
  - size: `299417` bytes
  - byte-for-byte identical to
    `redmine_project_percent_done-1.3.15-staging-20260924.zip`.
  - release state after production package preparation: `packaged-production`.
- Production was confirmed OK by the user on 2026-09-24 after manual checks
  and production log review.
- Final release state: `production-approved`.

## 2026-09-24 - 1.3.14 Diagnostic UI Polish

- Restyled calculation detail quick filters to follow the Project Risk
  dashboard pill/tab visual pattern: rounded pills, semantic colors, active
  selection ring, and count bubbles.
- Added server-rendered counts to included and not-included quick filters.
- Improved not-included combined non-progress filtering so rows excluded by
  both status and tracker match both quick filters.
- Extended `Subject` left alignment to historical issue detail tables.
- Bumped plugin version to `1.3.14` and CSS cache busters to `1.3.14-r1`.
- Local validation:
  - `ruby -c lib\project_percent_done.rb` -> OK;
  - `ruby -c test\functional\project_percent_done_controller_test.rb` -> OK;
  - `ruby -c test\unit\project_percent_done\public_api_v1_test.rb` -> OK;
  - ERB compile checks for touched settings/show/history views: passed;
  - locale YAML parse checks: passed;
  - `git diff --check` passed with expected Windows LF/CRLF warnings only.
- Redmine runtime focused tests were not run in this pass because the current
  approval policy rejected escalated access to the shared Redmine test runtime.
- Prepared staging package:
  - `redmine_project_percent_done-1.3.14-staging-20260924-r2.zip`
  - SHA-256:
    `FFF1ABFA0E3DC316C8933A2363A33816FFDF5666090DAD88EC2F174420615CA2`
  - size: `287251` bytes
  - archive root: `redmine_project_percent_done/`
  - package inspection confirmed version `1.3.14` and no `.git`, `.agents`,
    `.codex`, `tmp`, or `release_packages` entries.
- Staging was confirmed OK by the user on 2026-09-24.
- Release state after staging confirmation: `staging-approved`.
- Prepared production package as a byte-for-byte copy of the approved staging
  package:
  - `redmine_project_percent_done-1.3.14-production-20260924.zip`
  - SHA-256:
    `FFF1ABFA0E3DC316C8933A2363A33816FFDF5666090DAD88EC2F174420615CA2`
  - size: `287251` bytes
  - byte-for-byte identical to
    `redmine_project_percent_done-1.3.14-staging-20260924-r2.zip`.
  - release state after production package preparation: `packaged-production`.
- Production was confirmed OK by the user on 2026-09-24 after installing
  `1.3.14`.
- Final release state: `production-approved`.

## 2026-09-23 - 1.3.13 All-Excluded Non-Progress Diagnostics

- Fixed QA finding `QAPPD1312-001`: when all candidate leaf issues are excluded
  by configured non-progress status and/or tracker rules, calculation details
  now still build the not-included diagnostic rows and reasons.
- Kept calculation semantics unchanged: the result remains `0%` with
  `no_eligible_issues`; the fix only restores diagnostics/CSV/history issue
  rows and the diagnostic excluded applied weight.
- Added calculator regressions for:
  - all leaf issues excluded by tracker scope;
  - all leaf issues excluded by combined status and tracker rules;
  - excluded applied weight including the unestimated fallback in the
    all-excluded branch.
- Validation after the change:
  - `ruby -c lib\project_percent_done\project_progress_calculator.rb` -> OK;
  - `ruby -c test\unit\project_percent_done\project_progress_calculator_test.rb`
    -> OK;
  - focused calculator test: `27 runs`, `113 assertions`, `0 failures`,
    `0 errors`, `0 skips`;
  - focused controller test: `12 runs`, `97 assertions`, `0 failures`,
    `0 errors`, `0 skips`;
  - focused Public API V1 test: `16 runs`, `128 assertions`, `0 failures`,
    `0 errors`, `0 skips`;
  - focused history snapshot collector test initially hit SQLite
    `database is locked` after an earlier interrupted parallel run; after the
    leftover Ruby process exited, sequential rerun passed with `10 runs`,
    `44 assertions`, `0 failures`, `0 errors`, `0 skips`.
  - ERB compile checks for touched settings/show views: passed;
  - locale YAML parse checks: passed;
  - `git diff --check` passed with expected Windows LF/CRLF warnings only;
  - full Redmine 6.1.2 plugin suite passed:
    `136 runs`, `735 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Prepared staging QA package:
  - `redmine_project_percent_done-1.3.13-staging-20260923.zip`
  - SHA-256:
    `4EE45CACE42A178285812A4E1524F5230F8BE2C5541082C2E37D44213A588499`
  - size: `282660` bytes
  - archive root: `redmine_project_percent_done/`
  - package inspection confirmed version `1.3.13` and no `.git`, `.agents`,
    `.codex`, `tmp`, or `release_packages` entries.
- Prepared QA agent bundle:
  - `qa-agent-project-percent-done-1.3.13-20260923-qappd1312-001.zip`
  - SHA-256:
    `1ADC55A1396D48D765E6530B520D34996ADAF807BFA0CA00AF00557D65174495`
  - size: `220199` bytes
  - contents: staging plugin ZIP, `HANDOFF_1.3.13.md`, and
    `QA_BRIEF_project_percent_done_1.3.13.md`.

## 2026-09-16 - 1.3.12 Non-Progress Tracker Scope

- Added an explicit `No tracker exclusions` / `All trackers` setting for
  tracker-based non-progress exclusions.
- Preserved legacy behavior for existing saved tracker IDs that predate the new
  tracker scope setting: if tracker IDs exist and no tracker scope key is stored,
  the effective scope remains `all`.
- Exposed `non_progress_tracker_scope` in live API metadata and historical
  settings snapshots.
- Prepared packages:
  - staging: `redmine_project_percent_done-1.3.12-staging-20260916.zip`
    - SHA-256: `B621DB93624D222EEE91441E01C6EDCF5C1CF1274CAB20852962385EC22EBC47`
    - size: `276834` bytes
  - production: `redmine_project_percent_done-1.3.12-production-20260916.zip`
    - SHA-256: `BA6E998B1A69EB3C8B2C8F7A0B5956A8FCACA238199D49FB22BB9E165B1EE563`
    - size: `276834` bytes
  - archive root: `redmine_project_percent_done/`
  - packages were built from the same source state but are not byte-for-byte
    identical because they were created as separate staging/production archives.
- Local validation:
  - syntax checks for touched Ruby tests and code: passed;
  - locale YAML parse checks: passed;
  - ERB compile checks for touched views: passed;
  - focused settings test: `9 runs`, `49 assertions`, `0 failures`,
    `0 errors`, `0 skips`;
  - focused calculator test: `24 runs`, `96 assertions`, `0 failures`,
    `0 errors`, `0 skips`;
  - focused Public API test: `16 runs`, `128 assertions`, `0 failures`,
    `0 errors`, `0 skips`;
  - focused history snapshot collector test: `10 runs`, `44 assertions`,
    `0 failures`, `0 errors`, `0 skips`;
  - focused settings controller test after applying plugin migrations in the
    shared test DB: `7 runs`, `60 assertions`, `0 failures`, `0 errors`,
    `0 skips`;
  - focused controller test: `12 runs`, `97 assertions`, `0 failures`,
    `0 errors`, `0 skips`;
  - full Redmine 6.1.2 plugin suite passed:
    `133 runs`, `718 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Staging was confirmed OK by the user on 2026-09-16 after installing
  `1.3.12`.
- Production was confirmed OK by the user on 2026-09-16 after installing
  `1.3.12`; release state is `production-approved`.

## 2026-08-13 - 1.3.6 Dashboard Snapshot Freshness Refinement

- Replaced the single dashboard "last snapshot" line with separated freshness
  rows for latest operational backup, latest official weekly snapshot, and
  latest official monthly snapshot.
- Added an explicit dashboard message when no official monthly snapshot exists
  yet, while preserving the safe no-table guard during code-before-migrations
  deployment windows.
- Focused hook/dashboard check passed:
  `113 runs`, `544 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `113 runs`, `544 assertions`, `0 failures`, `0 errors`, `0 skips`.

## 2026-08-13 - 1.3.5 Dashboard Snapshot Freshness

- Added dashboard freshness information to the project overview and sidebar
  Project % done widgets. When stored history exists, the widgets show the
  latest snapshot capture time, snapshot kind, period type, and period end.
- Added focused hook/partial coverage proving the latest snapshot is passed to
  the dashboard partial and rendered. The hook also skips the lookup safely when
  the snapshot table is not available yet during a code-before-migrations swap.
- Focused hook/dashboard check passed:
  `113 runs`, `537 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `113 runs`, `537 assertions`, `0 failures`, `0 errors`, `0 skips`.
- `git diff --check` passed with only expected Windows LF/CRLF warnings.

## 2026-08-12 - 1.3.4 Fresh-Install Migration Safety

- Reviewed the migration chain and confirmed the issue: current migration `001`
  already creates `project_percent_done_snapshots.period_type`, while migration
  `002` tried to add the same column unconditionally.
- Fixed migration `002` so it is safe in both supported scenarios:
  - fresh install: skip duplicate `period_type` column/index creation when
    `001` already created them;
  - upgrade from pre-period-type history: add `period_type`, backfill existing
    snapshot rows to `weekly`, remove the old uniqueness index, and add the new
    `project_id + period_type + period_end` uniqueness boundary.
- Added focused migration strategy tests that simulate fresh-install and
  upgrade schema shapes without dropping real test tables.
- Added and ran `scripts/check_period_type_migrations.ps1`, which executes the
  real migrations against a temporary SQLite database. Result:
  `fresh_install=ok` and `upgrade=ok`.
- Focused migration/API check passed:
  `110 runs`, `527 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Full Redmine 6.1.2 plugin suite passed:
  `110 runs`, `527 assertions`, `0 failures`, `0 errors`, `0 skips`.

## 2026-08-12 - 1.3.3 Monthly Initial-Start Status Fix

- Fixed the monthly status banner for installations/projects that have no
  monthly official snapshots yet. The first past monthly period is no longer
  shown as overdue when monthly collection is newly introduced; the status waits
  for the current month-end snapshot.
- Added regression coverage proving that real monthly gaps still become
  overdue after monthly history has started.
- Full Redmine 6.1.2 plugin suite passed:
  `107 runs`, `513 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Prepared production and staging ZIP packages:
  - `redmine_project_percent_done-1.3.3-production-20260812.zip`
  - `redmine_project_percent_done-1.3.3-staging-20260812.zip`
  - SHA-256 for both: `2ABA8D485247F2B4B8FBAE4158BBD3335975FEE5CDD1B5E4004A053DECD0ACDD`
  - size for both: `151592` bytes
  - archive root: `redmine_project_percent_done/`
- Staging was confirmed OK by the user after installation:
  `plugin_version=1.3.3`, `history_enabled=true`,
  `monthly_status_state=waiting`, `monthly_next_period_end=2026-09-30`,
  `monthly_expected_capture_date=2026-10-01`, and no fresh log errors.

## 2026-08-12 - 1.3.0-1.3.2 Historical Public API and Monthly Snapshots

- Added official monthly snapshot support on top of the existing weekly history
  model. Existing official rows migrate to `period_type = weekly`; monthly rows
  use `period_type = monthly`.
- Added historical in-process Public API methods:
  `history_capabilities`, `latest_official_snapshot`,
  `official_snapshot_for`, `official_snapshots_between`, and `progress_at`.
- Added project history period-type selection, monthly table/chart support, and
  monthly digest reporting.
- Fixed the staging simulation edge case where a future-dated monthly snapshot
  was created and emailed but hidden from the monthly table/chart.
- Full-suite results during the 1.3.x cycle were green; detailed per-patch
  evidence is in `docs/TESTING_1.3.0.md`, `docs/TESTING_1.3.1.md`,
  `docs/TESTING_1.3.2.md`, and `docs/TESTING_1.3.3.md`.

## 2026-07-16 - 1.2.0 Historical Progress V1

- Implemented optional daily operational and weekly official history with
  project/issue detail levels, retention, diagnostics, email, and graph/table UI.
- Added observed project start/planned-end date history, calendar plan phases,
  reported-time boundary analysis, explicit pre-collection gaps, and guarded
  shadow forecasts.
- Applied migration `001` in the shared Redmine 6.1.2 test runtime.
- Focused plan/history suite passed: `20 runs`, `78 assertions`, `0 failures`,
  `0 errors`, `0 skips`.
- Full suite passed: `65 runs`, `277 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Staging regression fixed: project-type values now load immediately when the
  selected custom field changes, without an intermediate save.
- Focused settings test passed: `3 runs`, `13 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Post-fix full suite passed: `66 runs`, `281 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Second staging feedback fixed: legacy settings now render the numeric defaults,
  and the email section follows the historical collection switch.
- Focused settings suite passed: `6 runs`, `25 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Final full suite passed: `69 runs`, `293 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Hardened the staging fix for persisted blank values and Redmine theme CSS;
  both chart and email sections now follow the history switch.
- Focused settings checks: `6 runs`, `26 assertions`; final full suite:
  `69 runs`, `294 assertions`, all green.
- Added the run-level digest subject default and blank-legacy fallback. Focused
  settings checks passed with `6 runs`, `28 assertions`; subject renderer checks
  passed with `4 runs`, `8 assertions`.
- Final full suite passed: `70 runs`, `297 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Fixed staging settings submission: diagnostic `button_to` helpers had emitted
  nested forms that broke the enclosing Redmine settings form in browsers.
  Diagnostic controls now use independent POST action links.
- Focused settings controller: `7 runs`, `36 assertions`, all green. Final full
  suite: `71 runs`, `305 assertions`, `0 failures`, `0 errors`, `0 skips`.
- Removed the unnecessary multi-value-only restriction for the project-type
  custom field. Both single-value and multi-value list fields are supported;
  non-list fields remain rejected.
- Focused selector/validator/settings checks passed with `3/9`, `5/13`, and
  `7/36`. Final full suite: `73 runs`, `310 assertions`, all green.
- Split historical progress into a dedicated project route/page/tab, added a
  clear no-official-snapshots state, and removed admin-only "Initial" wording
  from project controls.
- Initial collection now excludes untracked closed/archived projects while
  retaining state-marker processing for previously tracked projects.
- Focused controller/selector/collector checks passed with `5/25`, `5/13`, and
  `6/23`. Final full suite: `78 runs`, `332 assertions`, all green.
- Fixed hidden project-menu items by assigning Redmine's `view_project`
  permission. Added direct history links to the overview/sidebar progress block
  and calculation page. Focused controller checks passed with `6 runs`, `28
  assertions`; final full suite passed with `79 runs`, `335 assertions`, all green.
- Fixed the staging 500 caused by calling a plugin helper from Redmine's generic
  hook view context; history availability is now passed as a render local.
- Fixed same-day idempotent collection returning boolean `false` into an integer
  counter. Focused hook and collector tests passed with `1/2` and `6/26`; final
  full suite passed with `80 runs`, `342 assertions`, all green.
- Fixed project-menu focus by assigning action-specific menu items to the
  calculation and history actions. Focused controller checks passed with `6
  runs`, `32 assertions`; final full suite passed with `80 runs`, `344
  assertions`, all green.
- Added a staging-host-guarded demo-history generator with preview, idempotent
  seed, cleanup, foreign-history refusal, 16 weekly periods, state/gap samples,
  issue details, plan changes, time anomalies, and forecast-ready points.
- Focused demo generator checks passed with `3 runs`, `23 assertions`; final
  full suite passed with `83 runs`, `367 assertions`, all green.
- Added Project Risk-style Administration cron guidance with a generated rake
  command, full hosting command, runtime detection, copy controls, and the
  recommended daily `5 0 * * *` schedule. Focused checks passed with `9 runs`,
  `47 assertions`; final full suite passed with `85 runs`, `378 assertions`.
- Reworked the protected staging demo into a coherent project model with six
  phase-based issues, 200 estimated hours, 132 real reported hours, and a live
  result of 60%. Every active project snapshot is derived from its issue-detail
  weights, and repeated seeding replaces the same demo work items without
  duplication. The generator now also absorbs snapshots created in its strictly
  identified private demo project by normal admin or cron runs, while refusing
  renamed projects and foreign issues. Focused checks passed with `3 runs`, `59
  assertions`; final full suite passed with `85 runs`, `414 assertions`.
- Ruby, ERB, YAML, EN/BG parity, and `git diff --check` passed.
- Prepared staging package:
  `redmine_project_percent_done-1.2.0-staging-20260716-r17.zip`.
- Package size: `195334` bytes.
- SHA-256:
  `4500639E28B49402982B4E256951B9BD09A88094DF2860FDFB1C4D3657ADA43F`.
- Release state: `staging-approved` on 2026-07-16. The user confirmed the `r17`
  installation and the protected seed result: 14 project snapshots, 66 issue
  snapshots, 15 collection runs, 60% live progress, 200 estimated hours, and
  132 reported hours. Production promotion remains pending.
- Detailed evidence: `docs/TESTING_1.2.0.md`.

## 2026-07-10 - 1.1.1 Administration Settings Help UI

Prepared Project Percent Done `1.1.1` as a UX consistency patch for the
Administration → Plugins → Project Percent Done settings page.

Scope:

- added help icons to every administrative setting;
- added concise English and Bulgarian help copy;
- followed the Budget Risk Monitor / Risk Monitor Pro help UX model:
  `button.icon-help`, custom `data-tooltip`, hover/focus/tap support, Escape to
  close, and no native `title` tooltip on help buttons;
- added minimal plugin stylesheet for compact help icons and tooltip styling;
- did not change calculation behavior, REST output, Public API V1, algorithm
  version, or Risk Monitor integration contract.

Validation notes:

- local static checks completed:
  - `ruby -c init.rb`
  - Ruby syntax check for `lib`, `app`, and `test`
  - YAML parsing for every locale file
  - ERB compile for every `.erb` view
  - `ruby -c app/views/project_percent_done/show.api.rsb`
  - EN/BG help locale parity check: 8 help keys
  - settings partial check confirmed help buttons use `data-tooltip` and no
    native `title=`
  - `git diff --check` reported no whitespace errors, only Windows LF/CRLF
    warnings
- staging package prepared:
  - `redmine_project_percent_done-1.1.1-staging-20260710.zip`
  - SHA-256:
    `A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388`
- staging was confirmed OK by the user on 2026-07-10;
- production package prepared as a byte-for-byte copy of the accepted staging
  package:
  - `redmine_project_percent_done-1.1.1-production-20260710.zip`
  - SHA-256:
    `A5DEFBC04FE6C5FBABB42661B80D21B33702147100EFB9C9C97E3E5315466388`
- production was confirmed OK by the user on 2026-07-15; version `1.1.1`
  is installed and working as expected on both GCR staging and GCR production;
- added a repeatable local Redmine 6.1.2 test runtime with portable Ruby
  3.3.11, SQLite, plugin-specific test databases, and reusable setup/runner
  parameters for other plugin repositories;
- extracted the runtime logic into the installed `redmine-plugin-test-runtime`
  skill and published it in `pavelstf/Codex-Skills` at commit `43ef12a`;
- moved the prepared runtime to the shared location
  `C:\RedmineTestRuntimes\redmine-6.1.2` and verified the repository wrappers
  without environment overrides;
- full Redmine plugin suite passed on 2026-07-15:
  - `28 runs`
  - `130 assertions`
  - `0 failures`
  - `0 errors`
  - `0 skips`
- the Windows junction/subst execution emits non-fatal duplicate constant
  warnings because the same plugin files are visible through physical and
  mapped paths; the suite result is green.
