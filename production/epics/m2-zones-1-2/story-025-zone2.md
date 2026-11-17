# Story 025: Zone 2 — Luminous Mycelium Forest

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-17) · **Layer**: Content · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum zone table (16 rooms, 2 altars, Nyra in room 8 freed from roots, swap
tutorial, vertical climbing, bounce mushrooms, wall-jump, Husk ambush gauntlet, Track 03 "Spore
Light" 84 BPM 6/8), Narrative 2 (Nyra strangled by roots; her memories show Wardens herding
citizens downward), gate table (shadow veils, rift scar tease). Decision D-031 (6/8 clock).

## Acceptance Criteria

- [x] 16 rooms, a zone map and 2 altars; bioluminescent fungal chasm theme; vertical shafts.
- [x] Room 8: hack the roots, then interact to free Nyra; she joins the loadout; swap and backstab tutorials follow.
- [x] Husk ambush gauntlet: exits lock, 3 waves, then they open and stay cleared.
- [x] A shadow-veil curtain on the critical path; a rift scar tease; the flooded stair down to Zone 3 sealed until M3.
- [x] Track 03 stems synthesised with the same stem names; zone entry autosave.
- [x] Every room screenshotted; the bridge walks the zone end to end.

## Files

- `data/world/zone2.json`, `data/audio/music.json`, `tools/audio/synth_stems.py`, `assets/audio/music/zone2/`

---

## Completion

Evidence: `production/qa/evidence/story-025-zone2/`. Decision D-036. Files added: `src/world/root_prison.gd`, `tests/integration/world/zone2_story_test.gd`, `tools/playtest/zone2_walk.py`; arena waves in `src/world/arena.gd`.
