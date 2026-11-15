#!/usr/bin/env bash
# Hand one scoped task to a free helper AI CLI and log its output.
# Usage: bash tools/ai-helpers/delegate.sh <opencode|codex|copilot|agy> "<task prompt>" [model]
#        bash tools/ai-helpers/delegate.sh check   (which helpers are reachable)
# Runs from the repo root. Output -> production/ai-helpers/logs/<timestamp>-<tool>.log
set -u
tool="${1:?tool: opencode|codex|copilot|agy|check}"; prompt="${2:-}"; model="${3:-}"
[ "$tool" = check ] || [ -n "$prompt" ] || { echo "prompt required"; exit 2; }
cd "$(dirname "$0")/../.." || exit 1
mkdir -p production/ai-helpers/logs
log="production/ai-helpers/logs/$(date +%Y%m%d-%H%M%S)-$tool.log"
preamble="You are a helper on the Soul Vessels Godot 4.7.2 GDScript project. Read AGENTS.md first and follow it. Only touch the files this task names. Do not commit, delete files, or change project.godot/export settings. End with a short summary: files changed, what you did, anything unsure.

TASK:
"
full="$preamble$prompt"
# Make the helpers findable even when this shell's PATH predates their install
# (Claude Code's Git Bash keeps the PATH it started with).
to_unix() { if command -v cygpath >/dev/null 2>&1; then cygpath -u "$1"; else printf '%s' "$1"; fi; }
for d in "${APPDATA:+$(to_unix "$APPDATA")/npm}" \
         "${LOCALAPPDATA:+$(to_unix "$LOCALAPPDATA")/agy/bin}" \
         "$HOME/AppData/Roaming/npm" "$HOME/AppData/Local/agy/bin"; do
  [ -n "$d" ] && [ -d "$d" ] && case ":$PATH:" in *":$d:"*) ;; *) PATH="$d:$PATH" ;; esac
done
export PATH

# `delegate.sh check` lists which helpers this shell can run.
if [ "$tool" = check ]; then
  for c in opencode codex copilot agy; do
    if p=$(command -v "$c" 2>/dev/null); then echo "OK       $c -> $p"; else echo "MISSING  $c"; fi
  done
  exit 0
fi
if ! command -v "$tool" >/dev/null 2>&1; then
  echo "[delegate] '$tool' not found. Run: bash tools/ai-helpers/delegate.sh check"; exit 127
fi

case "$tool" in
  opencode) if [ -n "$model" ]; then opencode run -m "$model" "$full"; else opencode run "$full"; fi ;;
  codex)    codex exec --full-auto "$full" ;;
  copilot)  copilot -p "$full" --allow-all-tools ;;
  agy)      agy -p "$full" ;;
  *) echo "unknown tool: $tool"; exit 2 ;;
esac 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
echo; echo "[delegate] exit=$status log=$log"; echo "[delegate] review with: git diff --stat && git diff"
exit "$status"
