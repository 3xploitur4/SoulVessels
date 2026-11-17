# Story 044: Boss 2: the Guardian Below, on a tilting elevator

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Ready · **Layer**: Feature · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum boss table: 8,000 HP, posture 900, phases at 65 % and 30 %. Posture builds
only on its fists (P1-P2) and core (P3). Its arena is a 24 m elevator that tilts 15 degrees in
P2, with rocks sliding every 6 s.

Bible: P1 seismic fist slams and a sweeping chest laser; P2 smashes the elevator chains (the tilt);
P3 exposes a glowing reactor core, +40 % attack speed, radial shockwaves. Drops: Heart of the
Guardian (Legendary), Greater Soul Shards x3, Caelan's Greatsword. Track 10.

Builds on the story-034 `Boss` base.

## Acceptance Criteria

- [ ] Hit zones: separate hurt rects for the fists and the core; only zone hits build posture, per phase.
- [ ] Its attacks in data, at least 2 parryable, 2 unblockable and 1 magic per phase: fist slams, the chest laser (a sweeping beam), and shockwaves in P3.
- [ ] P2 tilts the arena 15 degrees (story 043) and rocks slide down every 6 s as hazards.
- [ ] P3: the core opens, attack speed x1.4.
- [ ] Rewards on defeat: the Heart, 3 Greater Shards, the Greatsword unlock flag (used by story 050); the elevator then descends to the Starless Shore.
- [ ] Unit tests for hit-zone posture rules and the 2/2/1 attack rule; an integration fight through three phases; screenshots of each phase.

## Files

- `src/enemies/guardian_below.gd`, `data/balance/enemies/guardian_below.json`, `src/enemies/boss.gd` (hit zones)
- `tests/unit/enemies/guardian_test.gd`, `tests/integration/enemies/guardian_fight_test.gd`, `tools/playtest/guardian_check.py`
