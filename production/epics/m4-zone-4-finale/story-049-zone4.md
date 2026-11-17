# Story 049: Zone 4 — the Sealed Rift and the Starless Shore

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Ready · **Layer**: Content · **Type**: Integration · **Estimate**: L

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

- [ ] 14 rooms in two parts (the Sealed Rift, then the Starless Shore below the elevator), 1 altar, and a checkpoint before each boss (respawn there, not at the altar).
- [ ] Room 3: Darius, how he is found and won over (his distrust shows in his lines), joining the loadout; his tutorial.
- [ ] Dark rooms with light sources; sliding-floor rooms; masonry walls that need Darius; Crawler swarms of 8; Wardens.
- [ ] The Guardian's elevator arena and the Leviathan's shore arena; the rift that opens into Ilyr's awakening.
- [ ] Lore placement for the rest of Chapter I, including the Primeval Truth from the Leviathan.
- [ ] Every room screenshotted; a walk script crosses the zone end to end.

## Files

- `tools/world/build_zone4.py`, `data/world/zone4.json`, `data/world/themes.json`, `data/lore/lore.json`, `assets/locale/strings.csv`
- `tests/integration/world/zone4_story_test.gd`, `tools/playtest/zone4_walk.py`
