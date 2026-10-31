# Site content: team, timeline, home, about, site-wide facts

## Site-wide facts (keep consistent everywhere they appear)

These live in the Organization JSON-LD on all 8 pages, in `llms.txt`, and in visible copy:
- Founded **2003**; first competed **2005** (Rex's ruling; older copy said 2006).
- **60+ members** (team-page counter also says 60); six subteams.
- **10 first-place overall finishes, 30 top-five finishes.** 2025 (car TG21): won all three competitions,
  Iron Team, first since 2014.
- Footer: "Student Project Team" tagline, plus the required line "This organization is a registered
  student organization of Cornell University." Contacts: baja@cornell.edu (general),
  rp665@cornell.edu (sponsorship).
- The business subteam runs the **Sales** presentation, which is the only static event it owns; it
  does *not* do the cost report (stated in about.html's Static Events paragraph). The Organization
  JSON-LD still calls it "the SAE Business Presentation event"; that wording was left as-is.

## Team page (`team.html`)

Sections are `<h2>`s, in order: Team Leads, Onboarding Lead, Drivetrain, Transmission, Suspension,
Frame, Brakes, Business, R&D (`id="senior"`), New Members (`id="directors"`, unplaced first-years).

Member card (non-leads omit `lead` and the `.role` line; omit `.social` if there's no LinkedIn):
```html
          <div class="member lead" data-aos="fade-up">
            <div class="pic"><img src="assets/img/headshots/First_Last.webp" class="img-fluid" loading="lazy" alt="First Last"></div>
            <div class="member-info">
              <h4 id="bold-name">First Last</h4>
              <span>Mechanical Engineering '28</span>
              <p class="role">Transmission Lead</p>
              <div class="social">
                <a href="https://www.linkedin.com/in/slug"><i class="icofont-linkedin"></i></a>
              </div>
            </div>
          </div>
```
- When parsing cards, match `class="member"` **and** `class="member lead"`. A regex for only the first
  silently merges each lead's card into its neighbour. A real HTML parser (HTMLParser with div depth) is safer.
- A name change touches the `<h4>` **and** the img `alt`. The headshot filename and the person's LinkedIn
  slug may still carry the old name; renaming the image means uploading the new file too, and the LinkedIn
  slug only changes from the person's own profile.
- LinkedIn custom URLs break when someone edits theirs; the trailing ID usually stays the same
  (`adam-s-05a035325` → `adam-sayah-05a035325`), which confirms it's the same profile.
- Leads also appear in the `Person` @graph JSON-LD in `<head>` (name, jobTitle, description with
  major, image, LinkedIn `sameAs`). Change a lead's details in both places.
- Stats counters (subteams, majors, % women, members) appear in **two** count blocks; edit both.
- Subteam descriptions: about three sentences each, matter-of-fact tone. Scope split Rex asked for:
  **Transmission owns the CVT**; **Drivetrain** owns gearboxes, driveshafts, wheel hubs and the 4WD
  driveline. Don't list individual project assignments.
- Headshots live in `assets/img/headshots/First_Last.webp`. Unreferenced ones were purged in Oct 2026;
  check references in HTML **and** CSS before deleting (`banner.webp` is the hero, used only from team.css).

## Timeline (`timeline.html`)

One `<li>` per season; the season label is `<h3>YYYY - CAR</h3>` (TG22 = 2026, TG21 = 2025,
TGXX = 2024, TG19 = 2023, ...). Each competition is a column:
```html
            <div class="column">
              <h3 class="align-left">September</h3>
              <p class="align-left">
                <em>Nashport, OH</em><br>
                5th Place Overall<br>
                1st Overall Dynamics<br>
                1st Suspension<br>
                ...
              </p>
            </div>
```
- A 1st overall uses `<span class="podium">1st Place Overall</span>`; other overall placements are plain text.
- Placements are ordered best-first; at the same place, the aggregates (Overall Statics/Dynamics) come before events.
- **Only top-10 placements are published** (drop e.g. "18th Endurance"). Older seasons predate the
  rule; leave them unless Rex asks.
- Event names: **"Sales"** (not "Business Presentation"), **"Sled Pull"**. No point totals or field sizes.
- `align-left` / `align-right` alternate by season; copy the season you're editing.
- Every competition also has a `SportsEvent` in the `ItemList` JSON-LD in `<head>` (52 of them). When
  results come in, replace that entry's `"eventStatus": ...EventScheduled` + "Upcoming…" description with
  `"description": "Baja Racing at Cornell competed with car TG22. Results: <same list, '; '-separated>."`
- Before publishing results Rex pastes, check the arithmetic: statics sum to the static total, dynamics
  to the dynamic total; endurance is scored separately and added on top for the overall.

## Home page (`index.html`)

- Six subteam cards (`icon-box`), linking to `team.html#<id>`: Drivetrain, Suspension, Frame, Brakes,
  Business, Transmission (Transmission replaced R&D in Oct 2026). Icons come from boxicons/icofont,
  which are already loaded; check a class exists in the vendor CSS before using it.
- The recap video embed is the TG21 season recap, `youtube.com/embed/BZFN0cBk7Dg`. To identify a video,
  use YouTube oEmbed (`https://www.youtube.com/oembed?url=…&format=json`) to get its real title; a
  commented-out link on the carousel was once mislabelled (it was TG19, not TG21).

## About page (`about.html`)

Static Events and Dynamic Events prose, plus a 5-question FAQ (same visible + schema sync rule as apply).

## llms.txt

Plain-text summary for AI crawlers: identity, record, subteams, how to join, competition format, page
list. When facts change (recruiting rules, subteam scope, record), update it too.

## Known loose ends

- `#girlsofbaja` hero: `gobaja.css` still points at `girlsofbaja_img/gob-hero.webp`, deleted in Aug 2026.
  The hero has no background image until it's restored or replaced.
- Old Squadfree CSS references fonts/backgrounds that never existed (check_site.py WARNs); harmless.
