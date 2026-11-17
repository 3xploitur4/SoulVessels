# Story 041: Darius's kit, his distrust, and AoE that kills Crawlers outright

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Logic · **Estimate**: L

## Context

**Design**: addendum Vessel tables. Darius: +160 HP, ATK 60, DEF 35, 5.2 m/s, attack speed 0.6x,
posture damage 2.5x. Kit:
- 3-hit hammer swings with hyper-armor.
- Crushing Blow: shatters shields and armor, 150 posture, 7 s cooldown.
- Groundbreaker: 5 m seismic slam, 9 s cooldown.
- Dodge: a shoulder charge with knockback.
- Passives: Unbreakable (hyper-armor) and Last Survivor (+1 % damage per 2 % HP missing, max +50 %).
- Resonance: Meteor Drop, a ground slam with 90 posture damage and 3 m AoE. Echo: against an Unraveled enemy, its armor shatters at once.
- Sync Guard: survives at 1 HP and gains 3 s of Last Survivor at maximum.
- Ultimate: Worldbreaker Override, a charged strike that breaks all posture on screen.
- "Darius's AoE kills Crawlers instantly" (Resolved contradictions).
- Narrative 4: he distrusts the Intruder, so Affinity XP is -25 % until the Leviathan falls.
His data file has stats only; like Seris before story 030, he cannot attack yet.

## Acceptance Criteria

- [x] `darius.json` gains primary, ability_1, ability_2, dodge, passive, resonance, sync_guard and ultimate data in the shape the other kits use.
- [x] A DariusKit: hyper-armor on the combo; Crushing Blow breaks a Warden's shield and armor; Groundbreaker is an AoE slam; the shoulder charge knocks enemies back; Last Survivor as a pure formula; the 1 HP Sync Guard; Worldbreaker breaks every on-screen enemy's posture.
- [x] Darius's AoE hits kill an Echo Crawler outright (a data flag on the Crawler, not a name check).
- [x] Affinity XP for Darius is x0.75 until the flag `boss_abyssal_leviathan` is set.
- [x] His ability ranks (4 abilities) and three Sync passives are added to the story-037 data files.
- [x] Unit tests: Last Survivor at several HP fractions and its cap, the 1 HP guard, Crawler instant kill, the distrust multiplier switching off. Each seen failing first.
- [x] A screenshot of each ability in game (bridge script).

## Files

- `data/balance/vessels/darius.json`, `src/vessels/darius_kit.gd`, `data/progression/ability_ranks.json`, `sync_passives.json`
- `src/progression/affinity.gd`, `tests/unit/vessels/darius_kit_test.gd`, `tools/playtest/darius_check.py`

---

## Completion

Decision D-049. Evidence: `production/qa/evidence/story-041-darius-kit/`. New: `src/vessels/darius_kit.gd`;
kit hooks `damage_dealt_multiplier` and `tick`; `heavy_aoe` and `ignore_def` packet tags; Crawler data
`dies_to_heavy_aoe`; `Affinity.xp_multiplier` with `affinity.json` "distrust"; the
`GameEvents.slam_landed` signal for masonry (story 042).
