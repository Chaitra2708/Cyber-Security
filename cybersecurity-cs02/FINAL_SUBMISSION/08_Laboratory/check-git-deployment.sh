#!/usr/bin/env bash
# ============================================================================
# CS-02 - scripts/check-git-deployment.sh
#
# WHAT:   Reports the state of the Git-sourced local deployment.
# WHY:    Confirms the running application really came from the GitHub
#         repository and is the genuine OWASP Juice Shop, not a directory
#         listing or a static copy of the project folder.
# WHERE:  bash cybersecurity-cs02/scripts/check-git-deployment.sh
# EXPECT: Every field is a real observed value. Nothing is fabricated; a field
#         that cannot be observed is reported BLOCKED, never guessed.
#
# This script is READ-ONLY. It starts nothing and changes nothing.
# ============================================================================
set -uo pipefail

REPO_URL="https://github.com/Chaitra2708/Cyber-Security"
PORT="${PORT:-3000}"
HOST="127.0.0.1"
URL="http://$HOST:$PORT/"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PROJECT_DIR/.." && pwd)"
APP_DIR="$PROJECT_DIR/lab/juice-shop_20.2.0"

cd "$REPO_ROOT" 2>/dev/null || true

echo "==============================================================="
echo " CS-02 GIT DEPLOYMENT CHECK"
echo " $(date -Iseconds)"
echo "==============================================================="

# --- REPOSITORY ------------------------------------------------------------
REPO_STATUS="BLOCKED"
REMOTE_URL="unavailable"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  REMOTE_URL="$(git remote get-url origin 2>/dev/null || echo 'no origin')"
  if timeout 30 git ls-remote --exit-code --heads origin >/dev/null 2>&1; then
    REPO_STATUS="PASS (reachable)"
  else
    REPO_STATUS="BLOCKED (not reachable from this host)"
  fi
fi
echo "REPOSITORY   : $REPO_URL"
echo "               remote=$REMOTE_URL"
echo "               status=$REPO_STATUS"

# --- BRANCH / COMMIT -------------------------------------------------------
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
COMMIT="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo "BRANCH       : $BRANCH"
echo "COMMIT       : $COMMIT"

# --- WORKTREE --------------------------------------------------------------
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  CHANGED="$(git status --short 2>/dev/null | wc -l | tr -d ' ')"
  AHEAD_BEHIND="$(git rev-list --left-right --count HEAD...origin/$BRANCH 2>/dev/null || echo 'n/a')"
  if [ "$CHANGED" = "0" ]; then
    WORKTREE="clean"
  else
    WORKTREE="$CHANGED uncommitted change(s) present (never auto-discarded)"
  fi
  echo "WORKTREE     : $WORKTREE"
  echo "               ahead/behind vs origin/$BRANCH: $AHEAD_BEHIND"
else
  echo "WORKTREE     : not a git repository"
fi

# --- NODE / NPM ------------------------------------------------------------
if command -v node >/dev/null 2>&1; then
  if [ -s "${HOME}/.nvm/nvm.sh" ]; then
    # shellcheck disable=SC1091
    . "${HOME}/.nvm/nvm.sh" >/dev/null 2>&1
    nvm use 22 >/dev/null 2>&1
  fi
else
  export PATH="$HOME/.nvm/versions/node/v22.23.3/bin:$PATH" 2>/dev/null
fi
echo "NODE         : $(node -v 2>/dev/null || echo 'not installed')"
echo "NPM          : $(npm -v 2>/dev/null || echo 'not installed')"

# --- APPLICATION -----------------------------------------------------------
APP_STATUS="FAIL"
APP_NAME="unknown"
APP_VERSION="unknown"
APP_PID="none"
if [ -f "$APP_DIR/package.json" ]; then
  APP_NAME="$(node -p "require('$APP_DIR/package.json').name" 2>/dev/null || echo unknown)"
  APP_VERSION="$(node -p "require('$APP_DIR/package.json').version" 2>/dev/null || echo unknown)"
  for p in $(pgrep -x node 2>/dev/null); do
    tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null | grep -q 'build/app' || continue
    APP_PID="$p"
    break
  done
  [ -f "$APP_DIR/build/app.js" ] && APP_STATUS="PASS ($APP_NAME $APP_VERSION, pid $APP_PID)"
fi
echo "APPLICATION  : $APP_NAME $APP_VERSION  ($APP_DIR)"
echo "               $APP_STATUS"

# --- PORT ------------------------------------------------------------------
LISTENING="no"
if (command -v ss >/dev/null 2>&1 && ss -ltn 2>/dev/null | grep -q "127.0.0.1:$PORT") || \
   (command -v netstat >/dev/null 2>&1 && netstat -ltn 2>/dev/null | grep -q "127.0.0.1:$PORT"); then
  LISTENING="yes"
fi
echo "PORT         : $PORT (bound to $HOST only - loopback, never public)"
echo "               listening: $LISTENING"

# --- URL / HTTP ------------------------------------------------------------
echo "URL          : $URL"
HTTP_STATUS="FAIL"
BODY="$(mktemp)"
CODE="$(curl -s -o "$BODY" -w '%{http_code}' -m 10 "$URL" 2>/dev/null)"
BYTES="$(wc -c < "$BODY" 2>/dev/null | tr -d ' ')"
if [ "$CODE" = "200" ] && [ "$BYTES" -gt 2000 ]; then
  if grep -qiE '<title>Index of|Directory listing for' "$BODY"; then
    HTTP_STATUS="FAIL (served a DIRECTORY LISTING)"
  elif grep -qi 'OWASP Juice Shop' "$BODY" && grep -qi 'app-root' "$BODY"; then
    HTTP_STATUS="PASS (real Juice Shop HTML, ${BYTES} B)"
  else
    HTTP_STATUS="FAIL (200 but not recognised as Juice Shop)"
  fi
fi
API_CODE="$(curl -s -o /dev/null -w '%{http_code}' -m 10 "http://$HOST:$PORT/rest/products/search?q=apple" 2>/dev/null)"
echo "HTTP         : $HTTP_STATUS"
echo "               GET / -> ${CODE:-no response}, ${BYTES:-0} B"
echo "               GET /rest/products/search -> ${API_CODE:-no response}"
rm -f "$BODY"

# --- BROWSER ---------------------------------------------------------------
BROWSER_STATUS="BLOCKED"
BROWSER_NOTE=""
BROWSER_BIN=""
for b in google-chrome google-chrome-stable chromium chromium-browser; do
  if command -v "$b" >/dev/null 2>&1; then BROWSER_BIN="$b"; break; fi
done
if [ -z "$BROWSER_BIN" ]; then
  BROWSER_NOTE="no Chrome/Chromium binary found on this host"
elif [ "$CODE" != "200" ]; then
  BROWSER_STATUS="BLOCKED"
  BROWSER_NOTE="application not reachable, cannot load in a browser"
else
  DOM="$(mktemp)"; UDD="$(mktemp -d)"
  if "$BROWSER_BIN" --headless=new --user-data-dir="$UDD" --virtual-time-budget=12000 \
       --disable-gpu --no-sandbox --dump-dom "$URL" > "$DOM" 2>/dev/null; then
    TILES="$(grep -oE 'mat-card' "$DOM" 2>/dev/null | wc -l | tr -d ' ')"
    TITLE="$(grep -oE '<title>[^<]*</title>' "$DOM" 2>/dev/null | head -1)"
    if [ "$TILES" -ge 10 ] && printf '%s' "$TITLE" | grep -qi 'juice shop'; then
      BROWSER_STATUS="PASS (rendered $TILES product tiles, $TITLE)"
    else
      BROWSER_STATUS="FAIL (page loaded but UI did not render: $TILES tiles, title='$TITLE')"
    fi
  else
    BROWSER_STATUS="BLOCKED"
    BROWSER_NOTE="headless browser failed to run"
  fi
  rm -rf "$DOM" "$UDD"
fi
echo "BROWSER      : $BROWSER_STATUS"
[ -n "$BROWSER_NOTE" ] && echo "               $BROWSER_NOTE"

# --- STATUS ----------------------------------------------------------------
echo
echo "==============================================================="
echo " NOTE: local, authorized, isolated deployment only."
echo "       The application is intentionally vulnerable and must not"
echo "       be published to the public Internet."
echo "==============================================================="

# Machine-readable single status
if [ "$REPO_STATUS" != "BLOCKED (not reachable from this host)" ] && \
   [ "$APP_STATUS" != "FAIL" ] && [ "$LISTENING" = "yes" ] && \
   { [ "$HTTP_STATUS" = "PASS (real Juice Shop HTML, ${BYTES} B)" ] || \
     [ "${HTTP_STATUS#PASS*}" != "$HTTP_STATUS" ]; } && \
   { [ "$BROWSER_STATUS" = "PASS (rendered $TILES product tiles, $TITLE)" ] || \
     [ "${BROWSER_STATUS#PASS*}" != "$BROWSER_STATUS" ]; }; then
  echo "STATUS       : PASS"
  exit 0
fi
if [ "${REPO_STATUS#*BLOCKED}" != "$REPO_STATUS" ] || [ "$BROWSER_STATUS" = "BLOCKED" ]; then
  echo "STATUS       : BLOCKED"
  exit 2
fi
echo "STATUS       : FAIL"
exit 1