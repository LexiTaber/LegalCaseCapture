# Legal Deadline Capture — Stakeholder Design Doc / PRD

Status: Draft
Last updated: 2026-07-28

## Overview

Legal Deadline Capture adds structured, reportable deadline tracking on top of the
team's existing case workflow. It is a companion to the separate Legal Case Capture
and Legal Notes Capture Salesforce application, which is the system of record for
cases.

## Background / Current State

- The paralegal manages a single shared Google Calendar ("US A&L Master Calendar")
  containing all deadlines across the legal team.
- Attorneys create events on their own calendars and add/share them to the shared
  calendar.
- This workflow works well and the team likes it — it is not being replaced.
- Gap: the shared calendar supports the day-to-day workflow but does not support
  reporting (by assignee, by type, by case, capacity views, etc.).

## Problem

There is no way today to answer questions like "what's overdue," "who has too much
on their plate this month," or "how many response deadlines are open across all
cases" without manually reading a calendar.

## User Stories

1. As an attorney, I want to be able to easily track deadlines associated with my
   cases so I can stay organized and ensure I am hitting milestones.
2. As a paralegal, I want to be able to easily track deadlines across multiple
   cases, so I can monitor upcoming deadlines, deliverables, and organize
   reminders.
3. As the team lead, I want to be able to track upcoming deadlines by assignee,
   type, and deadline so that I can get a view of upcoming commitments and use
   this as a capacity indicator.

## Goals

- Give the team a reportable source of truth for deadlines (by case, assignee,
  type, status).
- Do not change the day-to-day calendar workflow people already like.
- Keep data entry to a single action (creating the calendar event) wherever
  possible.
- Route proactive reminders (digest emails) to the right people automatically.

## Non-Goals / Out of Scope (v1)

- Replacing Google Calendar as the daily workflow tool.
- Migrating historical/past deadlines from the shared calendar — starting fresh
  going forward ([[decisions#D-004]]).
- A Google Calendar Add-on / custom structured-entry UI — rejected due to adoption
  risk; only helps for events created through it ([[decisions#D-005]]).
- Two-way sync (Salesforce changes pushed back to Google Calendar).
- Syncing individual attorneys' personal calendars — only the one shared calendar
  is synced ([[decisions#D-009]]).

## Proposed Solution

### Data model (high level)

`Deadline__c` is a child object of Case (Master-Detail), owned by the Legal Case
Capture app's object model. See `docs/DEPLOYMENT_TRACKER.md` for exact API names
once pulled from the other repo, and `docs/decisions.md` for the field-level
decisions (Status values, Needs Review handling, external ID for idempotent sync).

### Calendar sync

A scheduled Claude-driven agent reads new/changed events off the single shared
"US A&L Master Calendar," matches the case referenced in the event title against
Salesforce Case records, classifies the Deadline Type from the event text, and
maps the event creator to a Salesforce User for Assignee. It upserts `Deadline__c`
records via the Salesforce API, keyed on the calendar event ID. See
`docs/decisions.md` D-006 through D-009 for the reasoning and the org convention
that makes Assignee attribution reliable (event must be created by the deadline
owner).

### Reminders

Scheduled Flow sends email digests to the assignee and to the relevant Case Team
lead(s), rather than relying solely on native per-user reminders.

### Reporting

Standard Salesforce reports/dashboards on `Deadline__c`, filterable by Assignee,
Type, Status, and Case — covering all three user stories above (attorney's own
deadlines, paralegal's cross-case view, team lead's capacity view).

## Open Questions

- Exact Case / Case Team object API names and Role field values (pending pull from
  the Case Capture repo).
- How the Claude sync agent authenticates/writes to Salesforce (integration user,
  Connected App scope).
- Whether the "event created by deadline owner" convention needs any enforcement
  or training beyond documentation.

## Success Metrics

- Team lead can produce an accurate capacity-by-assignee view without manually
  reading the calendar.
- Low volume of records landing in `Needs Review` (indicates the case-matching and
  ownership convention are working).
