# Story 032: Light-rune doors and puzzles

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum gate table (light-rune door: dark rune circle, opened by Seris's Arcane
Bolt; Zone 3, plus 3 secrets in Zones 1–2) and "Light-rune puzzles (Zone 3, 6 total)":
1. Sequence: light runes in mural order (3, 4, then 5 runes).
2. Reflection: bounce a Watcher beam or Arcane Bolt off rotatable mirror-shields (Caelan can carry one).
3. Tide: freeze the water surface with Frost Binding at the right height and light the rune from the ice.
The final puzzle opens the throne room and combines all three.

Needs story 030 (Arcane Bolt) and story 031 (water).

## Acceptance Criteria

- [x] A rune that lights when an Arcane Bolt hits it; a door that opens when its runes are lit. State is saved per room, as the M2 gates are.
- [x] Sequence puzzle: runes must be lit in the order the mural shows; a wrong rune puts them all out with a clear sound and flash.
- [x] Mirror-shield: interact to rotate it in 45° steps; a bolt that hits it bounces off at the mirrored angle. Caelan can pick one up and set it down elsewhere. (Watcher beams: deferred, D-041.)
- [x] Tide puzzle: a rune placed above the reach of a normal jump, reachable only from frozen water at the right height.
- [x] The bounce angle is a pure function and unit-tested; the sequence check is unit-tested; an integration test solves one puzzle of each kind through the room loader.
- [x] 3 light-rune secret doors are added to Zones 1–2, each holding a reward.
- [x] Screenshots of each puzzle unsolved and solved.

## Files

- `src/world/light_rune.gd`, `src/world/mirror_shield.gd`, `src/world/ward_math.gd` (reflection), `src/world/room_builder.gd`
- `data/world/zone1.json`, `zone2.json`
- `tests/unit/world/light_rune_test.gd`, `tests/integration/world/rune_puzzles_test.gd`

---

## Completion

Decision D-041. Evidence: `production/qa/evidence/story-032-light-runes/`. Files added:
`src/world/rune_sequence.gd`, `rune_puzzle.gd`, `mirror_shield.gd`, the two test files and
`tools/playtest/rune_check.py`; `WardMath.mirror_reflect`; SFX `rune_lit` and `rune_wrong`. Bolts now
stop at rock and at closed gates (`RoomManager.solid_rects`). Bridge commands `mirror` and `runes`.
