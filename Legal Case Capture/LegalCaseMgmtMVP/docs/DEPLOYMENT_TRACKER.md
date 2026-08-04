# Deployment Tracker

Tracks every component related to the Legal Case Capture MVP, its API name,
and deployment status. Update this alongside any metadata change — it's the
map from "what we decided" (`decisions.md`) to "what actually exists in the
org(s)."

**Source of truth note:** the tables below reflect a live metadata pull
directly from **`KHRCSandbox`** (org ID `00DAK000000XGVp2AO`) on 2026-07-29,
not this project's checked-in `force-app` source, which has drifted — see
`decisions.md` D-006. On 2026-07-29, this was deployed to **`KHRCProd`**
(org ID `00DA0000000CWX2MAO`) in two passes:

1. Core + Legal_NotesViewer + Legal_DeadlineCapture (deploy id
   `0AfPB000001Idbp0AC`) — 71/71 components, 0 errors, 15/15 tests passed.
2. Legal Time Tracking (deploy id `0AfPB000001Idjt0AC`, after resolving
   D-008) — 36/36 components, 0 errors, 35/35 tests passed.

Everything in this tracker is now deployed to production.

Status values: `Planned` → `Built (local)` → `Deployed (Sandbox)` →
`Deployed (Production)`.

---

## Objects (core MVP data model)

| Component | API Name | Status | Notes |
|---|---|---|---|
| Legal Case | `LegalCase__c` | Deployed (Production) | Parent object. Sharing: Private. Name field: **Text** ("Case Name") — not AutoNumber (D-003). Search enabled. |
| Legal Case Contacts | `LegalCaseContacts__c` | Deployed (Production) | Formerly `LegalCaseParty__c` locally (D-002). Label "Legal Contacts". Master-Detail to `LegalCase__c`, `ControlledByParent` sharing. Name field: AutoNumber `PARTY-{0000}`. |
| Legal Case Note | `LegalCaseNote__c` | Deployed (Production) | Master-Detail to `LegalCase__c`, `ControlledByParent` sharing. Name field: **Text** ("Note Name") — not AutoNumber (D-003). Search enabled (D-004). **Note:** "Allow Search" is a manual per-org checkbox (D-004) — confirm it's on in `KHRCProd`, since a metadata deploy doesn't set it. |

## Fields — `LegalCase__c`

| Field | API Name | Type | Status | Notes |
|---|---|---|---|---|
| Case Name | `Name` | Text | Deployed (Production) | See D-003 — was AutoNumber in local source |
| Status | `Status__c` | Picklist | Deployed (Production) | `Open` (default), `Closed`, `Open - Fees`, `Open - Appeal` — two more values than local source's `Open`/`Closed` |
| District Filed | `DistrictFiled__c` | Picklist (restricted) | Deployed (Production) | 16 US district values; local source has this as free Text(255) instead |
| Circuit | `Circuit__c` | Picklist (restricted) | Deployed (Production) | Not in local source. 12 circuits (1st–11th + DC) |
| Case Number | `Case_Number__c` | Text(50) | Deployed (Production) | Not in local source |
| Filing Date | `Filing_Date__c` | Date | Deployed (Production) | Not in local source |
| Box Folder Link | `BoxFolderLink__c` | Url | Deployed (Production) | Matches local source |
| Website Overview | `Website_Overview__c` | Url | Deployed (Production) | Not in local source. Links to the KHRC website page for the case |
| Total Hours Logged | `Total_Hours_Logged__c` | Number(18,2) | Deployed (Production) | Not in local source. Owned in spirit by Legal Time Tracking (likely rollup target), not by this project |
| US Team Assigned | `US_Team_Assigned__c` | Picklist (restricted) | Deployed (Production) | Not in local source. Values: `Immigration`, `Criminal` |
| Lead Attorney | `LeadAttorney__c` | Lookup(User) | Deployed (Production) | Matches local source. Relationship: `LeadAttorneyLegalCases` |
| Support Staff | `SupportStaff__c` | Lookup(User) | Deployed (Production) | Matches local source. Relationship: `SupportStaffLegalCases` |

## Fields — `LegalCaseContacts__c`

| Field | API Name | Type | Status | Notes |
|---|---|---|---|---|
| Legal Case Party Name | `Name` | AutoNumber (`PARTY-{0000}`) | Deployed (Production) | |
| Legal Case | `LegalCase__c` | Master-Detail → `LegalCase__c` | Deployed (Production) | Relationship: `LegalCaseParties` (name unchanged despite the object rename) |
| Contact | `Contact__c` | Lookup(Contact) | Deployed (Production) | Relationship: `LegalCaseParties` |
| Role | `Role__c` | Picklist (restricted) | Deployed (Production) | `Client`, `Proxy Contact`, `Partner Org Contact`, `Opposing Counsel` — unchanged from local source |

## Fields — `LegalCaseNote__c`

| Field | API Name | Type | Status | Notes |
|---|---|---|---|---|
| Note Name | `Name` | Text | Deployed (Production) | See D-003 — was AutoNumber in local source |
| Legal Case | `LegalCase__c` | Master-Detail → `LegalCase__c` | Deployed (Production) | Relationship: `LegalCaseNotes` |
| Author | `Author__c` | Lookup(User) | Deployed (Production) | Relationship: `AuthoredCaseNotes` |
| Date | `NoteDate__c` | Date | Deployed (Production) | |
| Subject | `Subject__c` | Text(255) | Deployed (Production) | |
| Note Detail | `NoteDetail__c` | Html (32,768 chars, 10 lines) | Deployed (Production) | Matches local source |
| Note Detail Search | `NoteDetailSearch__c` | LongTextArea (32,768 chars, 3 lines) | Deployed (Production) | Auto-populated by trigger; matches local source |

## Apex (core MVP)

| Component | Status | Notes |
|---|---|---|
| `LegalCaseNoteTrigger` (before insert/update on `LegalCaseNote__c`) | Deployed (Production) | Source matches local `force-app` exactly (verified byte-for-byte on the handler) |
| `LegalCaseNoteHandler.stripNoteHtml()` | Deployed (Production) | Source matches local `force-app` exactly |
| `LegalCaseNoteHandlerTest` | Deployed (Production) | 3 tests: insert strips HTML, update re-strips, null detail → null search field |

## Permission Sets (core MVP)

| Component | API Name | Status | Notes |
|---|---|---|---|
| Legal Case Mgmt - General Access | `LegalCaseMgmt_GeneralAccess` | Deployed (Production) | **Diverged from local source.** Org copy: grants Delete on `LegalCaseNote__c` and `Contact` (local source grants no Delete on any object); references `LegalCaseContacts__c` not `LegalCaseParty__c`; includes 6 `Contact` field grants and 2 `Contact` record-type visibilities not in local source; assigns visibility to the `Advocacy` app and 4 tabs. `viewAllRecords=true` on all three core objects either way. |
| Legal Case Mgmt - Admin | `LegalCaseMgmt_Admin` | Deployed (Production) | **Not in local source at all.** Full CRUD + `modifyAllRecords`/`viewAllFields` on `LegalCaseContacts__c` and `LegalCaseNote__c`; on `LegalCase__c`: CRUD except Delete, no `modifyAllRecords`. |

## Profiles (field-level security)

| Component | Status | Notes |
|---|---|---|
| System Administrator (`Admin`) | Deployed (Production) | As of 2026-07-29, every field on `LegalCase__c`, `LegalCaseContacts__c`, `LegalCaseNote__c`, `LegalCaseDeadline__c`, and `Case_Team_Member__c` is explicitly readable+editable for this profile — closing gaps that existed even in `KHRCSandbox` (several fields, e.g. `LegalCase__c.Status__c`/`LeadAttorney__c`/`SupportStaff__c`, were `readable=false` there despite this being the admin profile — Salesforce does not exempt System Administrator from field-level security). `Time_Entry__c` field grants were **not** carried to production — see Time Tracking exclusion below. |
| Advocacy | Deployed (Production) | Same FLS treatment as above, now including `Time_Entry__c` fields (deployed in the second pass). |

## Lightning App

| Component | API Name | Status | Notes |
|---|---|---|---|
| Advocacy (Lightning App) | `Advocacy` | Deployed (Production) | **Not in local source at all** (local docs describe navigation as "not yet built"). Tabs: Home, `LegalCase__c`, `LegalCaseNote__c`, `LegalCaseContacts__c`, standard Account, standard Contact, Reports, Dashboards. Utility bar: `Advocacy_UtilityBar`. Brand color `#5D229E`. **Custom logo dropped for this deploy** — the sandbox's logo `ContentAsset` ("images") failed validation against production (`Access to entity 'bt_stripe__Stripe_Settings__c' denied`, an unrelated managed-package permission issue) and was excluded rather than chased down before the demo; app deploys with the brand color only, no logo. Re-add later if wanted. |

## Lightning Pages (Record Pages)

| Component | API Name | Object | Status | Notes |
|---|---|---|---|---|
| Legal Case Record Page | `Legal_Case_Record_Page` | `LegalCase__c` | Deployed (Production), active (org default View override) | **Not in local source at all.** Deployed as a 3-tab layout in the first production pass (Detail, Case Notes, Deadlines), then updated in the second pass to the full **4-tab** layout (+ Time Tracking) once that piece was ready — see "Legal Case Record Page composition" below. |
| Case Note Record Page | `Case_Note_Record_Page` | `LegalCaseNote__c` | Deployed (Production), **active** (org default View override) | Includes an admin-only field section (visible only when `$User.Profile.Name` contains "System Admin") showing `NoteDetail__c`/`NoteDetailSearch__c` again. |
| Case Note Record Page (duplicate) | `Case_Note_Record_Page1` | `LegalCaseNote__c` | Deployed (Sandbox only) | Simpler/earlier version of the page above; not the org's active View override; **not included** in the production deploy (redundant with the active page). Likely an orphaned draft — confirm before deleting from sandbox. |

### Legal Case Record Page composition

`Legal_Case_Record_Page` is a record page with tabs assembled from multiple
projects. Only the **Detail** tab's Case Contacts related list and the
**Case Notes** tab belong to this project's own scope; the rest render
components owned by companion repos, included here for a complete picture:

| Tab | Contents | Owning component's source |
|---|---|---|
| Detail | Standard fields + **Case Team Members** related list (`Case_Team_Members__r`) + **Case Contacts** related list (`LegalCaseParties__r`, i.e. `LegalCaseContacts__c`) | Case Team Members: Legal Time Tracking. Case Contacts: this project. |
| Case Notes | `legalCaseNoteFeed` LWC | Legal_NotesViewer |
| Deadlines | **Case Deadlines** related list (`Case_Deadlines__r`) | Legal_DeadlineCapture (deployed as `LegalCaseDeadline__c`, not `Deadline__c` as that project's own docs still say — see "External / companion objects" below) |
| Time Tracking | `timeEntryForm` LWC + **Case Time Entries** related list (`Case_Time_Entries__r`, resolves correctly against `Time_Entry__c.LegalCase__c` — see D-007 correction) | Legal Time Tracking |
| Sidebar (all tabs) | **Case Notes** related list, 3 records shown (`LegalCaseNotes__r`) | this project |

All five deployed to production as of the second deploy pass (D-008).

## LWCs placed on Legal Case pages

| Component | Status | Owning repo | Notes |
|---|---|---|---|
| `legalCaseNoteFeed` | Deployed (Production) | Legal_NotesViewer | Scrollable/searchable case notes feed. Targets `lightning__RecordPage` on `LegalCase__c`. Full spec in `Legal_NotesViewer/docs/NOTES_FEED_PLAN.md`. |
| `timeEntryForm` | Deployed (Production) | Legal Time Tracking | Targets `lightning__RecordPage` + `lightning__AppPage` on `LegalCase__c`. |
| `timerPopup` | Deployed (Production) | Legal Time Tracking | Not exposed to App Builder (`isExposed=false`) — opened via `window.open` from `timeEntryForm`, hosted in the standalone `timerPopupApp` Aura app. |

## External / companion components (owned elsewhere, referenced here for context)

Not this project's scope to build or maintain — listed so the full picture of
what's deployed against the Legal Case data model is in one place.

| Component | API Name | Status | Owning project |
|---|---|---|---|
| Legal Case Deadline (object) | `LegalCaseDeadline__c` | Deployed (Production) | Legal_DeadlineCapture — whose own docs still call this `Deadline__c` and mark it "Planned"; the org has moved past that project's docs |
| `LegalCaseNoteFeedController` (+ Test) | Apex | Deployed (Production) | Legal_NotesViewer |
| Case Team Member (object) | `Case_Team_Member__c` | Deployed (Production) | Legal Time Tracking. Its own tests (`CaseTeamMemberTriggerHandlerTest`) pass cleanly against production — unlike `Time_Entry__c`'s, this object's tests are self-contained. |
| `CaseTeamMemberTrigger` / `CaseTeamMemberTriggerHandler` (+ Test) | Apex | Deployed (Production) | Legal Time Tracking |
| Time Entry (object) | `Time_Entry__c` | Deployed (Production) | Legal Time Tracking. **This is the correct/real object** — see D-007 correction. |
| `TimeEntryTrigger` | Apex Trigger | Deployed (Production) | Legal Time Tracking |
| `TimeEntryController` / `TimeEntryTriggerHandler` / `TimerAutoStopScheduler` (+ Tests) | Apex | Deployed (Production) | Legal Time Tracking. See D-008 for why the first deploy attempt failed and how it was resolved (no code changes needed). |
| `LegalTimeEntry__c` | Object | Deployed (Sandbox only) | Legal Time Tracking — **appears to be an abandoned prototype, not the real object** (see D-007 correction). 8 custom fields vs. `Time_Entry__c`'s 27; no working Apex/LWC/related list references it. Deliberately not deployed to production. Disposition (delete vs. keep, in sandbox) tracked in `../../../outstanding-tasks.md`. |
| Advocacy_BaseAccess | Permission Set | Deployed (Production) | Legal Time Tracking |
| Advocacy_AdminAccess | Permission Set | Deployed (Production) | Legal Time Tracking. Grants "log time on behalf of another Case Team Member." |

## Reports / Dashboards

None found scoped to the core Legal Case objects during this pull (`enableReports=false` on `LegalCase__c` and `LegalCaseContacts__c`; `enableReports=true` on `LegalCaseNote__c` but no report definitions were retrieved). Not built as part of this MVP.

## Known open items

- Local `force-app` source needs to be retrieved from `KHRCSandbox` and
  reconciled before any deploy is attempted from this project (decisions.md
  D-006). The production deploy on 2026-07-29 was done from freshly
  retrieved sandbox metadata, **not** from this project's local source —
  local source is still stale.
- Confirm whether `LegalTimeEntry__c` is safe to delete from `KHRCSandbox`
  (decisions.md D-007 correction) — tracked in `../../../outstanding-tasks.md`.
- Confirm whether `Case_Note_Record_Page1` is safe to delete from
  `KHRCSandbox` (not deployed to production).
- The Advocacy app's custom logo was dropped from the production deploy
  (ContentAsset validation failure unrelated to this app — see Lightning App
  table above). Re-add once the underlying access issue is resolved, if
  wanted.
- Confirm "Allow Search" is enabled on `LegalCaseNote__c` in `KHRCProd`
  (D-004) — it's a manual per-org setting a metadata deploy doesn't turn on.
- Post-deploy: assign `LegalCaseMgmt_GeneralAccess` / `LegalCaseMgmt_Admin` /
  `Advocacy_BaseAccess` to the appropriate production users, and confirm the
  `Advocacy` app is visible/pinned for them.
