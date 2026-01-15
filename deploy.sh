#!/usr/bin/env bash
set -euo pipefail

# ================= CONFIG =================
HOST="uploads.courses2.cit.cornell.edu"
REMOTE_DIR="coursewww/baja.mae.cornell.edu/htdocs"
SITE_URL="https://baja.mae.cornell.edu"
NETID="rp665"
# =========================================

# Ensure we're running from the git repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "ERROR: Not inside the BajaWebsite git repo."
  exit 1
fi
cd "$REPO_ROOT"

# Find all HTML files in repo root (not recursive)
HTML_FILES=(*.html)

if [[ "${HTML_FILES[0]}" == "*.html" ]]; then
  echo "ERROR: No HTML files found in repo root."
  exit 1
fi

echo "========================================="
echo " Deploying BajaWebsite"
echo " Repo:   $REPO_ROOT"
echo " User:   $NETID"
echo " Host:   $HOST"
echo " Remote: $REMOTE_DIR"
echo " Files:"
for f in "${HTML_FILES[@]}"; do
  echo "   - $f"
done
echo "========================================="
echo

# Upload all HTML files
sftp "${NETID}@${HOST}" <<EOF
cd ${REMOTE_DIR}
$(for f in "${HTML_FILES[@]}"; do echo "put ${f}"; done)
ls -l ${HTML_FILES[*]}
exit
EOF

echo
echo "Upload complete."
echo

# Verify one canonical page
echo "Live site check (/apply):"
curl -IL "${SITE_URL}/apply" | egrep -i 'HTTP/|server:|last-modified:|content-length:|location:' || true

echo
echo "Done."
echo "Tip: verify content:"
echo "  curl -sL ${SITE_URL}/apply | head"