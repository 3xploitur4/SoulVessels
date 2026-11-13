# Story 013: Debug HUD, playtest bridge, evidence and sandbox APK

> **Epic**: M1 — Combat Sandbox · **Status**: Ready · **Layer**: Presentation · **Type**: Integration · **Estimate**: M

## Context

User brief: "debug HUD with FPS", "use the playtest bridge in tools/gamedev-kit/bridge/bridge.gd
so you can test the game yourself". Milestone rule: ends with an installable Android build.

## Acceptance Criteria

- [ ] Debug HUD (F3 / `debug_hud`): FPS, frame ms, draw calls, primitives, pipeline compilations, player state, active Vessel, stamina/posture/gauge numbers, enemy count, music state.
- [ ] `DebugBridge` autoload wraps `Bridge` (copied to `src/debug/bridge.gd`) with `run_command`: `ping`, `get_state` (player pos/HP/stamina/gauge/vessel/state, enemies list, music state, fps), `get_value`/`set_value` (Balance keys), `sim_input(action, seconds)`, `screenshot(path)`, `window_size`, `spawn(enemy_id, x)`, `set_vessel(id)`, `teleport(x,y)`, `kill_all`, `quit`. Port from `BRIDGE_PORT` (default 9177), enabled only in debug builds or with `--bridge`.
- [ ] `tools/playtest/drive.py` (uses `tools/mcp/bridge_client.py`) launches the sandbox windowed, waits for `BRIDGE_READY`, runs a scripted fight (spawn 3 Crawlers, attack, dodge, swap, parry a Warden), saves screenshots to `production/qa/evidence/story-013-sandbox/` and prints the final state.
- [ ] `bash tools/build/export_android.sh` exports the sandbox APK; the APK is listed in `production/qa/smoke-2026-11-13.md`.
- [ ] Evidence: retained screenshots of the fight, the debug HUD visible in one.

## Files

- `src/debug/debug_hud.gd/.tscn`, `src/debug/bridge.gd`, `src/debug/debug_bridge.gd`, `tools/playtest/drive.py`

## Dependencies

- Depends on: 009, 010, 011, 012, `../m0-setup/story-003-android-export.md` · Unlocks: M2
