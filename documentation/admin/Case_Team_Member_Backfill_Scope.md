# Scope: Backfill Case Team Members from Lead Attorney / Support Staff

## Goal

One-time data backfill: for every `LegalCase__c` with `LeadAttorney__c` and/or
`SupportStaff__c` populated, create a corresponding `Case_Team_Member__c`
record (`Staff_Role__c` = **Lead Attorney** / **Supporting Attorney**
respectively), so the staffing data already captured on those two lookup
fields carries forward onto the Case Team roster before the fields are
removed from the Legal Case Record Page.

This is **not** ongoing automation. After this runs, Case Team assignment
stays fully admin-managed directly on `Case_Team_Member__c` — same as the
existing documented assumption in the Time Tracking build scope — and
`LeadAttorney__c` / `SupportStaff__c` disappear from the UI.

---

## Prerequisite: sync the value-set change to source

`Staffing_Roles.globalValueSet-meta.xml` in this repo
(`Legal_TimeTracking/force-app/main/default/globalValueSets/`) currently only
lists Attorney, Paralegal, Legal Assistant/Secretary, Law Clerk, and Of
Counsel — it does not yet show **Lead Attorney** / **Supporting Attorney**.
Since those two values were added directly in the org, retrieve current
metadata for that value set before deploying anything else in
`Legal_TimeTracking`, or a future deploy from this stale source could
silently drop them.

---

## Important existing-schema facts that shape this

- **Both source fields are single-value Lookups to User** —
  `LeadAttorney__c` and `SupportStaff__c` on `LegalCase__c`. This backfill can
  therefore carry over at most one Lead Attorney and one Support Staff per
  case. Any case that in reality has more than one support person only gets
  the one name captured in `SupportStaff__c`; anyone else has to be added by
  hand afterward.

- **`Case_Team_Member__c` already enforces one record per Case+User.** The
  existing `CaseTeamMemberTriggerHandler.preventDuplicateMemberships` blocks
  a second `Case_Team_Member__c` for the same `LegalCase__c` + `User__c`
  pair, erroring with "This user already has a role on this case...". Two
  consequences for the backfill:
  - If a case's `LeadAttorney__c` and `SupportStaff__c` point to the **same**
    user, only one `Case_Team_Member__c` can exist for that pair — Lead
    Attorney wins; the Support Staff side is skipped for that person on that
    case (see Assumptions below).
  - If a case+user pair **already has** a `Case_Team_Member__c` record (e.g.
    someone was already added by hand, possibly under a different role), the
    insert is blocked by the existing trigger. Treat that as already covered
    and skip it — don't try to overwrite the existing role.

- **No classic Page Layouts exist for `LegalCase__c`.** Staffing fields live
  on the Lightning Record Page
  (`Legal_TimeTracking/force-app/main/default/flexipages/Legal_Case_Record_Page.flexipage-meta.xml`,
  "Staffing" field section), which already has a "Case Team" related list
  (`Case_Team_Members__r`, columns Name / User / Staff Role) directly below
  it. Removing `LeadAttorney__c` / `SupportStaff__c` after backfill just
  means deleting those two `fieldInstance` entries from that flexipage's
  Staffing facet — no separate classic layout to touch.

---

## The backfill script

Recommended as an anonymous Apex script, matching this project's existing
`scripts/apex/*.apex` convention (e.g.
`Legal_TimeTracking/scripts/apex/schedule-timer-auto-stop.apex`) rather than
a Data Loader CSV — the skip-on-duplicate / skip-on-null logic below is
simpler to express in Apex than a CSV transform.

**Logic:**

1. Query `LegalCase__c` WHERE `LeadAttorney__c != null OR SupportStaff__c != null`.
2. For each case, build a candidate `Case_Team_Member__c` per populated
   field: `LegalCase__c` = the case Id, `User__c` = the attorney/support
   user, `Staff_Role__c` = `'Lead Attorney'` or `'Supporting Attorney'`.
3. Within the batch, drop the Support Staff candidate for any case+user pair
   that collides with a Lead Attorney candidate on the same case (same
   person listed in both fields) — Lead Attorney takes priority.
4. Insert with partial success (`Database.insert(records, false)`), so a
   case+user pair already covered by an existing `Case_Team_Member__c`
   record is skipped via its own per-record error rather than failing the
   whole run.
5. Report counts: records created, records skipped as already-covered
   (existing `Case_Team_Member__c`), records skipped as same-person-both-
   roles.

```apex
// Legal_TimeTracking/scripts/apex/backfill-case-team-members.apex
List<Case_Team_Member__c> toInsert = new List<Case_Team_Member__c>();
Set<String> keysInBatch = new Set<String>();
Integer skippedSamePerson = 0;

for (LegalCase__c c : [
    SELECT Id, LeadAttorney__c, SupportStaff__c
    FROM LegalCase__c
    WHERE LeadAttorney__c != null OR SupportStaff__c != null
]) {
    if (c.LeadAttorney__c != null) {
        toInsert.add(new Case_Team_Member__c(
            LegalCase__c = c.Id,
            User__c = c.LeadAttorney__c,
            Staff_Role__c = 'Lead Attorney'
        ));
        keysInBatch.add(c.Id + ':' + c.LeadAttorney__c);
    }
    if (c.SupportStaff__c != null) {
        String key = c.Id + ':' + c.SupportStaff__c;
        if (keysInBatch.contains(key)) {
            skippedSamePerson++;
        } else {
            toInsert.add(new Case_Team_Member__c(
                LegalCase__c = c.Id,
                User__c = c.SupportStaff__c,
                Staff_Role__c = 'Supporting Attorney'
            ));
            keysInBatch.add(key);
        }
    }
}

Database.SaveResult[] results = Database.insert(toInsert, false);
Integer created = 0, alreadyCovered = 0;
for (Database.SaveResult r : results) {
    if (r.isSuccess()) {
        created++;
    } else {
        alreadyCovered++;
    }
}

System.debug('Created: ' + created);
System.debug('Skipped (already covered / duplicate): ' + alreadyCovered);
System.debug('Skipped (same person, both roles): ' + skippedSamePerson);
```

---

## Suggested build order

1. Retrieve the `Staffing_Roles` global value set metadata from the org to
   confirm/sync the two new values locally.
2. Run the script against `KHRCSandbox` first; read the debug counts before
   touching production.
3. Spot-check a handful of cases' Case Team related list against what
   `LeadAttorney__c` / `SupportStaff__c` used to show, including at least one
   case where the skip logic should have fired (same person in both fields,
   or a pre-existing manual `Case_Team_Member__c`).
4. Remove `LeadAttorney__c` / `SupportStaff__c` from the "Staffing" section
   of `Legal_Case_Record_Page.flexipage-meta.xml`.
5. Run the backfill against `KHRCProd`, then deploy the flexipage change.

---

## Out of scope

- No new trigger/Flow — this is one-time, not an ongoing sync.
- No change to the `LeadAttorney__c` / `SupportStaff__c` field definitions
  themselves — layout removal only, not field deletion (delete later once
  nothing else, e.g. a report, depends on them).
- Multiple support staff per case isn't modeled — the source data (a single
  `SupportStaff__c` lookup) doesn't support it.

---

## Assumptions to confirm

- **Lead Attorney wins** when the same person is listed as both
  `LeadAttorney__c` and `SupportStaff__c` on one case. Reasonable default,
  but worth a gut check since it silently drops the Support Staff assignment
  for that person on that case rather than erroring loudly.
- Backfill targets **all** `LegalCase__c` records regardless of `Status__c`
  (Open or Closed) — flag if closed cases should be excluded.
