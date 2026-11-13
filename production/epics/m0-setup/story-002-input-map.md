# Story 002: Input map and input router

> **Epic**: M0 — Setup
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Last Updated**: 2026-11-13

## Context

**Design**: addendum §"UI, controls and localisation" (gamepad table; "controller input hides
touch UI; touch brings it back"); bible §1 Controls. **Decision**: D-010 (keyboard layer).

## Acceptance Criteria

- [ ] Input actions exist: `move_left`, `move_right`, `move_up`, `move_down`, `jump`, `attack`, `dodge`, `ability_1`, `ability_2`, `ultimate`, `swap_prev`, `swap_next`, `flask`, `pause`, `map`, `debug_hud`.
- [ ] Gamepad bindings match the addendum table (X/A/B/Y/RT, LT+RT ultimate via chord, LB/RB, D-pad up). Keyboard bindings per D-010.
- [ ] `InputRouter` (autoload-free node under Main) emits `device_changed(kind)` with `touch` or `gamepad` when the last meaningful input source changes; touch UI visibility follows it.
- [ ] `ultimate` fires when LT and RT are both held (chord), tested in `tests/unit/input/input_router_test.gd`.

## Files

- `project.godot` (`[input]` section), `src/core/input_router.gd`, `tests/unit/input/input_router_test.gd`

## Test Evidence

**Story Type**: Logic. **Required**: `tests/unit/input/input_router_test.gd` passes under `tests/run_tests.sh`.

## Dependencies

- Depends on: `story-001-godot-project-scaffold.md`
- Unlocks: M1 stories 006, 011
