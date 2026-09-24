# Development Brief: Project Percent Done Public API V1

Last updated: 2026-07-01

Target release: `redmine_project_percent_done` version `1.1.0`

## 1. Assignment

Extend Redmine Project Percent Done with a small, documented, versioned,
in-process public API that can be consumed safely by Project Time Budget Risk
Monitor.

The extension must expose the current project-progress calculation together
with enough provenance and estimate-coverage information for an
EVM-inspired, hours-based Delivery Health assessment.

Do not implement EVM calculations in Project Percent Done. Project Percent Done
owns project progress; Risk Monitor owns Delivery Health.

## 2. Repository Context

```text
Repository: https://github.com/pavelstf/redmine_project_percent_done
Local path: C:\Codex Projects\Project Percent Done Plugin
Plugin ID: redmine_project_percent_done
Current analyzed version: 1.0.2
Target version: 1.1.0
Primary Redmine target: 6.1.2
Compatibility target: Redmine 5.x and 6.x
```

The analyzed local worktree has an existing unpublished `.gitignore` change.
Preserve it. Do not discard, overwrite, commit, or push unrelated user changes.

Before development:

1. Read the repository instructions and documentation.
2. Run `git status`.
3. Review the existing unpublished diff.
4. Synchronize with GitHub safely according to repository instructions.
5. Do not commit or push unless the user explicitly requests it.

## 3. Existing Behavior That Must Be Preserved

Version 1.0.2:

- calculates progress live;
- uses direct-project issues only;
- excludes same-project parent issues in leaf-only scope;
- supports Redmine issue-field and status-derived done ratio behavior;
- supports configurable closed-issue behavior;
- supports configurable missing-estimate behavior;
- supports configurable display rounding;
- renders overview/sidebar/details UI;
- exposes an optional REST endpoint;
- has no database migrations.

The 1.1.0 work must be backward-compatible. Do not change existing defaults or
the user-visible percentage for an unchanged project and unchanged settings.

## 4. Required Public Namespace

Add a stable public facade:

```ruby
ProjectPercentDone::PublicApi::V1
```

Required entry points:

```ruby
ProjectPercentDone::PublicApi::V1.capabilities
ProjectPercentDone::PublicApi::V1.calculate(project:)
```

The facade may call existing private/internal calculator services. Consumers
must not need to instantiate those services directly.

Load the API through the plugin's normal library entry point so it is available
after Redmine plugin initialization without relying on controller loading or a
REST request.

## 5. Public Value Objects

Return documented value objects rather than mutable implementation Hashes.

Suggested classes:

```ruby
ProjectPercentDone::PublicApi::V1::Capabilities
ProjectPercentDone::PublicApi::V1::Result
```

Requirements:

- public readers for every documented field;
- immutable or effectively immutable after construction;
- no ActiveRecord objects in the returned structure;
- no issue rows or issue IDs;
- stable field meaning within Public API V1;
- additive fields may be introduced compatibly;
- breaking semantic changes require a new API namespace.

If `to_h` is provided, it must return a defensive copy containing scalar,
array, or symbol/string values only.

## 6. Capabilities Contract

`capabilities` must report:

```text
contract_name
contract_version
plugin_version
algorithm_version
calculation_mode
persistence_mode
issue_scope
closed_issue_mode
unestimated_issue_mode
hours_weighted
supports_raw_percent_done
supports_estimate_coverage
```

Initial expected values:

```text
contract_name = project_percent_done
contract_version = 1.0
plugin_version = 1.1.0
calculation_mode = live
persistence_mode = none
supports_raw_percent_done = true
supports_estimate_coverage = true
```

`algorithm_version` must be independent from the plugin release version. It
identifies the calculation semantics used for a result.

`hours_weighted` must be:

- `true` for estimate-based modes, including modes that impute, assign fallback
  weight, or ignore some unestimated issues;
- `false` for `equal_weight_all`.

The value reflects the configured global mode at call time.

## 7. Calculation Result Contract

`calculate(project:)` must return a public Result with the following fields.

### 7.1 Availability and Percentage

```text
progress_available
unavailable_reason
raw_percent_done
display_percent_done
```

Rules:

- `raw_percent_done` is the unrounded numeric result used for downstream
  calculations;
- `display_percent_done` follows the configured display-rounding behavior;
- a valid 0% result is different from unavailable progress;
- normal data insufficiency is represented in the Result, not by returning
  `nil`;
- expected reasons include `no_eligible_issues` and `no_usable_weight`.

### 7.2 Scope Counts

```text
all_project_issue_count
eligible_issue_count
estimated_eligible_issue_count
unestimated_eligible_issue_count
included_issue_count
excluded_parent_issue_count
ignored_unestimated_issue_count
```

Definitions:

- `all_project_issue_count`: all issues belonging directly to the project;
- `eligible_issue_count`: issues remaining after issue-scope processing but
  before missing-estimate handling;
- `estimated_eligible_issue_count`: eligible issues with positive
  `estimated_hours`;
- `unestimated_eligible_issue_count`: eligible issues without positive
  `estimated_hours`;
- `included_issue_count`: issues receiving a positive applied weight;
- `excluded_parent_issue_count`: same-project parents excluded by leaf scope;
- `ignored_unestimated_issue_count`: eligible unestimated issues excluded by
  the configured `ignore` mode.

These definitions must remain correct for every missing-estimate mode. In
particular, `ignore` must not make unestimated eligible issues disappear from
coverage reporting.

### 7.3 Weight and Coverage Fields

```text
known_estimated_hours
imputed_weight
total_applied_weight
estimate_coverage_percent
known_weight_percent
```

Definitions:

```text
estimate_coverage_percent =
  estimated_eligible_issue_count / eligible_issue_count * 100
```

Return `nil` when there are no eligible issues.

`known_estimated_hours` is the sum of positive estimates belonging to eligible
estimated issues that participate in the configured calculation.

`imputed_weight` is the total applied weight assigned to included unestimated
issues. It is zero for ignored unestimated issues.

`total_applied_weight` is the denominator of the weighted progress formula.

`known_weight_percent` is:

```text
known_estimated_hours / total_applied_weight * 100
```

when that ratio has meaningful hours-based semantics. Return `nil` when the
calculation is equal-weighted or has no usable denominator.

Do not describe `estimate_coverage_percent` as measured hours coverage. It is
estimate-presence coverage by eligible issue count.

### 7.4 Configuration and Diagnostics

```text
issue_scope
closed_issue_mode
unestimated_issue_mode
hours_weighted
warnings
```

Warnings should use documented stable codes. Existing useful warning concepts
include:

```text
no_issues
no_eligible_issues
no_usable_weight
unestimated_issues
all_issues_unestimated
```

Use a frozen defensive array or equivalent immutable representation.

## 8. Calculation Semantics

Preserve the existing formula:

```text
Project % done =
  sum((effective issue % done / 100) x applied weight)
  / sum(applied weight)
  x 100
```

Preserve these rules:

- project scope is `Issue.where(project_id: project.id)`;
- subproject issues are not included;
- with leaf-only scope, a parent is excluded only when it has a child in the
  same project;
- closed issue handling follows the configured mode;
- when Redmine derives done ratio from status, use the status default when
  available;
- effective done ratio is constrained to `0..100`;
- positive `estimated_hours` means estimated;
- the configured missing-estimate mode determines applied weight;
- calculation uses the raw value; rounding is presentation behavior.

Do not add Risk Monitor or EVM-specific policy to the calculator.

## 9. Argument and Error Behavior

Document the behavior for invalid API use.

Recommended behavior:

- require a persisted `Project`-compatible object;
- raise `ArgumentError` for `nil`, wrong-type, or unpersisted project input;
- represent ordinary project data insufficiency in Result fields;
- do not rescue and hide database or programming errors inside the public API;
- do not write settings, project data, custom fields, or cache rows.

Risk Monitor will handle unexpected provider failures at its adapter boundary.

## 10. REST and UI Compatibility

The public in-process API is the required deliverable. It must not depend on
the optional REST setting.

Requirements:

- existing HTML views continue to work;
- existing REST response fields keep their names and meanings;
- existing REST enable/disable behavior remains unchanged;
- existing permission and issue-visibility behavior remains unchanged;
- no additional issue detail is exposed through the public integration result.

Adding the new aggregate fields to REST is optional and should be done only if
it remains backward-compatible and is explicitly documented. It is not
required for Risk Monitor integration.

## 11. Settings Hardening

Centralize and document the allowed values for:

```text
issue_scope
closed_issue_mode
unestimated_issue_mode
rounding_mode
```

The public capabilities object must report the effective normalized setting,
not an unchecked raw value.

Preserve current fallback behavior for invalid or missing stored settings unless
changing it is required to fix a demonstrated bug. Add tests for normalization.

## 12. Performance Requirements

The public calculation is expected to run once per analyzed project during a
Risk Monitor batch.

Requirements:

- use a summary calculation mode;
- do not build issue breakdown rows;
- preload or select only required status and issue fields;
- avoid per-issue database queries;
- preserve direct-project scoping;
- document observed staging runtime for representative small and large
  projects.

Do not add persistence or background jobs in this release.

## 13. Required Automated Tests

### 13.1 Existing behavior

- weighted average of estimated leaf issues;
- same-project parent exclusion;
- parent retained when its child belongs to another project;
- direct project only, without subproject rollup;
- closed issue treated as 100%;
- closed issue using issue done ratio;
- status-derived done ratio;
- rounding modes;
- no project issues.

### 13.2 Missing estimates

- `use_average_estimate`;
- average mode with no estimated issues and fallback weight;
- `use_weight_1`;
- `ignore`;
- `equal_weight_all`;
- all eligible issues unestimated;
- mixed estimated and unestimated issues;
- zero or negative estimates treated as unestimated.

For every mode, assert the new eligible counts, included counts, coverage,
known hours, imputed weight, total weight, and warnings.

### 13.3 Public contract

- namespace is loaded after plugin initialization;
- capabilities exposes all documented fields;
- plugin, contract, and algorithm versions are correct;
- result exposes all documented fields;
- result cannot be mutated through public arrays or hashes;
- raw and display percentages are distinct where rounding applies;
- valid zero progress is marked available;
- no eligible issues is marked unavailable with a reason;
- no usable weight is marked unavailable with a reason;
- equal-weight mode reports `hours_weighted = false`;
- `ignore` still reports unestimated eligible issues and reduced coverage;
- no issue IDs or ActiveRecord objects are exposed;
- invalid project arguments follow the documented error contract.

### 13.4 Regression

- existing controller tests remain green;
- existing REST payload remains backward-compatible;
- existing UI helper/hook behavior is unchanged;
- test suite runs under the supported Redmine environments available to the
  project.

## 14. Documentation Deliverables

Update or add:

- README public integration API section;
- dedicated Public API V1 reference;
- calculation documentation with exact coverage definitions;
- CHANGELOG entry for 1.1.0;
- deployment and rollback notes;
- examples showing capabilities and calculation usage;
- compatibility and non-persistence statements.

Document clearly that this is an in-process aggregate API and not an
authorization mechanism for exposing issue details.

## 15. Versioning

Release the extension as `1.1.0` if the public API is the only feature addition
and existing behavior remains backward-compatible.

Use separate versions:

```text
Plugin release version: 1.1.0
Public contract version: 1.0
Calculation algorithm version: explicitly chosen semantic version
```

Breaking a Public API V1 field meaning requires `PublicApi::V2`, even if the
plugin release uses ordinary semantic versioning.

## 16. Local Validation

Run all checks available in the local environment:

- Ruby syntax checks;
- plugin unit tests when a Redmine test runtime is available;
- functional/controller tests;
- locale parsing/parity checks if locale files change;
- whitespace and diff checks;
- package-content checks.

If the Windows workspace lacks Ruby/Redmine, document the limitation and do not
claim runtime tests passed.

## 17. Staging Package and Runbook

After local review, prepare a staging-only 1.1.0 package. Do not replace any
approved production package with unvalidated bytes.

Provide a complete copy-paste staging runbook containing:

- target environment;
- ZIP filename and SHA-256;
- upload path;
- plugin backup;
- virtualenv activation;
- package extraction and structure verification;
- migration command;
- restart;
- final version verification;
- automated provider checks;
- rollback commands;
- manual validation checklist.

## 18. Staging Acceptance Matrix

Choose representative projects with:

- complete estimates;
- 80-99% estimate coverage;
- 50-79% estimate coverage;
- below 50% estimate coverage;
- all estimates missing;
- parent/subtask structures;
- closed issues with incomplete recorded done ratio;
- status-derived done ratio;
- many issues.

For every project compare:

```text
Project Percent Done UI value
Existing REST value
Public API display value
Public API raw value
Eligible/estimated/unestimated counts
Estimate coverage
Known and imputed weight
Warnings
Execution time
```

The UI, REST, and public display value must agree for the same configuration.
The raw value may contain additional precision.

## 19. Definition of Done

The Project Percent Done extension is ready for Risk Monitor integration when:

- Public API V1 is implemented and documented;
- all new contract and regression tests pass in an available Redmine runtime;
- existing UI and REST behavior is unchanged;
- no migrations or persistence were introduced;
- coverage remains accurate in `ignore` mode;
- equal-weight mode is identifiable as not hours-weighted;
- no private issue data is exposed;
- staging performance is acceptable;
- staging results match existing UI/REST results;
- the staging package and rollback path are verified;
- the user explicitly approves the provider release for integration work.

## 20. Out of Scope

Do not implement in this assignment:

- EVM or Delivery Health formulas;
- Risk Monitor settings or adapters;
- Risk Monitor snapshot migrations;
- digest or recipient changes;
- a persisted progress cache;
- Project custom field synchronization;
- a duplicate progress implementation in Risk Monitor;
- automatic production deployment;
- commits or pushes without explicit user authorization.

## 21. Required Handoff

At completion, provide:

- concise summary of changed behavior;
- exact files changed;
- test commands and outcomes;
- known limitations;
- staging ZIP name and SHA-256, if prepared;
- full staging deployment and rollback runbook;
- confirmation that unrelated local changes were preserved;
- remaining decisions or risks before Risk Monitor integration.

