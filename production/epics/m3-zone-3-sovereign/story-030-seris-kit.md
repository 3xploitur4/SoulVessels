# Story 030: Seris's kit

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Ready · **Layer**: Feature · **Type**: Logic · **Estimate**: L

## Context

**Design**: addendum "Vessel stats and ability kits", Seris's row: Arcane Bolt (3-shot ranged
chain, 20 m), Frost Binding (4 m ice field, 60 % Frost build-up, 8 s cooldown), Aether Shield
(3 s projectile barrier, 10 s cooldown), Rift Step (5 m blink), passive +10 % spell damage per
enemy within 10 m (max +30 %), Ultimate Cataclysm. Base stats are already in
`data/balance/vessels/seris.json`, with Resonance (Aether Burst), Sync Guard and the Ultimate.

Known gap from M2: Seris, Darius and Ilyr have no `primary` block, so they cannot attack. This
story fixes Seris only.

## Acceptance Criteria

- [ ] `seris.json` gains `primary`, `ability_1`, `ability_2` and `passive` blocks in the same shape as Caelan's and Nyra's.
- [ ] Arcane Bolt: three magic projectiles in a chain (one per press), 20 m range, Aether build-up; a bolt is a `Projectile` that other systems can detect (rune doors, mirror-shields in story 032).
- [ ] Frost Binding: a 4 m ground field that applies 60 % Frost build-up to enemies inside it, 8 s cooldown; on water it freezes the surface (hook used by story 031).
- [ ] Aether Shield: 3 s barrier that destroys enemy projectiles it touches, 10 s cooldown.
- [ ] Rift Step: the existing blink dodge breaks a root-snare at once (addendum "Resolved contradictions").
- [ ] Passive: +10 % spell damage per enemy within 10 m, capped at +30 %, as a pure function.
- [ ] Unit tests: the passive formula and cap, cooldowns, Frost build-up from the field, the shield eating a projectile, Arcane Bolt's range limit. Each test seen failing first.
- [ ] A screenshot of each ability in the sandbox.

## Files

- `data/balance/vessels/seris.json`, `src/vessels/` (Seris's kit), `src/combat/projectile.gd`
- `tests/unit/vessels/seris_kit_test.gd`
