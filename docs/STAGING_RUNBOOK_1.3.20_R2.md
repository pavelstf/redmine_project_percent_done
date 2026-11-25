# GCR staging — Project Percent Done 1.3.20 r2

Prepared 2026-11-25. This is a manual deployment handoff, not a deployment log.
Runtime bytes are copied from the accepted QA install ZIP without rebuilding.
Source QA tag: qa-v1.3.20-r2, commit f763c1723d9e586261c5beff9bbd19f1e7270b80.

## Target and files

- SSH user: gcrbgcaa; Redmine root: /home/gcrbgcaa/redminestaging.
- Ruby venv: /home/gcrbgcaa/rubyvenv/redminestaging/3.2.
- Rails environment: production (the staging host's Rails environment).
- URL: https://www.redminestaging.gcr.bg (redirects may occur).
- Upload directory: /home/gcrbgcaa/redminestaging/plugins.
- Plugin: redmine_project_percent_done, version 1.3.20, algorithm 1.2,
  public contract/evidence schema 1.0.
- ZIP: redmine_project_percent_done-1.3.20-staging-20261125-r2.zip.
- Bytes: 169409. SHA-256:
  FA3B218167DAEC4996486BB22D6D0F1D0B5FFC3CC0952DCFD2C1F1B923B60F67.
- Operator archive: redmine_project_percent_done-1.3.20-staging-handoff-20261125-r2-op3.zip.
  It contains the runtime ZIP, both self-contained shell scripts and these
  instructions. Each script writes its quoted Ruby verifier into /tmp; no
  external helper or caller-directory lookup is required. The separate
  manifest records every member's SHA-256.

## Commands to paste

Upload the operator archive to the upload directory. Verify its outer SHA-256
against the handoff response, then extract and run the installation script:

```bash
clear
set -eo pipefail
cd /home/gcrbgcaa/redminestaging/plugins
unzip -o redmine_project_percent_done-1.3.20-staging-handoff-20261125-r2-op3.zip
sha256sum -c SHA256SUMS
bash ./ppd-staging-install-1.3.20-r2.sh
```

The script is for an existing PPD installation with recorded migration 2, its
three legacy tables and the period_type unique index. A partial schema/version
state is rejected before replacement; investigate rather than creating tables
or editing migration records. No bundle install is performed.

Operator revision op3 uses conditional venv activation, then checks its final
status and the selected Ruby executable. This accommodates cPanel activation
probes under errexit without suppressing later deployment errors. Progress
markers and an early ERR trap report phase/line/exit even before backups exist.
For a read-only environment/file/dependency preflight, run:

```bash
clear
bash /home/gcrbgcaa/redminestaging/plugins/ppd-staging-install-1.3.20-r2.sh --preflight-only
```

The preflight-only mode does not reach extraction, DB backup, Rails runner,
migrations or file replacement. Successful activation may emit RubyGems warnings;
the VENV_ACTIVATED marker and actual exit statuses determine progress.

Before replacement it verifies the target, SHA and bytes, prepares extracted
code outside plugins/, records aggregate baseline progress, and creates:

- compressed transaction-consistent MySQL/MariaDB DB backup;
- plugin code tar.gz and original version sidecar;
- standard and fingerprinted plugin assets tar.gz;
- before/after comparison logs and JSON baseline, without issue subjects/contact
  or evidence payloads.

Paths are printed and stored under plugins/. The last code backup pointer is
redmine_project_percent_done-staging-last-backup.txt. Archive and log permissions
are restricted by umask 077. The DB password is not printed or passed in argv;
it is scoped to the dump child environment. Do not run schema alterations while
the transaction-consistent dump is being taken. If DB backup fails, code is not
replaced. Use a quiet staging period for the operation.

It replaces only PPD, runs its up-migration check, refreshes its standard and
existing fingerprinted assets, touches tmp/restart.txt and verifies the registry,
algorithm, every installed manifest hash, unchanged settings and API/evidence.
Existing PB/PPH adapters are checked read-only when available; their versions are
printed rather than assumed. No separate PB/PPH package is replaced.

The verification includes cross-project-parent projects and up to three other
active projects. Before/after live values may differ under algorithm 1.2. If no
projects are available for sampling, it stops before code replacement.
The script does not collect snapshots, send mail, change cron or rewrite history.

## Rollback commands

Use this on an install failure after code replacement or rejected smoke checks:

```bash
clear
bash /home/gcrbgcaa/redminestaging/plugins/ppd-staging-rollback-1.3.20-r2.sh
```

It restores the code and both asset trees from the last backup pointer, retains
DB/schema/history, restarts Passenger and checks the restored registry version.
No down migrations or automatic SQL restoration occur. The DB backup remains
available for a separately reviewed DB recovery. Failure work directories under
/tmp are retained for diagnosis; they are never scanned as installed plugins.

## Manual validation and approval

1. Require BEFORE_OK, AFTER_OK and the final SUCCESS line. A cPanel Bundler
   prelude is non-blocking only when the intended result and marker checks pass.
2. Open the staging project overview/sidebar, details, settings and CSV. Check
   1.3.20, algorithm 1.2, EN/BG and limited-user private issue visibility.
3. Review printed before/after aggregate progress for cross-project parents and
   open the PB 0.1.8 panel with integration enabled. No unexpected 500s.
4. Confirm PPH progress/evidence adapter reads are successful if it is installed,
   legacy PPD collection remains guarded and existing history is unchanged.
5. Inspect new production.log errors; unrelated-plugin errors are not silently
   attributed to PPD. Confirm styles render correctly after reload.
6. Leave real SMTP/cron and any native snapshot write validation as separate
   explicit operations. CPU benchmarks do not validate real DB performance.
7. Send the complete terminal output and smoke-check findings for staging
   acceptance. Preparing/running a script is not itself production approval.

Local evidence for the immutable runtime: full Redmine 6.1.2 suite 165 runs,
1084 assertions, 0 failures/errors/skips; focused 8/199; valid archive hashes,
LF text and byte-reproducible ZIPs. Operator op3 passed nine local Linux/WSL
filesystem workflow checks (Rails/DB/host commands mocked), including the exact
op2 failure, relative/absolute launches and rollback after failures. Bash and
embedded Ruby syntax passed. Real MySQL/host behavior awaits staging execution.

N-01 is deferred in docs/BACKLOG.md as PPD-N-01. It is not implemented in these
runtime bytes. Local docs/operator additions do not alter the accepted QA tag.
