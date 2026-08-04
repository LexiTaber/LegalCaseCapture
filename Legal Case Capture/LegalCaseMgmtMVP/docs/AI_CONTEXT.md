# AI Context & Instructions

This file is written for AI agents working on or around this project. Read
this before making changes so you don't re-derive or contradict facts already
established here. Full reasoning lives in `docs/decisions.md`; stakeholder-
facing scope and status live in `docs/PRD.md`; the verified, current
component inventory lives in `docs/DEPLOYMENT_TRACKER.md`. This file is the
condensed, operational version.

## What this project is

**Legal Case Capture** (internal SFDX project name `LegalCaseMgmtMVP`) is the
core data-model project for KHRC's Legal Case Management MVP, under the
"Advocacy App" initiative. It owns three custom objects — `LegalCase__c`,
`LegalCaseContacts__c`, `LegalCaseNote__c` — plus the trigger/handler that
keeps case notes searchable and the two permission sets that govern access.

It deploys into the **`KHRCSandbox`** org, which it shares with three sibling
SFDX projects (`Legal_NotesViewer`, `Legal_DeadlineCapture`, Legal Time
Tracking) that each add their own Apex/LWC on top of this data model and get
placed onto the same `LegalCase__c` record page. See `decisions.md` D-005 for
why UI ownership is split this way.

**As of 2026-07-29, everything — the core data model, Legal_NotesViewer,
Legal_DeadlineCapture, and Legal Time Tracking — is deployed to `KHRCProd`**
(RFK Human Rights' live production org), in two deploy passes. See
`DEPLOYMENT_TRACKER.md` for exact deploy IDs and `decisions.md` D-008 for
why Time Tracking's first deploy attempt failed and how it was resolved
(no code changes were needed — it was a first-deploy transaction artifact).

## Read this before touching anything: local source is stale

**As of 2026-07-29, this project's checked-in `force-app` source does not
match what's deployed in `KHRCSandbox`.** A direct metadata pull from the org
(full detail in `DEPLOYMENT_TRACKER.md`) found:

- The party object is deployed as `LegalCaseContacts__c`, not
  `LegalCaseParty__c` as local source still names it (D-002).
- `LegalCase__c.Name` and `LegalCaseNote__c.Name` are Text fields in the org,
  not the AutoNumber format local source declares (D-003).
- Six fields exist on `LegalCase__c` in the org with no local counterpart:
  `Case_Number__c`, `Circuit__c`, `Filing_Date__c`, `Total_Hours_Logged__c`,
  `US_Team_Assigned__c`, `Website_Overview__c`.
- A second permission set, `LegalCaseMgmt_Admin`, exists in the org only.
- `LegalCaseMgmt_GeneralAccess`'s org copy has diverged from local source
  (different Delete grants, different object references, app/tab visibility
  not present locally).
- An entire Lightning App/tabs/record-page/LWC layer (the `Advocacy` app,
  `Legal_Case_Record_Page`, `Case_Note_Record_Page`) exists only in the org.

**Do not deploy from this project's current local source.** Doing so risks
reverting the org to the stale schema (wrong object API name, wrong
Name-field format, a permission set missing grants the org copy has). If a
task requires changing this project's metadata, retrieve current source from
`KHRCSandbox` first and reconcile before editing. See `decisions.md` D-006.

## Ground rules for anyone (or anything) editing this repo

- Use `LegalCaseContacts__c`, never `LegalCaseParty__c`, in any new work —
  the object was renamed in the org (D-002). If you see `LegalCaseParty__c`
  referenced anywhere (including this project's own local `force-app`),
  treat it as stale, not as a second real object.
- Don't assume `LegalCase__c.Name` / `LegalCaseNote__c.Name` are
  auto-generated — they're free Text fields in the deployed org (D-003).
- `LegalCaseNote__c.NoteDetailSearch__c` is derived/read-only in practice —
  it's maintained by `LegalCaseNoteTrigger` → `LegalCaseNoteHandler.
  stripNoteHtml()`. Never write to it directly; if you add similar
  derived/search-mirror fields, follow the same thin-trigger/handler-class
  pattern.
- Don't build the Deadlines, Time Tracking, or Case Notes feed UI inside this
  project — that's a deliberate split across sibling repos (D-005). If asked
  for changes to those features, the work belongs in `Legal_DeadlineCapture`,
  Legal Time Tracking, or `Legal_NotesViewer` respectively, not here.
- If you change anything with downstream impact (schema, sharing, a new
  deployable component), add an entry to `docs/decisions.md` in the existing
  format and update `docs/DEPLOYMENT_TRACKER.md`.
- Before describing "what's built" to a stakeholder or in a new doc, check
  `DEPLOYMENT_TRACKER.md` rather than this project's local `force-app` —
  they currently disagree (see above).

## Known open issues (don't silently "fix" without confirming — see decisions.md)

- Local `force-app` needs a deliberate retrieve-and-reconcile pass against
  `KHRCSandbox` (D-006) — not yet done as of this writing. The 2026-07-29
  production deploy was done from freshly retrieved sandbox metadata, not
  from this project's local source.
- `Time_Entry__c` is the real Time Tracking object; `LegalTimeEntry__c` is a
  separate, sparser object nothing deployed actually uses and is likely
  safe to delete (D-007 correction) — unconfirmed, tracked in
  `../../../outstanding-tasks.md`.
- `Case_Note_Record_Page1` is an inactive, likely-orphaned duplicate of
  `Case_Note_Record_Page` in `KHRCSandbox` — confirm before deleting.
- The Advocacy app's custom logo didn't make it to production (a
  ContentAsset validation failure unrelated to this app) — deployed with
  brand color only, no logo.

## Open items that affect this file

- Whether/when local `force-app` gets reconciled with the org — update this
  file and D-006's status once that happens.
