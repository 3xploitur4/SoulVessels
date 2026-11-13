# Story 021: Traversal: wall-jump, bounce mushrooms, one-way platforms, void falls

> **Epic**: M2 — Zones 1–2 · **Status**: In progress · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum Zone 2: vertical climbing, bounce mushrooms, wall-jump. Decision D-029.

## Acceptance Criteria

- [ ] Wall slide (capped fall speed) and wall-jump (kick away, short input lock) from data; a wall-jump resets the air-dash.
- [ ] Bounce mushroom: landing on its cap launches the player to a data height; squash animation and sound.
- [ ] One-way platforms: pass up through, stand on top, drop down with down + jump.
- [ ] Falling out of the room costs a data share of max HP and returns you to the last safe ground (death if that kills).
- [ ] Integration tests: wall-jump climbs a 2-wall shaft; mushroom apex matches data; one-way pass and drop.

## Files

- `src/player/player.gd`, `src/world/bounce_mushroom.gd`, `data/balance/combat.json` (`traversal`)
- `tests/integration/player/traversal_test.gd`
