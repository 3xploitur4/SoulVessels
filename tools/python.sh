#!/usr/bin/env bash
# Runs the real Python 3.12 interpreter (the bare `python` on this PC is Microsoft's Store alias
# stub; see docs/design/decision-log.md D-009). Usage: bash tools/python.sh script.py [args]
PY="/c/Users/ACHRAF CHARKAM/AppData/Local/Programs/Python/Python312/python.exe"
if [ ! -x "$PY" ]; then
  PY="$(command -v python3.12 || command -v python3 || command -v python)"
fi
exec "$PY" "$@"
