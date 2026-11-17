# Deploying (`deploy.sh`)

## The host

- Cornell Academic Static Web Hosting (static only, no PHP), since Oct 2026.
- SFTP host **`uploads.courses.cit.cornell.edu`** (it was `uploads.courses2…` before the migration).
  Login rp665 with a password. Web root `coursewww/baja.mae.cornell.edu/htdocs`, which resolves to
  `/acadtech/www/courses/bajamae_vh`. Problems: acadtech@cornell.edu.
- The server's `.htaccess` (tracked in the repo) rewrites `/page` to `page.html` and 301s `/page.html`
  to `/page`, so canonical URLs are extensionless. **What this host accepts in it, learned the hard way
  (Nov 2026, site down ~1 hr):** `Options +FollowSymLinks +SymLinksIfOwnerMatch` is REQUIRED (without it,
  mod_rewrite makes every request 403); `CheckSpelling` is NOT supported (500 on every request);
  `AddDefaultCharset` is untested and unneeded. A bad directive breaks every URL on the site, not one page.
- deploy.sh deliberately never uploads `.htaccess`. To change it: edit the repo copy, upload just that file
  by hand, and immediately `curl -s -o /dev/null -w '%{http_code}' https://baja.mae.cornell.edu/`. Keep the
  last known-good copy ready to put back (it's in git).

## How deploy.sh works

```
./deploy.sh              upload every site file changed since the last deploy, then verify
./deploy.sh --dry-run    list what would upload; connects to nothing
./deploy.sh --all        upload every site file (~37 MB) — only to resync
./deploy.sh --mark-only  record HEAD as deployed without uploading (use after committing
                         changes that are already live, so the next run doesn't resend them)
```
- `.last-deploy` (gitignored, per machine) holds the last deployed commit. Changes are computed against
  it **including uncommitted edits**, so a deploy can run before a commit. If Rex deploys and commits
  afterwards, run `--mark-only` once after the commit.
- Sends pages, CSS, JS, images. New untracked files under `assets/` go automatically; new files
  elsewhere are held until `git add`ed (so scratch files never publish). Never uploads `deploy.sh`,
  `README.md`, `.gitignore`, `.htaccess`, other dotfiles, or `.DS_Store`. **Never deletes** anything
  on the server; locally deleted files are just listed.
- Runs `sftp -o BatchMode=no -b <batch>`: `-b` stops at the first failed command (so a bad path can't
  scatter files), and `BatchMode=no` placed first keeps the password prompt working.
- `-chmod 644` after each put is allowed to fail (see ownership below).
- Afterwards, fetches every uploaded file from the live site and compares bytes. The marker only moves
  forward if everything matches, so a failed run retries the same files next time.

## Failure modes seen so far

| Symptom | Cause | Fix |
|---|---|---|
| New logo shows broken, URL returns **403** | File arrived with mode 600 (common for downloads). Overwriting keeps the server's old mode. | `chmod 644` locally before upload; on the server `chmod 644 <path>` in sftp. check_site.py catches the local case. |
| A new logo slot shows **a different sponsor's logo** (before Nov 2026) | Old `CheckSpelling On` fuzzy-matched a missing file to a similar name (`skb.svg` → `SKF.svg`). Removed from `.htaccess`; a missing file is now a plain 404. | Upload the file. |
| `remote setstat …: Permission denied` on chmod | Files copied over in the Oct 2026 migration belong to another account; you can overwrite but not chmod them. They're already world-readable. | Harmless; the script continues. Long term, ask acadtech to give the site files to rp665 or a team group (also needed for handoff to the next Business Lead). |
| `→`, em dashes or curly quotes show as `â†’`-style garbage | The host sends `charset=ISO-8859-1`, overriding `<meta charset>`. | Keep files ASCII: HTML entities in pages, `\uXXXX` in JSON-LD (all converted Nov 2026; check_site.py enforces it). Don't fix it in `.htaccess`. |
| **Every URL returns 500** | A directive in `.htaccess` the host doesn't support (was `CheckSpelling`). | Put back the last good `.htaccess` by hand (sftp `put`), then curl the home page. |
| **Every URL returns 403** (after an `.htaccess` change) | `RewriteEngine` without `Options +FollowSymLinks +SymLinksIfOwnerMatch`. | Restore the `Options` line. |
| Page looks unchanged after deploy | Browser cache | Hard refresh (Cmd+Shift+R). The script's byte-compare is the real proof. |
| sftp `Invalid command` / chmod hitting `varda.svgchmod` | Typing paths without `cd`, or pasting multi-line commands that run together | One command per line; or let deploy.sh do it. |

Manual sftp, when needed (e.g. fixing one file's mode):
```
sftp rp665@uploads.courses.cit.cornell.edu
cd coursewww/baja.mae.cornell.edu/htdocs
put assets/img/sponsors_img/x.svg assets/img/sponsors_img/x.svg
chmod 644 assets/img/sponsors_img/x.svg
```
Use the two-argument `put`, or the file lands in the remote working directory instead of its folder.

## Checking the live site from here

The site is public, so curl can verify any deploy without credentials:
```bash
f=sponsors.html; [ "$(shasum < $f)" = "$(curl -sL https://baja.mae.cornell.edu/$f | shasum)" ] && echo live || echo stale
```
