# Deployment Checklist — Legal Case Note Feed (Legal_NotesViewer)

CLI-driven deployment checklist using the Salesforce CLI (`sf`), for the
`Legal_NotesViewer` project deploying into **`KHRCSandbox`** — the same org that
already hosts `LegalCase__c`/`LegalCaseNote__c` and the `LegalCaseMgmt_GeneralAccess`
permission set from the sister `LegalCaseMgmtMVP` project. This project ships new
components only (an Apex controller + an LWC) — it does not touch existing objects,
triggers, or the permission set's source.

Run all commands from the project root (the folder containing `sfdx-project.json`).

---

## 0. One-time setup

Unlike `LegalCaseMgmtMVP`, this project has **no org alias configured yet** — start
here.

- [ ] Salesforce CLI installed and up to date
  ```
  sf --version
  sf update
  ```
- [ ] Node dependencies installed
  ```
  npm install
  ```
- [ ] Authenticate to the target org and set the alias
  ```
  sf org login web --alias KHRCSandbox
  sf org display --target-org KHRCSandbox
  ```
- [ ] Confirm the org is the one you think it is (check `Instance Url` / `Username`
      in the `org display` output) before doing anything else — this is the most
      common source of "deployed to the wrong org" mistakes. Double-check it's the
      same `KHRCSandbox` that already has `LegalCase__c` in it.

---

## 1. Pre-deployment checks (local)

- [ ] Lint passes
  ```
  npm run lint
  ```
- [ ] Formatting is clean
  ```
  npm run prettier:verify
  ```
- [ ] LWC unit tests pass
  ```
  npm run test:unit
  ```
- [ ] Review the diff of what you're about to ship — this project should only ever
      add `LegalCaseNoteFeedController(.cls|Test.cls)` and the `legalCaseNoteFeed`
      LWC bundle. If a diff touches anything under `objects/`, `permissionsets/`,
      or other metadata this project doesn't own, stop and re-check — see
      `DECISIONS.md` item 8 on why a same-named permission set file here would be
      dangerous.

---

## 2. Validate before deploying (dry run — no changes made)

- [ ] Run a validation-only deploy to catch errors and confirm Apex test coverage
  ```
  sf project deploy validate \
    --source-dir force-app \
    --target-org KHRCSandbox \
    --test-level RunLocalTests
  ```
- [ ] Read the output carefully: component failures, Apex test failures, and
      coverage below the org's required threshold (75% org-wide minimum, enforced
      in production; sandboxes may not enforce it).
- [ ] Fix and re-validate before proceeding if anything fails.

---

## 3. Deploy

- [ ] Deploy the validated changes
  ```
  sf project deploy start \
    --source-dir force-app \
    --target-org KHRCSandbox \
    --test-level RunLocalTests
  ```
- [ ] Or quick-deploy an already-validated run:
  ```
  sf project deploy quick --job-id <job-id-from-validate-output> --target-org KHRCSandbox
  ```
- [ ] If the deploy fails partway, don't blindly retry — read the error, fix the
      source, and re-validate (step 2) before deploying again.

---

## 4. Post-deploy manual steps (required — not automated by this deploy)

- [ ] Enable **"Allow Search"** on `LegalCaseNote__c` if it isn't already (Setup →
      Object Manager → Legal Case Note → Details → Allow Search → Save). Required
      for keyword search to work at all — without it, searching throws
      `entity type LegalCaseNote__c does not support search` (a hard error, not a
      silent failure). This is a one-time, per-org setting; already done in
      `KHRCSandbox` as of 2026-07-28, but a fresh org (e.g. production, later) will
      need it too. See `DECISIONS.md` item 10.
- [ ] Grant the new `LegalCaseNoteFeedController` Apex class access to
      `LegalCaseMgmt_GeneralAccess` so general legal-team users can actually call
      it. Either via Setup UI (Permission Sets → Legal Case Mgmt - General Access →
      Apex Class Access → enable `LegalCaseNoteFeedController`), or by updating that
      permission set's source in the `LegalCaseMgmtMVP` project and redeploying it
      from there.
- [ ] Add the `legalCaseNoteFeed` component to the `LegalCase__c` Lightning Record
      Page via App Builder (Setup → Object Manager → Legal Case → Lightning Record
      Pages, or edit page from a case record's gear menu), then activate the page.
      It appears in the component picker as **"Case Notes Feed"**.
- [ ] Confirm a test user with only `LegalCaseMgmt_GeneralAccess` assigned (no admin
      profile) can see the component and its data once the above steps are done.

---

## 5. Post-deploy verification

- [ ] Re-run Apex tests directly against the org
  ```
  sf apex run test --target-org KHRCSandbox --class-names LegalCaseNoteFeedControllerTest --result-format human --wait 10
  ```
- [ ] Manually spot-check in the org UI (after step 4 above) — the component
      displays as a card titled **"Case Notes Feed"**, which is also how to find it
      in the App Builder component picker:
  - [ ] Open a `LegalCase__c` record with several notes — the feed loads, most
        recent note first
  - [ ] On a case with more than 10 notes, scrolling down loads additional notes
  - [ ] Searching a keyword that only appears in a note's body (not its subject)
        still finds it — proves search is reaching note content, not just
        `Subject__c` — and the match is highlighted in the preview
  - [ ] Searching a keyword that matches nothing shows the "no notes match" empty
        state, not an error
  - [ ] A case with zero notes shows the "no notes on this case" empty state
  - [ ] Switching the sort control between "Newest first"/"Oldest first" reloads
        the feed in the new order (and resets scroll position to the top page)
  - [ ] A long note (roughly 300+ words) shows a truncated preview with a
        "Show more" toggle; clicking it expands to the full rich-text note and the
        toggle now reads "Show less"
  - [ ] Clicking a note's author name opens that user's User record
  - [ ] Clicking a note's "Edit" link opens the note's standard record edit page
  - [ ] Note: SOSL search indexing is near-real-time, not instant — if a note
        created moments earlier doesn't show up in a body-text search yet, wait a
        minute and retry before assuming something's broken

---

## 6. Rollback plan

This project only _adds_ new components — it doesn't modify or delete anything
`LegalCaseMgmtMVP` owns, so rollback is simple:

- [ ] Remove the two new components from the org (destructive changes, or delete via
      Setup): `LegalCaseNoteFeedController` (+ test class), and the
      `legalCaseNoteFeed` LWC.
- [ ] If it was added to a Lightning Record Page (step 4), remove it from the page
      in App Builder first — Salesforce won't let you delete an Apex class or LWC
      that's still referenced by an active page.
- [ ] No data or existing schema is affected by rolling this back.

---

## 7. Production-specific notes (if/when this graduates beyond sandbox)

- [ ] Always run `sf project deploy validate` before `deploy start` against
      production — never skip straight to a live deploy.
- [ ] Production enforces the 75% Apex code coverage minimum org-wide.
- [ ] Confirm who owns running production deploys and whether a maintenance
      window / stakeholder notice is expected first, consistent with how
      `LegalCaseMgmtMVP` handles this (see that project's own deployment doc).
