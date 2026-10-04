#!/usr/bin/env bash
# ============================================================================
# CS-02 - scripts/check-lab.sh
# Laboratory health gate. Prints "LAB STATUS: PASS" ONLY if everything works.
#
# WHAT:   Verifies process, port, HTTP page, frontend bundle, REST API,
#         storage file, and network isolation.
# WHY:    The specification forbids claiming success without proof.
# WHERE:  Run on the lab host:  bash scripts/check-lab.sh
# EXPECT: "LAB STATUS: PASS" (exit 0) when all checks succeed.
# ERROR:  "LAB STATUS: FAIL" (exit 1) with each failed check listed.
# RECOVERY: bash scripts/start-lab.sh  then re-run this check.
# ============================================================================
set -u

URL="http://127.0.0.1:3000"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/lab/juice-shop_20.2.0"
FAIL=0

# Match ONLY a real `node build/app` process (see stop-lab.sh for why a bare
# `pgrep -f` is unsafe: it also matches shells that merely mention the string).
app_pids() {
  local pid exe argv
  for pid in $(pgrep -x node 2>/dev/null || true); do
    exe="$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)"
    [ "$(basename "${exe:-/nonexistent}")" = "node" ] || continue
    argv="$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)"
    case "$argv" in
      *node\ build/app*) printf '%s\n' "$pid" ;;
    esac
  done
}

check() {  # check <label> <command...>
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf "  [PASS] %s\n" "$label"
  else
    printf "  [FAIL] %s\n" "$label"
    FAIL=1
  fi
}

echo "================================================"
echo " CS-02 LABORATORY HEALTH CHECK"
echo " $(date -Iseconds)"
echo "================================================"

echo "Checks:"
check "Application process running (node build/app)" \
  app_pids
check "Process runs from lab dir (not a stale path)" \
  bash -c "readlink /proc/\$(pgrep -x node | while read p; do tr '\\0' ' ' < /proc/\$p/cmdline 2>/dev/null | grep -q 'build/app' && echo \$p; done | head -1)/cwd | grep -q '$APP_DIR'"
check "Port 3000 listening" \
  bash -c "ss -tln | grep -q ':3000'"
check "HTTP 200 from $URL" \
  bash -c "curl -s -m 5 -o /dev/null -w '%{http_code}' '$URL/' | grep -q 200"
check "Page is OWASP Juice Shop (not a directory listing)" \
  bash -c "curl -s -m 5 '$URL/' | grep -qi '<app-root'"
check "Response is NOT a source/directory listing" \
  bash -c "! curl -s -m 5 '$URL/' | grep -qiE 'Index of /|Directory listing for'"
check "Frontend bundle served (main.js)" \
  bash -c "curl -s -m 8 -o /dev/null -w '%{http_code}' '$URL/main.js' | grep -q 200"
check "Backend REST API answers (/rest/user/whoami)" \
  bash -c "curl -s -m 5 '$URL/rest/user/whoami' | grep -q 'user'"
check "Application storage present (SQLite)" \
  test -s "$APP_DIR/data/juiceshop.sqlite"

# Isolation: app must NOT be reachable via the LAN IP.
# Pick the first non-loopback IPv4 (127.x.x.x is loopback, not a LAN face).
LAN_IP="$(ip -4 addr show 2>/dev/null | awk '/inet / && $2 !~ /^127\./ {split($2,a,"/"); print a[1]; exit}')"
if [ -n "$LAN_IP" ]; then
  if curl -s -m 3 -o /dev/null "http://$LAN_IP:3000/" 2>/dev/null; then
    printf "  [FAIL] Isolation: reachable via LAN IP %s (should be blocked)\n" "$LAN_IP"
    FAIL=1
  else
    printf "  [PASS] Isolation: LAN IP %s blocked (loopback only)\n" "$LAN_IP"
  fi
else
  printf "  [PASS] Isolation: no LAN interface (loopback only)\n"
fi

echo "------------------------------------------------"
if [ "$FAIL" -eq 0 ]; then
  echo " Application URL : $URL"
  echo " LAN IP (blocked): ${LAN_IP:-none}"
  echo "LAB STATUS: PASS"
  echo "================================================"
  exit 0
else
  echo "LAB STATUS: FAIL"
  echo " Recovery: bash scripts/start-lab.sh"
  echo "================================================"
  exit 1
fi
