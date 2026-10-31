---
name: baja-website
description: Everything needed to edit, validate, commit and deploy the Cornell Baja Racing website (baja.mae.cornell.edu, this repo). Use this whenever the task touches the Baja site at all — adding/moving/removing a sponsor or sponsor logo, team roster changes (names, majors, LinkedIn links, headshots, leads), the apply/recruitment page (application links, info sessions, deadlines, opening or closing the cycle), competition results on the timeline, home-page subteam cards, FAQs, SEO/structured data, llms.txt, or running deploy.sh — even for a one-line edit, because the conventions, sync rules, and deploy gotchas here are not discoverable from the files alone.
---

# Cornell Baja Racing website

Static site (Bootstrap "Squadfree" template + jQuery) for Baja Racing at Cornell.
Maintained by Rex Popick (Business Lead, NetID rp665). Live at https://baja.mae.cornell.edu,
repo github.com/rex-popick/BajaWebsite, branch `main`.

## Map

| File | What it is |
|---|---|
| `index.html` | Home: carousel, about blurb, recap video, 6 subteam cards, donate |
| `about.html` | Competition format (static/dynamic events) + 5-question FAQ |
| `apply.html` | Recruitment: cycle intro, application buttons, event schedule, 15-question FAQ |
| `team.html` | Stats counters, leads, subteam rosters with descriptions |
| `timeline.html` | Year-by-year car + competition results, 2005 to now |
| `sponsors.html` | Four sponsor tiers |
| `girlsofbaja.html`, `contact.html` | #girlsofbaja + merch; contact emails |
| `header.html`, `footer.html` | Partials injected by `loadPartial()` in `assets/js/main.js` into `#site-header` / `#site-footer` |
| `llms.txt`, `robots.txt`, `sitemap.xml` | AI-crawler summary and SEO files |
| `.htaccess` | `/page.html` → 301 → `/page`; also `CheckSpelling On` (see deploy gotchas) |
| `assets/css/<page>.css` | One stylesheet per page (index → `style.css`, girlsofbaja → `gobaja.css`) |
| `deploy.sh` | Upload to the host; see `references/deploy.md` |

Each page carries the **same Organization JSON-LD block** in its `<head>`. It is copy-pasted, so a fact
in it (member count, awards, description) must be changed on all 8 pages at once. Extra structured
data: `FAQPage` on apply + about, a `Person` @graph of leads on team, an `ItemList` of `SportsEvent`s on timeline.

## Workflow

1. **Edit** with small Python/sed replacements that assert the old text occurs exactly once
   (`assert s.count(old) == 1`). Pages have lots of near-duplicate markup; a blind replace hits the wrong block.
2. **Validate**: `python3 .claude/skills/baja-website/scripts/check_site.py` (add `--sponsors` to list
   every sponsor by tier). It checks JSON-LD parses, the Organization block is identical everywhere,
   FAQ visible text == FAQ schema, tag balance, and that referenced assets exist and are world-readable.
   Pre-existing WARNs about template CSS leftovers are expected; ERRORs are not.
3. **Commit** straight to `main`, grouped by concern (e.g. sponsors vs. recruitment vs. roster), with a
   descriptive message. "commit" means commit only; push when Rex says push ("push/commit" = both).
4. **Deploy** is Rex running `./deploy.sh` (it prompts for his password). It uploads every file changed
   since the last deploy, then verifies each one live. Details and failure modes: `references/deploy.md`.

## Conventions that matter

- **Match neighbouring markup exactly** (classes, alt text "Company logo", no `target="_blank"` on
  sponsor/social links). Rex often asks to "follow current conventions".
- **Keep structured data in sync with visible text.** Google requires FAQ schema text to be visible on
  the page, and a stale schema is what AI answer engines quote. Change both copies of an FAQ answer,
  and update the timeline `SportsEvent` / team `Person` entries when the visible content changes.
- **Check every date's weekday** with Python before publishing ("Thursday, Sept. 1" has been wrong before).
  Also keep `data-date="YYYY-MM-DD"` in step with the visible date; scripts key off it.
- **Don't invent facts** about the team (eligibility, sponsor relationships, owners of events). Ask.
  Rex answers quickly; when a request is ambiguous ("move it to the Tuesday"), offer the concrete options.
- **Never delete an asset without grepping HTML, CSS and JS for it first.** Old commits are the backup:
  `git checkout <commit> -- <path>`.
- Dark sections: the global `a { color: black }` is invisible on the dark CTA background; links there
  need an explicit colour rule.

## Where to look next

- Sponsors page (tiers, card markup, logos, the sponsor sheet's tier rules, open audit items): `references/sponsors.md`
- Apply page (in-season vs. off-season, schedule script, FAQ facts, things never to publish): `references/apply.md`
- Team, timeline, home, about, llms.txt, site-wide facts: `references/content.md`
- deploy.sh, the host, permissions, and every deploy failure seen so far: `references/deploy.md`

## Shell gotchas

- Rex's shell is **zsh**: `"$c:apply.html"` triggers the `:a` modifier. Write `"${c}:apply.html"`.
- macOS ships **bash 3.2** (deploy.sh targets it): no `mapfile`, no associative arrays.
- `assets/img/sponsors_img/.DS_Store` is tracked in git. Don't `rm` it in test cleanup.
