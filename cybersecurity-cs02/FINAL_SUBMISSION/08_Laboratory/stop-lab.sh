#!/usr/bin/env bash
# ============================================================================
# CS-02 - scripts/stop-lab.sh
# Stops the OWASP Juice Shop laboratory application.
#
# WHAT:   Sends SIGTERM to the Juice Shop node process only.
# WHY:    Clean shutdown so port 3000 is released and evidence logs flush.
# WHERE:  Run on the lab host:  bash scripts/stop-lab.sh
# EXPECT: "LAB STOPPED" and port 3000 no longer listening.
# ERROR:  "NOT RUNNING" (harmless) or "STOP FAILED".
# RECOVERY: pkill -f "node build/app"   (manual fallback)
# ============================================================================
set -u

URL="http://127.0.0.1:3000"

# Match ONLY a real `node build/app` process. A bare `pgrep -f 'node build/app'`
# also matches any shell whose command line merely mentions that string, and
# would make this script SIGTERM unrelated processes.
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

PIDS="$(app_pids | tr '\n' ' ')"
if [ -z "${PIDS// /}" ]; then
  echo "NOT RUNNING: no Juice Shop process found."
  exit 0
fi

echo "Stopping Juice Shop (pid(s): $(echo $PIDS | tr '\n' ' ')) ..."
# shellcheck disable=SC2086
kill $PIDS 2>/dev/null || true

for i in $(seq 1 15); do
  sleep 1
  if [ -z "$(app_pids | tr -d '[:space:]')" ]; then
    if ss -tln 2>/dev/null | grep -q ':3000'; then
      continue
    fi
    echo "LAB STOPPED: port 3000 released."
    exit 0
  fi
done

echo "STOP FAILED: process still alive. Manual: pkill -x -f 'node build/app'"
exit 1
