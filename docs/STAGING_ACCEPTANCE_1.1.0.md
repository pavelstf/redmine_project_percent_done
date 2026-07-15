# Staging Acceptance: Project Percent Done 1.1.0

Date: 2026-07-01

Environment: GCR Redmine staging (`https://www.redminestaging.gcr.bg`)

Package:
`redmine_project_percent_done-1.1.0-staging-20260701.zip`

SHA-256:
`A68EE28370864D2A6AB598638BFE5E1A666DFB2605BCAB966F18738AA9571D4C`

## Status

**PASS for the active staging configuration.**

Installation, Public API execution, performance sampling, legacy-calculator
parity, closed-issue behavior, post-deployment log review, and manual
overview/details UI checks passed. REST and status-derived behavior are not
active in the current staging configuration.

## Production Promotion Status

**Production promotion package prepared on 2026-07-10.**

Version 1.1.0 is installed and accepted on Staging. The Production package
`redmine_project_percent_done-1.1.0-production-20260710.zip` is a byte-for-byte
copy of the approved Staging package and has the same SHA-256:
`A68EE28370864D2A6AB598638BFE5E1A666DFB2605BCAB966F18738AA9571D4C`.

Risk Monitor Pro 0.2.3 Production deployment depends on Project Percent Done
`>= 1.1.0` and `ProjectPercentDone::PublicApi::V1`, so Project Percent Done
1.1.0 should be promoted first, then Risk Monitor Pro 0.2.3.

## Automated Parity

The legacy summary calculator and Public API V1 returned identical display
progress, raw progress, included count, and total applied weight for every
selected project.

| Project | Legacy display | Public display | Public raw | Eligible | Estimated | Unestimated | Coverage | Known hours | Imputed | Total weight | Warnings |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `timeoff` | 100 | 100 | 99.621653641106 | 1377 | 1377 | 0 | 100.00% | 52333.0 | 0.0 | 52333.0 | none |
| `di231` | 6 | 6 | 5.980392156863 | 455 | 430 | 25 | 94.51% | 25475.0 | 25.0 | 25500.0 | `unestimated_issues` |
| `di-215-2` | 100 | 100 | 99.752168525403 | 34 | 25 | 9 | 73.53% | 394.5 | 9.0 | 403.5 | `unestimated_issues` |
| `gcr-training-and-team-development` | 0 | 0 | 0.298953662182 | 89 | 4 | 85 | 4.49% | 584.0 | 85.0 | 669.0 | `unestimated_issues` |
| `pmis-in-gcr-requirements-gathering` | 0 | 0 | 0.0 | 46 | 0 | 46 | 0.00% | 0.0 | 46.0 | 46.0 | `unestimated_issues`, `all_issues_unestimated` |

Automated parity result: **PASS**

## Coverage Matrix

| Required category | Representative project | Status |
|---|---|---|
| Complete estimates | `timeoff` | Pass |
| 80–99% coverage | `di231` | Pass |
| 50–79% coverage | `di-215-2` | Pass |
| Below 50% coverage | `gcr-training-and-team-development` | Pass |
| All estimates missing | `pmis-in-gcr-requirements-gathering` | Pass |
| Parent/subtask structure | `di231` (564 direct issues, 455 eligible) | Pass |
| Many issues | `timeoff` (1377 issues) | Pass |
| Closed issue with incomplete ratio | `timeoff` (1373 eligible matches) | Pass |
| Status-derived done ratio | Staging uses `issue_field` | Not active |

## Closed-Issue Behavior

Effective configuration:

```text
closed_issue_mode=treat_as_100
issue_done_ratio=issue_field
```

On `timeoff`, 1373 eligible closed issues had a recorded done ratio below
100%. A sampled issue had:

```text
recorded_done_ratio=0.0
effective_done_ratio=100.0
```

All matching included rows followed the configured behavior.

Closed-issue result: **PASS**

## Performance

Observed summary calculation runtimes:

| Project | Direct issues | Runtime |
|---|---:|---:|
| `timeoff` | 1377 | 179.56 ms |
| `di231` | 564 | 44.89 ms |
| `di-215-2` | 41 | 11.28 ms |
| `gcr-training-and-team-development` | 90 | 10.37 ms |
| `pmis-in-gcr-requirements-gathering` | 59 | 7.60 ms |

No provider failure occurred. The observed runtime is provisionally acceptable
for one live summary calculation per analyzed project.

## Log Review

Passenger restart: `2026-07-01 12:07:28 +0300`.

The latest pre-deployment fatal entry at `12:02:54` was an unrelated
`ActionController::RoutingError` for `/favicon.ico`.

After restart:

- plugin settings returned HTTP 200;
- project listing and overview returned HTTP 200;
- `ProjectPercentDoneController#show` returned HTTP 200;
- issue-filter navigation returned HTTP 200;
- no Project Percent Done exception was observed.

Log review result: **PASS**

## Manual UI Verification

The user confirmed that overview and details values matched the expected
legacy/Public API display values:

| Project | Confirmed UI display |
|---|---:|
| `timeoff` | 100% |
| `di231` | 6% |
| `di-215-2` | 100% |
| `gcr-training-and-team-development` | 0% |
| `pmis-in-gcr-requirements-gathering` | 0% |

Manual UI result: **PASS**

## Remaining Limitations and Decisions

- The optional REST endpoint is disabled (`rest_enabled=false`); its staging
  value comparison is not applicable under the active configuration.
- Status-derived done ratio is not active (`issue_done_ratio=issue_field`);
  staging cannot exercise that branch without an explicit temporary
  configuration change.
- Promote Project Percent Done 1.1.0 to Production before Risk Monitor Pro
  0.2.3, because Risk Monitor Pro requires Public API V1.
- After Project Percent Done is validated on Production, continue with Risk
  Monitor Pro 0.2.3 Production deployment.
