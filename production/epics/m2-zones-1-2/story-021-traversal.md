# Story 021: Traversal: wall-jump, bounce mushrooms, one-way platforms, void falls

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum Zone 2: vertical climbing, bounce mushrooms, wall-jump. Decision D-029.

## Acceptance Criteria

- [x] Wall slide (capped fall speed) and wall-jump (kick away, short input lock) from data; a wall-jump resets the air-dash.
- [x] Bounce mushroom: landing on its cap launches the player to a data height; squash animation and sound.
- [x] One-way platforms: pass up through, stand on top, drop down with down + jump.
- [x] Falling out of the room costs a data share of max HP and returns you to the last safe ground (death if that kills).
- [x] Integration tests: wall-jump climbs a 2-wall shaft; mushroom apex matches data; one-way pass and drop.

## Files

- `src/player/player.gd`, `src/world/bounce_mushroom.gd`, `data/balance/combat.json` (`traversal`)
- `tests/integration/player/traversal_test.gd`

---

## Completion

Decision D-029. Wall slide has its own braced pose on the painted sprites. Evidence: `production/qa/evidence/story-021-traversal/`.
