# Outstanding Tasks

Cross-project follow-up items for the Advocacy App (Legal Case Capture, Legal_NotesViewer,
Legal_DeadlineCapture, Legal Time Tracking). Add to this list as new gaps are found; check
items off with the date resolved rather than deleting them.

---

## Open

- [ ] **Reconcile `Legal Case Capture/LegalCaseMgmtMVP`'s local `force-app`
  source with the org.** Confirmed stale as of 2026-07-29 — see that
  project's `docs/decisions.md` D-006.

- [ ] **Confirm whether `LegalTimeEntry__c` (a second, mostly-empty custom
  object discovered in `KHRCSandbox` alongside the real `Time_Entry__c`) is
  an abandoned prototype safe to delete, or still needed for something.**
  Found during production-deploy prep on 2026-07-29 — it is *not* the object
  any working Apex/LWC/permission set actually uses; `Time_Entry__c` is.

---

## Resolved

- [x] (2026-07-29) Production deploy of Legal Case Capture core +
  Legal_NotesViewer + Legal_DeadlineCapture to `KHRCProd`
  (deploy id `0AfPB000001Idbp0AC`), with field-level permissions on all
  Legal/Advocacy object fields carried over for the System Administrator and
  Advocacy profiles. 71/71 components, 0 errors, 15/15 tests passed.

- [x] (2026-07-29) Legal Time Tracking's Apex test suite investigated and
  deployed to production (deploy id `0AfPB000001Idjt0AC`, 36/36 components,
  0 errors, 35/35 tests passed). **No test rewrite was actually needed** —
  running the existing suite directly against `KHRCSandbox`
  (`TimeEntryControllerTest`, `TimeEntryTriggerHandlerTest`,
  `TimerAutoStopSchedulerTest`, `CaseTeamMemberTriggerHandlerTest`) showed
  26/26 passing with 92–100% coverage per class — well above the 75%
  minimum and close to the 90% target. The original "Staff_Role__c required
  field missing" failures were an artifact of the 2026-07-29 first-time
  deploy trying to create the object, its trigger, and run its tests all in
  one atomic transaction against a completely fresh org — not a defect in
  the tests. Deploying Time Tracking on its own (after the core schema
  already existed in production from the earlier deploy) validated and
  deployed cleanly on the first attempt. `DEPLOYMENT_TRACKER.md`/
  `decisions.md` D-008 updated accordingly.
