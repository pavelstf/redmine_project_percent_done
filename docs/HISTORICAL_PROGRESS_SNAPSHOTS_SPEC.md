# Historical Project Progress Snapshots - V1 Specification

- Status: Implemented for V1; staging validation in progress
- Decision date: 2026-07-15
- Target plugin: `redmine_project_percent_done`
- Primary Redmine target: 6.1.2, with Redmine 5.x/6.x compatibility

## 1. Purpose

Add optional persistent project progress history without changing the existing
live Project Percent Done calculation when history collection is disabled.

The feature will:

- capture short-lived daily operational snapshots;
- retain one official snapshot for each weekly period ending on Sunday;
- preserve aggregate project progress history indefinitely by default;
- optionally retain per-issue details for a configurable period;
- explain inactive, archived, out-of-scope, disabled, and missing periods;
- display project history as a graph and table;
- provide administrative diagnostics and configurable email notifications.

The feature is opt-in. An installation that does not enable it continues to use
the existing live calculation and does not accumulate project or issue history.

Collection and project-history visibility are separate controls. An
administrator can enable collection in production while keeping the dedicated
project history page hidden from all project users. Diagnostics, cron, retention
and configured collection email still operate in this shadow mode.

## 2. V1 Scope

### Included

- Global history enable/disable setting.
- Project selection through a configurable single-value or multi-value list project custom field.
- Global detail level: project only, or project plus all issues.
- Daily rolling operational snapshots.
- Official weekly snapshots for periods ending on Sunday.
- Recovery of a missed official snapshot from the nearest eligible operational
  snapshot.
- Active, closed, archived, out-of-scope, disabled, and missing period states.
- Configurable issue-detail retention and inactive-project grace period.
- Graph and table on a dedicated project history page, separate from live calculation details.
- Weekly/monthly period-type switch on the dedicated project history page.
- Monthly status notice showing the next month-end snapshot date, expected
  capture date, days remaining, or overdue/disabled state.
- Calendar and fiscal quarter/year filters.
- System-administrator-only issue snapshot details.
- Administrative diagnostics, preview, manual due capture, cleanup, test email,
  and per-project history deletion.
- Observed project-plan history from configurable start/end date custom fields,
  calendar-time analysis, time-entry boundary anomalies, and guarded forecasts.
- Configurable operational email notifications.
- Email digest monthly section showing actual monthly snapshots created by the
  run, or the same next/overdue/disabled monthly status shown in the UI.
- Configurable project-history visibility, including production shadow collection.
- Versioned in-process historical Public API for official snapshots.
- Monthly official snapshots for completed calendar months, created whenever
  historical collection is enabled.
- Derived quarterly, half-yearly, and yearly progress from monthly snapshots.

### Deferred

- Historical CSV export.
- Historical REST API.
- Reconstruction or backfill of periods before collection was enabled.
- Global destructive deletion by date or for all projects through the UI.
- Per-project overrides for detail level, retention, or notification policy.

## 3. Definitions

### Weekly period

A weekly period ends at the end of Sunday in the Redmine application time zone.
The canonical period key is the Sunday `period_end` date.

### Monthly period

A monthly period ends on the last calendar day of a completed month in the
Redmine application time zone. The canonical period key is the month-end
`period_end` date, for example `2026-02-28` or `2028-02-29`.

### Operational snapshot

A daily, short-lived snapshot used as a recovery candidate. At most one current
operational snapshot per project is retained after a successful run. It is not
shown in normal project history unless it is promoted to an official snapshot.

### Official snapshot

The retained project snapshot for a weekly or monthly period. It can be:

- captured normally near the end of the period; or
- promoted from the nearest eligible operational snapshot after a missed run.

Weekly and monthly official snapshots are separate period types. They may share
the same `period_end`, for example when the last calendar day of a month is also
Sunday.

### State-only record

A weekly project record with no calculated progress or issue details. It
explains why an official progress value does not exist for that project and
period.

### Collection run

One rake or administrative execution. A run records operational diagnostics
separately from project snapshot data and email delivery status.

## 4. Feature Activation

The global `history_enabled` setting defaults to disabled.

When disabled:

- live project percentage behavior remains unchanged;
- no project or issue snapshots are created;
- existing history remains intact;
- retention cleanup may still run;
- if email notification remains enabled, at most one weekly `disabled`
  notification is sent;
- a small global period marker may be retained after the feature has previously
  been enabled so project graphs can explain the disabled interval.

Disabling history never implicitly deletes existing data. Destructive actions
are separate and explicit.

## 5. Project Eligibility

### Configuration

The administrator selects:

1. one project list custom field, either single-value or multi-value;
2. one or more allowed values from that field.

A project is in scope when at least one of its current custom-field values
intersects the configured allowed values.

The selector and collector must validate that:

- the configured field exists;
- it belongs to projects;
- it supports the required value model;
- at least one allowed value is configured;
- stale configured values are reported as a health warning.

### Status behavior

For a project that is or has previously been tracked:

| Project condition | Weekly result |
|---|---|
| Active and in scope | Official aggregate snapshot; issue details when enabled |
| Closed | `closed` state-only record |
| Archived | `archived` state-only record |
| Active but no longer in scope | `out_of_scope` state-only record |
| Collection disabled | Global `collection_disabled` period state |
| No usable collection result | `missing` period shown in history |

Projects that have never matched the configured scope do not receive history
records. Changing the custom field or selected values affects future collection
only and never deletes previous history.

The snapshot stores the project's current custom-field values so historic scope
decisions remain explainable after configuration or project changes.

## 6. Daily, Weekly, and Monthly Snapshot Lifecycle

### Normal execution

The rake task runs every day. A recommended cron time is shortly after midnight,
for example 00:05, using the Redmine application time zone.

The exact `captured_at` timestamp is always stored. The task:

1. acquires a single-run lock;
2. creates the current project snapshots;
3. identifies any Sunday period requiring an official snapshot;
4. promotes the appropriate snapshot to official when applicable;
5. deletes obsolete operational snapshots only after the new data is committed;
6. applies retention cleanup in batches;
7. finalizes run diagnostics;
8. sends any configured notification.

Each project is processed in its own transaction. One project failure must not
roll back successful snapshots for other projects.

The same daily collector lifecycle promotes due weekly and monthly official
snapshots. Monthly snapshots are always enabled when historical collection is
enabled; there is no separate setting. A due monthly snapshot represents the
completed calendar month whose last day is the monthly `period_end`.

The project history UI can display either weekly or monthly official snapshots.
Weekly remains the default screen mode. Monthly mode uses month-end periods and
does not display the weekly forecast, because the V1 forecast is explicitly
based on consecutive weekly points. The page also displays the next monthly
period end, expected capture date, days remaining, and overdue/disabled status.

The collection notification email includes a monthly section. When the run
created monthly official snapshots, the section summarizes the actual rows
officialized by that run, grouped by `period_type = monthly` and `period_end`.
When the run did not create monthly snapshots, the section reports the next
monthly period or overdue/disabled status using the same scheduling rules as the
project history page. The email must not infer monthly success from the weekly
`target_period_end` alone.

### Operational rotation

After a successful current operational snapshot is committed, the preceding
operational snapshot for the same project is deleted unless it has become an
official snapshot. Official snapshots are never removed by operational
rotation.

At steady state, storage contains all retained official snapshots and no more
than one current operational snapshot per project.

### Normal official snapshot

The first successful capture nearest the Sunday period boundary becomes the
official snapshot for that `period_end`. The official row stores its actual
capture time and source.

### Missed official snapshot recovery

If the normal official capture is unavailable:

1. consider the last operational snapshot before the target period boundary;
2. consider the first successful snapshot after the target boundary;
3. reject candidates outside the configured maximum deviation;
4. select the candidate with the smallest absolute time difference;
5. on an exact tie, select the earlier candidate to avoid including changes
   made after the period ended;
6. promote the selected candidate to official without recalculating its values;
7. store whether it is early or late and its exact deviation.

The maximum deviation is configurable from 0 to 3 days and defaults to 2 days.
A value of 0 disables operational promotion.

One snapshot cannot represent more than one weekly period. If no valid candidate
exists, the period remains `missing`. Long outages are not filled with invented
values. Available candidates may recover only the periods for which they are
valid; all other periods remain visibly missing.

### Idempotency and concurrency

- A project can have at most one official snapshot for a `period_type` and
  `period_end`.
- A run can be repeated without duplicating official or operational data.
- Existing successful project snapshots are not overwritten during retry.
- A retry processes only missing or failed project results where possible.
- Database uniqueness constraints are the final duplicate safeguard.
- A global/advisory lock prevents concurrent collectors from racing.

## 7. Snapshot States and Provenance

Project history must distinguish:

- `active`;
- `closed`;
- `archived`;
- `out_of_scope`;
- `collection_disabled`;
- `missing`.

Active official snapshots also record:

- `direct` or `promoted` source;
- `on_time`, `early`, or `late` timing;
- exact capture deviation from the target boundary;
- calculation algorithm version;
- non-sensitive calculation settings digest;
- plugin version;
- current configured rounding mode;
- warnings returned by the calculator.

Email addresses and notification recipient settings must not be copied into the
snapshot settings digest.

Changing calculation settings never rewrites old snapshots. Historic rows must
remain explainable using the stored provenance.

## 8. Persistent Data Model

Exact Rails class and table names may be adjusted to Redmine conventions during
implementation. The logical model requires the following records.

### Collection run

One row per execution, including:

- started and completed timestamps;
- run source: cron, manual due capture, preview, cleanup, or test email;
- run status: successful, partial, failed, disabled, or recovery;
- target period when applicable;
- processed, succeeded, skipped, failed, recovered, created, promoted, and
  deleted counters;
- summarized safe errors;
- email attempted/sent/failed state and recipient count;
- duration.

Preview and test-email actions must remain explicitly distinct from real
collection runs. Preview never persists snapshots, performs retention cleanup,
or sends collection email.

### Project snapshot

One row per project capture or state marker, including:

- project ID;
- snapshot kind: operational or official;
- period type: `weekly` or `monthly`;
- `period_end` for official snapshots;
- `captured_at`;
- project state;
- direct/promoted source and timing deviation;
- project custom-field values at capture time;
- displayed and raw progress values;
- all available aggregate calculator counts, weights, estimate totals, estimate
  coverage, and warnings;
- algorithm, plugin, and calculation-setting provenance;
- whether issue details originally existed and whether they were later purged.

Aggregate fields should include at least the current calculator output:

- displayed percent done;
- raw percent done;
- all project issue count;
- eligible issue count;
- included issue count;
- excluded parent issue count;
- estimated and unestimated eligible issue counts;
- ignored unestimated issue count;
- known estimated hours;
- total and imputed weight;
- estimate coverage percent;
- warning codes.

These aggregates are stored even when the initial chart mode hides them. This
supports future CSV and REST contracts without changing old rows.

Existing installations that already have official weekly rows must migrate them
to `period_type = weekly`. The snapshot uniqueness boundary must include period
type, so a weekly and monthly official snapshot can coexist for the same project
and `period_end`:

```text
project_id + period_type + period_end
```

### Issue snapshot

When detail level is `project_and_issues`, every issue in the project is stored,
including issues excluded from the calculation.

The issue row should include:

- parent project snapshot ID;
- issue ID;
- issue subject at capture time;
- original and effective done ratio;
- estimated hours;
- applied weight and weighted value;
- included flag;
- exclusion reason;
- calculation note codes;
- status identifier/name needed to explain the historic value.

Storing subject/status text is a proposed V1 technical default so deleted or
later-renamed issues remain understandable during the detail-retention window.
The data is visible only to system administrators and is removed by the same
detail-retention and project-deletion rules.

### Period/run state

Global period/run data must be sufficient to distinguish:

- collection explicitly disabled;
- collector not executed;
- collector failed;
- collector partially completed;
- collector later recovered.

Missing periods must never be silently presented as zero progress.

## 9. Retention and Deletion

### Aggregate project history

Official aggregate project history and state markers are retained indefinitely
by default.

They are deleted only when:

- the Redmine project itself is deleted;
- a system administrator explicitly purges that project's complete history;
- the plugin is explicitly uninstalled through its destructive uninstall path.

They are not deleted when a project is closed, archived, made out of scope, or
when history collection is disabled or reconfigured.

This applies to both weekly and monthly aggregate snapshots. Monthly aggregate
snapshots are retained indefinitely because they are the audit source for
downstream bonus-cap calculations. Issue-detail retention remains separate.

### Issue-detail age retention

- Configurable range: 13 to 520 weeks.
- Default: 52 weeks.
- Applies to issue snapshot rows, not aggregate project rows.
- Reducing the value causes newly out-of-policy details to be deleted during the
  next cleanup.
- Cleanup is batched and reports exact deletion counts.
- The settings UI must warn that reducing retention causes irreversible
  deletion.

### Closed/archived project retention

- Configurable grace range: 0 to 52 weeks.
- Default: 4 weeks.
- The grace period begins with the first official weekly state that observes the
  project as closed or archived.
- A transition from closed to archived does not restart the grace period.
- Reopening before expiry cancels the pending inactive-project purge.
- After expiry, all issue-detail history for the project is deleted, even if it
  is newer than the general issue-detail retention threshold.
- Aggregate project history remains intact.
- Reopening after deletion starts new issue-detail collection; deleted details
  are not reconstructed.

An active `out_of_scope` project does not use the short inactive-project grace
period. Its issue details follow the normal age-retention policy.

### Operational details

Issue rows attached to an obsolete operational snapshot are removed with that
snapshot during daily rotation. A promoted snapshot and its details become
official and follow official retention rules.

### Project deletion

Deleting a project from Redmine deletes all plugin data for that project:

- aggregate snapshots;
- issue snapshots;
- state records;
- project-specific diagnostics where retention is not independently required.

Use a supported Redmine hook/callback integration where available and add an
orphan cleanup safety check to the rake task. Avoid broad model monkey patches.

### Manual project purge

V1 provides a system-administrator-only action for one project at a time. It:

- previews aggregate and detail row counts;
- requires explicit irreversible-action confirmation;
- deletes all plugin history for the selected project;
- does not delete or modify the Redmine project;
- records a safe operational audit result without retaining purged issue data.

No global UI purge is included in V1. A maintenance rake command may support an
explicit project identifier and dry-run mode.

## 10. Administration Settings

### Collection

- Enable historical collection; default off.
- Detail level: project only, or project plus issues; default project only.
- History visibility: hidden, system administrators only, or visible according
  to project access; default hidden.
- Project type custom field.
- Allowed project type values; at least one required when enabled.
- Maximum operational promotion deviation: 0-3 days, default 2.

### Retention

- Issue-detail retention: 13-520 weeks, default 52.
- Closed/archived issue-detail grace: 0-52 weeks, default 4.

### History display defaults

- Initial chart mode: percent only or extended; default percent only.
- Default period: 13, 26, 52, 104 weeks, current quarter, current year, or all
  history; default 52 weeks.
- Default change display: hidden, percentage points, or relative percent;
  default percentage points.
- Reporting year: calendar or fiscal.
- Fiscal year start month; default January, so calendar and fiscal years match.

Display settings affect only the initial view. All aggregate data is always
stored. User changes are retained locally in the browser, keyed by plugin/user,
without database writes.

### Email

- Enable collection email; default off.
- Notification level; default weekly only.
- Required comma-separated recipient list when email is enabled.
- Recipient mode: TO or BCC; default BCC.
- Subject template with supported placeholders.

In BCC mode, recipients are hidden and the Redmine system sender address is used
as the visible `To` address.

### Validation and help

Every non-obvious setting must have complete English and Bulgarian help that
explains:

- purpose and effect;
- default value;
- allowed range/values;
- interaction with other settings;
- when a change takes effect;
- storage and irreversible deletion consequences;
- a practical example where useful.

The settings page must:

- disable or hide dependent controls when their parent feature is off;
- reject invalid enabled configurations;
- warn about stale custom fields/values;
- warn and require confirmation when retention is reduced;
- avoid duplicate native/custom tooltips;
- preserve EN/BG key and interpolation-placeholder parity.

## 11. Reporting Calendar and Filters

### Rolling periods

- 13 weeks: approximately one quarter.
- 26 weeks: approximately half a year.
- 52 weeks: one year and the default view.
- 104 weeks: two-year comparison.
- All history.

These are rolling windows ending at the latest available period.

### Calendar periods

- Q1: January 1-March 31.
- Q2: April 1-June 30.
- Q3: July 1-September 30.
- Q4: October 1-December 31.
- Full calendar year.

A weekly snapshot belongs to the quarter/year containing its Sunday
`period_end`. A week is never split or counted in two periods.

### Fiscal periods

The administrator configures the fiscal-year start month. Fiscal years are named
for the year in which they start. For a fiscal year starting in April:

```text
FY2026 Q1: 2026-04-01 through 2026-06-30
FY2026 Q4: 2027-01-01 through 2027-03-31
```

The UI always displays exact period dates to avoid ambiguity. Available years
are derived from stored history. The current quarter/year may display partial
history.

## 12. Project History UI

History appears on a dedicated `Progress history` project page. The existing
Project Percent Done page remains focused on the live calculation and its
rationale.

### Access

- Aggregate graph/table access first follows the global history visibility
  setting. In `project access` mode it then follows the user's current access to
  the project and the dedicated project history page.
- In `hidden` mode, the project history tab/link and direct history URL are not
  available to project users even while collection continues.
- In `system administrators only` mode, only Redmine system administrators can
  open aggregate project history.
- Only Redmine system administrators can view or expand per-issue historical
  details.
- Regular users never receive issue snapshot rows through HTML endpoints.
- Future CSV/REST work must preserve the same visibility boundary.

### Graph

- Default range: 52 weeks.
- Primary series: displayed project percent done.
- Exact point values appear in tooltips.
- Only the latest point has a permanent value label to avoid overlap.
- Extended mode allows series/indicators for:
  - all issue count;
  - included issue count;
  - known estimated hours;
  - estimate coverage percent.
- Closed, archived, out-of-scope, disabled, and missing periods are visibly
  distinguished.
- The progress line is not connected across interrupted periods.
- Promoted official snapshots show early/late and deviation indicators.

Use a locally bundled, Redmine-compatible chart implementation. Do not rely on a
remote CDN. The final choice must be verified for Redmine 5.x/6.x compatibility,
responsive layout, accessibility, and acceptable asset size.

### Change display

The current value is always shown. Change display can be:

- hidden: `56%`;
- percentage points: `56% (+4 pp)`;
- relative percent: `56% (+7.7%)`.

Percentage points are the default. Relative change is undefined when the prior
value is zero and is shown as unavailable. The first active snapshot after any
closed, archived, out-of-scope, disabled, or missing interruption shows no
change, because the movement cannot be attributed to one weekly period.

### Table

Each weekly row includes:

- period end;
- project/collection state;
- exact displayed value;
- selected change representation;
- all, eligible, and included issue counts;
- known estimated hours;
- estimate coverage;
- direct/promoted and on-time/early/late timing;
- warnings.

Rows are newest first and paginated as needed. An administrator can expand an
active row to inspect issue details. If details were purged, the row remains and
states that details were removed by the retention policy.

### Browser-local preferences

The selected range, chart mode, enabled extended series, and change display are
stored locally in the browser. Keys must include the current Redmine user ID to
avoid leaking preferences between users sharing a browser profile. Server-side
defaults apply when no local preference exists.

## 13. Historical Public API

Project Percent Done exposes a versioned in-process historical Public API under
the existing namespace:

```ruby
ProjectPercentDone::PublicApi::V1
```

This API is the supported integration boundary for other Redmine plugins.
Consumers must not read `ProjectPercentDoneSnapshot`, issue snapshot models, or
plugin tables directly, and must not recalculate project progress locally.

### Public methods

The historical API covers these use cases:

```ruby
ProjectPercentDone::PublicApi::V1.history_capabilities
ProjectPercentDone::PublicApi::V1.latest_official_snapshot(project:, period_type: :monthly)
ProjectPercentDone::PublicApi::V1.official_snapshot_for(project:, period_type:, period_end:)
ProjectPercentDone::PublicApi::V1.official_snapshots_between(project:, period_type:, from:, to:)
ProjectPercentDone::PublicApi::V1.progress_at(project:, date:, preferred_period_type: :monthly)
```

The exact Ruby class names of the returned value objects are implementation
details, but the method names and result fields form a public contract once
released.

### History capabilities

`history_capabilities` returns an immutable object with at least:

- contract name and version;
- plugin and algorithm version;
- `history_supported`;
- supported period types, including `weekly` and `monthly`;
- default period type: `monthly`;
- official snapshot support;
- monthly snapshot support;
- `progress_at` support;
- calculation mode;
- persistence mode: `snapshots`.

Adding historical methods must not change the existing live
`ProjectPercentDone::PublicApi::V1.calculate` contract. If the historical API
contract needs independent evolution, add explicit history capability fields or
a dedicated history contract version instead of silently changing live result
semantics.

### Historical snapshot result

Historical API methods return immutable value objects with defensive `to_h`
copies. A result includes at least:

- project ID;
- period type;
- period end;
- captured timestamp;
- project state;
- `progress_available`;
- stable unavailable reason;
- displayed and raw percent done;
- estimate coverage;
- warning codes;
- source, timing, and deviation provenance;
- algorithm and plugin version;
- calculation settings used at capture time;
- aggregate issue counts, weights, and estimate metrics stored on the snapshot.

A valid `0%` snapshot has `progress_available = true`. Zero must never be used
as a synonym for missing or unavailable progress.

### Monthly official snapshots

Monthly official snapshots are created automatically whenever historical
collection is enabled. There is no separate setting for monthly collection.

A monthly snapshot represents project progress observed for the end of a
completed calendar month. It is not an average for the month. If exact
month-end capture is missed, the collector uses the same nearest eligible
operational candidate pattern as weekly snapshots, with the configured
promotion tolerance and actual `captured_at`, timing, and deviation preserved.

Monthly missing periods remain explicit and must not be fabricated from current
live project data.

### Derived periods

Quarterly, half-yearly, and yearly historical values are derived from monthly
snapshots, not stored as duplicate aggregate rows:

```text
Q1 2026 = monthly snapshot at 2026-03-31
Q2 2026 = monthly snapshot at 2026-06-30
H1 2026 = monthly snapshot at 2026-06-30
H2 2026 = monthly snapshot at 2026-12-31
Calendar year 2026 = monthly snapshot at 2026-12-31
```

Consumers that need progress delta compare boundary snapshots. Bonus cap logic
primarily uses the absolute progress value at the cut-off date.

### `progress_at` semantics

For `preferred_period_type: :monthly`, the deterministic MVP rule is:

```text
period_end = date.end_of_month
```

- If that month has not completed as of execution time, return
  `progress_available = false` and `unavailable_reason = period_not_completed`.
- If the month has completed but no official monthly snapshot exists, return
  `progress_available = false` and `unavailable_reason = snapshot_missing`.
- If the snapshot exists but the stored progress is unavailable, return
  `progress_available = false` with the snapshot's stable unavailable reason.
- Do not fall back to weekly snapshots.
- Do not fall back to live calculation.

For an annual cut-off on `2026-12-31`, `progress_at` returns the official
monthly snapshot whose `period_end` is `2026-12-31`, once December 2026 is
complete and the snapshot exists.

### Missing and unavailable reasons

The API distinguishes at least:

- `period_not_completed`;
- `snapshot_missing`;
- `history_disabled`;
- `project_not_tracked`;
- `project_closed`;
- `project_archived`;
- `project_out_of_scope`;
- `collection_disabled`;
- `progress_unavailable`;
- `no_eligible_issues`;
- `no_usable_weight`.

Invalid arguments raise `ArgumentError`. Database/runtime errors may propagate.
Missing or unavailable historical progress is represented as an immutable result
object so downstream workflows can show stable reason codes and refuse
finalization without exception control flow.

## 14. Administration Diagnostics and Actions

The settings page includes a diagnostic block with:

- last successful execution;
- last attempted execution and status;
- last processed official period;
- counts for active, closed, archived, out-of-scope, failed, and recovered
  projects;
- created, promoted, retained, and deleted snapshot counts;
- email delivery status;
- duration;
- configuration warnings;
- an overdue warning when no expected execution has occurred for more than
  eight days.

V1 administrative actions:

### Preview without persistence

- Shows eligible projects and expected issue volume.
- Performs no snapshot writes.
- Performs no cleanup.
- Sends no collection email.

### Create due snapshot now

- Runs the same idempotent due-capture logic as cron.
- Does not create duplicate official snapshots.
- Uses normal configured notification behavior only when it creates, promotes,
  repairs, or detects a configured reportable state.

### Test email

- Sends only to configured test/notification recipients.
- Adds localized `[TEST]` or `[TEST]` equivalent subject prefix.
- Creates no snapshots and runs no cleanup.
- Clearly labels the content as test data.

### Per-project purge

- Available only to system administrators.
- Displays row counts and irreversible warning.
- Requires explicit confirmation.

## 15. Email Notifications

### Recipient handling

- Email is disabled by default.
- At least one valid comma-separated address is required when enabled.
- Whitespace is trimmed and normalized duplicates are removed.
- Any invalid address blocks saving the enabled configuration.
- TO mode exposes all configured addresses.
- BCC mode hides configured addresses and uses the Redmine system sender in
  `To`.
- Recipient addresses are settings, not snapshot provenance.

### Notification levels

| Level | Official results | Successful operational results | Operational problems |
|---|---:|---:|---:|
| Weekly only | Yes | No | No |
| Weekly plus problems | Yes | No | Yes |
| Every execution | Yes | Yes | Yes |

Default: weekly only.

Regardless of level:

- `successful`, `partial`, `failed`, and `recovery` official outcomes are
  reportable;
- collection-disabled notification is sent at most once per week;
- a repeated idempotent run with no new, promoted, repaired, or newly detected
  reportable state sends no duplicate message;
- email failure never rolls back snapshot data;
- email delivery status is tracked separately from collection status.

### Recovery notification

If an official run is partial or failed and a later run completes the missing
project results, send a localized `[RECOVERY]` notification. The email identifies
the recovered period and count. A recovery message is sent only when recipients
were previously eligible to receive the problem state.

### Subject template

Use the same `%{placeholder}` convention and safety behavior as Project Risk.
Supported placeholders:

- `%{date}`;
- `%{period_end}`;
- `%{status}`;
- `%{snapshot_type}`;
- `%{captured_at}`;
- `%{deviation}`;
- `%{snapshot_count}`;
- `%{active_count}`;
- `%{closed_count}`;
- `%{archived_count}`;
- `%{out_of_scope_count}`;
- `%{issue_snapshot_count}`;
- `%{deleted_detail_count}`;
- `%{recovered_count}`.

Rules:

- unknown placeholders remain literal;
- blank or invalid templates use a localized default;
- CR/LF and unsafe control characters are rejected;
- whitespace is normalized;
- final subject length is limited to 200 characters;
- test messages add a localized test prefix;
- recovery messages add a localized recovery prefix.

### Email body

The message includes:

- run type/status and exact timestamps;
- official period when applicable;
- processed/succeeded/failed/recovered project counts;
- created/promoted issue and project snapshot counts;
- deleted detail counts;
- timing deviation for promoted official snapshots;
- names of failed projects and a short safe error code/message;
- link to the administration diagnostics page.

It must not include issue subjects/details, stack traces, secrets, or arbitrary
exception text. Detailed technical errors remain in the Redmine log.

## 16. Rake Tasks

Planned tasks:

```text
redmine:project_percent_done:snapshots
redmine:project_percent_done:cleanup
```

The snapshot task is scheduled daily and performs capture, promotion, rotation,
normal cleanup, diagnostics, and configured notification.

The cleanup task supports maintenance execution and dry run. A project-specific
purge mode must require an explicit project identifier. Destructive global
defaults are prohibited.

Console output reports exact counters, for example:

```text
Projects processed: 42
Project snapshots created: 31
State records created: 11
Issue snapshots created: 4820
Issue snapshots deleted by age: 1240
Issue snapshots deleted after project closure: 8610
Failures: 0
```

## 17. Failure Semantics

### Run status

- `successful`: every required project operation completed.
- `partial`: at least one project succeeded and at least one required project
  operation failed.
- `failed`: no required collection result could be completed, or configuration
  prevents collection.
- `disabled`: collection is intentionally disabled.
- `recovery`: a later run completed previously failed required results.

Collection status and email status are independent. A successful collection
with failed email remains a successful collection with `email_failed` delivery.

### Safe degradation

- Invalid history configuration must not affect live percentage calculation.
- A snapshot failure must not affect project overview/sidebar/tab rendering.
- A notification failure must not affect persistence or cleanup transactions.
- A chart/history rendering failure must not affect the existing live result.
- Missing periods display as missing, never as zero.

### No backfill claims

The plugin does not reconstruct progress before activation or fabricate missed
weekly values from current Redmine data. Promoted operational snapshots retain
their real capture timestamp and deviation.

## 18. Performance and Database Requirements

- Use additive, rollback-safe plugin migrations.
- Use portable column types and indexes for supported Redmine databases.
- Index project ID, period end, snapshot kind/state, capture time, and parent
  snapshot ID according to query paths.
- Enforce unique official project/period rows.
- Batch issue inserts and deletes where compatible with supported Rails versions.
- Avoid loading every issue for every project simultaneously.
- Use eager loading/select lists to avoid N+1 queries.
- Keep large cleanup operations bounded and resumable.
- Do not store runtime databases, logs, gems, or Redmine checkouts in this repo.

## 19. Security and Privacy

- Only system administrators can view historical issue rows or purge history.
- Aggregate project history is hidden by default and follows the configured
  visibility mode before current project-page access is considered.
- Server endpoints must enforce permissions; hiding UI controls is insufficient.
- Stored issue subject/status text follows detail-retention deletion.
- Project deletion removes all project-specific plugin history.
- Emails contain aggregate diagnostics and failed project names, never issue
  details.
- Subject templates are protected against header injection.
- Future CSV/REST endpoints require a separate security review before release.

## 20. Testing and Acceptance

Implementation is incomplete until focused and full Redmine plugin tests pass in
the shared runtime declared by `.redmine-test.yml`.

Required coverage includes:

### Settings and validation

- defaults and allowed ranges;
- single-value and multi-value list custom-field matching by intersection;
- stale/missing field and value handling;
- dependent setting validation;
- retention reduction warning/confirmation;
- EN/BG key and placeholder parity.

### Collection lifecycle

- normal daily operational creation and rotation;
- direct official creation;
- nearest-candidate promotion before and after Sunday;
- earlier-candidate tie break;
- 0/1/2/3-day deviation boundaries;
- no promotion outside tolerance;
- one candidate cannot fill two periods;
- long outage missing-period behavior;
- idempotent rerun and concurrent-run protection;
- per-project transaction isolation and recovery.

### Eligibility and state

- active/in-scope capture;
- closed, archived, out-of-scope, disabled, and missing representation;
- close/reopen before grace expiry;
- close/archive without grace restart;
- reopen after detail purge;
- custom-field/value configuration changes preserving old history.

### Retention and deletion

- age-based issue detail cleanup;
- complete issue-detail purge after inactive grace;
- operational detail rotation;
- lowering retention;
- project deletion full cleanup;
- administrator project purge authorization and confirmation;
- orphan safety cleanup;
- aggregate rows preserved when only details are purged.

### Permissions and UI

- aggregate history limited to visible/current project access;
- issue detail restricted to system administrators;
- graph gaps and promoted timing markers;
- rolling, calendar, fiscal quarter, and full-year filters;
- fiscal year naming by start year;
- exact value and change-mode behavior;
- zero baseline and post-gap change handling;
- browser-local preferences keyed by user;
- responsive graph/table and accessible controls.

### Email

- disabled/default behavior;
- required recipient validation and de-duplication;
- TO and BCC mapping;
- three notification levels;
- successful, partial, failed, disabled, and recovery behavior;
- no duplicate email on no-op rerun;
- weekly cap for disabled notification;
- subject placeholders, fallback, injection rejection, and length limit;
- test prefix and test-path separation;
- email failure not rolling back data;
- safe failed-project content without issue details/stack traces.

### Compatibility and regression

- existing live calculation unchanged when history is disabled;
- existing overview/sidebar/tab behavior unchanged;
- existing REST API and live `PublicApi::V1.calculate` contract unchanged;
- historical Public API methods returning immutable value objects;
- weekly and monthly official snapshots coexisting for the same `period_end`;
- monthly leap-year and month-end promotion behavior;
- `progress_at` monthly cut-off behavior, including `period_not_completed`,
  `snapshot_missing`, unavailable progress, and valid `0%`;
- Redmine 5.x and 6.1.x compatibility where the shared test matrix permits;
- migration up/down behavior reviewed without destructive ordinary rollback.

## 21. Implementation Sequence

Recommended increments:

1. Add migrations, models, and provenance fields, including `period_type`.
2. Backfill existing official rows to `weekly` and adjust uniqueness to
   `project_id + period_type + period_end`.
3. Implement daily collector weekly/monthly promotion, locking, and run
   diagnostics without changing current weekly UI behavior.
4. Implement historical Public API capabilities, snapshot results, lookup
   methods, and `progress_at`.
5. Implement retention, project deletion cleanup, dry-run, and manual purge.
6. Implement admin health block, preview, manual due capture, and test email.
7. Implement notification resolver, subject renderer, mailer, and recovery rules.
8. Implement aggregate graph/table and browser-local preferences.
9. Implement administrator-only issue detail expansion.
10. Complete tests, performance checks, migration validation, documentation, and
   staging acceptance.

Each increment should preserve the existing live behavior and be testable before
the next surface is added.

## 22. Implementation-Time Verification Items

These are technical verification items, not unresolved product requirements:

- confirm cross-version Redmine project active/closed/archived APIs;
- select the least invasive supported project-deletion hook;
- benchmark issue snapshot volume and batch sizes on representative data;
- select and bundle a compatible chart implementation;
- verify BCC delivery with the configured Redmine mail sender;
- verify browser-local preference isolation for anonymous/shared browser cases;
- decide final Rails table/class names within database identifier limits;
- confirm whether captured issue subject/status text requires any customer-
  specific privacy restriction before production enablement.

## 23. Approved Product Decisions Summary

- History is optional and disabled by default.
- Daily operational snapshots rotate; official Sunday snapshots persist.
- Official monthly snapshots are created for completed calendar months whenever
  historical collection is enabled.
- Monthly aggregate snapshots are retained indefinitely.
- Quarterly, half-yearly, and yearly values are derived from monthly snapshots.
- `progress_at` with monthly preference never falls back to weekly or live
  calculation.
- Missed Sunday snapshots use the nearest valid operational candidate.
- Promotion tolerance is 0-3 days, default 2; ties prefer the earlier snapshot.
- Weekly gaps that cannot be recovered remain explicitly missing.
- Project scope uses intersection with selected values from a single-value or multi-value project list
  custom field.
- Only active, in-scope projects receive calculated snapshots.
- Closed, archived, and out-of-scope periods remain explainable.
- Detail level is globally project-only or project-plus-all-issues.
- All issues are captured in detailed mode, including excluded issues.
- Issue details default to 52-week retention, configurable 13-520 weeks.
- Closed/archived detail grace defaults to 4 weeks, configurable 0-52 weeks.
- After grace, all issue details are deleted; aggregate history remains.
- Project deletion removes all plugin history.
- System administrators can explicitly purge one project's full history.
- Aggregate history is indefinite otherwise.
- V1 UI is graph plus table; CSV and REST history are deferred.
- Aggregate visibility is configurable: hidden by default, administrators only,
  or project access. Issue history is always admin-only.
- Rolling periods, calendar quarters/years, and fiscal quarters/years are
  supported.
- Fiscal years are named by start year and default to a January start.
- Exact values are always shown; change can be hidden, percentage points, or
  relative percent, defaulting to percentage points.
- User display preferences are stored locally in the browser.
- Email supports TO/BCC, templates, test and recovery prefixes, failed project
  names, and three notification levels.
- Successful operational email can be enabled by selecting every-execution
  notification level.
- Preview and manual due capture are included in V1.

## 24. Observed Plan Dates, Time Boundaries, and Forecast Inputs

### Purpose and terminology

The administrator may configure one project date custom field as the project
start date and one as the current planned end date. Redmine exposes only their
current values. Every plugin snapshot therefore stores both values as observed
at capture time so later changes form an auditable plan history.

The first stored values are called the **first observed plan**, never the
original, contractual, or baseline plan. The plugin cannot prove whether either
field changed before collection began.

The date fields are optional inputs for plan analysis and forecasting. Missing,
stale, invalid, or incomplete date configuration never blocks normal project
progress collection, retention, or live calculation.

### Administration settings

- Project start date custom field; optional; when selected it must be an
  existing project custom field with `date` format.
- Planned project end date custom field; optional; same validation.
- The same field cannot be selected for both roles.
- Calendar mode is `calendar_days_v1` in this release.
- A future business-day mode will use a versioned public provider contract from
  a holiday/calendar plugin. It must not read that plugin's private models or
  tables.

Help text in English and Bulgarian explains that dates affect analysis and
forecasts only, that old snapshots retain old values, and that the first value
is merely the first observed plan.

### Snapshot fields

Every operational and official project snapshot stores:

- configured start/end custom-field IDs and names;
- observed project start date and planned end date;
- calendar mode;
- whether this is the first observed plan;
- start/end change flags and calendar-day differences from the preceding
  official snapshot;
- planned duration, elapsed days, capped elapsed-time percentage, days before
  start, and days overdue where meaningful;
- schedule variance in percentage points: raw project progress minus capped
  elapsed-time percentage;
- plan phase and plan warning codes.

Date changes never rewrite earlier snapshots. Changing the configured custom
fields also leaves previous provenance and values intact.

### Time-entry aggregates

Snapshots store aggregate direct-project time-entry facts only. They do not
store time-entry comments, users, activities, or per-entry rows:

- total hours and time-entry count known at capture time;
- hours whose `spent_on` date is before the observed start;
- hours within the valid observed start/end interval;
- hours after the observed planned end;
- hours that cannot be classified because the plan is incomplete/invalid;
- earliest and latest `spent_on` dates;
- pre-start and post-end activity flags.

`spent_on` determines the work date. A later snapshot may change a historic
bucket when a time entry is added, edited, deleted, or backdated, or when a plan
date changes. Such a plan-change week must not describe the bucket difference
as purely new work. All boundary buckets remain part of total reported hours.

Time-entry scope matches the current calculator's direct-project scope and does
not include subprojects.

### Plan phases and anomalies

- `insufficient_date_data`: one or both dates are missing, invalid, or end is
  not after start. Forecasts are unavailable; normal collection continues.
- `planned_not_started`: capture date is before start and there is no reported
  time or positive project progress.
- `pre_start_activity`: capture date is before start and there are reported
  hours and/or positive progress. Show exact hours, first activity date, and
  calendar days before start. Never move the start date automatically.
- `within_planned_period`: capture date is from start through planned end.
- `overdue_active`: project remains active after planned end. Show calendar
  days overdue and post-end hours.
- `after_planned_end`: a non-active tracked project is observed after planned
  end; post-end time remains visible as an anomaly.

Pre-start progress and pre-start reported hours are separate warning signals.
Post-end hours are shown even when the project is closed or archived.

### Period before collection began

No historic progress percentage is reconstructed. Weekly periods from the
observed start date through the first official project snapshot are displayed
as `not_observed`. This differs from `missing` (an expected execution failed),
`disabled` (collection was explicitly off), and `planned_not_started` (the
observed start date had not arrived).

Time entries can be summarized retrospectively for the unobserved interval
because they have `spent_on` dates, but that summary is labelled separately and
never presented as a progress snapshot or backfilled percent.

### Forecast V1

Forecasting is informational shadow output and never changes the stored/live
project percentage. A projected 100% date is available only when:

- the latest official snapshot is active and on/after the observed start;
- its plan dates are valid;
- at least four consecutive weekly active official snapshots have numeric raw
  progress;
- the fitted progress slope is positive;
- no state/gap interruption exists in the selected trailing sample.

Use at most the latest eight qualifying points and calendar-day linear
regression. Store raw inputs in snapshots; calculate the forecast at read time.
Show sample size, slope, R-squared confidence (`low`, `medium`, `high`), projected
date, and calendar-day difference from the current observed planned end. Never
show a date when the result is mathematically invalid or already contradicted
by an incomplete latest point.

### UI and acceptance additions

- History table shows observed start/end dates, date changes, plan phase,
  elapsed-time percentage, schedule variance, total/boundary hours, and plan
  warnings.
- Graph marks start/end changes, pre-start activity, overdue periods, and the
  current observed start/end milestones when they fall in or near the view.
- Regular project viewers receive aggregate plan/time facts only. Historical
  issue-detail permissions remain unchanged.
- Tests cover optional settings, stale/wrong-format fields, date changes,
  invalid/incomplete plans, all plan phases, time-entry buckets, backdated
  entries, `not_observed`, forecast guards, regression output, and no change to
  live/API contracts.
