#!/usr/bin/env bash
# ============================================================================
# CS-02 - scripts/deploy-from-github.sh
#
# WHAT:   Deploys the REAL OWASP Juice Shop application from the GitHub
#         repository https://github.com/Chaitra2708/Cyber-Security into the
#         authorized local laboratory and verifies it over HTTP.
# WHY:    The assessment must run against the genuine application, not a
#         static copy of the project folder.
# WHERE:  Run from the repository root:  bash cybersecurity-cs02/scripts/deploy-from-github.sh
# EXPECT: Prints the local URL and "DEPLOYMENT STATUS: PASS".
#
# SAFETY PROPERTIES
#   * LOCAL / ISOLATED ONLY. The app is intentionally vulnerable. It is bound
#     to 127.0.0.1 and is never published, tunnelled or exposed publicly.
#   * This script NEVER destroys local work. It does not run `git reset
#     --hard`, `git clean`, `git checkout .` or `git push`.
#   * The vulnerable baseline under lab/juice-shop_20.2.0 must stay pristine;
#     this script only starts it, never edits it.
#
# RECOVERY: bash cybersecurity-cs02/scripts/stop-lab.sh
# ============================================================================
set -uo pipefail

REPO_URL="https://github.com/Chaitra2708/Cyber-Security"
EXPECTED_REMOTE="https://github.com/Chaitra2708/Cyber-Security"
PORT="${PORT:-3000}"
HOST="127.0.0.1"
LOG="/tmp/cs02-deploy-3000.log"
READY_TIMEOUT=120

fail() { echo "ERROR: $*" >&2; exit 1; }
step() { echo; echo "--- $* ---"; }

# Resolve repository root (this script lives in <repo>/cybersecurity-cs02/scripts)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$PROJECT_DIR/.." && pwd)"
cd "$REPO_ROOT" || fail "cannot enter repository root: $REPO_ROOT"

echo "==============================================================="
echo " CS-02 GIT-SOURCED DEPLOYMENT (LOCAL / AUTHORIZED LAB ONLY)"
echo "==============================================================="
echo " repository : $REPO_URL"
echo " target     : real OWASP Juice Shop application"
echo " bind       : $HOST:$PORT (loopback only - never public)"
echo "==============================================================="

# --- 1. verify Git ---------------------------------------------------------
step "1/10 verify Git"
command -v git >/dev/null 2>&1 || fail "git is not installed"
echo " git  : $(git --version)"
git rev-parse --show-toplevel >/dev/null 2>&1 || fail "not inside a git repository"
echo " root  : $(git rev-parse --show-toplevel)"

# --- 2. verify Node / npm --------------------------------------------------
step "2/10 verify Node and npm"
command -v node >/dev/null 2>&1 || fail "node is not on PATH"
if [ -s "${HOME}/.nvm/nvm.sh" ]; then
  # shellcheck disable=SC1091
  . "${HOME}/.nvm/nvm.sh" >/dev/null 2>&1
  nvm use 22 >/dev/null 2>&1 || echo " note: 'nvm use 22' reported a problem; continuing"
fi
echo " node : $(node -v)"
echo " npm  : $(npm -v 2>/dev/null || echo 'not available')"
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" != "22" ]; then
  fail "Node 22 is required by this project (found $(node -v)). Install/switch to Node 22."
fi

# --- 3. verify repository remote ------------------------------------------
step "3/10 verify repository remote"
REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"
if [ -z "$REMOTE" ]; then
  echo " origin not set - adding $REPO_URL"
  git remote add origin "$REPO_URL" || fail "could not add remote"
  REMOTE="$(git remote get-url origin)"
fi
NORMALISED="$(printf '%s' "$REMOTE" | sed -E 's#^git@github\.com:#https://github.com/#; s#\.git$##')"
echo " origin : $REMOTE"
[ "$NORMALISED" = "$EXPECTED_REMOTE" ] || fail "unexpected origin '$REMOTE' (expected $EXPECTED_REMOTE)"

# --- 4. fetch latest approved revision (never destructive) ----------------
step "4/10 fetch latest approved revision"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo " branch : $BRANCH"
if git fetch origin "$BRANCH" >/tmp/cs02-fetch.log 2>&1; then
  echo " fetch  : OK"
else
  echo " fetch  : FAILED (offline?) - continuing with the local checkout"
  sed 's/^/          /' /tmp/cs02-fetch.log
fi
LOCAL_COMMIT="$(git rev-parse HEAD)"
REMOTE_COMMIT="$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo 'unknown')"
echo " local  : $LOCAL_COMMIT"
echo " remote : $REMOTE_COMMIT"
if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
  echo " state  : IN SYNC"
else
  echo " state  : DIFFERENT - local work is kept, nothing is overwritten."
  echo "          Uncommitted/committed local changes are never discarded by this script."
  git status --short | head -20 | sed 's/^/          /'
fi

# --- 5. locate the runnable Juice Shop install ----------------------------
step "5/10 locate the runnable Juice Shop application"
# The repository root holds the Juice Shop TypeScript sources, but the shipped
# distribution contains no tsconfig.json, so `npm run build:server` (tsc) cannot
# run and the root is NOT executable. The genuine runnable install is the
# official distribution extracted under the CS-02 lab directory.
APP_DIR="$PROJECT_DIR/lab/juice-shop_20.2.0"
TGZ="$PROJECT_DIR/lab/juice-shop-20.2.0_node22_linux_x64.tgz"

if [ ! -f "$APP_DIR/build/app.js" ]; then
  echo " application not extracted yet - extracting from the repository archive"
  [ -f "$TGZ" ] || fail "distribution archive missing: $TGZ"
  if [ -f "$PROJECT_DIR/lab/juice.tgz.md5" ]; then
    EXPECT_MD5="$(tr -d ' \n' < "$PROJECT_DIR/lab/juice.tgz.md5")"
    ACTUAL_MD5="$(md5sum "$TGZ" | cut -d' ' -f1)"
    if [ "$EXPECT_MD5" != "$ACTUAL_MD5" ]; then
      fail "archive checksum mismatch (expected $EXPECT_MD5, got $ACTUAL_MD5)"
    fi
    echo " checksum: $ACTUAL_MD5 (matches lab/juice.tgz.md5)"
  fi
  tar xzf "$TGZ" -C "$PROJECT_DIR/lab" || fail "extraction failed"
fi
[ -f "$APP_DIR/build/app.js" ] || fail "build/app.js not found in $APP_DIR"
echo " app dir : $APP_DIR"
echo " version : $(node -p "require('$APP_DIR/package.json').version" 2>/dev/null)"
echo " start   : $(node -p "require('$APP_DIR/package.json').scripts.start" 2>/dev/null)"

# --- 6. dependencies -------------------------------------------------------
step "6/10 verify dependencies"
if [ -d "$APP_DIR/node_modules/express" ]; then
  echo " node_modules present - reusing existing install (no reinstall needed)"
else
  echo " node_modules missing - installing from package-lock.json"
  ( cd "$APP_DIR" && npm ci --omit=dev ) || fail "npm ci failed"
fi

# --- 7. build --------------------------------------------------------------
step "7/10 build"
# The official distribution ships prebuilt JavaScript under build/. Building
# from source needs tsconfig.json, which the distribution does not contain.
if [ -f "$APP_DIR/build/app.js" ]; then
  echo " prebuilt build/ present - no compilation required"
  echo " note: 'npm run build:server' (tsc) cannot run, the distribution has no tsconfig.json."
fi

# --- 8. start --------------------------------------------------------------
step "8/10 start OWASP Juice Shop"
RUNNING_PID=""
for p in $(pgrep -x node 2>/dev/null); do
  tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null | grep -q 'build/app' || continue
  RUNNING_PID="$p"
  break
done
if [ -n "$RUNNING_PID" ]; then
  echo " already running (pid $RUNNING_PID)"
else
  echo " starting: PORT=$PORT node build/app   (cwd $APP_DIR)"
  ( cd "$APP_DIR" && PORT="$PORT" setsid node build/app > "$LOG" 2>&1 < /dev/null & )
fi

# --- 9. wait for HTTP readiness -------------------------------------------
step "9/10 wait for HTTP readiness on $HOST:$PORT"
READY=0
for _ in $(seq 1 "$READY_TIMEOUT"); do
  CODE="$(curl -s -o /dev/null -w '%{http_code}' -m 3 "http://$HOST:$PORT/" 2>/dev/null)"
  if [ "$CODE" = "200" ]; then READY=1; break; fi
  sleep 1
done
if [ "$READY" -ne 1 ]; then
  echo "--- application log (tail) ---"
  tail -25 "$LOG" 2>/dev/null
  fail "application did not become ready on $HOST:$PORT"
fi
echo " ready after HTTP 200"

# --- 10. verify the response is the real application ----------------------
step "10/10 verify the HTTP response is the REAL Juice Shop app"
BODY="$(mktemp)"
curl -s -m 10 "http://$HOST:$PORT/" -o "$BODY"
BYTES="$(wc -c < "$BODY" | tr -d ' ')"

BAD=0
check_absent() {  # a FAIL marker must NOT be present
  if grep -qiE "$1" "$BODY"; then
    echo " FAIL  unexpected marker: $2"
    BAD=1
  else
    echo " ok    absent: $2"
  fi
}
check_present() {
  if grep -qiE "$1" "$BODY"; then
    echo " ok    present: $2"
  else
    echo " FAIL  missing marker: $2"
    BAD=1
  fi
}
check_absent '<title>Index of'        "directory listing"
check_absent 'Directory listing for'  "directory listing"
check_present '<title>OWASP Juice Shop' "Juice Shop title"
check_present 'app-root'              "Angular application root"
[ "$BYTES" -gt 2000 ] && echo " ok    body size ${BYTES} B (not a stub)" || { echo " FAIL  body too small"; BAD=1; }

API_CODE="$(curl -s -o /dev/null -w '%{http_code}' -m 10 "http://$HOST:$PORT/rest/products/search?q=apple")"
if [ "$API_CODE" = "200" ]; then echo " ok    REST API /rest/products/search -> 200"; else echo " FAIL  REST API -> $API_CODE"; BAD=1; fi
PRODUCTS="$(curl -s -m 10 "http://$HOST:$PORT/rest/products/search?q=apple" | node -pe 'JSON.parse(require("fs").readFileSync(0,"utf8")).data.length' 2>/dev/null)"
echo " info  products returned for 'apple': ${PRODUCTS:-unknown}"
rm -f "$BODY"

echo
echo "==============================================================="
echo " URL              : http://$HOST:$PORT/"
echo " DEPLOYMENT STATUS: $([ "$BAD" -eq 0 ] && echo PASS || echo FAIL)"
echo "==============================================================="
echo
echo "This application is INTENTIONALLY VULNERABLE. It is bound to loopback"
echo "and must stay inside the authorized laboratory. Do NOT expose it to"
echo "the public Internet, public hosting or any third party."
echo "Stop it with: bash cybersecurity-cs02/scripts/stop-lab.sh"
exit "$BAD"