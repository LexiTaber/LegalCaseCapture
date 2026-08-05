# Scope: Create Google Calendar Events from Legal Case Deadlines

## Goal

When a `LegalCaseDeadline__c` record is created, automatically create a
Google Calendar event inviting the deadline's Owner (`AssignedTo__c`) and
the case's Case Team (`Case_Team_Member__c` for that `Legal_Case__c`) — using
**per-user OAuth** (each person connects their own Google account once in
Salesforce; Salesforce only acts on behalf of people who've done that). No
domain-wide delegation, no Super Admin dependency.

**v1 is create-only.** Later edits to the deadline record (due date, owner,
membership changes) do not update the calendar event — that's explicitly
deferred to a future stage.

**Applies to every `Type__c` value** (Discovery Deadline, Hearing, Motion
Filing, Response Due, Filing Date) — no exclusions in v1.

---

## Prerequisite: retrieve real `LegalCaseDeadline__c` metadata

Nobody has pulled this object's actual field metadata into any repo yet.
Everything referenced below (`Legal_Case__c`, `Type__c`, `DueDate__c`,
`Details__c`, `AssignedTo__c`) is pieced together from the Filing Date scope
doc and a flexipage related-list column reference — not a real retrieve.
Confirm exact field types/labels against the org before implementing,
especially `AssignedTo__c` (assumed Lookup(User), consistent with every
other "who" field in this org, but never directly confirmed) and `Details__c`
(type unconfirmed).

---

## Key facts that shape this design

**1. Per-user OAuth authenticates as whoever's Apex transaction makes the
callout — not an arbitrary user referenced by a lookup field.** You
confirmed deadlines are often created on someone else's behalf (a paralegal
creating a deadline and assigning an attorney as Owner). In that case, the
callout only has the *creator's* Google token available — not the Owner's.
Writing an event directly onto the Owner's calendar as organizer is simply
not achievable with per-user OAuth when creator ≠ owner; only domain-wide
delegation could do that, and that's already been ruled out (D-009,
Super-Admin cost).

**Resolution:** the event is organized on the **creator's** connected
calendar, with the Owner and Case Team added as **invitees**. This still
gets the deadline onto the Owner's calendar (as an invite they see/can
accept), just via a different mechanism than direct ownership. It also means
the feature only needs *creators* — not every attorney — to have connected
their calendar for it to work, which is a smaller onboarding lift given
paralegals/admins are apparently the most frequent creators.

**2. Salesforce doesn't allow synchronous callouts from triggers.** The
after-insert trigger has to enqueue an async Queueable to make the actual
HTTP callout — this is unrelated to the per-user OAuth issue above (async
Apex still runs in the context of whoever enqueued it, so it doesn't change
whose token gets used), it's just a separate, unconditional platform rule.

**3. "Members" = the case's Case Team, not arbitrary users** (per your
call). Resolved via `SELECT User__c, User__c.Email FROM Case_Team_Member__c
WHERE LegalCase__c = :deadline.Legal_Case__c`, matching the object/pattern
already established for Time Tracking.

**4. Not every creator will have connected their Google Calendar.** This is
the unavoidable remaining gap even after the organizer/invitee flip above —
handled via a visible failure flag rather than silently dropping the event
(see Piece 3).

---

## New fields on `LegalCaseDeadline__c`

| Field | Type | Purpose |
|---|---|---|
| `Calendar_Event_Created__c` | Checkbox | True once the event is successfully created. Default false. |
| `Calendar_Event_Creation_Error__c` | Text | Short reason when creation is skipped/fails — e.g. "No connected Google Calendar for {creator name} — add this deadline to their calendar manually." Blank when `Calendar_Event_Created__c` is true. |

---

## Piece 1: Google OAuth plumbing in Salesforce

- **Google Cloud Console** (separate from Workspace Admin — whoever has
  access to the org's GCP project): create an OAuth 2.0 Client ID (Web
  application type), enable the Calendar API, scope
  `https://www.googleapis.com/auth/calendar.events` (create/manage events
  the app created — narrower than full calendar access, which v1 doesn't
  need).
- **Salesforce Setup → Auth. Providers**: new Google provider using that
  Client ID/Secret.
- **Salesforce Setup → Named Credentials → External Credential**:
  Authentication Protocol = OAuth 2.0, **Identity Type = Per User
  Authentication**, mapped to the Auth Provider above. Then a Named
  Credential pointing at `https://www.googleapis.com/calendar/v3/`.
- **Permission Set**: grants access to the Named Credential/External
  Credential — likely worth including in `Advocacy_BaseAccess` (or a new,
  smaller permission set) so any user *can* connect, even though only
  creators strictly need to for the feature to fire.
- **Connecting an account** (native Salesforce UX, no custom page needed for
  v1): each user goes to their own **Setup → Personal Settings →
  Authentication Settings for External Systems → New**, picks the Named
  Credential, and authenticates with Google. One-time, matches the "connect
  once" framing already agreed on.

---

## Piece 2: After-insert trigger + Queueable

`LegalCaseDeadlineTrigger` (after insert) — for records with both
`AssignedTo__c` and `Legal_Case__c` populated, enqueue **one** Queueable per
transaction covering the whole `Trigger.new` batch (bulk-safe, not one job
per record).

`CreateDeadlineCalendarEventQueueable` logic, per deadline:

1. Re-query the deadline: `Type__c`, `DueDate__c`, `Details__c`,
   `AssignedTo__c`, `Legal_Case__c`, `Legal_Case__r.Name`.
2. Query `Case_Team_Member__c` for `Legal_Case__c`, resolve to
   `User__c.Email`.
3. Build the attendee list: Owner's email + Case Team emails, deduplicated
   (skip re-adding the Owner if they're also on the Case Team).
4. Build the event payload:
   - `summary`: `{Type__c}: {Legal_Case__r.Name}`
   - `description`: `Details__c`, plus a link back to the
     `LegalCaseDeadline__c` record
   - `start` / `end`: `DueDate__c` / `DueDate__c` + 1 hour (default duration
     — see Assumptions)
   - `attendees`: the list from step 3
5. `POST` to
   `{Named Credential}/calendar/v3/calendars/primary/events?sendUpdates=all`
   — creates on the **running user's** (the creator's) primary calendar per
   Key Fact #1. `sendUpdates=all` ensures invitees actually get an email,
   not just a silent calendar entry.
6. **Success** → `Calendar_Event_Created__c = true`.
7. **Failure** (no connected calendar, expired token, API error) →
   `Calendar_Event_Created__c = false`,
   `Calendar_Event_Creation_Error__c` set to a specific reason — distinguish
   "creator has no connected Google Calendar" (auth failure) from a generic
   API error, since the fix for each is different (connect vs. retry).

```apex
trigger LegalCaseDeadlineTrigger on LegalCaseDeadline__c (after insert) {
    List<Id> deadlineIds = new List<Id>();
    for (LegalCaseDeadline__c d : Trigger.new) {
        if (d.AssignedTo__c != null && d.Legal_Case__c != null) {
            deadlineIds.add(d.Id);
        }
    }
    if (!deadlineIds.isEmpty()) {
        System.enqueueJob(new CreateDeadlineCalendarEventQueueable(deadlineIds));
    }
}
```

---

## Piece 3: Surfacing failures for manual follow-up

Add `Calendar_Event_Created__c` (unchecked) and
`Calendar_Event_Creation_Error__c` to the **Case Deadlines** related list
columns, and create a list view — e.g. "Deadlines Needing a Manual Calendar
Entry" (`Calendar_Event_Created__c = false`) — for whoever's already doing
the manual add-to-calendar step today. Mirrors the `Needs_Review__c` triage
pattern from the calendar → Salesforce read-direction sync: fail loud and
visible, not silent.

---

## Suggested build order

1. Retrieve real `LegalCaseDeadline__c` metadata (Prerequisite above).
2. Set up the Google Cloud OAuth client + Salesforce Auth Provider +
   External/Named Credential (Piece 1) — GCP Console access and Salesforce
   Setup access may be different people; coordinate both.
3. Connect 1-2 test users via Authentication Settings for External Systems;
   confirm a manual anonymous-Apex callout to the Calendar API succeeds for
   each before writing any trigger logic.
4. Add the two new fields to `LegalCaseDeadline__c`.
5. Build and test the trigger + Queueable in `KHRCSandbox`, including the
   unconnected-creator failure path (create a deadline as a user who hasn't
   connected Google Calendar — confirm it fails gracefully with a clear
   error, not a silent no-op or a blocked save).
6. Add the "needs manual calendar entry" list view (Piece 3).
7. Deploy to `KHRCProd`; roll out "connect your Google Calendar" as an
   onboarding step, prioritizing whoever creates deadlines most often
   (sounds like paralegals) since the feature is only as complete as their
   connection status.

---

## Out of scope (v1)

- Keeping the event in sync after creation (owner reassignment, due-date
  edits, member changes) — deferred to a future stage, per your call.
- Domain-wide delegation / writing directly onto the Owner's calendar as
  organizer — not achievable with per-user OAuth when creator ≠ owner; the
  creator organizes, Owner + Case Team are invitees instead.
- Any custom UI for connecting Google Calendar — v1 uses Salesforce's native
  Personal Settings page.

---

## Assumptions to confirm

- **Default event duration: 1 hour**, starting at `DueDate__c`. If deadlines
  are usually date-only with no meaningful time-of-day, an all-day event
  might read better once you see real data.
- **Scope `.../auth/calendar.events`** is sufficient — v1 never needs
  broader calendar read/settings access.
- **Onboarding priority**: whoever creates deadlines most often should
  connect their calendar first, since every deadline created by someone
  unconnected falls through to the manual-entry flag rather than firing
  automatically.
