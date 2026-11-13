# Story 006: Intruder body — run, jump, air-dash, dodge i-frames, stamina

> **Epic**: M1 — Combat Sandbox · **Status**: Done (2026-11-13) · **Layer**: Core · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Core combat systems" (Stamina, Dodge timing, Exhausted), "Vessel stats"
(move speed per Vessel: Caelan 6.0, Nyra 7.5 m/s); bible section 1 (air-dash/dodge 0.25 s i-frames).

## Acceptance Criteria

- [ ] `Player` (`CharacterBody3D`, Jolt) moves on X only, z locked at 0; horizontal speed = active Vessel `move_speed`; gravity tuned for a 2.2 m jump apex in about 0.45 s (values in `combat.json` under `movement`); coyote time 0.08 s and jump buffer 0.1 s.
- [ ] Ground dodge: 0.45 s roll, i-frames from 0.05 s to 0.30 s (0.25 s), cancel window into attack in the last 0.15 s, costs 20 stamina. Nyra's dodge is a shorter flip costing 15 (per-Vessel `dodge` block).
- [ ] Air-dash: one per airborne period, 25 stamina, 0.25 s i-frames, horizontal only.
- [ ] `Stamina` component: 100 max per Vessel, regen 40/s after 0.6 s idle, Exhausted (no dodge) 1.5 s at 0; inactive Vessels regen at 2x.
- [ ] Facing flips the Vessel visual; movement reads `InputRouter` axes (joystick, stick or keys).
- [ ] Unit tests: dodge i-frame window math, stamina regen timing, exhausted lock; a headless integration run moves the player 10 m right in 2 s at Caelan speed (plus or minus 0.3 m).

## Files

- `src/player/player.tscn`, `src/player/player.gd`, `src/player/movement_state_machine.gd`, `src/combat/stamina.gd`
- `tests/unit/player/stamina_test.gd`, `tests/unit/player/dodge_window_test.gd`, `tests/integration/player/movement_test.gd`

## Dependencies

- Depends on: 004, 005, `../m0-setup/story-002-input-map.md` · Unlocks: 007, 008

---

## Completion

Scenes are built in code (no .tscn per body), so tests can build any piece alone. Timed actions live in `src/combat/player_action.gd`. Integration: tests/integration/player/movement_test.gd (run, 2.2 m jump, 15-frame i-frames, Exhausted).
