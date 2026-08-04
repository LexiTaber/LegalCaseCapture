# Advocacy Accounts Load — Guesses Flagged for Team Review

Source file: `dataload/Advocacy_Accounts_reviewed.csv` (see the `Guessed` column there for
a machine-filterable version of this same list). This document is the plain-language
version for sharing with the team.

Of 51 rows in the reviewed load file, 33 involved a guess of some kind before this
data goes into `KHRCProd`. They're grouped below by what kind of guess it was.

---

## 1. Could not be identified at all — no guess made

No real-world organization could be found for these, so no website/address was
invented. These need someone who knows the org to fill them in directly.

| Row | Notes |
|---|---|
| **Innovation Lab** | Too generic a name; nothing in the sheet gives enough context to know which "Innovation Lab" is meant. |
| **JMF** | Searched under immigration/asylum/legal-services context; no matching org found. |

---

## 2. Org identity guessed (which real org does this acronym/shorthand mean?)

| Row in sheet | Guessed as | Why flagged |
|---|---|---|
| **CCIJ** | Canadian Centre for International Justice (Ottawa) | Low confidence — nothing else on the list is Canadian, so this may be the wrong "CCIJ" entirely. |
| **PLS** | Prisoners' Legal Services **of New York** | There is no single national "Prisoners' Legal Services" — it's a name used separately by state-level orgs (at least NY and MA). Picked NY as the most prominent; could be wrong state. |
| **Ballard** | Ballard Spahr LLP | Reasonable guess (large firm, common pro bono partner) but no other context confirms it. |
| **TLC** | Transgender Law Center | Assumed based on the human-rights/advocacy context of the rest of the list. |
| **Texas A&M** | Texas A&M University (main campus) | Too large/generic an institution to know which department or campus relationship is actually meant. |
| **Philadelphia Defenders** | Assumed to be the same organization as "Defender Association of Philadelphia" (a separate row on this same list) and given that org's address | If they're actually two different things, this address is wrong. |

---

## 3. Existing production records already exist — need a human to pick the right one

These already have one or more matching Accounts in `KHRCProd`. Rather than inserting
a new duplicate, someone needs to choose (or confirm) which existing Id the load
should point to.

| Row in sheet | Existing KHRCProd record(s) | Situation |
|---|---|---|
| **Howard Law** | 2 duplicate `Howard University School of Law` records | Pick one, or flag the dupe for prod cleanup. |
| **KHR Int'l** (revised: "Kennedy Human Rights International") | 7(!) self-referential records: `Kennedy Human Rights`, `KHRC`, `RFKHR`, `RFK Human Rights` (×2), `Robert & Ethel Kennedy Human Rights Center`, `Robert F. Kennedy Human Rights` | **This may be your own org, not an external partner.** Needs a decision on whether this row needs an Account at all. |
| **Kilpatrick Townsend & Stockton** | `Kilpatrick Stockton LLP` (the firm's pre-2009-merger name) | Likely the same firm renamed — probably should update the existing record rather than insert a new one. |
| **SPLC** | Both `Southern Poverty Law Center` AND `SPLC` exist as separate accounts already | Prod already has this org duplicated under two names; don't add a third variant until that's resolved. |
| **HLS Clinic** | 3 duplicate `Harvard Law School` records | Also uncertain whether this row means the university generally or a specific clinical program — resolve identity and duplicate together. |
| **Public Citizen** | 3 duplicate `Public Citizen` records | Pick one rather than inserting a 4th. |
| **JAC** (revised: "Justice Action Center") | Existing record named `Jac` | Confirm it's the same org before renaming — otherwise the load orphans the existing record instead of updating it. |
| **UC Berkely** (revised: "University of California, Berkeley") | 3 duplicate records under that exact name | Pick one rather than inserting a 4th. |

---

## 4. Org identity is solid, but the address is a guess or incomplete

| Row | What's uncertain |
|---|---|
| **University of Dayton HCR** (revised: "University of Dayton Human Rights Center") | Used the university's general campus address (the Center has no separately published address). Also possibly a duplicate of the plain "University of Dayton" row below it. |
| **University of Dayton** | Same address as above — confirm these are genuinely two separate Accounts, not one org listed twice. |
| **Hecker Fink** | Address is solid, but note the firm's full legal name is "Kaplan Hecker & Fink LLP." |
| **UndocuBlack** | No confirmed street address found, only general Oakland-area references — left blank. |
| **Juror Project** | Confirmed city (New Orleans, LA) but no specific street address found. |
| **Rutgers CRC** (revised: "Rutgers Constitutional Rights Clinic") | Address given is Rutgers Law School's general Newark campus address — the clinic itself doesn't publish a separate one. |
| **Handley Farah & Anderson PLLC** | Firm has multiple offices (Brooklyn, Philadelphia, DC) with conflicting "main office" info online — DC address used, may not be the one you want on file. |

---

*All addresses/websites in the load file were sourced from general web search, not
directly from the organizations or an official filing — treat everything (not just
the rows above) as needing a light sanity check before it's fully trusted, but these
33 rows are the ones most likely to need an actual correction.*
