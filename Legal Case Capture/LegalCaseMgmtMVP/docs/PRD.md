# Legal Case Capture — Stakeholder Design Doc / PRD

Status: MVP built and deployed to production, including Time Tracking
Last updated: 2026-07-29

## Overview

Legal Case Capture gives KHRC's legal/advocacy team a single, structured place
in Salesforce to track legal cases — who's involved, what's happening, and
where to find related documents — instead of relying on scattered notes,
email threads, and personal files. It is the foundational data model that a
family of companion tools (Legal_NotesViewer, Legal_DeadlineCapture, Legal
Time Tracking) build on top of inside the same `KHRCSandbox` org, all
surfaced together on one Case record page.

## Background / Current State

As of this pull from `KHRCSandbox` (2026-07-29), this is further along than
this project's own prior docs described: the core data model, a Lightning
App ("Advocacy"), and a fully composed Case record page with note search,
deadlines, and time tracking are all deployed and active in sandbox. See
`DEPLOYMENT_TRACKER.md` for the full, verified component list.

## Problem

Legal/advocacy case information previously lived in a mix of places — email,
individual notes, shared drives — making it hard to see a case's status at a
glance, know who's involved and in what capacity, find prior notes (especially
by keyword), or hand off context across attorney and support staff.

## Who it's for

- **Attorneys** leading cases
- **Support staff** assisting on cases
- Anyone at KHRC who needs visibility into case status and history

## What this project owns (MVP scope)

The core recordkeeping model — three objects:

1. **Legal Case** (`LegalCase__c`) — the central record for a legal matter.
   Tracks status, district filed, circuit, case number, filing date, lead
   attorney and support staff, and links out to the case's Box folder and its
   KHRC website overview page (documents themselves live in Box, not
   Salesforce).
2. **Legal Case Contacts** (`LegalCaseContacts__c`) — the people connected to
   a case and their role (Client, Proxy Contact, Partner Org Contact,
   Opposing Counsel), each linked to an existing Salesforce Contact.
3. **Legal Case Note** (`LegalCaseNote__c`) — a running, timestamped log of
   activity on a case: subject, date, author, and rich-text note content,
   automatically mirrored to a plain-text field so it's keyword-searchable.

Plus the general-access and admin permission sets that govern who can do what
with these three objects (`LegalCaseMgmt_GeneralAccess`,
`LegalCaseMgmt_Admin`).

## What's now visible on the Case page, built by companion projects

The Legal Case record page stakeholders see is broader than this project's
own object model, because sibling projects deploy their own Apex/LWC source
into the same org and place it on the same page. All of it is in production:

- **Case Notes tab** — a scrollable, keyword-searchable note feed
  (Legal_NotesViewer), Chatter-like, replacing the plain related list.
- **Deadlines tab** — a related list of case deadlines (Legal_DeadlineCapture).
- **Time Tracking tab** — a time-entry form and timer, plus a related list of
  logged time (Legal Time Tracking).
- **Detail tab** — also shows a Case Team Members related list (Legal Time
  Tracking) alongside this project's own Case Contacts related list.

This project's docs describe its own scope in depth and the others by
reference only — see each sibling project's own `docs/` folder for detail on
how those pieces work.

## Access & sharing

Two permission sets govern the core objects:

- **Legal Case Mgmt - General Access** (`LegalCaseMgmt_GeneralAccess`) — for
  general legal team members. Can view every case/contact/note
  (`viewAllRecords=true`), create and edit all three, and delete
  `LegalCaseNote__c` and `Contact` records (but not `LegalCase__c` or
  `LegalCaseContacts__c`). Also grants visibility into the `Advocacy` app and
  its Legal Case/Note/Contacts tabs.
- **Legal Case Mgmt - Admin** (`LegalCaseMgmt_Admin`) — broader access: full
  CRUD plus `modifyAllRecords`/`viewAllFields` on `LegalCaseContacts__c` and
  `LegalCaseNote__c`; on `LegalCase__c`, CRUD except Delete.

`LegalCase__c` itself uses `Private` org-wide sharing — edit access beyond
what a permission set grants still depends on ownership/sharing rules, none
of which exist in source today.

## Current status

| Area | Status |
|---|---|
| Core data structure (case, contacts, notes) | ✅ Built and deployed to **production** (2026-07-29) |
| Automatic note search support (HTML-stripping trigger + SOSL search enabled) | ✅ Built and deployed to **production** |
| Access/permissions for legal staff (2-tier: General + Admin) | ✅ Built and deployed to **production**, plus full field-level access for the System Administrator and Advocacy profiles |
| Dedicated navigation (Advocacy Lightning App, tabs) | ✅ Built and deployed to **production** (custom logo dropped — see `DEPLOYMENT_TRACKER.md`) |
| Legal Case record page (Detail/Case Notes/Deadlines tabs, related lists) | ✅ Built and deployed to **production** |
| Case Notes feed (searchable, scrollable) | ✅ Built by Legal_NotesViewer, deployed to **production** |
| Deadlines tracking | ✅ Built by Legal_DeadlineCapture, deployed to **production** — that project's own docs are stale and don't yet reflect this |
| Time tracking | ✅ Built by Legal Time Tracking, deployed to **production** (deploy id `0AfPB000001Idjt0AC`, 36/36 components, 0 errors, 35/35 tests passed — see `decisions.md` D-008 for how the initial deploy attempt's failure was resolved) |
| Reports/dashboards on case data | ⬜ Not yet built |
| Production deployment | ✅ Done 2026-07-29 in two passes — core stack (deploy id `0AfPB000001Idbp0AC`) then Time Tracking (deploy id `0AfPB000001Idjt0AC`) |
| This project's local source in sync with the org | ❌ **No** — see `decisions.md` D-006. Local `force-app` predates several schema changes and the entire UI layer. The production deploy was done from freshly retrieved sandbox metadata, not local source. |

## What's intentionally out of scope for this project

- Storing documents directly in Salesforce (Box remains the document store)
- External/client-facing access (this is an internal staff tool)
- Building the Deadlines/Time Tracking/Notes-feed UI inside this project —
  by decision (`decisions.md` D-005), that lives in sibling repos
- Reports/dashboards (not yet built anywhere)

## Open questions for stakeholders

- Who should be able to edit a case they didn't create — just the assigned
  attorney/support staff, or any legal team member with General Access?
- Should this project's local source be reconciled with the org now (pull
  down everything in `DEPLOYMENT_TRACKER.md`), or left as historical record
  until the next active development cycle?
- Is `Case_Note_Record_Page1` (the inactive duplicate Note record page) or
  `LegalTimeEntry__c` (an apparently-abandoned duplicate object — see
  `decisions.md` D-007 correction) safe to remove from `KHRCSandbox`?
- Do we want the Advocacy app's custom logo re-added in a follow-up deploy?
  It was dropped from the 2026-07-29 production deploy due to an unrelated
  ContentAsset access error.

## Glossary

- **Case** — a single legal matter being tracked (`LegalCase__c`)
- **Case Contact** — a person connected to a case and their relationship to
  it (`LegalCaseContacts__c`; client, opposing counsel, etc.)
- **Case Note** — a dated log entry recording activity or updates on a case
  (`LegalCaseNote__c`)
- **Advocacy** — the Lightning App that surfaces Legal Case, Legal Case Note,
  and Legal Contacts alongside standard Account/Contact/Reports/Dashboards
- **MVP** — Minimum Viable Product: the smallest useful version of the tool,
  built to validate the core need before investing further
