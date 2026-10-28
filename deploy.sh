#!/usr/bin/env bash
# Deploy BajaWebsite to Cornell's Academic Static Web Hosting over sftp.
#
# Uploads every site file that changed since the last successful deploy: pages,
# CSS, JS, images, anything. The commit last deployed is recorded in
# .last-deploy, and git reports what changed since (including uncommitted
# edits). Every uploaded file is chmod 644 on the server where allowed, because the web server
# cannot read owner-only files and answers them with 403 Forbidden. After the
# upload, each file is fetched back from the live site and compared byte for
# byte; the deploy is only recorded if everything matches.
#
# Usage:
#   ./deploy.sh               upload what changed since the last deploy
#   ./deploy.sh --dry-run     show what would be uploaded, connect to nothing
#   ./deploy.sh --all         upload every site file (~37 MB)
#   ./deploy.sh --mark-only   record HEAD as deployed without uploading anything
#                             (use when the server is already up to date)
#
# Written for the bash 3.2 that ships with macOS: no mapfile, no associative
# arrays, and empty arrays are expanded with ${a[@]+"${a[@]}"} under set -u.
set -euo pipefail

# ================= CONFIG =================
# Host moved from uploads.courses2 to uploads.courses in Oct 2026, when the site
# was migrated to Academic Static Web Hosting (no PHP).
HOST="uploads.courses.cit.cornell.edu"
REMOTE_DIR="coursewww/baja.mae.cornell.edu/htdocs"
SITE_URL="https://baja.mae.cornell.edu"
NETID="rp665"
MARKER=".last-deploy"
# Repo files that are not part of the website and are never uploaded.
NOT_SITE="README.md deploy.sh .gitignore $MARKER"
# =========================================

DRY_RUN=0
ALL=0
MARK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --dry-run)              DRY_RUN=1 ;;
    --all|--all-assets)     ALL=1 ;;
    --mark-only)            MARK_ONLY=1 ;;
    -h|--help)              sed -n '2,21p' "$0"; exit 0 ;;
    *) echo "ERROR: unknown option '$arg' (try --help)"; exit 1 ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "ERROR: Not inside the BajaWebsite git repo."
  exit 1
fi
cd "$REPO_ROOT"

HEAD_SHA="$(git rev-parse HEAD)"

if [[ "$MARK_ONLY" == 1 ]]; then
  echo "$HEAD_SHA" > "$MARKER"
  echo "Recorded $(git log -1 --format='%h %s' HEAD) as deployed."
  echo "Nothing was uploaded. The next ./deploy.sh sends what changed after this commit."
  exit 0
fi

# ---------- decide what to send ----------
FILES=()      # to upload
DELETED=()    # removed locally; reported, never deleted on the server
SKIPPED=()    # can't be quoted safely for sftp
HELD=()       # untracked outside assets/; needs `git add` first

is_site_file() {
  local f="$1" n
  for n in $NOT_SITE; do [[ "$f" == "$n" ]] && return 1; done
  case "$f" in
    .DS_Store|*/.DS_Store) return 1 ;;
    .htaccess)             return 0 ;;   # server config, ships with the site
    .*)                    return 1 ;;   # editor/tool dirs: .vscode/, .claude/, ...
  esac
  return 0
}

add_file() {
  local f="$1"
  is_site_file "$f" || return 0
  case "$f" in *\"*|*\\*) SKIPPED+=("$f"); return 0 ;; esac
  [[ -f "$f" ]] && FILES+=("$f")
  return 0
}

if [[ "$ALL" == 1 ]]; then
  BASE_DESC="every site file (--all)"
  while IFS= read -r f; do add_file "$f"; done < <(git ls-files)
else
  if [[ ! -f "$MARKER" ]]; then
    echo "ERROR: No record of a previous deploy ($MARKER is missing)."
    echo
    echo "Pick one:"
    echo "  ./deploy.sh --mark-only   the live site is already current; start tracking from HEAD"
    echo "  ./deploy.sh --all         upload every site file (~37 MB) and start tracking"
    exit 1
  fi
  BASE_SHA="$(tr -d '[:space:]' < "$MARKER")"
  if ! git cat-file -e "${BASE_SHA}^{commit}" 2>/dev/null; then
    echo "ERROR: $MARKER points at $BASE_SHA, which isn't in this repo's history."
    echo "Run ./deploy.sh --all to resync, or --mark-only if the server is current."
    exit 1
  fi
  BASE_DESC="changed since $(git log -1 --format='%h %s' "$BASE_SHA")"

  # Base commit vs the working tree, so uncommitted edits to tracked files ship
  # too. --no-renames reports a rename as delete + add, so the new path uploads.
  while IFS= read -r f; do add_file "$f"; done \
    < <(git diff --name-only --no-renames --diff-filter=ACMT "$BASE_SHA")
  while IFS= read -r f; do is_site_file "$f" && DELETED+=("$f"); done \
    < <(git diff --name-only --no-renames --diff-filter=D "$BASE_SHA")
  # Brand-new files git doesn't track yet: new images and CSS under assets/ go
  # straight up; anything else must be `git add`ed first, so a stray scratch
  # file in the repo root is never published by accident.
  while IFS= read -r f; do
    is_site_file "$f" || continue
    case "$f" in
      assets/*) add_file "$f" ;;
      *)        HELD+=("$f") ;;
    esac
  done < <(git ls-files --others --exclude-standard)
fi

# Parent directories of uploaded files, shallowest first, so sftp can create any
# that are new. A leading "-" tells sftp to carry on if the directory exists.
DIRS=()
if [[ ${#FILES[@]} -gt 0 ]]; then
  while IFS= read -r d; do DIRS+=("$d"); done < <(
    for f in "${FILES[@]}"; do
      d="$(dirname "$f")"
      while [[ "$d" != "." && "$d" != "/" ]]; do echo "$d"; d="$(dirname "$d")"; done
    done | sort -u | awk -F/ '{ print NF "\t" $0 }' | sort -n | cut -f2-
  )
fi

# ---------- summary ----------
bytes=0
if [[ ${#FILES[@]} -gt 0 ]]; then bytes=$(cat "${FILES[@]}" | wc -c | tr -d ' '); fi

echo "========================================="
echo " Deploying BajaWebsite"
echo " Host:   $NETID@$HOST"
echo " Remote: $REMOTE_DIR"
echo " Files:  ${#FILES[@]}, $((bytes / 1024)) KB, $BASE_DESC"
for f in ${FILES[@]+"${FILES[@]}"}; do echo "   + $f"; done
if [[ ${#HELD[@]} -gt 0 ]]; then
  echo " New files NOT sent (run 'git add <file>' to include them):"
  for f in "${HELD[@]}"; do echo "   ? $f"; done
fi
if [[ ${#DELETED[@]} -gt 0 ]]; then
  echo " Removed locally, left on the server (not deleted): ${#DELETED[@]} file(s)"
  for f in "${DELETED[@]}"; do echo "   - $f"; done
fi
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo " SKIPPED (quote or backslash in name, upload by hand):"
  for f in "${SKIPPED[@]}"; do echo "   ! $f"; done
fi
if ! git diff --quiet HEAD -- . 2>/dev/null; then
  echo " Note: includes uncommitted changes."
fi
echo "========================================="

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo
  echo "Nothing to upload; the live site is already current."
  exit 0
fi

if [[ "$DRY_RUN" == 1 ]]; then
  echo
  echo "Dry run: nothing uploaded, $MARKER unchanged."
  exit 0
fi

# ---------- upload ----------
# -b runs the commands as a batch that STOPS at the first failure (a bad cd,
# a failed put; lines starting with "-" are allowed to fail), instead of carrying on and scattering files in the wrong
# place. -b would normally also disable the password prompt; passing
# BatchMode=no first keeps it, because ssh honours the first value it sees.
BATCH="${TMPDIR:-/tmp}/baja-deploy.$$"
trap 'rm -f "$BATCH"' EXIT
{
  echo "cd \"${REMOTE_DIR}\""
  for d in ${DIRS[@]+"${DIRS[@]}"}; do echo "-mkdir \"$d\""; done
  for f in "${FILES[@]}"; do
    echo "put \"$f\" \"$f\""
    # "-" = keep going if chmod is refused. Files carried over in the Oct 2026
    # host migration belong to another account, so their mode can't be changed
    # (they're already world-readable). Files we create are ours and chmod works.
    # Either way the live check below catches a real 403.
    echo "-chmod 644 \"$f\""
  done
} > "$BATCH"

echo
echo "Connecting (you'll be asked for your password)..."
if ! sftp -o BatchMode=no -b "$BATCH" "${NETID}@${HOST}"; then
  echo
  echo "ERROR: Upload stopped partway. $MARKER was NOT updated, so the next run"
  echo "retries everything above. If the error was about '$REMOTE_DIR', the"
  echo "folder layout on $HOST differs: log in with"
  echo "  sftp ${NETID}@${HOST}"
  echo "and run 'pwd' and 'ls' to find it, then update REMOTE_DIR at the top of this script."
  exit 1
fi
echo "Upload complete."

# ---------- verify ----------
# Fetch each file back from the live site and compare bytes. A mismatch means
# the file isn't what the site is serving: a permissions problem (403), the
# upload landing outside the web root, or a cache that hasn't caught up.
echo
echo "Checking each file on the live site:"
FAILED=0
for f in "${FILES[@]}"; do
  [[ "$f" == ".htaccess" ]] && { echo "   --   $f (not publicly readable, skipped)"; continue; }
  url="${SITE_URL}/${f// /%20}"
  live="$(curl -sL --max-time 20 "$url" | shasum | cut -d' ' -f1 || true)"
  mine="$(shasum < "$f" | cut -d' ' -f1)"
  if [[ "$live" == "$mine" ]]; then
    echo "   ok   $f"
  else
    code="$(curl -sL -o /dev/null --max-time 20 -w '%{http_code}' "$url" || echo 000)"
    echo "   FAIL $f (HTTP $code, content differs)"
    FAILED=$((FAILED + 1))
  fi
done

echo
if [[ "$FAILED" -gt 0 ]]; then
  echo "WARNING: $FAILED file(s) don't match the live site. $MARKER was NOT updated,"
  echo "so the next run will resend them. HTTP 403 = permissions; 200 with different"
  echo "content = the upload went somewhere the site doesn't serve, or a cache."
  exit 1
fi

echo "$HEAD_SHA" > "$MARKER"
echo "Done. All ${#FILES[@]} file(s) verified live. Recorded $(git log -1 --format='%h' HEAD) as the last deploy."
