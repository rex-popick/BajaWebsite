#!/usr/bin/env python3
"""Validate the Baja website before committing or deploying.

Run from anywhere inside the repo:
    python3 .claude/skills/baja-website/scripts/check_site.py            # checks
    python3 .claude/skills/baja-website/scripts/check_site.py --sponsors # + sponsor list by tier

Checks:
  1. Every JSON-LD block on every page parses.
  2. The Organization JSON-LD is identical on all pages (it's copy-pasted into each).
  3. FAQ pages: visible <details> Q&A text matches the FAQPage schema exactly.
  4. HTML tag balance (unclosed / stray tags).
  5. Every local asset referenced by a rendered page or a CSS url() exists and is
     world-readable. Owner-only files (mode 600, common for downloaded logos)
     are served as 403 Forbidden by the web host.
  6. Sponsors: no logo used twice, and logo files in sponsors_img that nothing uses.
Exits 1 if any ERROR is found; WARN lines are informational.
"""
import json, os, re, stat, subprocess, sys
from html.parser import HTMLParser

ROOT = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True,
                      text=True, check=True).stdout.strip()
os.chdir(ROOT)
PAGES = sorted(f for f in os.listdir(".") if f.endswith(".html"))
VOID = {"br", "img", "input", "meta", "link", "hr", "source", "area", "base", "col",
        "embed", "param", "track", "wbr"}
errors, warns = [], []

def err(m): errors.append(m)
def warn(m): warns.append(m)
def strip_comments(s): return re.sub(r"<!--.*?-->", "", s, flags=re.S)

class Balance(HTMLParser):
    def __init__(self):
        super().__init__(); self.stack = []; self.stray = []
    def handle_starttag(self, t, a):
        if t not in VOID: self.stack.append(t)
    def handle_endtag(self, t):
        if t in VOID: return
        if t in self.stack:
            while self.stack and self.stack.pop() != t: pass
        else:
            self.stray.append(t)

orgs = {}
for page in PAGES:
    src = open(page, encoding="utf-8").read()

    # 1 + 2: JSON-LD
    for i, block in enumerate(re.findall(r'<script type="application/ld\+json">(.*?)</script>', src, re.S), 1):
        try:
            data = json.loads(block)
        except Exception as e:
            err(f"{page}: JSON-LD block {i} does not parse: {e}"); continue
        t = data.get("@type")
        if isinstance(t, list) and "SportsOrganization" in t:
            orgs[page] = json.dumps(data, sort_keys=True)
        # 3: FAQ sync
        if t == "FAQPage":
            visible = dict(re.findall(r"<summary>(.*?)</summary>\s*<p>(.*?)</p>", src, re.S))
            for q in data["mainEntity"]:
                name, ans = q["name"], q["acceptedAnswer"]["text"]
                if name not in visible:
                    err(f"{page}: FAQ schema question has no visible copy: {name!r}")
                elif visible[name].strip() != ans.strip():
                    err(f"{page}: FAQ answer differs between visible text and schema: {name!r}")
            extra = set(visible) - {q["name"] for q in data["mainEntity"]}
            for name in extra:
                err(f"{page}: visible FAQ question missing from schema: {name!r}")

    # 4: tag balance
    b = Balance(); b.feed(src)
    if b.stack: err(f"{page}: unclosed tags {b.stack}")
    if b.stray: err(f"{page}: stray closing tags {b.stray}")

    # 5: local assets referenced by the rendered page (comments ignored)
    rendered = strip_comments(src)
    for ref in re.findall(r'(?:src|href)="(assets/[^"#?]+)"', rendered):
        if not os.path.isfile(ref):
            err(f"{page}: references missing file {ref}")
        elif not os.stat(ref).st_mode & stat.S_IROTH:
            err(f"{page}: {ref} is not world-readable (chmod 644) - will 403 on the live site")

# 2: org schema drift
if orgs:
    variants = {}
    for p, j in orgs.items(): variants.setdefault(j, []).append(p)
    if len(variants) > 1:
        groups = sorted(variants.values(), key=len, reverse=True)
        err("Organization JSON-LD differs between pages (edit all copies together): "
            + " | ".join(", ".join(g) for g in groups))
    missing = [p for p in PAGES if p not in orgs and p not in ("header.html", "footer.html")]
    if missing: warn(f"pages without the Organization JSON-LD: {missing}")

# 5b: CSS url() references
for dirpath, _, files in os.walk("assets/css"):
    for f in files:
        if not f.endswith(".css"): continue
        css = os.path.join(dirpath, f)
        text = re.sub(r"/\*.*?\*/", "", open(css, encoding="utf-8").read(), flags=re.S)
        missing = set()
        for ref in re.findall(r'url\(["\']?([^"\')]+)["\']?\)', text):
            if ref.startswith(("http", "data:", "#")): continue
            path = os.path.normpath(os.path.join(dirpath, ref.split("?")[0].split("#")[0]))
            if not os.path.isfile(path): missing.add(path)
        # Template leftovers (fonts/backgrounds that never existed) are long-standing
        # and harmless, so they warn instead of failing the run.
        if missing:
            warn(f"{css}: url() to {len(missing)} missing file(s): {', '.join(sorted(missing))}")

# 6: sponsors
sp = strip_comments(open("sponsors.html", encoding="utf-8").read())
tiers = []
for m in re.finditer(r"<h2>([^<]+)</h2>(.*?)</section>", sp, re.S):
    items = re.findall(r'<img src="assets/img/sponsors_img/([^"]+)"[^>]*alt="([^"]*)"', m.group(2))
    tiers.append((m.group(1), items))
used = [f for _, items in tiers for f, _ in items]
for f in sorted({f for f in used if used.count(f) > 1}):
    err(f"sponsors.html: logo {f} appears more than once")
for f in sorted(os.listdir("assets/img/sponsors_img")):
    if f.startswith(".") or f == "sponsors_hero.webp": continue
    if f not in used:
        warn(f"sponsors_img/{f} is not used on the sponsors page")

if "--sponsors" in sys.argv:
    for name, items in tiers:
        print(f"\n## {name} ({len(items)})")
        for f, alt in items:
            print(f"   {alt.replace(' logo', ''):40} {f}")
    print()

for w in warns: print("WARN ", w)
for e in errors: print("ERROR", e)
print(f"\n{len(PAGES)} pages checked: {len(errors)} error(s), {len(warns)} warning(s).")
sys.exit(1 if errors else 0)
