# Story 009: Vessel swap, Resonance Strikes, Soul Gauge, Sync Guard, Sync Ultimate

> **Epic**: M1 — Combat Sandbox · **Status**: Ready · **Layer**: Feature · **Type**: Logic · **Estimate**: L

## Context

**Design**: addendum "Vessel switching, Resonance and Soul Sync" (swap 1.5 s cooldown / 0.2 s
i-frames, inactive 2x stamina regen, Resonance table, Echo Bonuses, Soul Gauge gains and drain,
Sync Guard rules, Sync Ultimates, Affinity gates), "Resolved contradictions" (Sync Guard + Sync Ultimate).

## Acceptance Criteria

- [ ] `Loadout` holds up to 3 Vessels with per-Vessel Stamina/Posture; `swap_to(index)` respects the 1.5 s global cooldown, gives 0.2 s i-frames, swaps the kit and visual, and fires the incoming Resonance Strike.
- [ ] Resonance Strikes: Caelan Oathbreaker Lunge (shield-bash dash, 60 posture); Nyra Severing Arrival (teleport behind the nearest enemy within 8 m, guaranteed backstab). Echo Bonuses: Caelan vs Frozen (3x posture), Nyra vs Staggered (guaranteed crit), data-driven so the Seris/Darius rows load without code.
- [ ] `SoulGauge` (shared, 300): +2 hit, +10 perfect parry/dodge, +8 connecting Resonance, +5 kill, +1 per 10 damage taken; drains 1/s out of combat (6 s after the last aggro).
- [ ] Sync Guard: costs 1 bar, requires Affinity 2+ (the sandbox sets Affinity 3 via `data/balance/sandbox.json`), 90 s per Vessel; Caelan intercepts a lethal blow (HP would reach 0) and blocks it; Nyra auto-evades an `unblockable` hit and counters; an inactive Vessel's guard triggers a free swap-in.
- [ ] Sync Ultimate (`ultimate`, 2 bars, Affinity 3+): Caelan Final Stand, 6 m AoE knockdown + 50 % damage reduction for 4 s; Nyra Dance of Shadows, 12 auto-targeted slashes over 3 s; the Vessel takes control (input locked, camera pulls in slightly).
- [ ] Unit tests: swap cooldown, gauge gains and drain, Sync Guard eligibility and 90 s lockout, Ultimate cost, Echo Bonus lookup.

## Files

- `src/player/loadout.gd`, `src/combat/soul_gauge.gd`, `src/vessels/resonance.gd`, `src/vessels/sync_guard.gd`, `src/vessels/sync_ultimate.gd`, `data/balance/sandbox.json`
- `tests/unit/player/loadout_test.gd`, `tests/unit/combat/soul_gauge_test.gd`, `tests/unit/vessels/sync_test.gd`

## Dependencies

- Depends on: 008 · Unlocks: 011, 013
