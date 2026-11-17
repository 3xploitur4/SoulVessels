# Story 024: Zone 1 — Whispering Cavern

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-17) · **Layer**: Content · **Type**: Integration · **Estimate**: L

## Context

**Design**: addendum zone table (14 rooms, 2 altars, Caelan in room 2, attack, dodge and parry
tutorial, Branded Warden set-piece, Track 01), Narrative 1 "Awakening" (the Intruder wakes as a
wisp; the Weeping Sovereign's voice calls it "thief"; it enters Caelan, who died guarding a sealed
door), gate table (+4 shadow-veil secrets, light-rune and cracked-masonry seals). Bible section 5.

## Acceptance Criteria

- [x] 14 rooms with names, a zone map and 2 altars; collapsed marble aqueduct theme.
- [x] Room 1: the wisp (move and jump only). Room 2: Caelan's body before the sealed door; interacting possesses him.
- [x] Tutorials: move, jump, attack, dodge, block (shield ward), parry (Warden), rest, flask.
- [x] Shield-ward gate on the critical path; the Warden set-piece locks the hall until it falls; 4 shadow-veil secret pockets for the return with Nyra.
- [x] Parchments and the Sovereign's voice lines through translation keys.
- [x] Every room screenshotted; the bridge walks the zone end to end.

## Files

- `data/world/zone1.json`, `data/lore/lore.json`, `assets/locale/strings.csv`, `src/world/possession.gd`

---

## Completion

Evidence: `production/qa/evidence/story-024-zone1/`. Decision D-035. Files added: `src/world/possession.gd`, `src/world/arena.gd`, `src/world/story_triggers.gd`, `tests/integration/world/zone1_story_test.gd`, `tools/playtest/zone1_walk.py`.
