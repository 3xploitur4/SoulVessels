# Story 017: Soul Altars

> **Epic**: M2 — Zones 1–2 · **Status**: In progress · **Layer**: Feature · **Type**: Integration · **Estimate**: M

## Context

**Design**: addendum "Soul Altars": full heal and flask refill, respawn ordinary enemies (not killed
elites), save, change the 3-Vessel loadout, upgrades, Lore playback, Censer Core crafting; fast
travel once all 7 are lit. Bible section 5. Reforge, Censer crafting and Travel come in later
milestones.

## Acceptance Criteria

- [ ] An altar lights the first time you use it; resting heals fully, refills flasks, resets ordinary enemies, sets the respawn point and saves.
- [ ] Altar menu: Rest (done on open), Loadout (pick up to 3 unlocked Vessels, order = wheel order), Soul Core, Lore (read collected entries; a Vessel memory gives +1 Affinity once), Leave. Track 02 plays while the menu is open.
- [ ] Killed elites and cleared arenas stay cleared after rest and reload.
- [ ] Integration test: resting after killing a Crawler and the Warden brings back the Crawler only.

## Files

- `src/world/altar.gd`, `src/ui/altar_menu.gd`, `data/lore/lore.json`
