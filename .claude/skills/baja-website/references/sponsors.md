# Sponsors page (`sponsors.html`)

## Tiers and card markup

Four sections, each an `<h2>` followed by a row container. The card class differs per tier, so copy the
markup from the tier you're adding to, not from another tier.

| Tier (h2) | Row id | Card wrapper class | Description `<p>`? |
|---|---|---|---|
| Premier Partners | `elite` | `portfolio-item filter-web` (no col class) | **Yes**, every card has one |
| Major Supporters | `gold` | `col-lg-4 col-md-6 portfolio-item filter-card` | No |
| Supporting Tier | `silver` | `col-lg-3 col-md-6 portfolio-item filter-card` | No |
| Contributors | `contributor` | `col-lg-2 col-md-6 portfolio-item filter-card` | No |

Non-premier card (swap the col class for the tier):
```html
          <div class="col-lg-3 col-md-6 portfolio-item filter-card">
            <a href="https://www.example.com/">
              <div class="portfolio-wrap">
                <img src="assets/img/sponsors_img/example.svg" class="img-fluid" alt="Example logo">
              </div>
            </a>
          </div>
```
Premier cards are the same shape with `class="portfolio-item filter-web"` and a `<p>…</p>` after the
`<img>`. Moving a sponsor between tiers means changing its col class too, otherwise it renders at the
old tier's size. Every logo should be wrapped in a link (Rochester Clutch once wasn't).

Premier blurbs: neutral, factual description of the company (what it *is*), not claims about what it
gives the team unless Rex supplies them. Citadel's blurb deliberately gives the hedge fund and
Citadel Securities one sentence each of near-equal length, both called "the leading …" (Rex's call).

## Logos

- Folder: `assets/img/sponsors_img/`. Prefer SVG, **white fills (`#fff`) on transparent**, because tiers
  sit on a dark background. Name lowercase-hyphenated with no `-logo` / `-seeklogo` suffix
  (`citadel.svg`, `miller-electric.svg`, `pacific-fusion.svg`). Older files don't all follow this; don't rename them.
- Rex usually pastes **SVG text** into chat: write it to the file verbatim, then validate it parses
  (`xml.etree.ElementTree.parse`). If he pastes an *image* and it looks blank, it's a white logo on
  transparent; ask for the SVG text or the file instead of guessing.
- Raster logos (PNG/JPG) can be converted with the `baja-sponsor-logo-to-svg` skill.
- **`chmod 644` new logo files.** Downloaded/exported files often arrive as 600, which the host serves
  as 403 (this broke Pacific Fusion and Varda). check_site.py flags it.
- Verify the company's URL resolves (`curl -sIL`). 403/429 from big sites (Citadel, Miller) is bot
  blocking, not a dead link.

## Source of truth for tiers

The sponsorship Google Sheet's **Level** column, set by donation value:
Premier > $6k · Major $2k–6k · Supporting $500–2k · Contributor < $500.
Known ambiguity: G&C, KISSsoft and Citadel are all exactly $6,000 and labelled Premier, but the written
rule ("> 6k") would make them Major. Rex hasn't settled whether the rule should read ≥ 6k.

Don't copy contact names, emails, phone numbers or account credentials from the sheet into the repo.

## Open audit items (as of 2026-10-31, from comparing the sheet to the site)

- Wrong tier on site: KISSsoft (site Major → sheet Premier); Alro Steel and Custom Laser (Supporting → Major);
  HGSI / The Sensor Connection and Bicycle Frame Depot (Supporting → Contributor).
- Missing from site: DKM Fabrication (Major; `DKM-logo.svg` already in the folder), Unlimited Metalwork
  (Supporting; no logo in repo), Val-Kro (Major; deal not finalised, no logo).
- On site but not in the sheet: Anoplate (Major). Either a past sponsor to remove or a missing sheet row.
- Removed: Siemens (Oct 2026; `siemens.svg` left in folder).
Confirm with Rex before acting on these; some were left pending on purpose.

## Settled one-offs

- Carlisle links to `carlstar.com` (the Carlisle tire maker), not carlisle.com (an unrelated conglomerate).
- Rochester Clutch links to `rochesterclutch.com`.
- Citadel links to `citadel.com` (the hedge fund), with the plain Citadel wordmark.
- SKB Cases sits directly under Creative Engineering in the Supporting Tier.
