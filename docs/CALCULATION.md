# Calculation Behavior

## Scope

Each project is calculated independently.

Subprojects are not included.

Algorithm 1.2 includes only direct-project global leaf issues. Every parent is
excluded, even if all its children belong to another project. Children outside
the project are not imported. This aligns leaf scope with Project Budget and
prevents a parent's Redmine-derived progress from importing another project's
progress. Algorithm 1.1 used same-project children to identify parents.

QA build r2 safely excludes issues with incomplete NULL nested-set coordinates
instead of raising during the leaf check. It does not repair or rewrite the
source hierarchy. Normal-data leaf semantics and algorithm version 1.2 remain
unchanged.

Weights and weighted progress are aggregated as exact Rational values derived
from the decimal estimates, including average-estimate imputation. Integer
rounding is applied before conversion to public Float values. This avoids
binary floating-point artifacts at floor/ceil boundaries without snapping
legitimate nearby values. Existing history is not recalculated.

Administrators can also configure non-progress statuses and non-progress
trackers. Matching direct leaf issues are excluded before numerator and
denominator calculation. Status and tracker matching is by Redmine record ID,
not by name. The status selector defaults to no status exclusions. Administrators
can switch to closed-status exclusions or to an all-statuses mode for workflows
where open statuses should also be removed from progress scope.
The tracker selector also defaults to no tracker exclusions. Administrators can
switch it to all trackers before choosing tracker IDs to remove whole issue
types from progress scope.

## Formula

```text
Project % done =
  sum((effective issue % done / 100) x applied weight)
  / sum(applied weight)
  x 100
```

## Effective Issue % Done

The plugin starts with the issue `% Done` value.

If Redmine is configured to derive `% Done` from issue statuses, the plugin uses the status default done ratio when available.

If closed issues are configured to be treated as complete, closed issues use `100%` as their effective value.

The effective value is normalized to the `0..100` range.

## Applied Weight

By default, issue weight comes from `estimated_hours`.

Issues without estimates can be handled in one of these modes:

| Mode | Behavior |
|---|---|
| Use average estimate | Uses the average estimate of estimated included issues. Falls back to weight `1` if no issue has an estimate. |
| Use weight 1 | Uses weight `1` for unestimated issues. |
| Ignore unestimated issues | Excludes unestimated issues from the calculation. |
| Equal weight for all issues | Uses weight `1` for every issue and ignores estimates. |

## Included Issues

Included issues are issues that:

- belong to the current project;
- are in the calculation scope;
- do not match a configured non-progress status or tracker;
- have a positive applied weight.

## Estimate Coverage

The Public API reports estimate-presence coverage by eligible issue count:

```text
estimate_coverage_percent =
  estimated eligible issues / all eligible issues * 100
```

It is `nil` when there are no eligible issues. This is not measured-hours
coverage. An eligible issue is counted as estimated only when its
`estimated_hours` value is positive; zero, negative, and missing estimates are
unestimated.

The coverage counts are taken before missing-estimate handling. Consequently,
an unestimated issue ignored by the calculation still reduces estimate
coverage.

`known_estimated_hours` is the sum of positive estimates on estimated eligible
issues included in the calculation. `imputed_weight` is the applied weight
assigned to included unestimated issues. `total_applied_weight` is the
denominator of the progress formula.

`known_weight_percent` is `known_estimated_hours / total_applied_weight * 100`
for hours-weighted modes. It is `nil` for equal-weight calculation and when
there is no usable denominator.

## Not Included Issues

Not included issues can be:

- parent issues excluded to avoid double counting;
- leaf issues excluded by configured non-progress status or tracker;
- unestimated issues ignored by plugin setting;
- issues outside the calculation scope.

## Details Page

The details page displays:

- summary totals;
- formula;
- included issues table;
- not included issues table;
- calculation notes and reasons.

Concrete issue rows are shown only when the issue is visible to the current user. Totals and the final percentage still represent the entire project.
