# Project Percent Done 1.3.20 — repeat QA

Prepared 2026-11-24. Public contract 1.0; calculation algorithm 1.2; evidence
schema 1.0. State: prepared for repeat QA, not newly staging/production approved.
The user approved global parent exclusion. Historical snapshots are untouched.

QA build **r2**, 2026-11-25, closes the three follow-up findings. It preserves
plugin/algorithm 1.3.20/1.2 and is built from local QA tag `qa-v1.3.20-r2`.

| Follow-up | Remediation | Retest |
|---|---|---|
| R-01 | Reject NULL lft/rgt as non-leaf without arithmetic on nil | Actual DB NULL/nil combinations; summary/details, API/evidence and HTTP Overview remain available; source hierarchy is not repaired |
| R-02 | LF policy, normalized source; immutable QA Git ref and deterministic ZIP entry metadata | No CR in packaged UTF-8 text, workspace/ref equality, source commit/ref/hash in manifests, independent archive verification |
| R-03 | Restored historical 1.3.19 changelog entry from its release handoff | Evidence/API release, exact historical test totals and 2026-10-11 approval recorded separately from QA r2 |

## Remediation and retest matrix

| Finding | Change | Retest |
|---|---|---|
| PPD-01 | Exact Rational aggregation from decimal estimates, round before Float conversion; no arbitrary epsilon | 0.1h/0.2h at 70% floor=70; 0.2h at 10% + 0.05h at 50% ceil=18; imputed decimal averages; exact/near boundaries, all modes, raw and evidence |
| PPD-02 | Global leaf rule through Redmine lft/rgt, including cross-project parents; evidence child count is global | Parent-only project has no eligible weight; mixed project counts only its own leaves; evidence excludes foreign rows and reports parent reason/is_parent/children_count consistently |
| PPD-03 | Set membership for parent/included/status/tracker IDs, same public arrays/order | Summary/details parity; synthetic benchmark at multiple sizes; representative DB-backed performance remains a staging gate |
| PPD-04 | Quoted Norwegian root; CI validates filename/root agreement | YAML no root is String, Norwegian resolves and falls back to EN |
| PPD-05 | Explicit EN/BG completeness and partial English compatibility locales | EN/BG parity; other language fallback, no removal of existing locales |
| PPD-06 | Migration 002 down raises IrreversibleMigration before DDL | Fresh/upgrade up unchanged; fake schema no operations; real weekly/monthly same-date rows and schema preserved after refusal |
| PPD-07 | Localized fixed flash error; external SMTP exception message not exposed | Inject HTML/secret into simulated exception; actual Redmine flash renderer stays clean; admin and PPH guards |
| PPD-08 | Details access clarified; runtime-only install ZIP separate from source ZIP | Install has no CI/AGENTS/prompts/test/developer scripts; source retains regression tests for analysis; inspect ZIP inventories/hashes |

## Regression coverage

`test/unit/project_percent_done/qa_regressions_test.rb` covers numeric, global
hierarchy, evidence and locale regressions. Existing calculator/API tests and
admin/migration suites cover compatibility and guards. Run focused tests then
the complete shared Redmine 6.1.2 suite with normal DB preparation, sequentially.
Exact results and package hashes are supplied by the generated QA bundle.

## QA installation and access

Use the installation instructions in QA_GUIDE_BG.md from the bundle. Details
HTML/CSV is enabled when overview, sidebar OR project tab is enabled. The tab
itself defaults off; details remains accessible from overview/sidebar links.
REST defaults off independently. Evidence is in-process only and may include
private issue/contact data; consumers must enforce authorization.

## Remaining environment validation

Local automated tests use Redmine 6.1.2, Ruby 3.3.11 and SQLite. They are not
evidence of MySQL/MariaDB migration validation, deployed GCR theme/keyboard UI,
real SMTP or cron success, or measurements on a representative large project.
Those checks remain explicit staging/re-QA gates. Existing full-suite coexistence
tests do not certify every separate PB/PPH version. PB 0.1.8 uses the same global
leaf condition; provider contract and JSON field types are unchanged.

Plugin 1.3.20/algorithm 1.2 changes live results for cross-project parents and
rounding edge cases. Existing stored PPD/PPH history must not be rewritten.
Verify provenance transitions and downstream consumer presentation on staging.

## Packaging

`scripts/build_qa_package.py --ref qa-v1.3.20-r2` builds installation, source and
outer QA ZIPs from that committed Git source, with exact commit/ref, snapshot
digest, branch, dirty status and per-file SHA-256 manifests. It refuses failed
test process status, missing full-suite results, CR text or a workspace/ref
mismatch. ZIP timestamps/permissions are fixed for repeatability. Packaging
does not itself create a commit/tag or deploy. Installation uses a runtime allowlist;
source ZIP includes tests/docs/developer tooling, excluding private ignored
files, QA input PDFs, runtimes, generated output and archive artifacts.
