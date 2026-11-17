# Story 030: Seris's kit

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Logic · **Estimate**: L

## Context

**Design**: addendum "Vessel stats and ability kits", Seris's row: Arcane Bolt (3-shot ranged
chain, 20 m), Frost Binding (4 m ice field, 60 % Frost build-up, 8 s cooldown), Aether Shield
(3 s projectile barrier, 10 s cooldown), Rift Step (5 m blink), passive +10 % spell damage per
enemy within 10 m (max +30 %), Ultimate Cataclysm. Base stats are already in
`data/balance/vessels/seris.json`, with Resonance (Aether Burst), Sync Guard and the Ultimate.

Known gap from M2: Seris, Darius and Ilyr have no `primary` block, so they cannot attack. This
story fixes Seris only.

## Acceptance Criteria

- [x] `seris.json` gains `primary`, `ability_1`, `ability_2` and `passive` blocks in the same shape as Caelan's and Nyra's.
- [x] Arcane Bolt: three magic projectiles in a chain (one per press), 20 m range, Aether build-up; a bolt is a `Projectile` that other systems can detect (rune doors, mirror-shields in story 032).
- [x] Frost Binding: a 4 m ground field that applies 60 % Frost build-up to enemies inside it, 8 s cooldown; on water it freezes the surface (hook used by story 031).
- [x] Aether Shield: 3 s barrier that destroys enemy projectiles it touches, 10 s cooldown.
- [x] Rift Step: the existing blink dodge breaks a root-snare at once (addendum "Resolved contradictions").
- [x] Passive: +10 % spell damage per enemy within 10 m, capped at +30 %, as a pure function.
- [x] Unit tests: the passive formula and cap, cooldowns, Frost build-up from the field, the shield eating a projectile, Arcane Bolt's range limit. Each test seen failing first.
- [x] A screenshot of each ability in the sandbox.

## Files

- `data/balance/vessels/seris.json`, `src/vessels/` (Seris's kit), `src/combat/projectile.gd`
- `tests/unit/vessels/seris_kit_test.gd`

---

## Completion

Decision D-039. Evidence: `production/qa/evidence/story-030-seris-kit/`. Files added:
`src/vessels/seris_kit.gd`, `src/combat/frost_field.gd`, `tests/unit/vessels/seris_kit_test.gd`,
`tools/playtest/seris_check.py`; SFX `bolt`, `frost`, `shield`. Also built (beyond the criteria):
Aether Burst (Resonance), the automatic shield Sync Guard and Cataclysm Fused (Ultimate), so Seris
is complete when she joins in Zone 3. Bridge commands `root_player` and `set_affinity` added.
