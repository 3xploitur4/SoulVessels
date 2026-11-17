# Story 049: Zone 4 — the Sealed Rift and the Starless Shore

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done · **Layer**: Content · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum zone table:
- Zone 4: 14 rooms, 1 altar plus boss checkpoints, Darius in room 3.
- Mechanics: darkness (light radius) and sliding floors.
- Set-pieces: the Guardian Below, the Abyssal Leviathan, Ilyr's awakening. Tracks 10, 12, 13.
- Enemies: Crawler swarms in groups of 8 ("Resolved contradictions"), and Wardens in Zones 3-4.

Narrative 4: Darius came from the surface 20 years ago seeking his lost expedition, and distrusts
the Intruder. The Guardian guards the elevator to the Starless Shore.

Lore: the remaining parchments (19-24), relics (6-10), Darius's memory and the Primeval Truth, "The Descent Was Not a Fall".

Generated with a `build_zone4.py` like Zone 3's.

## Acceptance Criteria

- [x] 14 rooms in two parts (the Sealed Rift, then the Starless Shore below the elevator), 1 altar, and a checkpoint before each boss (respawn there, not at the altar).
- [x] Room 3: Darius, how he is found and won over (his distrust shows in his lines), joining the loadout; his tutorial.
- [x] Dark rooms with light sources; sliding-floor rooms; masonry walls that need Darius; Crawler swarms of 8; Wardens.
- [x] The Guardian's elevator arena and the Leviathan's shore arena; the rift that opens into Ilyr's awakening.
- [x] Lore placement for the rest of Chapter I, including the Primeval Truth from the Leviathan.
- [x] Every room screenshotted; a walk script crosses the zone end to end.

## Files

- `tools/world/build_zone4.py`, `data/world/zone4.json`, `data/world/themes.json`, `data/lore/lore.json`, `assets/locale/strings.csv`
- `tests/integration/world/zone4_story_test.gd`, `tools/playtest/zone4_walk.py`

---

## Completion

Decision D-055. Evidence: `production/qa/evidence/story-049-zone4/` (`zone4_walk.py`, 21 checks, every room screenshotted).
- `tools/world/build_zone4.py` -> `data/world/zone4.json`: 14 rooms, altar `altar_z4_a` (z4_04), checkpoints z4_09 and z4_12, three dark rooms, three sliding floors, masonry in z4_03, z4_06 (the Expedition Cache secret) and z4_08, three swarms of 8 Crawlers, six Wardens, the Guardian's lift (z4_10) and the Leviathan's 46 m shore (z4_13), the rift into Beyond the Rift (z4_14, the awakening).
- z3_18's right exit leads to z4_01 behind masonry that opens on `boss_weeping_sovereign`.
- New: `src/world/rift_portal.gd`; RootPrison look `rubble`; room keys `checkpoint`, `music`, `rift`, `masonry_opens_on`, slide `strip`; themes `rift` and `shore`; materials `z4_*`; bridge command `flag`.
- Lore: parchments 19-24, relics 6-10, `memory_darius`, `truth_01` (the Leviathan's Primeval Truth drop); Darius's lines show his distrust until he joins.
- Tests: `tests/integration/world/zone4_story_test.gd` (8), zone 3 and world-links updates. 409 tests pass, smoke ok, drive.py 44/44.
- Not verified: hand-walked pacing; Darius's rig has no clips yet (story 051).
