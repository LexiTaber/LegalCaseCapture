# Scope: "Filing Date" as a Legal Case Deadline Type

## Goal

Let users record a case's filing date by creating a **Legal Case Deadline**
(`LegalCaseDeadline__c`) with Type = **Filing Date**, instead of (or in
addition to) editing the `Filing_Date__c` field on the Legal Case directly.
When that deadline's due date changes, the Legal Case's own `Filing_Date__c`
field should stay in sync automatically. Only one Filing Date deadline should
ever exist per case.

Three pieces:
1. Add "Filing Date" as a `Type__c` picklist value.
2. Sync `LegalCase__c.Filing_Date__c` from the Filing Date deadline's due date.
3. Prevent more than one Filing Date deadline per case.

---

## Important schema fact that shapes pieces 2 and 3

`LegalCaseDeadline__c.Legal_Case__c` is a plain **Lookup** to `LegalCase__c`,
not a Master-Detail relationship (confirmed via `FieldDefinition`: `DataType
= Lookup(Legal Case)`). Two consequences:

- **No Roll-Up Summary field is possible** on `LegalCase__c` to count related
  deadlines — Roll-Up Summary only works across Master-Detail.
- **A plain Validation Rule can't enforce "only one Filing Date per case"** —
  validation rules only see the record being saved (plus one hop up a
  lookup/parent), never sibling/child records. There's no formula that can
  ask "do any other `LegalCaseDeadline__c` records for this case already
  have Type = Filing Date?"

So piece 3 has to be code or a Flow that queries sibling records, not a
validation rule, despite the original ask. Details below.

---

## Piece 1: Add the picklist value

Setup → Object Manager → **Legal Case Deadline** → Fields & Relationships →
`Type__c` → New. Add value: `Filing Date`. Add it to any relevant record
types/page layouts the same way the existing four values (`Discovery
Deadline`, `Hearing`, `Motion Filing`, `Response Due`) are configured.

No dependency on pieces 2 or 3 — this can be done first and independently.

---

## Piece 2: Sync Filing Date onto the Legal Case

**Trigger condition:** a `LegalCaseDeadline__c` is inserted or updated with
`Type__c = 'Filing Date'` (also handle the case where a record's Type or
Legal_Case__c *changes* to/away from Filing Date on update).

**Action:** update the related `LegalCase__c.Filing_Date__c` to match the
deadline's `DueDate__c`.

**Watch for:** `DueDate__c` is a **DateTime**; `Filing_Date__c` on the case
is a plain **Date**. Converting drops the time-of-day — decide once whether
that should be the org's default timezone date or GMT date, and use it
consistently (Apex: `myDateTime.date()` uses GMT; be explicit if that's not
what's wanted).

### Flow

This particular sync (updating a *different, parent* record from a child
trigger) is a standard, well-supported Flow pattern — unlike the Name-field
self-update that failed earlier, this doesn't involve mutating `$Record`.
Record-triggered flow on `LegalCaseDeadline__c`, after save, create/update,
entry condition `Type__c = 'Filing Date'`: Get Records (the case via
`Legal_Case__c`) → Update Records (that case's `Filing_Date__c` = `DATEVALUE
({!$Record.DueDate__c})`). Worth trying if you'd rather keep this one
declarative — just be ready to fall back to Apex if it hits the same
unexplained activation issue.

---

## Piece 3: Enforce one Filing Date deadline per case

As noted above, this can't be a Validation Rule. Recommended as an Apex
trigger since it's a straightforward "query siblings, block if a conflict
exists" check — exactly what triggers are good at and Flow is clunky at.

**Logic:** before insert / before update, for any record being saved with
`Type__c = 'Filing Date'`, count *other* `LegalCaseDeadline__c` records for
the same case that already have `Type__c = 'Filing Date'`. If that count is
≥ 1, add an error to the record being saved (block it). Must correctly
exclude the record's own prior state on update (a record that was already
the one-and-only Filing Date deadline shouldn't block itself when you edit
its due date).

### Recommended: Apex trigger (before insert, before update)

```apex
trigger LegalCaseDeadlineTrigger on LegalCaseDeadline__c (before insert, before update) {
    Set<Id> caseIdsToCheck = new Set<Id>();
    for (LegalCaseDeadline__c d : Trigger.new) {
        if (d.Type__c == 'Filing Date' && d.Legal_Case__c != null) {
            caseIdsToCheck.add(d.Legal_Case__c);
        }
    }
    if (caseIdsToCheck.isEmpty()) return;

    Map<Id, Integer> filingDateCountByCase = new Map<Id, Integer>();
    for (AggregateResult ar : [
        SELECT Legal_Case__c caseId, COUNT(Id) cnt
        FROM LegalCaseDeadline__c
        WHERE Legal_Case__c IN :caseIdsToCheck AND Type__c = 'Filing Date'
        GROUP BY Legal_Case__c
    ]) {
        filingDateCountByCase.put((Id) ar.get('caseId'), (Integer) ar.get('cnt'));
    }

    for (LegalCaseDeadline__c d : Trigger.new) {
        if (d.Type__c != 'Filing Date' || d.Legal_Case__c == null) continue;

        Integer existingCount = filingDateCountByCase.containsKey(d.Legal_Case__c)
            ? filingDateCountByCase.get(d.Legal_Case__c) : 0;

        // If this exact record was already a Filing Date deadline before
        // this save, it's included in existingCount - don't let it block itself.
        Boolean wasAlreadyFilingDate = Trigger.isUpdate &&
            Trigger.oldMap.get(d.Id).Type__c == 'Filing Date' &&
            Trigger.oldMap.get(d.Id).Legal_Case__c == d.Legal_Case__c;
        Integer otherFilingDateDeadlines = wasAlreadyFilingDate
            ? existingCount - 1 : existingCount;

        if (otherFilingDateDeadlines >= 1) {
            d.addError('This case already has a Filing Date deadline. Only one is allowed per case.');
        }
    }
}
```

If pieces 2 and 3 are both built as Apex, they can live in the same
`LegalCaseDeadlineTrigger` (before-context block for piece 3, after-context
block for piece 2) with a shared handler class, or stay as two separate
trigger contexts — either is fine at this object's size.

### Alternative: Flow

Possible but more awkward: record-triggered flow (before-save), Get Records
(count sibling deadlines on the same case with Type = Filing Date, excluding
this record's own Id on update), Decision (count > 0 → fault path with a
custom error via a Fault Connector on the flow, or an "Error" element).
Given piece 2 above already has to query siblings, and the trigger point
(before-save) needs to see other committed records, this is genuinely more
natural in Apex.

---

## Suggested build order

1. Add the picklist value (piece 1) — no dependencies.
2. Build the uniqueness check (piece 3) first, so bad data can't pile up
   while piece 2 is still being tested.
3. Build the sync logic (piece 2).
4. Test: create a Filing Date deadline on a case with no existing one
   (should succeed, case's Filing_Date__c updates); try creating a second
   one on the same case (should be blocked); edit the due date on an
   existing Filing Date deadline (should succeed, case updates again).