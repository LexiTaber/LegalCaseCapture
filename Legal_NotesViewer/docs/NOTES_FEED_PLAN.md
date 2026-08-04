# Legal Case Note Feed — Implementation Plan

_Feature: scrollable, keyword-searchable case notes viewer, Chatter-like, for
lead attorneys. Last updated: 2026-07-29 (evening)._

## Context

User story: _as a lead attorney, I want to view all case notes for a legal case in
Salesforce, and scroll through / keyword-search them, similar to Chatter._

This repo (`Legal_NotesViewer`) is a separate SFDX project from `LegalCaseMgmtMVP`,
which already owns and has deployed the data model this feature depends on, into the
**`KHRCSandbox`** org:

- `LegalCase__c` — the parent case record
- `LegalCaseNote__c` — child notes (Master-Detail to `LegalCase__c`), fields:
  `Subject__c`, `NoteDate__c`, `Author__c` (Lookup User), `NoteDetail__c` (rich text),
  `NoteDetailSearch__c` (plain-text mirror of `NoteDetail__c`, HTML-stripped,
  trigger-maintained — built specifically to make note content searchable)

This project adds new components (Apex + LWC) that deploy into the same org, without
redeclaring the existing objects or permission set locally. See `DECISIONS.md` for
why, and `DEPLOYMENT.md` for how this ships.

Scope is **read-only** viewing/search, per the story — no note creation UI. An Edit
link was later added that opens Salesforce's own standard edit page for a note (not
a custom edit form built by this feature).

## Approach

**Apex controller** (`with sharing`) exposes one cacheable method the LWC calls
**imperatively** (not `@wire`), so the component can both _replace_ results (new
search or sort change) and _append_ results (infinite scroll) — `@wire` only
supports replace.

**LWC** (`legalCaseNoteFeed`) is exposed to `Lightning_RecordPage` for `LegalCase__c`,
driven by `recordId`. A debounced search box filters on `Subject__c` and
`NoteDetailSearch__c`; a sort control switches between newest-first and oldest-first
(server-side, since pagination happens at the query/search-index layer). Each note
renders as a card: subject, date, a clickable author name (links to the User
record), an Edit link (opens the note's standard edit page), and a ~300-word preview
of the note body with search-term matches highlighted, expandable to the full rich
text via a Show more/Show less toggle. The feed loads more on scroll-near-bottom,
Chatter-style. See `DECISIONS.md` items 11-14 for the highlighting, truncation,
sorting, and navigation-link design choices specifically.

The component is wrapped in `<lightning-card title="Case Notes Feed">` so it has a
visible, identifiable title both on the record page and in App Builder's component
picker (decision 16).

This deploy ships the component only, not a flexipage/record page — placement onto
the `LegalCase__c` record page is a manual App Builder step (see `DEPLOYMENT.md`).

## Files

### `force-app/main/default/classes/LegalCaseNoteFeedController.cls`

```
public with sharing class LegalCaseNoteFeedController {
    @AuraEnabled(cacheable=true)
    public static NoteFeedPage getNotes(Id legalCaseId, String searchTerm, Integer pageSize, Integer pageOffset, String sortDirection)

    public class NoteFeedPage {
        @AuraEnabled public List<LegalCaseNote__c> notes;
        @AuraEnabled public Boolean hasMore;
    }
}
```

- Query fields: `Id, Subject__c, NoteDate__c, NoteDetail__c, CreatedDate,
Author__r.Id, Author__r.Name` — deliberately **not** `NoteDetailSearch__c` or the
  raw `Author__c` lookup field, since neither is FLS-visible to the running user and
  `WITH SECURITY_ENFORCED` hard-fails on that; `Author__r.Id`/`Author__r.Name`
  (relationship traversal) don't hit the same restriction. The LWC instead builds
  its highlighted preview by stripping HTML from `NoteDetail__c` client-side. See
  `DECISIONS.md` item 15.
- No `searchTerm`: plain SOQL, `WITH SECURITY_ENFORCED`, `WHERE LegalCase__c = :legalCaseId`,
  ordered by `NoteDate__c`/`CreatedDate` in the requested direction, `LIMIT :pageSize
OFFSET :pageOffset`
- With a `searchTerm`: **SOSL**, not a SOQL `LIKE` — `NoteDetailSearch__c` is a Long
  Text Area field, which SOQL cannot filter on in a `WHERE` clause at all. The term is
  split into alphanumeric word tokens, each wildcarded (`word*`) and joined with
  `AND`, then run as `FIND '<term>' IN ALL FIELDS RETURNING LegalCaseNote__c(...
WHERE LegalCase__c = '<id>' ORDER BY ... LIMIT ... OFFSET ...)` — SOSL's `IN` clause
  only supports a fixed set of predefined groups (`ALL FIELDS`, `NAME FIELDS`, etc.),
  not an arbitrary field list, so scoping to just `Subject__c`/`NoteDetailSearch__c`
  isn't possible; the `RETURNING` object type + `WHERE` clause is what keeps results
  scoped. `WITH SECURITY_ENFORCED` isn't valid in SOSL, so FLS is enforced via
  `Security.stripInaccessible` on the returned records instead. See `DECISIONS.md`
  item 9 for the full rationale and tradeoffs (prefix-word matching, no `totalCount`).
- `sortDirection` (`'ASC'`/`'DESC'`, normalized server-side, defaults to `'DESC'`)
  controls `ORDER BY NoteDate__c ... NULLS ..., CreatedDate ...` in both paths
  (decision 13). Since the value only ever normalizes to one of two fixed literals,
  it's safe to concatenate into the dynamic SOSL string in the search path.
- `hasMore` is `true` when a full page (`pageSize` rows) came back, `false`
  otherwise — SOSL has no `COUNT()` equivalent, so the LWC uses this instead of an
  exact total to decide whether to request another page
- `pageSize`/`pageOffset` defaulted/clamped server-side (default page size **10** —
  dropped from an initial 20 once real note sizes were known, see `DECISIONS.md`
  items 6 and 10) so a bad client call can't request unbounded rows

### `force-app/main/default/classes/LegalCaseNoteFeedControllerTest.cls`

Covers: no-search returns all notes correctly ordered (desc and asc); search
matching `Subject__c`; search matching note body via `NoteDetailSearch__c`; search
matching nothing; paging across two pages; notes on a different `LegalCase__c` never
leak in.

### `force-app/main/default/lwc/legalCaseNoteFeed/`

- `legalCaseNoteFeed.js-meta.xml` — exposed, `lightning__RecordPage` target,
  `objects: [LegalCase__c]`
- `legalCaseNoteFeed.js` — `@api recordId`; extends `NavigationMixin(LightningElement)`;
  imperative `getNotes` calls; debounced (300ms) search and sort-change that both
  reset to page 0 and replace; scroll-near-bottom handler that advances the page and
  appends; per-note preview truncation (~300 words) + regex-based search-term
  highlight segments built client-side from HTML-stripped `NoteDetail__c`; per-note
  expand/collapse toggle state; author/edit link URLs resolved via
  `NavigationMixin.GenerateUrl` and navigated via `NavigationMixin.Navigate` on click
- `legalCaseNoteFeed.html` — search input, sort combobox, scrollable card feed,
  spinner, empty states ("no notes on this case" vs "no notes match your search"),
  per-card author/edit links, highlighted preview vs. full rich text toggle
- `legalCaseNoteFeed.css` — feed card styling, including `<mark>` highlight styling
- `__tests__/legalCaseNoteFeed.test.js` — jest coverage of initial load, debounced
  search, scroll-triggered pagination, sort-change reload, preview truncation/expand,
  search-term highlighting, and author/edit link navigation (mocking the imperative
  Apex import and asserting against `NavigationMixin.Navigate`/`GenerateUrl`)

### `scripts/apex/` (dev/test data only — not part of the deployed package)

Since this feature is read-only (no note-creation UI), preview data was seeded via
anonymous Apex run directly against `KHRCSandbox` rather than through the app:

- `seedLegalCaseNotesV2.apex` — inserts 25 notes of varying length (~150–2,500
  words) and gibberish-but-searchable legal topics onto test case
  `a6sAK000000079ZYAQ`, with deliberately shared/unique phrases across notes so
  single-match, multi-match, and word-prefix search behavior can all be checked by
  eye. See the comment header in the file for the exact search terms it sets up.
- `deleteSeedLegalCaseNotes.apex` — deletes a specific, hardcoded list of note Ids
  (the ones the first seed pass created), never a broad query, so it can't touch
  unrelated data.
- `seedLegalCaseNotes.apex` (the first version) is superseded by V2 and kept only as
  a reference; it isn't meant to be re-run.

None of these are referenced by `sfdx-project.json` packaging or required for
deployment — see `DECISIONS.md` item 17.

## Manual follow-up (not part of this deploy)

1. Grant `LegalCaseNoteFeedController` class access on `LegalCaseMgmt_GeneralAccess`
   (or another appropriate permission set).
2. Add `legalCaseNoteFeed` to the `LegalCase__c` Lightning Record Page via App
   Builder.

## Verification

- `npm run lint`, `npm run prettier:verify`, `npm run test:unit`
- `sf project deploy validate --source-dir force-app --target-org KHRCSandbox --test-level RunLocalTests`,
  then deploy, then
  `sf apex run test --target-org KHRCSandbox --class-names LegalCaseNoteFeedControllerTest --result-format human --wait 10`
- Manual UI check after the two follow-up steps: feed loads and paginates on a case
  with 10+ notes; a keyword found only in note body text (not the subject) is found
  by search and highlighted in the preview; switching sort direction reloads in the
  new order; a long note shows a truncated preview with Show more/Show less;
  clicking an author name opens their User record; clicking Edit opens the note's
  edit page
