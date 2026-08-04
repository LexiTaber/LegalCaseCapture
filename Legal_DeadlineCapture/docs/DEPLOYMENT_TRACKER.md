# Deployment Tracker

Tracks every component this project introduces, its API name, and deployment
status. Update this alongside any metadata change — it's the map from "what we
decided" (`decisions.md`) to "what actually exists in the org."

Status values: `Planned` → `Built (local)` → `Deployed (Sandbox)` →
`Deployed (Production)`.

## Objects

| Component | API Name | Status | Notes |
|---|---|---|---|
| Deadline object | `Deadline__c` | Planned | Master-Detail to Case |
| Case object (external) | TBD — pull from Case Capture repo | Not started | Owned by the separate Legal Case Capture app |
| Case Team object (external) | TBD — pull from Case Capture repo | Not started | Needed for digest routing (D-003) |

## Fields on `Deadline__c`

| Field | API Name | Type | Status | Notes |
|---|---|---|---|---|
| Case | `Case__c` | Master-Detail (to Case) | Planned | Blocked on real Case API name (D-001) |
| Deadline Type | `Deadline_Type__c` | Picklist | Planned | Deadline, Hearing, Motion Filing, Response Due (D-013) |
| Status | `Status__c` | Picklist | Planned | Upcoming, Due, Overdue, Completed (D-010) |
| Due Date | `Due_Date__c` | Date | Planned | |
| Assigned To | `Assigned_To__c` | Lookup (User) | Planned | Populated from calendar event creator (D-007) |
| Notes | `Notes__c` | Long Text Area | Planned | Carries event description / rule nuance (D-008) |
| Calendar Event Id | `Calendar_Event_Id__c` | Text (External Id, Unique) | Planned | Sync upsert key (D-012) |
| Needs Review | `Needs_Review__c` | Checkbox | Planned | (D-011) |
| Review Reason | `Review_Reason__c` | Text | Planned | Populated when Needs Review = true |

## Automation

| Component | API Name | Type | Status | Notes |
|---|---|---|---|---|
| Status transition | TBD | Scheduled Flow | Planned | Moves Upcoming → Due → Overdue based on Due Date (D-010) |
| Deadline digest | TBD | Scheduled Flow | Planned | Emails assignee + Case Team lead(s) (D-003) — blocked on Case Team object/Role field |

## Integration / Access

| Component | Type | Status | Notes |
|---|---|---|---|
| Sync agent auth | Integration user or Connected App (TBD) | Not started | Used by the Claude-driven calendar sync agent to upsert `Deadline__c` (D-006) |
| Attorney permission set | Permission Set | Planned | Read/write own Deadlines |
| Paralegal permission set | Permission Set | Planned | Read/write all Deadlines |
| Team Lead permission set | Permission Set | Planned | Read all Deadlines + reports/dashboards |

## Reports / Dashboards

| Component | Status | Notes |
|---|---|---|
| Deadlines by Assignee | Planned | Team lead capacity view |
| Deadlines by Type | Planned | |
| Upcoming / Overdue Deadlines | Planned | Attorney + paralegal working views |
| Needs Review queue | Planned | Paralegal triage list view (not a formal report) |

## External dependencies

- Legal Case Capture app (separate repo) — source of the Case and Case Team
  objects. API names pending pull-down.
- Google Calendar API access to "US A&L Master Calendar" — auth mechanism TBD.
