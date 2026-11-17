# Story 042: Cracked masonry gates and 5 secrets in Zones 1-3

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Integration · **Estimate**: M

## Context

**Design**: addendum gate table. Cracked masonry is an orange-veined wall or floor, opened by
Darius's Crushing Blow or Groundbreaker; it is used in Zone 4, with 5 secrets in Zones 1-3. Grid
code `K` exists and is sealed with a hint (story 023); z3_18's way down to Zone 4 is masonry.

## Acceptance Criteria

- [x] A masonry gate opens when a Crushing Blow or Groundbreaker hits it (a packet tag the gate reads); it crumbles with a sound and dust, and is saved as opened.
- [x] Masonry floors drop the player to the room below when broken (one floor case at least).
- [x] z3_18's masonry opens the way to Zone 4 (the wall breaks now; the exit beyond it is built with Zone 4 in story 049).
- [x] 5 masonry secrets across Zones 1-3, each with a reward; placed so they read as cracked walls from the first visit.
- [x] Integration test: a Crushing Blow opens a wall and it stays open on return; other attacks do nothing.
- [x] Screenshots before and after each kind.

## Files

- `src/world/` (masonry gate), `data/world/zone1.json`, `zone2.json`, `tools/world/build_zone3.py`
- `tests/integration/world/masonry_test.gd`

---

## Completion

Evidence: `production/qa/evidence/story-042-masonry/`. New: `src/world/masonry_wall.gd` (a target in the
combat world that only `breaks_masonry` packets open; saved as "<room>:masonry:<i>"), registered as a room
feature; the five secrets in z1_06, z1_14, z2_05, z2_14 and z3_12.
