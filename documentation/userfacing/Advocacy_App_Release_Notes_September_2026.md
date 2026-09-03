# Advocacy App Release Notes — September 2026

Based on feedback from the team, here's a summary of what's changed in the
Advocacy App. Details on each change are below, with instructions where
there's something new to try.

> **Note on screenshots/links:** the images and links below are placeholders —
> each is marked with `[SCREENSHOT: ...]` or `[LINK: ...]` describing exactly
> what to capture or link to. Swap them for the real screenshots/links before
> sharing this document further.

---

## 1. Filing Date is now editable

The **Filing Date** field on a Legal Case can now be entered and changed
directly on the case record — it's no longer locked after the case is
created.

`[SCREENSHOT: Legal Case record with the Filing Date field open for editing]`

---

## 2. New "Case Contacts" related list, and "Related Organizations" renamed

Legal Case records now show two related lists for tracking who's connected to
a case:

- **Case Contacts** (new) — for external *individuals* related to the case,
  such as outside counsel, paralegals, or other contacts.
- **Related Organizations** (renamed from the previous related list) — for
  the *organizations* related to the case.

Both lists work in both directions: from a Legal Case, you can see every
contact or organization related to it, and from a Contact or Organization
record, you can see every Legal Case they're related to.

For example, if the contact Jane Tester is listed as an Outside Paralegal on
a case, visiting Jane's Contact record will also show that case in her list
of related Legal Cases.

`[SCREENSHOT: Legal Case record showing the Case Contacts and Related Organizations related lists]`

`[SCREENSHOT: A Contact record showing its related Legal Cases]`

---

## 3. Investigating: duplicate time entries on the same case/day

It was reported that logging time twice on the same case on the same day
sometimes behaves unexpectedly. We were not able to reproduce this — multiple
time entries (both timed and manual) were logged successfully against the
same case on the same day during testing.

`[SCREENSHOT: Test time entry records showing multiple successful entries on the same case/day]`

`[LINK: Test time entry record demonstrating multiple entries]`

**If this happens again for you or anyone on the team:** please take a
screenshot (or copy/paste) of any error message you see, along with the case
and approximate time, so it can be looked into further.

---

## 4. Hourly reminders for time tracking

Starting a timer opens a small pop-out timer window. That window can now
remind you it's still running, so an open timer doesn't get lost behind
other windows on your screen.

**To turn reminders on:**

1. In the pop-out timer window, switch on **Hourly Reminders**.
2. A **"Remind me every"** dropdown appears — choose 15, 30, 45, or 60
   minutes. This is how often you'll be reminded while a timer is running.
3. Use the **"🔔 Test Reminder Chime"** button below the timer to preview the
   sound at any time.

`[SCREENSHOT: Pop-out timer window with "Hourly Reminders" toggled on and the interval dropdown visible]`

Once turned on, at each interval you'll get a short chime and the browser
tab's title will briefly flash, as long as the timer is still running
(pausing a timer pauses the reminder countdown too). Your reminders on/off
setting and preferred interval are both remembered on your browser, so you
won't need to set them again next time.

---

## 5. Comms team now has view access

The Comms team now has view access to the Advocacy App.

---

## 6. Case Number split into District, Circuit, and Supreme fields

Cases sometimes have different case numbers as they move through different
courts — for example, a different number at the Circuit (appellate) level
than at the District level. Rather than one Case Number field, the case page
now has three separate fields so all of them stay visible on the same case
record, and nothing gets overwritten as a case moves up:

- **Case Number (District)**
- **Case Number (Circuit)**
- **Case Number (Supreme)**

`[SCREENSHOT: Legal Case record showing the three Case Number fields]`

We can explore conditionally showing/hiding these based on the case's current
level or status down the line, but this is a good starting point for now.

---

## 7. Corrected Sarah Gillman's name

Sarah Gillman's name was previously misspelled in Salesforce as "Gilman." This
has been corrected.

---

## 8. Added Georgia to the court district options

All three Georgia federal judicial districts have been added to the list of
court district options.

`[SCREENSHOT: Court District picklist showing the Georgia districts]`

---

## 9. Case Name is now available immediately when creating a new Legal Case

Previously, creating a new Legal Case required saving the case number and
other details first, then going back to edit the Case Name. This was a bug —
the Case Name field is now available on the initial case creation form, so it
can be filled in right away.

`[SCREENSHOT: New Legal Case creation form with the Case Name field available]`

---

## Questions or issues?

If anything here doesn't look right, or you run into a new issue, let us
know with a screenshot and a short description of what you were doing —
that's the fastest way to track down what's happening.
