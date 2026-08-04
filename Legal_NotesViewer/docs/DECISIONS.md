# Decisions — Legal Case Note Feed

_Decision log for the notes-viewer feature. Last updated: 2026-07-29._

1. **Separate repo, same org.** `Legal_NotesViewer` is a standalone SFDX project
   that deploys into the same `KHRCSandbox` org as `LegalCaseMgmtMVP`, rather than
   being built inside that project.
   **Why:** user's explicit choice — keeps this feature's source isolated from the
   core data-model project.

2. **No local copy of existing objects/permission set.** This repo does not retrieve
   or redeclare `LegalCase__c`, `LegalCaseNote__c`, or `LegalCaseMgmt_GeneralAccess`
   locally; it only adds new components that reference the already-deployed schema.
   **Why:** avoids creating a second, potentially-stale source of truth for metadata
   that `LegalCaseMgmtMVP` already owns.

3. **Read-only scope.** This feature only views/searches notes — no create/edit UI.
   **Why:** matches the user story as written; avoid building beyond what was asked.

4. **Search targets `Subject__c` + `NoteDetailSearch__c`, not `NoteDetail__c`.**
   **Why:** `NoteDetailSearch__c` is a plain-text, HTML-stripped mirror of the rich
   text field, purpose-built by the existing trigger for exactly this kind of
   search. Searching raw HTML in `NoteDetail__c` would be unreliable.

5. **Imperative Apex calls, not `@wire`.**
   **Why:** the feed needs to _replace_ results on a new search but _append_
   results on scroll (infinite scroll). `@wire` only re-runs and replaces on
   reactive parameter changes — it can't express an append.

6. **Infinite scroll (scroll-position threshold, page size 10), not a "Load More"
   button.**
   **Why:** the story explicitly asks for a Chatter-like continuous-scroll feel.
   Page size was set to 10, not the more typical 20, because individual notes run
   500–3,000 words of rich text — 10 full notes per page keeps both the payload and
   the rendered DOM reasonable.

7. **Component-only deploy — no flexipage.**
   **Why:** user chose to keep page-layout ownership (Lightning Record Page
   composition) separate from this component build; they will place the component
   via App Builder. Matches the sister project's existing pattern of deferring
   page/navigation work.

8. **Permission set access is a manual follow-up, not a deployed file.**
   **Why:** this repo doesn't hold `LegalCaseMgmt_GeneralAccess`'s full source.
   Deploying a same-named permission set file with only partial content (e.g. just
   the new class access) would overwrite the real one and could silently strip
   existing object/field grants. Granting Apex class access is called out as a
   manual step in `DEPLOYMENT.md` instead.

9. **Keyword search uses SOSL, not a SOQL `LIKE` filter, against `NoteDetailSearch__c`.**
   **Why:** discovered during the first deploy validation — `NoteDetailSearch__c` is
   a Long Text Area field, and Salesforce does not allow Long Text Area fields to be
   filtered in a SOQL `WHERE` clause at all (this isn't an FLS/permission issue, it's
   a hard platform restriction). SOSL is the supported way to keyword-search such a
   field — it's the same mechanism Chatter/global search use, which also fits the
   "similar to how I would for chatter" framing of the original story. Tradeoffs
   accepted as part of this: search matches whole-word prefixes (SOSL tokenized
   search, wildcarded per word) rather than arbitrary substrings; the search term is
   reduced to alphanumeric word tokens rather than escaped, since free-text keyword
   search doesn't need SOSL's special operators; `WITH SECURITY_ENFORCED` isn't valid
   in SOSL, so FLS is enforced via `Security.stripInaccessible` on that path instead;
   and the API no longer returns a `totalCount` (SOSL has no `COUNT()` equivalent) —
   it returns a `hasMore` boolean instead, based on whether a full page came back.

10. **"Allow Search" was enabled on `LegalCaseNote__c` (an org config change, not a
    metadata deploy from either repo) rather than switching to a fetch-then-filter
    Apex approach.**
    **Why:** the object wasn't search-enabled, so the SOSL query in decision 9
    initially failed with "entity type LegalCaseNote__c does not support search."
    The alternative — Apex fetching a batch of notes and filtering/paginating in
    memory — was evaluated and rejected once note size was factored in: notes run
    500–3,000 words, so a handful of dozen large notes on one case could already
    approach the 6 MB synchronous Apex heap limit if loaded wholesale to be
    filtered, well short of any realistic note count. SOSL avoids this because the
    search index filters server-side before anything reaches Apex heap — a page of
    already-matched notes is bounded and safe regardless of total note count or
    size. This is why page size was also dropped from 20 to 10 (decision 6) once
    real note sizes were known.

11. **Search-term highlighting is done client-side on plain text, not on the rich
    HTML in `NoteDetail__c` directly.**
    **Why:** injecting `<mark>` around matches inside arbitrary rich HTML risks
    splitting tags or matching inside attributes; doing it on plain text is safe and
    simple. The collapsed preview (see decision 12) is built from this same plain
    text, so highlighting only ever applies there — the expanded full note renders
    the real rich text via `lightning-formatted-rich-text` unhighlighted. Matching
    mirrors the SOSL word-prefix behavior from decision 9 (word-boundary + prefix,
    not arbitrary substring) so what's highlighted is consistent with why a note
    matched the search in the first place. Segments are built as an array of
    `{text, isMatch}` tokens rendered via template iteration (`<mark>` vs `<span>`),
    not via innerHTML injection, since LWC disallows/discourages unsanitized HTML
    injection into templates. _(Originally the plain-text source was
    `NoteDetailSearch__c`; decision 15 switched it to HTML-stripped `NoteDetail__c`
    — the highlighting mechanism itself didn't change.)_

12. **Notes are truncated to a ~300-word preview by default, with a per-note
    Show more/Show less toggle, instead of always rendering the full note.**
    **Why:** requested directly, and reinforced by decision 10/6 — notes run
    500–3,000 words, so rendering all of them in full for every note on a page
    would make the feed unwieldy to scroll and read. The word-count boundary is
    approximate (computed by splitting the plain text on whitespace, per decision
    15), not an exact rendering measurement.

13. **Sorting (newest/oldest first) is a server-side parameter, not a client-side
    re-sort of the current page.**
    **Why:** pagination happens at the database/search-index layer (decisions 9-10),
    so sort order has to be decided before that LIMIT/OFFSET is applied, not after —
    re-sorting only the notes already loaded into the browser would just reorder
    one page, not the whole feed. Changing sort resets to page 0 and reloads.

14. **Author and Edit links use `NavigationMixin` with a resolved URL on the anchor's
    `href` plus an `onclick` handler that calls `Navigate`, rather than either alone.**
    **Why:** `href` alone (a manually-built relative URL) would work but bypasses
    Salesforce's own URL generation, which can vary by context (community, Lightning
    console, etc.); `Navigate` alone leaves the link with no real `href`, so
    middle-click/right-click-to-open-in-new-tab wouldn't work. Using
    `NavigationMixin.GenerateUrl` for the `href` and `NavigationMixin.Navigate` (via
    `onclick` + `preventDefault`) for the actual click is the combination Salesforce
    itself documents for this. The Edit link navigates to `LegalCaseNote__c`'s
    standard edit page (`actionName: 'edit'`) rather than a custom edit UI, since no
    custom edit form exists (or was asked for) in this feature.

15. **The preview/highlight source is `NoteDetail__c` (HTML-stripped client-side), not
    `NoteDetailSearch__c`; the author link's Id comes from `Author__r.Id`, not the raw
    `Author__c` field.**
    **Why:** discovered via deploy validation — neither `NoteDetailSearch__c` nor the
    raw `Author__c` lookup field is FLS-visible to the running user, and
    `WITH SECURITY_ENFORCED` hard-fails (rather than silently omitting) when a query
    selects a field the user can't read. `Author__r.Name` had already been working
    fine without needing FLS granted on `Author__c` itself, which showed that
    traversing a relationship to a field on the _parent_ record doesn't require FLS
    on the _child's_ lookup field — so `Author__r.Id` sidesteps the same problem
    `Author__c` hit. `NoteDetailSearch__c` has no such traversal option (it's a field
    on `LegalCaseNote__c` itself), so its preview text is instead derived by
    stripping HTML tags/entities from `NoteDetail__c` (a field already proven
    accessible, since it's what the expanded view renders) with a small client-side
    regex — good enough for read-only preview text rendered through safe template
    interpolation, not a full HTML sanitizer. This avoids asking for another manual
    FLS grant on top of the "Allow Search" change from decision 10, and also fixes a
    latent bug: the SOSL search path's `Security.stripInaccessible` was silently
    dropping these same two fields (soft-fail, unlike `WITH SECURITY_ENFORCED`'s
    hard-fail), which would have made author links/highlighting silently not work on
    search results even if the no-search path had been left broken.

16. **The component wraps its content in `<lightning-card title="Case Notes Feed">`.**
    **Why:** requested directly, to give the component a visible, identifiable title
    both in the record page UI and when locating it in Lightning App Builder's
    component picker — `lightning-card` is the standard/idiomatic way to do this in
    LWC rather than a hand-rolled header element.

17. **Preview/test data is seeded via ad hoc anonymous Apex scripts in `scripts/apex/`
    (`seedLegalCaseNotesV2.apex`, `deleteSeedLegalCaseNotes.apex`), run directly
    against `KHRCSandbox` on the test case `a6sAK000000079ZYAQ` — not part of the
    deployed package.**
    **Why:** this feature is read-only (decision 3), so there's no in-app way to
    create notes from this component; anonymous Apex was the fastest way to get
    realistic-volume, realistic-length preview data onto a test case to exercise
    scrolling/search/sort/truncation. `seedLegalCaseNotes.apex` (the first version)
    is superseded by `seedLegalCaseNotesV2.apex`, which layers in deliberately
    reusable/unique gibberish phrases across notes specifically so search behavior
    (single-match, multi-match, word-prefix) can be verified by eye; it's left in
    place as an example, not meant to be re-run. Nothing under `scripts/apex/` is
    required for or touched by deployment.
