# Calculation Behavior

## Scope

Each project is calculated independently.

Subprojects are not included.

By default, the plugin includes only leaf issues in the current project. A parent issue is excluded when it has at least one child issue in the same project. This prevents double counting the same work through both a parent issue and its children.

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
