#!/usr/bin/env bash
# Runs the in-repo test runner headless. Usage: bash tests/run_tests.sh [--integration] [--filter name]
# Exit codes: 0 all passed, 1 failures, 2 no tests ran or script errors.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT_BIN:-engine/godot/Godot_v4.7.2-stable_win64_console.exe}"
LOG="$(mktemp)"
# Import first so new class_name scripts are in the global class cache before -s loads the runner.
"$GODOT" --headless --path . --import >"$LOG.import" 2>&1 || { echo "tests: import failed"; tail -20 "$LOG.import"; exit 2; }
"$GODOT" --headless --path . -s res://tests/runner/test_runner.gd -- "$@" >"$LOG" 2>&1
code=$?
grep -E "^FAIL |^TESTS:|SCRIPT ERROR|Parse Error|USER ERROR|^ERROR" "$LOG"
if grep -qE "SCRIPT ERROR|Parse Error" "$LOG"; then
  echo "tests: script errors (see above)"; grep -nE -A2 "SCRIPT ERROR|Parse Error" "$LOG" | head -30; rm -f "$LOG"; exit 2
fi
rm -f "$LOG"
exit $code
