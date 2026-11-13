# Story 022: Enemies: Calcified Husk and Fungal Stalker

> **Epic**: M2 — Zones 1–2 · **Status**: In progress · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: bible section 5 (Calcified Husk: statue-disguised fungal ambusher, 1.0 s spore
telegraph before a root-snare); addendum stats (Husk 160 HP / 22 ATK / 70 posture, weak Ember,
resists Venom, root-snare 2.5 s; Fungal Stalker 140 / 26 / 60, weak Ember, ceiling ambusher) and
"Resolved contradictions": dodge during the 1.0 s telegraph or mash 6 taps; Shadowstep breaks it
at once.

## Acceptance Criteria

- [ ] Husk: stands as a statue (no bars, no aggro) until the player is in wake range; 1.0 s spore puff with the crimson X, then a root-snare cloud; a parryable claw swipe up close.
- [ ] Root-snare: rooted 2.5 s (no move, jump or dodge); 6 attack, jump or dodge taps break it; Shadowstep breaks it at once; a prompt shows.
- [ ] Stalker: hangs from the ceiling, drops when the player passes beneath (crimson X, 0.6 s), then fights on the ground with a gold slash.
- [ ] Data in `data/balance/enemies/`; unit tests on the snare escape rules.

## Files

- `src/enemies/calcified_husk.gd`, `fungal_stalker.gd`, `src/combat/root_snare.gd`
- `data/balance/enemies/calcified_husk.json`, `fungal_stalker.json`
- `tests/unit/combat/root_snare_test.gd`
