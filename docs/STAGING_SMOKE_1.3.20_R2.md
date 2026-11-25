# Staging PPD 1.3.20 r2 / Project Budget verification

## Evidence from the supplied op3 output

Redmine 6.1.2 / Ruby 3.2.11 / Rails 7.2.3 loaded PPD 1.3.20, algorithm 1.2.
The before phase was 1.3.19 / 1.1. DB/code/asset backups were created before
replacement. AFTER_OK proves installed runtime hashes, preserved PPD settings
and API/evidence checks passed. PB/PPH provider reads passed on projects
8, 9, 10, 19. Only project 8 had available progress (0); other samples had nil.

Do not treat the final SUCCESS as clean UI/staging acceptance yet: the log also
contains a process-substitution /dev/fd error during fingerprinted CSS refresh.
The companion 'not installed' output was a Ruby reporting bug, not reliable
registry evidence; successful provider reads already demonstrate loaded classes.
Correct version/registration output is supplied by the finish check.

## Complete assets without reinstalling

Upload scripts/staging/ppd-staging-finish-1.3.20-r2.sh to staging plugins/ and run
it with Bash. It makes an additional assets backup, verifies accepted runtime
hashes and copies/validates CSS through Ruby FileUtils/globs, without /dev/fd.
It prints real registered versions, PB integration enablement and provider parity.
It preserves code, DB/history and the original last-code-backup pointer.
It restarts Passenger after completion and requires STAGING_FINISH_OK.

## Manual checklist

1. Open https://www.redminestaging.gcr.bg/admin/plugins and confirm PPD 1.3.20.
   Open project 8 overview/sidebar/details; no 500, readable tables and tooltips,
   no missing CSS in browser Network after a hard reload. Check EN and BG.
2. Open /admin/project_budget. Confirm the integration with Project Percent Done
   is enabled; the adapter read passing does not prove this UI setting is on.
   Ensure project module 'Project budget' and role permission
   'View aggregate project budget metrics' are enabled for the tested project/user.
3. In a dedicated staging QA project with two eligible direct leaf issues,
   use estimates 2h and 6h and effective progress 50% and 100%. Confirm both rows
   are included in PPD details; the effective done values follow the current
   Redmine workflow/status configuration. Do not alter global workflow settings
   merely to force the example. Expected raw progress = 87.5%.
4. At nearest rounding PPD shows 88%; floor shows 87%, ceil 88%. Project Budget
   shows raw progress to one decimal (87.5%, or 87,5% in BG). This precision
   difference is expected; do not require identical formatted integer strings.
5. Optionally select a valid budget field and set QA budget 10h, log 2h on a
   direct QA issue. PB should show budget 10h, estimated 8h (80% of budget),
   spent 2h (20% of budget), remaining 8h, progress 87.5%. The progress/consumption
   difference is 67.5 percentage points. Compare PPD progress with PB project
   progress, not PB spent-budget percentage.
6. If cross-project subtasks are already permitted, add a parent in the QA project
   whose child is in another project. PPD excludes the parent and does not import
   the foreign child; progress stays 87.5% and PB estimated leaf hours stay 8h.
   Check parent_issue_excluded. Do not enable cross-project subtasks globally
   without a separate decision; mark this test not run if unavailable.
7. Check a valid 0% project: PB should show 0.0% when integration is enabled.
   For no usable progress (nil), the PB progress bar is omitted; it must not invent
   0%. Project 8 and samples 9/10/19 respectively exercise these provider cases.
8. Check a limited user with the required project/PB permission: aggregate values
   remain project-wide; PPD issue rows/CSV respect issue visibility. If the user
   lacks the PB permission/module, absence of the panel is expected.

Record finish terminal output, screenshots of both progress widgets, raw/display
values, effective issue values, project IDs, user role and any new production.log
errors. Existing cross-project-parent projects may legitimately change under
algorithm 1.2; stored history should remain unchanged. No snapshot/email/cron
operation is required by these checks.
