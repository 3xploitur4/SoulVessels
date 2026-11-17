# Story 036: Reforging and Censer Core crafting

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Progression, upgrades and loot": weapon reforging +0 → +5, +8 % ATK per
level, +3 adds a coating slot; costs per level (Essence and materials):

| Level | Essence | Materials |
| --- | --- | --- |
| +1 | 300 | 3 Crude Stone/Iron |
| +2 | 700 | 6 Crude Stone/Iron |
| +3 | 1,500 | 2 Polished Basalt Core or Luminous Root Resin |
| +4 | 3,000 | 4 Polished Basalt Core + 1 Censer Core |
| +5 | 6,000 | 1 Sovereign's Crown Fragment or Heart of the Guardian |

Censer Core (Epic) is crafted from 3 Tarnished Censer Shards at a Soul Altar ("Resolved
contradictions"). The altar menu lists Reforge (UI section).

## Acceptance Criteria

- [x] `data/progression/reforge.json` with the table above and the crafting recipe.
- [x] `Reforge` (pure): can_reforge (Essence, materials, an "or" between two materials), reforge, ATK multiplier per level, coating slot at +3. Per Vessel weapon level saved in `GameState`.
- [x] Censer Core crafting at the altar takes 3 shards and gives 1 core.
- [x] An altar Reforge page: each Vessel's weapon, its level, the next cost with what is held, works by touch and gamepad; all text through the string table.
- [x] Unit tests: every level's cost, the "or" material rule, the ATK multiplier, the save round-trip. Each seen failing first.
- [x] Screenshot of the Reforge page.

## Files

- `src/progression/reforge.gd`, `src/ui/altar_menu.gd`, `src/progression/game_state.gd`
- `data/progression/reforge.json`, `items.json`, `assets/locale/strings.csv`
- `tests/unit/progression/reforge_test.gd`

---

## Completion

Decision D-045. Evidence: `production/qa/evidence/story-036-reforge/`. `src/progression/reforge.gd`, its
data and unit tests were drafted by the opencode helper (glm-5.3-flash-free) and reviewed; the save
field `GameState.weapon_levels`, the ATK hookup (`VesselSlot.atk_mult`), the game actions and the
altar page were written here. Bridge command `essence`.
