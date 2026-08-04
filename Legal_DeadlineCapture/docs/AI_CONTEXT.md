# AI Context & Instructions

This file is written for AI agents working on or around this project — both
coding assistants (e.g. Claude Code editing this SFDX project) and the runtime
sync agent described below. Read this before making changes so you don't
re-derive or contradict decisions already made. Full reasoning lives in
`docs/decisions.md`; this file is the condensed, operational version.

## What this project is

Legal Deadline Capture is a Salesforce (SFDX) app that gives a legal team
reportable deadline tracking, without changing their existing Google Calendar
workflow. It's a companion to a separate Legal Case Capture / Notes Capture app
(different repo — see `docs/DEPLOYMENT_TRACKER.md` once its API names are
pulled in).

Full requirements: `docs/PRD.md`. Decision history: `docs/decisions.md`.

## Ground rules for anyone (or anything) editing this repo

- Don't invent Case/Case Team object API names. If they're not yet in
  `docs/DEPLOYMENT_TRACKER.md`, treat them as unresolved and ask, don't guess.
- `Status__c` values are fixed: Upcoming, Due, Overdue, Completed. Don't add a
  "Needs Review" or similar value to this field — use `Needs_Review__c`
  (checkbox) instead (D-011).
- `Deadline_Type__c` values are fixed: Deadline, Hearing, Motion Filing,
  Response Due. Don't add new values without an explicit decision logged in
  `docs/decisions.md`.
- Deadline is always Master-Detail to Case, never a lookup (D-001).
- The calendar sync only reads the one shared "US A&L Master Calendar" — never
  add per-attorney calendar syncing without a logged decision reversing D-009.
- One calendar event maps to exactly one `Deadline__c` record — never split an
  event into multiple records (D-008).
- When you make a decision with downstream impact (schema, integration
  behavior, process convention), add it to `docs/decisions.md` in the same
  format as existing entries, and update `docs/DEPLOYMENT_TRACKER.md` if it
  introduces or changes a deployable component.

## Instructions specific to the calendar → Salesforce sync agent

If you are the scheduled agent performing the sync (or are building/simulating
it), follow this logic:

1. **Source**: read events from the "US A&L Master Calendar" only. Process new
   events and events that changed since the last run (compare against
   `Calendar_Event_Id__c` + last-modified).
2. **Case matching**: extract the likely case reference from the event title
   (commonly formatted as `{Case Name}: {description}`, e.g. "Stewart v.
   Loftin: Completion of Discovery and Motions") and fuzzy-match it against
   Salesforce Case records. Case names/captions may vary in punctuation or
   ordering ("v." vs "vs.") — match semantically, not by exact string.
   - Confident match → set `Case__c`.
   - No confident match → still create the record, set `Needs_Review__c` =
     true, and set `Review_Reason__c` to something specific and actionable,
     e.g. `No matching case found for "Stewart v. Loftin"`.
3. **Type classification**: classify into exactly one of Deadline, Hearing,
   Motion Filing, Response Due using the event title + description. If it
   genuinely doesn't fit, leave blank and flag for review rather than
   guessing.
4. **Assignee**: use the event's creator/organizer, mapped to a Salesforce User
   by email. This relies on the org convention that the deadline owner creates
   their own event (D-007) — don't fall back to attendees or other heuristics
   unless that convention is later revised in `docs/decisions.md`.
5. **Write**: upsert `Deadline__c` keyed on `Calendar_Event_Id__c`. Never create
   a duplicate for the same event ID.
6. **Never split** one event into multiple `Deadline__c` records (D-008), even
   if the description implies multiple obligations — capture the extra nuance
   in `Notes__c` instead.
7. When uncertain, prefer creating a flagged record over silently dropping the
   event — the paralegal triages `Needs_Review__c = true` records, so failure
   mode should be "needs a human" not "vanished."

## Open items that affect this file

- Case / Case Team object API names and Role values (blocks D-001, D-003
  implementation details).
- How the sync agent authenticates to Salesforce (integration user vs.
  Connected App/OAuth) — update this section once decided.
