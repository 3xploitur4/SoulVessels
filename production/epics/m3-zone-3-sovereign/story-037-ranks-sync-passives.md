# Story 037: Vessel ability ranks and Sync passives

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Ready · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Progression, upgrades and loot":
- **Vessel Ability Ranks**, paid in Standard Soul Shards (1/2/3 per rank): rank 2 gives +20 % power; rank 3 adds a modifier (for example, King's Judgment travels along walls). 4 abilities × 3 ranks per Vessel.
- **Sync Passives**, paid in Greater Soul Shards (1 each): 1 slot per Vessel, choose 1 of 3 (for example, Caelan: Sync Guard also heals 20 %).

The M2 epic deferred both to M3. Standard and Greater Soul Shards already exist as loot items.

## Acceptance Criteria

- [ ] `data/progression/ability_ranks.json`: for Caelan, Nyra and Seris, the 4 abilities with rank costs, the rank-2 power gain and a rank-3 modifier each.
- [ ] `data/progression/sync_passives.json`: 3 options per Vessel for Caelan, Nyra and Seris.
- [ ] `AbilityRanks` and `SyncPassives` (pure): costs, buying, the power multiplier; ranks and the chosen passive are saved per Vessel. A passive can be swapped at an altar for free once bought.
- [ ] The Vessels read rank power and modifiers live; at least the 3 rank-3 modifiers of Caelan's abilities and one of each other Vessel work in play.
- [ ] An altar Upgrade page for ranks and passives, by touch and gamepad.
- [ ] Unit tests: costs, the multiplier, one slot per Vessel, save round-trip. Each seen failing first.
- [ ] Screenshot of the Upgrade page.

## Files

- `src/progression/ability_ranks.gd`, `sync_passives.gd`, `src/ui/altar_menu.gd`, `src/vessels/`
- `data/progression/`, `assets/locale/strings.csv`
- `tests/unit/progression/ranks_passives_test.gd`
