# Story 046: Overdrive: two Ultimates chained, unlocked by the Pure Soul Matrix

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Overdrive (3 bars, after the Leviathan)": chains two Ultimates back to back
with a combined finisher. It is unlocked by the Pure Soul Matrix from the Leviathan ("Resolved
contradictions").

## Acceptance Criteria

- [x] Overdrive needs the Matrix (a save flag) and a full 3-bar gauge; it is triggered by an input both touch and gamepad can reach, shown in the HUD when ready.
- [x] It plays the active Vessel's Ultimate, then the next loadout Vessel's (a free swap between them), then a combined finisher (an AoE with both Vessels' elements).
- [x] Invulnerable throughout; the gauge empties.
- [x] Unit tests: the unlock and cost rules, the order of the two Ultimates; an integration test running it through the game.
- [x] A screenshot of each part.

## Files

- `src/player/player.gd`, `src/vessels/vessel_kit.gd`, `src/ui/hud.gd`, `src/ui/touch_controls.gd`, `data/balance/combat.json`
- `tests/unit/player/overdrive_test.gd`

---

## Completion

Decision D-053. Evidence: `production/qa/evidence/story-046-overdrive/`. In `Player`: `overdrive_unlocked`,
`overdrive_stage`, `overdrive_ready()`, the chain and the finisher; `combat.json` `overdrive`; the HUD's gold
OVERDRIVE label; the game sets the unlock from the save flag `unlock_overdrive` and toasts it when earned;
bridge command `overdrive`.
