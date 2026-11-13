#!/usr/bin/env bash
# Smoke test: import, then boot the project headless for a few seconds and fail on any script
# error or a missing boot marker. Exit 0 = the build starts clean.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT_BIN:-engine/godot/Godot_v4.7.2-stable_win64_console.exe}"
LOG="${1:-$(mktemp)}"
"$GODOT" --headless --path . --import >"$LOG.import" 2>&1 || { echo "smoke: import failed"; tail -20 "$LOG.import"; exit 1; }
"$GODOT" --headless --path . --quit-after 60 >"$LOG" 2>&1
code=$?
if grep -qE "SCRIPT ERROR|Parse Error|ERROR: Failed to load script|USER ERROR" "$LOG"; then
  echo "smoke: script errors"; grep -nE "SCRIPT ERROR|Parse Error|ERROR|USER ERROR" "$LOG" | head -20; exit 1
fi
if ! grep -q "SOULVESSELS_BOOT_OK" "$LOG"; then
  echo "smoke: boot marker missing (exit $code)"; tail -20 "$LOG"; exit 1
fi
echo "smoke: ok ($(grep SOULVESSELS_BOOT_OK "$LOG"))"
