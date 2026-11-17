# Story 045: Boss 3: the Abyssal Leviathan, twelve eyes on a scrolling shore

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum boss table: 12,000 HP, posture 1,200, phases at 65 % and 30 %. It has 12
eyes of 300 HP each; every 3 destroyed gives a 5 s stagger. Its arena is a 40 m scrolling
shoreline. Narrative 5: the Foundation's jailer; its death tears the rift open.

Bible:
- P1: emerges from black water with tail-whips and lunge bites.
- P2: plunges the arena into darkness, with only its 12 glowing eyes visible before blindside strikes.
- P3: tears open dimensional rifts firing energy beams, and sonic roars.

Drops: Pure Soul Matrix, Abyssal Scale, Primeval Truth (all Legendary). Track 13.

## Acceptance Criteria

- [x] Twelve eye targets, each with its own 300 HP and hurt rect; every 3 destroyed staggers the Leviathan 5 s (at 2x damage, like other boss breaks).
- [x] The shoreline: the arena is 40 m and the Leviathan dives and resurfaces near the player every 14 s within it (the camera follows the player as usual).
- [x] P2 darkness (story 043) with only the eyes lit; the blindside strikes still telegraph by sound and icon.
- [x] P3 rift beams and roars; its attack set meets the 2/2/1 rule per phase.
- [x] Defeat: the three Legendaries, the flag that ends Darius's distrust, and the rift tearing open (the event that starts story 047).
- [x] Unit tests: eye damage and the stagger every 3, the 2/2/1 rule; an integration fight; screenshots of each phase.

## Files

- `src/enemies/abyssal_leviathan.gd`, `data/balance/enemies/abyssal_leviathan.json`
- `tests/unit/enemies/leviathan_test.gd`, `tests/integration/enemies/leviathan_fight_test.gd`, `tools/playtest/leviathan_check.py`

---

## Completion

Decision D-052. Evidence: `production/qa/evidence/story-045-leviathan/`.
- New: `src/enemies/abyssal_leviathan.gd`, `leviathan_eye.gd` and its data.
- `RigBody.bone()` and `part_point()`, so things can ride a rig part.
- The bridge's `boss` command reports `eyes`.
