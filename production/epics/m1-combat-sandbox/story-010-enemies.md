# Story 010: Enemies — Echo Crawler, Subterranean Watcher, Branded Warden

> **Epic**: M1 — Combat Sandbox · **Status**: Ready · **Layer**: Feature · **Type**: Logic · **Estimate**: L

## Context

**Design**: addendum "Enemy and boss stats" (Crawler 90 HP / 18 ATK / 40 posture, groups, 0.6 s
green flare then 4 m lunge, +50 % from AoE; Watcher 120 / 30 / 50, hovers 4 m, 1.2 s cyan charge,
1.5 s sweeping beam, beam reflects on parry; Warden 900 / 55 / 220, shield 80 % frontal, gold
halberd thrust parryable, crimson shield charge unblockable), "Resolved contradictions"
(first Warden beaten by Counterstrike: 2 s guard break). Bible section 5 descriptions. **Decision**: D-008.

## Acceptance Criteria

- [ ] `EnemyBase` (CharacterBody3D, z-locked): states Idle, Alert (player within `aggro_range`), Approach, Telegraph, Attack, Recover, plus Staggered and Dead; aggro raises the MusicDirector state; elites raise `elite` while alive.
- [ ] Echo Crawler: low wide arachnid silhouette (slate), 0.6 s green spine-sac flare plus the standard crimson X (unblockable lunge), 4 m lunge, dies in 3-5 Caelan hits; spawns in groups of 3; `aoe_multiplier` 1.5.
- [ ] Subterranean Watcher: hovering porcelain sphere at 4 m, cyan eye glow 1.2 s charge plus the violet diamond cue, 1.5 s sweeping beam (raycast hitbox) that a Caelan perfect parry reflects back for its own ATK; grounded for 4 s when hit by Aether (hook only in M1).
- [ ] Branded Warden: 2.6 m tall tower shield plus halberd silhouette (corroded iron); frontal arc of 120 deg blocks 80 %; rear hits and `shield_broken` ignore it; gold ring halberd thrust (parryable), crimson X shield charge (unblockable, 6 m); perfect parry opens a 2 s guard break (shield lowered); posture 220, stagger leads to riposte.
- [ ] Death: 0.4 s dissolve (shader alpha), no loot yet (M2).
- [ ] Unit tests on the state machine (telegraph durations from JSON, frontal-arc math, reflect rule); a headless integration run: Caelan kills a Crawler in at most 5 hits with base stats.

## Files

- `src/enemies/enemy_base.gd`, `enemy_visual.gd`, `echo_crawler.gd/.tscn`, `subterranean_watcher.gd/.tscn`, `branded_warden.gd/.tscn`, `src/enemies/spawner.gd`
- `tests/unit/enemies/enemy_state_test.gd`, `warden_shield_test.gd`, `tests/integration/enemies/crawler_kill_test.gd`

## Dependencies

- Depends on: 007 · Unlocks: 012, 013
