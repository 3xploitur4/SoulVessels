# Story 019: Loot: items, rarity rolls, pity, pickups

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-14) · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Progression, upgrades and loot" rarity table (Normal 70/25/5, Elite
20/65/15, bosses drop their full lists), normal enemies drop 35 % of the time and elites 100 %,
pity: 15 elite kills without an Epic guarantees the next. Bible section 6. Decision D-026.

## Acceptance Criteria

- [x] `data/progression/items.json`: every Chapter I item with rarity, kind and text keys.
- [x] `LootTable.roll` (pure, seeded): drop chance, rarity roll, the enemy's own pool per rarity with a zone fallback, pity counter.
- [x] Pickups: a bobbing orb in the rarity colour, magnet within 1.5 m, a toast on pickup; placed pickups are one-time and saved.
- [x] A Faded Parchment unlocks the next unread parchment entry (Essence once all are found).
- [x] Unit tests: 10,000 seeded rolls land within 1.5 points of each rarity rate; pity fires on the 16th elite kill.

## Files

- `src/progression/loot_table.gd`, `src/world/pickup.gd`, `data/progression/items.json`
- `tests/unit/progression/loot_table_test.gd`

---

## Completion

Decision D-026. The Zone 1-2 lore text (12 parchments, 3 relics, 2 Vessel memories) was written here so toasts and the Lore pages read properly. Evidence: `production/qa/evidence/story-019-loot/`.
