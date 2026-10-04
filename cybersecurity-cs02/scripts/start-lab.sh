#!/usr/bin/env bash
# ============================================================================
# CS-02 - scripts/start-lab.sh
# Starts the OWASP Juice Shop laboratory application and verifies it.
#
# WHAT:   Launches Juice Shop (Node.js) bound to 127.0.0.1:3000, then checks
#         process, port and HTTP response.
# WHY:    Reproducible lab startup required by the CS-02 specification.
# WHERE:  Run on the lab host:  bash scripts/start-lab.sh
# EXPECT: "LAB STARTED" plus the URL http://127.0.0.1:3000
# ERROR:  "START FAILED" (see log path printed).
# RECOVERY: bash scripts/stop-lab.sh && bash scripts/start-lab.sh
# ============================================================================
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/lab/juice-shop_20.2.0"
LOG="$ROOT/evidence/logs/juice-shop-startup.log"
URL="http://127.0.0.1:3000"

mkdir -p "$ROOT/evidence/logs"

# --- already running? ------------------------------------------------------
if curl -s -m 3 "$URL/" | grep -qi "OWASP Juice Shop"; then
  echo "ALREADY RUNNING: $URL"
  bash "$ROOT/scripts/check-lab.sh"
  exit 0
fi

# --- locate Node 22 (Juice Shop requires engine major 22) -------------------
if [ -s "$HOME/.nvm/nvm.sh" ]; then
  # shellcheck disable=SC1090
  . "$HOME/.nvm/nvm.sh"
  nvm use 22 >/dev/null 2>&1
fi
NODE_VER="$(node -v 2>/dev/null || echo missing)"
case "$NODE_VER" in
  v22*|v2[3-9]*) : ;;
  *) echo "ERROR: Node 22+ required, found: $NODE_VER"; exit 1 ;;
esac

if [ ! -f "$APP_DIR/build/app.js" ] && [ ! -d "$APP_DIR/build" ]; then
  echo "ERROR: Juice Shop not found at $APP_DIR"
  echo "       Download: juice-shop-20.2.0_node22_linux_x64.tgz (official release)"
  exit 1
fi

# --- launch detached (setsid survives the calling shell) --------------------
cd "$APP_DIR" || exit 1
setsid nohup node build/app > "$LOG" 2>&1 < /dev/null &
disown 2>/dev/null || true

# --- wait for readiness ------------------------------------------------------
echo "Starting Juice Shop ..."
for i in $(seq 1 30); do
  sleep 1
  if curl -s -m 2 "$URL/" | grep -qi "OWASP Juice Shop"; then
    echo "LAB STARTED: $URL"
    bash "$ROOT/scripts/check-lab.sh"
    exit 0
  fi
done

echo "START FAILED: app did not answer within 30s. Log:"
tail -20 "$LOG"
exit 1
