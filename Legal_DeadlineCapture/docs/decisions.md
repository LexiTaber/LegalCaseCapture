# Decision Log

Captures decisions with downstream or system impact, in the order they were made.
Each entry: what was decided, why, and what it affects. Update status to
`Revisit` (don't delete) if a decision is later questioned.

Format: `D-XXX` id so other docs can link to a specific decision
(e.g. `decisions.md#d-001`).

---

## D-001: Deadline is a child of Case (Master-Detail)

- Date: 2026-07-28
- Status: Decided
- Decision: `Deadline__c` relates to the Case object via Master-Detail, not a
  lookup.
- Why: Deadlines are always tied to a case; Master-Detail gives correct sharing
  inheritance and enables rollups (e.g., open-deadline counts on Case).
- Impact: `Deadline__c` cannot exist without a parent Case; deleting a Case
  cascades. Blocks on the real Case object API name.

## D-002: Salesforce is a reporting layer, not the daily workflow tool

- Date: 2026-07-28
- Status: Decided
- Decision: Google Calendar remains where attorneys/paralegal actually work
  day-to-day. Salesforce does not attempt to replace the calendar UX.
- Why: The team likes the current shared-calendar workflow; forcing a new daily
  habit was flagged as a bigger adoption risk than it's worth for what is
  fundamentally a reporting need.
- Impact: Rules out Salesforce Activities/Events as the primary UI; shapes every
  later decision toward "sync data out of the calendar" rather than "replace the
  calendar."

## D-003: Reminders via email digest, routed by Case Team

- Date: 2026-07-28
- Status: Decided
- Decision: Reminders are scheduled-Flow email digests sent to the assignee and
  to the Case Team lead(s), rather than a single fixed recipient.
- Why: Team lead digest should scale with however the Case Team object assigns
  roles, not a hardcoded person/email.
- Impact: Digest Flow logic depends on the Case Team object and its Role field
  (from the Case Capture app) — see open item in `PRD.md`.

## D-004: No historical migration

- Date: 2026-07-28
- Status: Decided
- Decision: Start capturing deadlines going forward only; past/historical
  calendar events are not backfilled into Salesforce.
- Why: Keeps v1 scoped to build effort, not data migration effort.
- Impact: Reporting has no historical trend data until enough new deadlines
  accumulate.

## D-005: Rejected — Google Calendar Add-on for structured entry

- Date: 2026-07-28
- Status: Decided (rejected)
- Decision: Considered building a Google Workspace Calendar Add-on (Apps Script)
  giving a Case lookup + Type dropdown at event-creation time, writing to
  Salesforce in real time. Rejected for v1.
- Why: Only benefits events actually created through the add-on — same adoption
  risk as dual-entry. Requires a second application (Apps Script project,
  Salesforce Connected App, Workspace admin install) for a benefit that a
  language-understanding-based sync can achieve without changing user behavior.
- Impact: Ruled out a real-time, fully-structured entry path in favor of
  after-the-fact interpretation (see D-006). Could be revisited later if the
  interpretation approach proves unreliable in practice.

## D-006: Calendar → Salesforce sync via a Claude-driven agent, not regex parsing

- Date: 2026-07-28
- Status: Decided
- Decision: A scheduled agent (Claude-based) reads events off the shared
  calendar and uses language understanding — not a rigid text convention or
  regex — to match the case, classify the deadline type, and identify the
  assignee.
- Why: An early real example ("Stewart v. Loftin: Completion of Discovery and
  Motions") showed attorneys already write case names naturally in event
  titles. A semantic matcher can use that as-is; a brittle convention (bracket
  tags, color-coding) would have required a new habit for comparatively little
  gain.
- Impact: Sync quality depends on the agent's matching/classification, not on
  users following a format. Ambiguous cases are flagged (`Needs_Review__c`,
  D-011) rather than silently dropped or blocking.

## D-007: Convention — event must be created by the deadline owner

- Date: 2026-07-28
- Status: Decided
- Decision: Organizationally, whoever owns a deadline creates the calendar event
  for it (rather than the paralegal creating it on their behalf).
- Why: Makes the event's "created by" field a reliable signal for `Assigned_To__c`
  without needing attendees or a text convention. Confirmed the paralegal
  (Aimee) does not want to be the implicit assignee on every event she helps
  curate onto the shared calendar.
- Impact: This is a process convention, not a technical control — nothing
  enforces it. If assignee data quality is poor in practice, revisit (e.g. add
  attendee-based fallback).

## D-008: One calendar event = one Deadline record

- Date: 2026-07-28
- Status: Decided
- Decision: The sync never splits a single event into multiple `Deadline__c`
  records, even if the event description implies more than one obligation.
- Why: Confirmed the team already creates separate calendar events for related
  deadlines (e.g., discovery completion has its own event distinct from a
  motion-to-compel deadline) — so 1:1 mapping matches actual practice.
- Impact: Simplifies the sync agent significantly — no need to reason about
  splitting or linking derived deadlines.

## D-009: Only the single shared calendar is synced

- Date: 2026-07-28
- Status: Decided
- Decision: The sync reads only "US A&L Master Calendar," not individual
  attorneys' personal calendars.
- Why: Simplest auth setup (one calendar to grant access to, no Workspace
  domain-wide delegation needed); the shared calendar is already the
  aggregation point by process.
- Impact: If an attorney's deadline never gets shared to the master calendar, it
  will not appear in Salesforce — reporting completeness depends on that step
  happening, same as it does today for the calendar itself.

## D-010: Status values and transition ownership

- Date: 2026-07-28
- Status: Decided
- Decision: `Status__c` = Upcoming, Due, Overdue, Completed. The first three
  transition automatically via a scheduled Flow based on `Due_Date__c`;
  `Completed` is set manually.
- Why: Keeps the status a reliable reporting field without relying on manual
  upkeep for time-based states.
- Impact: Requires a daily scheduled Flow evaluating open `Deadline__c` records.

## D-011: Needs Review is a separate flag, not a Status value

- Date: 2026-07-28
- Status: Decided
- Decision: Ambiguous sync results are marked with `Needs_Review__c` (checkbox)
  + `Review_Reason__c` (text), rather than adding a "Needs Review" value to
  `Status__c`.
- Why: Keeps `Status__c` clean for the team lead's capacity reporting; review
  state is an operational concern for the paralegal, not a reportable lifecycle
  state.
- Impact: Reports/dashboards on Status don't need to special-case a review
  state; a separate paralegal-facing list view handles triage.

## D-012: Idempotent sync via external ID

- Date: 2026-07-28
- Status: Decided
- Decision: `Calendar_Event_Id__c` (External Id) stores the Google Calendar
  event ID; the sync agent upserts on this field.
- Why: Event edits (date moved, title corrected) should update the existing
  record, not create duplicates.
- Impact: Sync agent must always have the calendar event ID available and pass
  it on every write.

## D-013: Deadline Type values

- Date: 2026-07-28
- Status: Decided
- Decision: `Deadline_Type__c` picklist = Deadline, Hearing, Motion Filing,
  Response Due.
- Why: Reflects actual categories the team uses today.
- Impact: The sync agent's classification step must map into exactly these four
  values (or leave it blank + Needs Review, not invent a fifth).
