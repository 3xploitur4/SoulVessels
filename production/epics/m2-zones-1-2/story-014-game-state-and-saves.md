# Story 014: Game state and save slots

> **Epic**: M2 — Zones 1–2 · **Status**: In progress · **Layer**: Core · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Death, saving, difficulty and accessibility": autosave at altars, zone entry,
after bosses; 3 slots; suspend-save when the Android app is backgrounded. Shards, items and
Affinity are never lost.

## Acceptance Criteria

- [ ] `GameState` (pure RefCounted): difficulty, carried Essence, inventory counts, Soul Core nodes, unlocked Vessels, loadout, Affinity XP and bonus levels per Vessel, rested altar, lit altars, checkpoint (room + position), killed elites, cleared arenas, opened gates, taken pickups, read lore, Soul Echo, visited rooms, story flags, elite pity counter, play time.
- [ ] `to_dict` / `from_dict` round-trip every field; missing keys fall back to defaults; a `version` field.
- [ ] `SaveSystem`: 3 slots as JSON under `user://saves/` (directory injectable for tests), atomic write (temp file then rename), `summary(slot)` for the title screen, delete; a corrupt file reads as empty with an error and keeps a `.bad` copy.
- [ ] Suspend-save: `NOTIFICATION_APPLICATION_PAUSED` and window close write the slot with a resume point; Continue resumes there once.
- [ ] Unit tests: round-trip, defaults, atomic write, corrupt file, slot summaries.

## Files

- `src/progression/game_state.gd`, `src/progression/save_system.gd`
- `tests/unit/progression/game_state_test.gd`, `save_system_test.gd`
