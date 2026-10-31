# Apply / recruitment page (`apply.html`)

## Lifecycle

The page has two states. **As of 2026-10-31 it is in the off-season state.**

**Off-season (between cycles):** the CTA `<h3>` reads "Recruitment" and the intro says the Fall YYYY
applications are closed and to stay tuned for next fall. The application buttons and the event
schedule are commented out inside a wrapper:
```
<!-- OFF-SEASON: application buttons and event schedule are hidden until the next cycle.
     To reopen, delete this comment wrapper, then update the form links, dates, and data-date values.
     ...buttons + schedule...
END OFF-SEASON -->
```
The block must not contain `--` or the comment ends early.

**Reopening for a new cycle (usually mid-August):**
1. Delete the OFF-SEASON wrapper.
2. Put the new Google Form links on both buttons (Upperclassmen; First-Year & Transfer). Rex sends
   `forms.gle/…` links; check each resolves and that the two are different forms.
3. Update every event row: visible date (check the weekday!), time, room, and `data-date`.
4. Change the `<h3>` back to "Fall YYYY" and rewrite the intro.
5. Update the FAQ answers "When are applications due?" and "Where can I meet the team before I apply?",
   which were generalised for the off-season (both visible and schema copies).

**Closing a cycle** is the reverse: wrap the buttons + schedule (through the `</div>` that closes the
schedule's inline-block wrapper, or the tags won't balance), switch the heading and intro, and generalise
the two FAQ answers. Previous closings for reference: commits `7980d6a` (2024) and `c1d536b` (2025).

## Schedule markup and the inline script

```html
<li data-date="2026-08-27">
  <span class="event-title">Info Session #1</span>
  <span class="event-details">Thursday, Aug. 27 <br> 4:30-6 p.m. <br>
    <a href="https://maps.app.goo.gl/iUGxgE4EuN3jYVN57">Autolab, Upson B74</a> (basement)</span>
</li>
<li class="due" data-date="2026-09-03">
  <span class="due-title">Upperclassmen Apps Due<br> Sept. 3 (11:59 p.m.)</span>
</li>
```
- Rows stay in chronological order. `.due` rows have no dot; they draw a dashed line instead.
- The application buttons carry `data-date` = their deadline.
- The inline script at the bottom of the page adds `.past` to anything whose `data-date` was
  yesterday or earlier (greys it, and sets `aria-disabled` on links), then draws the vertical progress
  line: solid grey through the last past marker, fading to red just above the next one. It measures
  the markers' pixel positions (`--past-px`, `--fade-px` in `apply.css`) because rows have unequal
  heights; a percentage-based fade overlapped the dots. It re-measures on load and resize.
- Venue links inside rows have their own colour rules in `apply.css` (white normally, grey when past).
- Rooms used: Autolab (Upson B74, basement, linked to the map pin above) and Upson 216 (unlinked).

## FAQ (15 questions)

Visible copy is `<details class="faq-item"><summary>Q</summary><p>A</p></details>` inside
`<section id="faq">`; the same text lives in the `FAQPage` JSON-LD in `<head>`. They must match
exactly (check_site.py verifies). The Instagram mention is an inline link
`<a href="https://www.instagram.com/cornellbajaracing/">@cornellbajaracing</a>`, in both copies.

Facts Rex has confirmed (use these; don't extrapolate past them):
- Recruiting is **fall only**; no spring cycle, because of the onboarding investment.
- Two applications (upperclassmen; first-year & transfer). Each asks the applicant to pick the
  **mechanical or business track**, and you may apply to only one ("track" = discipline; "application"
  = class year; keep those words distinct).
- All six subteams take members. Subteam placement happens **sophomore year**.
- Process: written screening → two in-person panel interviews (usually weekends, 20–30 min) → offers.
- Typical intake 20–25: 16–18 mech first-years, 1–2 mech sophomores, 2–3 business first-years,
  1–2 business sophomores.
- No prior experience needed; comprehensive onboarding led by an onboarding director, including
  training sessions the team calls "schools" (CAD through individual components like gears).
- Any Cornell undergraduate from any school or major, either track; transfers yes; **grad students no**.
- Deadlines are firm: 11:59 p.m., no extensions.
- 1–3 credits; Cornell counts ~3 hours/week per credit; real commitment varies.
- First-years can go to 2 of the 3 competitions; travel is fully covered.
- **No coffee chats**; talk to the team at info sessions, Project Teams Fest, or Club Fest.

**Never publish:** how many people apply (private, Rex's decision), or how Baja differs from other
project teams (Rex considers it confidential).
