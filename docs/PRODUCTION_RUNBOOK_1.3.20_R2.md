# GCR production — Project Percent Done 1.3.20 r2

## Current status: r3-text approved on staging and production, 2026-11-25

The subsequent locale-only r3-text build was installed successfully on both
environments. User confirmed production UI OK and supplied TEXT_FIX_OK locales=50,
ASSETS_OK verified_copies=2, AFTER_OK settings_preserved=true, PB/PPH matches and
final SUCCESS. Production backup suffix: 20261125T103847Z-2862087.
Two projects show PPD/PB 40%/40.0% and 30%/29.7%; corrected note is visible.
Use ppd-production-install-1.3.20-r3-text.sh and its paired rollback script for
r3-text, with the r3-text handoff ZIP and checksum recorded in HANDOFF.md.
The r2 instructions below are preserved as deployment history, not current commands.

Prepared 2026-11-25. Production installation was completed by the user and
verified from complete terminal output and two real-project UI comparisons.
BEFORE_OK, ASSETS_OK verified_copies=2, AFTER_OK settings_preserved=true and
final SUCCESS were confirmed. Installed PPD 1.3.20/algorithm 1.2, PB 0.1.8,
PPH 0.7.2; PB/PPH checks passed for projects 8/9/10/19. No new matching
application errors were printed. Code/assets/DB backups use suffix
20261125T100650Z-2656142 in the production plugins directory.

DI-221 shows PPD 88% / PB 87.9%, 22 included/1 excluded and weight 1996h.
DI-249 shows PPD 40% / PB 40.0%, 5 included/0 excluded and weight 40h, with
zero budget. Snapshot #4893 from 2026-11-23 opens with complete evidence;
the next scheduled capture under algorithm 1.2 has not yet been verified.

After installation, the outdated parent-exclusion explanation was corrected
locally in all locale files. This follow-up is not deployed and is not in the
immutable production ZIP below. The README inside the operator ZIP records
the earlier preparation state; this repository document records actual results.
The owner confirmed the two staging widgets belong to the same project and
staging is good: PPD 84%, PB 83.7%, plus correct progress with zero budget.
The finish run verified assets and registry: PPD 1.3.20, PB 0.1.8, PPH 0.7.2.

## Target and package

- SSH user: gcrbgcaa.
- Upload/backup directory: /home/gcrbgcaa/redmine/plugins.
- Application root: /home/gcrbgcaa/redmine.
- Ruby venv: /home/gcrbgcaa/rubyvenv/redmine612build/3.2.
- Rails environment: production; URL https://redmine.gcr.bg.
- Plugin/folder: redmine_project_percent_done; version 1.3.20; algorithm 1.2;
  public contract/evidence schema 1.0. QA tag qa-v1.3.20-r2, commit f763c17.
- Runtime ZIP: redmine_project_percent_done-1.3.20-production-20261125-r2.zip.
- Size: 169409 bytes. SHA-256:
  FA3B218167DAEC4996486BB22D6D0F1D0B5FFC3CC0952DCFD2C1F1B923B60F67.
- Runtime ZIP is byte-for-byte identical to the staging-approved r2 ZIP; its
  original QA manifest/README are preserved rather than rewritten for promotion.
- Operator ZIP: redmine_project_percent_done-1.3.20-production-handoff-20261125-r2-p1.zip.
  It includes runtime ZIP, self-contained install/rollback scripts, instructions,
  SHA256SUMS and an external production manifest with staging acceptance evidence.

## Upload and commands

Upload only the operator ZIP to /home/gcrbgcaa/redmine/plugins. Check its outer
SHA-256 against the handoff response, then paste:

```bash
clear
(
  set -eo pipefail
  cd /home/gcrbgcaa/redmine/plugins
  unzip -o redmine_project_percent_done-1.3.20-production-handoff-20261125-r2-p1.zip
  sha256sum -c SHA256SUMS
  bash /home/gcrbgcaa/redmine/plugins/ppd-production-install-1.3.20-r2.sh
)
```

Optional read-only preflight (no backup or deployment):

```bash
clear
bash /home/gcrbgcaa/redmine/plugins/ppd-production-install-1.3.20-r2.sh --preflight-only
```

Choose a quiet production period. The script validates canonical production root,
user, selected Ruby, package SHA/size and existing PPD migration 2/schema before
replacement. If migration records/tables/index disagree, it stops; no destructive
schema repair or bundle installation is attempted.

It records aggregate before values for cross-project-parent projects plus up to
three active projects, then makes a transaction-consistent MySQL/MariaDB dump
and compressed code/assets backups. The DB password is confined to the dump
child environment, not command argv or printed configuration. Avoid concurrent
schema alterations during the dump. Backup paths are printed under plugins/.

After backup validation it replaces only PPD, checks its migrations, and uses
the FileUtils asset refresh verified in the staging finish run. Existing
fingerprinted CSS is refreshed and every copied file is hash-checked, without
process substitution, /dev/fd, or a cwd-dependent external helper. The Ruby
checks are embedded in each shell script and written under private /tmp paths.

Passenger is restarted with tmp/restart.txt. Registry, algorithm, full installed
runtime manifest, unchanged PPD settings, public evidence and present PB/PPH
providers are verified. Actual companion versions and PB UI enablement are
printed; no companion upgrade/version assumption is hidden in this install.

The script does not collect snapshots, backfill history, send email, change cron,
alter timezone, create QA data, or replace PB/PPH. Ordinary live percentages can
change for cross-project parents and rounding edge cases under algorithm 1.2;
existing stored snapshots retain their values and provenance.

## Success and logs

Require BEFORE_OK, ASSETS_OK, AFTER_OK and:

```text
SUCCESS: redmine_project_percent_done 1.3.20 r2 installed and API-verified on production
```

RubyGems/Bundler preludes are non-blocking only when intended Rails results and
the explicit markers complete. Any early failure reports phase/line/exit status.
New log errors are printed for review; a final script success is not a substitute
for checking real HTTP pages and unrelated-plugin errors.

## Rollback

The original version, code tar.gz, assets tar.gz, DB sql.gz and comparison logs
remain in plugins/. The last code backup is recorded in
redmine_project_percent_done-production-last-backup.txt.

```bash
clear
bash /home/gcrbgcaa/redmine/plugins/ppd-production-rollback-1.3.20-r2.sh
```

Rollback restores previous code/assets, keeps DB/schema/history and restarts
Passenger, then verifies the original registry version. It performs no down
migrations or automatic SQL restoration. DB recovery is separate and requires
review of the actual failure. Failure work directories remain for diagnosis.

## Manual production acceptance

1. In Administration → Plugins confirm PPD 1.3.20; overview/sidebar/details and
   settings open without 500s. Hard-reload and verify CSS.
2. On the same real project compare PPD with PB Project progress, not Budget
   consumed. PB displays raw progress with one decimal; PPD applies configured
   integer rounding (e.g. raw 83.7 → nearest 84). No artificial QA project is implied.
3. Compare printed before/after values for cross-project-parent projects. Check
   leaf scope, meaningful 0% vs unavailable progress, and limited-user visibility.
4. Confirm PB module/role and integration setting where its panel is expected.
   Confirm PPH remains the history owner when active, with no legacy PPD collector.
5. Check production.log and real pages after restart. Report full terminal output
   plus UI results before marking production-approved.

## Evidence and deferred work

Immutable runtime: full Redmine 6.1.2 suite 165 runs/1084 assertions, zero
failures/errors/skips. Operator-flow tests use isolated Linux fixtures with
mocked Rails/DB commands and real filesystem/tar/gzip/FileUtils operations;
they are not live production execution. Package checksums are in the generated
production manifest. N-01 remains deferred as PPD-N-01 in docs/BACKLOG.md.
