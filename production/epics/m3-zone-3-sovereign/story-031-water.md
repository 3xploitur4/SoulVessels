# Story 031: Water

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum zone table (Zone 3 new mechanic: water levels), light-rune puzzle 3 (Tide:
freeze the water surface with Frost Binding at the right height, light the rune from the ice),
the Weeping Sovereign's arena (water rises 1.5 m in phase 2; Frost freezes it into platforms),
the Drowned Courtier (swims; freezes in water when hit with Frost).

## Acceptance Criteria

- [x] A room JSON `water` entry: a rectangle with a surface height; the surface can be raised or lowered over time by a trigger, an event or a boss phase.
- [x] The player in water: slower movement and a lower jump, no dodge roll, and they float up to the surface. All values live in `combat.json` or a new data file.
- [x] Frost Binding cast on or over water freezes a patch of the surface into a standing platform for a set time; the patch stays at the height the water had when it froze.
- [x] Water reads as water: a translucent surface with a moving shimmer and a splash on entry, built in code like the other placeholder materials.
- [x] Unit tests: rising surface height over time, buoyancy pushing up, a frozen patch keeping its height when the water moves, the patch melting after its time. Each seen failing first.

## Files

- `src/world/water.gd`, `src/world/room_builder.gd`, `src/player/player.gd`, `data/balance/combat.json`
- `tests/unit/world/water_test.gd`

---

## Completion

Decision D-040. Evidence: `production/qa/evidence/story-031-water/`. Files added:
`src/world/water.gd`, `src/world/water_surface.gdshader`, `tests/unit/world/water_test.gd`,
`tests/integration/world/water_swim_test.gd`, `tools/playtest/water_check.py`; SFX `splash`.
RoomManager builds a room's `water` entries (`RoomManager.water(id)` finds one); the bridge's
`water` command pours or raises a pool. The rising-water hook for the boss is `Water.rise_to()`.
