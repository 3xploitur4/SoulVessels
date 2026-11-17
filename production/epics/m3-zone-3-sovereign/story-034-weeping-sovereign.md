# Story 034: Boss framework and the Weeping Sovereign

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Ready · **Layer**: Feature · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum boss table: the Weeping Sovereign, HP 4,500, posture 500, phases at 60 % and
25 %; each full posture break gives 4 s vulnerable at 2× damage; throne hall 30 m; water rises
1.5 m in phase 2 and Frost freezes it into platforms. Phase changes: 1.5 s invulnerable, synced to
the next 4-bar musical boundary (audio may shift it by up to 1 s). Each phase has at least 2
parryable, 2 unblockable and 1 magic attack. Tuning target: a boss takes 3–5 minutes on Normal.
Loot: Zone Boss package (Epic 100 %, including the Sovereign's Crown Fragment). Narrative: the
Sovereign is Caelan's queen; beating her lets Caelan say goodbye (+1 Affinity).

The M2 Warden arena (`src/world/arena.gd`) already locks a room and clears on a kill; the boss
builds on it. The Sovereign rig exists (`data/art/rigs/weeping_sovereign.json`).

## Acceptance Criteria

- [ ] A reusable `Boss` base: phase thresholds from data, phase transition with invulnerability, a `phase_changed` signal the music director can answer, and a hook to wait for the next 4-bar boundary.
- [ ] The boss bar and posture bar at the top of the HUD, named from the string table.
- [ ] The Sovereign's attack set in data: per phase at least 2 parryable, 2 unblockable and 1 magic attack; phase 3 adds Ember (Burn).
- [ ] Phase 2 raises the arena water 1.5 m (story 031).
- [ ] Death and retry: dying respawns at the altar and the fight restarts at phase 1; a win is saved, the bars open, the loot drops and Caelan's goodbye line plays with +1 Caelan Affinity.
- [ ] Unit tests: phase thresholds, the invulnerable window, the 4 s vulnerable 2× rule, the attack-count rule per phase read from data. Each seen failing first.
- [ ] A bridge-driven fight that reaches all three phases, with a screenshot of each.

## Files

- `src/enemies/boss.gd`, `weeping_sovereign.gd`, `src/ui/hud.gd`, `src/world/arena.gd`
- `data/balance/enemies/weeping_sovereign.json`, `data/progression/loot.json`, `assets/locale/strings.csv`
- `tests/unit/enemies/boss_test.gd`, `tests/integration/enemies/sovereign_fight_test.gd`
