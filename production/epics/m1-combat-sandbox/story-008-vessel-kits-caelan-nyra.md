# Story 008: Vessel kits — Caelan and Nyra

> **Epic**: M1 — Combat Sandbox · **Status**: Ready · **Layer**: Feature · **Type**: Logic · **Estimate**: L

## Context

**Design**: addendum "Vessel stats and ability kits" (Caelan: 4-hit combo, Royal Guard +
Counterstrike, King's Judgment 8 m / 6 s, Iron Resolve; Nyra: 6-hit flurry, Shadowstep 6 m / 3 s,
hold for Vanishing Act 2 s / 12 s, Phantom Blades 5 knives / 5 s, Backstab 2.5x, crit 20 %);
bible section 3 appearance (silhouettes). **Decision**: D-008.

## Acceptance Criteria

- [ ] `Vessel` data class + `VesselKit` base: `primary()`, `ability_1(pressed/held)`, `ability_2()`, `passive_modifiers()`, cooldown timers from JSON; a kit owns its Hitbox windows and motion values.
- [ ] Caelan: 4-hit longsword chain (motion values 1.0/1.0/1.2/1.6, posture x1.2); Royal Guard hold = block, perfect block triggers Counterstrike (auto counter at 1.5 motion, 2 s guard break on a Warden); King's Judgment: 8 m ground shockwave hitbox travelling along the floor, 6 s cooldown, 15 stamina; Iron Resolve: -15 % damage taken, -30 % while blocking.
- [ ] Nyra: 6-hit flurry (0.6 motion each, 1.6x attack speed); Shadowstep: 6 m teleport dash with i-frames, 3 s cooldown, hold 0.35 s for Vanishing Act (enemies lose target for 2 s, next hit counts as a backstab), 12 s cooldown; Phantom Blades: 5 spectral knives fanned forward, 5 s cooldown; Backstab 2.5x from behind (rear arc of 120 deg); crit 20 %.
- [ ] Placeholder visuals: each Vessel is a distinct procedural silhouette (Caelan: tall, pauldron, shield and cape planes, navy/steel; Nyra: slim, hood, two blade planes, charcoal/violet) built from primitives in `vessel_visual.gd`; weapon trails via a simple `ImmediateMesh` swipe.
- [ ] All numbers come from `data/balance/vessels/*.json`; unit tests check combo motion-value tables, cooldown gating, Backstab arc math, and the Counterstrike trigger from a perfect parry.

## Files

- `src/vessels/vessel.gd`, `vessel_kit.gd`, `caelan_kit.gd`, `nyra_kit.gd`, `vessel_visual.gd`, `src/vfx/weapon_trail.gd`
- `tests/unit/vessels/caelan_kit_test.gd`, `nyra_kit_test.gd`, `backstab_arc_test.gd`

## Dependencies

- Depends on: 006, 007 · Unlocks: 009
