# Decision Log

Captures decisions with downstream or system impact, in the order they were made.
Each entry: what was decided, why, and what it affects. Update status to
`Revisit` (don't delete) if a decision is later questioned.

Format: `D-XXX` id so other docs can link to a specific decision
(e.g. `decisions.md#d-001`).

Several entries below are marked **Why: not documented** — they describe
decisions clearly reflected in the deployed org (confirmed by a metadata pull
from `KHRCSandbox` on 2026-07-29) but made before this log existed, with no
record of the reasoning. Don't backfill a plausible-sounding rationale for
these; if you learn the real reason, replace the note.

---

## D-001: Core data model — three objects, Case as parent

- Date: Undocumented (pre-dates this log)
- Status: Decided
- Decision: `LegalCase__c` is the parent record; `LegalCaseContacts__c` and
  `LegalCaseNote__c` are children via Master-Detail, both `ControlledByParent`
  sharing.
- Why: not documented.
- Impact: This is the foundational MVP shape and hasn't changed since the
  original build — everything else in this doc set assumes it.

## D-002: Party object renamed `LegalCaseParty__c` → `LegalCaseContacts__c`

- Date: Undocumented
- Status: Decided
- Decision: The child object for people connected to a case is deployed in
  `KHRCSandbox` as `LegalCaseContacts__c` (label "Legal Contacts"), not
  `LegalCaseParty__c` as this project's checked-in `force-app` source still
  names it.
- Why: not documented — discovered via a direct metadata pull from
  `KHRCSandbox` on 2026-07-29 (see `DEPLOYMENT_TRACKER.md`). Field-level
  structure (Contact lookup, Role picklist, PARTY-{0000} autonumber name) is
  unchanged; only the object API name/label changed.
- Impact: This project's local `force-app/main/default/objects/` still has a
  folder named `LegalCaseParty__c`, and `LegalCaseMgmt_GeneralAccess`'s local
  source still grants access to `LegalCaseParty__c`. Both are stale — see
  D-006. Any new work should target `LegalCaseContacts__c`.

## D-003: Case and Note "Name" fields are plain Text, not AutoNumber

- Date: Undocumented
- Status: Decided
- Decision: `LegalCase__c.Name` ("Case Name") and `LegalCaseNote__c.Name`
  ("Note Name") are Text fields entered by the user, not the AutoNumber
  `CASE-{0000}` / `NOTE-{0000}` format this project's local source still
  declares.
- Why: not documented — discovered via the same 2026-07-29 metadata pull.
- Impact: Case and note records are named by whatever the creator types, not
  a sequential number. Anything assuming the old auto-number format (docs,
  reports, integrations) is stale. `LegalCaseContacts__c`'s name field is
  still AutoNumber (`PARTY-{0000}`) — unaffected.

## D-004: Note search relies on SOSL + org-level "Allow Search"

- Date: Undocumented (setting enabled); reasoning documented in
  `Legal_NotesViewer/docs/DECISIONS.md` items 9–10
- Status: Decided
- Decision: `LegalCaseNote__c` has `enableSearch = true` (the "Allow Search"
  object setting) so the Legal Case Note Feed component's SOSL search works.
- Why: `NoteDetailSearch__c` is a Long Text Area field, which SOQL cannot
  filter on in a `WHERE` clause; SOSL is the supported alternative, and SOSL
  requires the target object to be search-enabled.
- Impact: This is an org-level checkbox (Setup → Object Manager → Legal Case
  Note → Details → Allow Search), not something a metadata deploy turns on by
  itself — confirmed on in `KHRCSandbox` as of this pull, but a fresh org
  (e.g. a future production org) will need it re-enabled manually.

## D-005: Case UI (LWCs, related lists) is assembled from sibling repos, not built inside this project

- Date: Documented in `Legal_NotesViewer/docs/DECISIONS.md` item 1; Legal
  Time Tracking follows the same pattern
- Status: Decided
- Decision: `Legal_NotesViewer` and the Legal Time Tracking project are
  separate SFDX projects that deploy Apex/LWC source into the same
  `KHRCSandbox` org and get placed onto `LegalCase__c`'s Lightning Record Page
  via App Builder — rather than being built inside `LegalCaseMgmtMVP`.
- Why: "keeps this feature's source isolated from the core data-model
  project" (Legal_NotesViewer's own words).
- Impact: `LegalCase__c`'s actual record page (`Legal_Case_Record_Page`) is
  composed of components whose source doesn't live in this project:
  `legalCaseNoteFeed` (Legal_NotesViewer) and `timeEntryForm` (Legal Time
  Tracking). This project's own `force-app` does not contain — and should not
  try to redeclare — everything rendered on that page. See
  `DEPLOYMENT_TRACKER.md` → "External / companion components."

## D-006 (finding, 2026-07-29): Local `force-app` source has drifted from the deployed org and must not be treated as current

- Date: 2026-07-29
- Status: Decided (documentation posture, not a schema change)
- Decision: Treat `KHRCSandbox` as the system of record for this project's
  metadata. This project's checked-in `force-app` source is stale and should
  be retrieved/reconciled before it's used as the basis for any deploy.
- Why: A metadata pull directly from `KHRCSandbox` on 2026-07-29 (full detail
  in `DEPLOYMENT_TRACKER.md`) turned up, none of which are reflected in local
  source: the `LegalCaseParty__c` → `LegalCaseContacts__c` rename (D-002),
  the AutoNumber → Text name-field changes (D-003), six fields on
  `LegalCase__c` not in local source (`Case_Number__c`, `Circuit__c`,
  `Filing_Date__c`, `Total_Hours_Logged__c`, `US_Team_Assigned__c`,
  `Website_Overview__c`), a second permission set (`LegalCaseMgmt_Admin`)
  alongside `LegalCaseMgmt_GeneralAccess`, and an entire Lightning App/tabs/
  record-page/LWC layer (the `Advocacy` app) that exists only in the org.
- Impact: **Do not run `sf project deploy start` from this project's current
  local source without first retrieving from `KHRCSandbox` and reconciling.**
  Deploying stale source risks reintroducing the retired `LegalCaseParty__c`
  API name, reverting the Name-field format, or overwriting
  `LegalCaseMgmt_GeneralAccess` with a version missing the fields/objects/
  Delete grants the org copy has. Reconciling local source is a deliberate,
  separate piece of work — flagged here rather than silently done as part of
  a documentation pass.

## D-007 (correction, 2026-07-29): `Time_Entry__c` is the real Time Tracking object — `LegalTimeEntry__c` is a separate, likely-abandoned duplicate

- Date: 2026-07-29
- Status: Decided
- Decision: The object Legal Time Tracking's Apex/LWC/related lists actually
  use is **`Time_Entry__c`** (27 fields, matches
  `Legal_TimeTracking/docs/time-tracking-build-scope.md` field-for-field:
  `Description__c`, `Entry_Method__c`, `Focus__c`, `Calculated_Hours__c`,
  `Staff_Role__c`, `Log_On_Behalf__c`, `Logged_By__c`, `On_Behalf_Of__c`,
  `Stopped_By_System__c`, `Paused_At__c`, `Total_Paused_Seconds__c`,
  `Record_Owner__c`, etc.). `LegalTimeEntry__c` — an object this doc
  originally (and wrongly) identified as the renamed/current version — is a
  separate, much sparser object (8 custom fields, missing all of the above)
  that nothing deployed actually references.
- Why this correction exists: an earlier pass of this doc searched
  `KHRCSandbox` for custom objects with `Name LIKE '%Legal%'`, found
  `LegalTimeEntry__c`, and wrongly assumed it was a rename of the
  `Time_Entry__c` object described in `Legal_TimeTracking`'s own docs — the
  search never checked for `Time_Entry__c` directly since it doesn't contain
  "Legal". This was caught during a 2026-07-29 production-deploy validation
  attempt: `TimeEntryController`/`TimeEntryTriggerHandler`/
  `TimerAutoStopScheduler` all reference `Time_Entry__c` and fail to compile
  against `LegalTimeEntry__c`; once `Time_Entry__c` was included instead,
  those classes compiled cleanly and `Legal_Case_Record_Page`'s "Case Time
  Entries" related list (`relatedListApiName = Case_Time_Entries__r`)
  resolved correctly against `Time_Entry__c.LegalCase__c`
  (`relationshipName = Case_Time_Entries`) — it was never broken; the
  original FlexiPage value was correct all along.
- Impact: `DEPLOYMENT_TRACKER.md`'s references to `LegalTimeEntry__c` are
  corrected to `Time_Entry__c`. `LegalTimeEntry__c`'s disposition (safe to
  delete vs. still needed) is an open item — see
  `../../../outstanding-tasks.md`. This is also a general caution: when
  searching org metadata by name pattern to identify "the" object behind a
  project's docs, confirm by field-set comparison, not name-pattern match
  alone.

## D-008 (finding, resolved same day 2026-07-29): Legal Time Tracking's first production-deploy attempt failed — root cause was a first-deploy transaction artifact, not a test defect

- Date: 2026-07-29
- Status: Resolved
- Original observation: On the first attempt to deploy the entire Advocacy
  App stack to `KHRCProd` in one shot, `TimeEntryControllerTest`,
  `TimeEntryTriggerHandlerTest`, and `TimerAutoStopSchedulerTest` all failed
  inserting `Time_Entry__c` records with `REQUIRED_FIELD_MISSING:
  Staff_Role__c`, dragging overall Apex coverage to ~69% (below production's
  75% minimum) and blocking the deploy. Time Tracking was excluded from that
  first production deploy as a result.
- Root cause, confirmed by direct investigation: **not a defect in the
  tests.** Running the exact same test classes directly against
  `KHRCSandbox` (`sf apex run test`) passed 26/26 with 92–100% coverage per
  class. The failure was specific to deploying the brand-new `Time_Entry__c`
  object, its required `Staff_Role__c` field, its trigger, and its tests all
  for the first time in a single atomic transaction against a completely
  fresh org — `Case_Team_Member__c` (also new in that same transaction)
  wasn't reliably queryable by `TimeEntryTriggerHandler.
  stampStaffRoleFromCaseTeam()` at test-execution time within that
  transaction. This is specific to a from-scratch, all-at-once deploy, not a
  code quality issue.
- Confirmation: once the core schema (`LegalCase__c`, `Case_Team_Member__c`,
  etc.) already existed in `KHRCProd` from the first deploy, a second,
  isolated deploy of just Time Tracking's remaining pieces validated and
  deployed cleanly on the first attempt — 36/36 components, 0 errors, 35/35
  tests passed (deploy id `0AfPB000001Idjt0AC`).
- Impact: Time Tracking (`Time_Entry__c`, `TimeEntryTrigger`,
  `TimeEntryController`/`TimeEntryTriggerHandler`/`TimerAutoStopScheduler` +
  tests, `timeEntryForm`/`timerPopup` LWCs, `Advocacy_AdminAccess`, the
  "Time Tracking" tab on `Legal_Case_Record_Page`) is now deployed to
  `KHRCProd` alongside everything else. No test rewrite was needed. General
  lesson for future first-time deploys of a large new object graph: consider
  deploying schema before (or separately from) the Apex/tests that depend on
  sibling new objects, to avoid this class of transaction-ordering issue.
