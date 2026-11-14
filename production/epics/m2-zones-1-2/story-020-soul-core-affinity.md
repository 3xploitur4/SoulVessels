# Story 020: Soul Core tree and Affinity progression

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-14) · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Progression": Soul Core (shared), 1 Lesser Soul Shard per node, +15 max HP,
+5 % stamina regen, +10 Soul Gauge cap, +1 flask charge (up to 6), 20 nodes, about 14 reachable in
Chapter I. "Affinity (trust), 0–5 per Vessel": XP from time active in combat, kills, perfect
parries and dodges; reading that Vessel's lore at an altar gives +1 level. Level 2 Sync Guard,
level 3 Ultimate and +5 % stats. Decisions D-027, D-028.

## Acceptance Criteria

- [x] `data/progression/soul_core.json`: 20 nodes with effect, prerequisites and a grid position.
- [x] `SoulCore` (pure): can_buy (shard, prerequisite, not owned), buy, summed modifiers. The player applies max HP, stamina regen, gauge cap and flask charges.
- [x] Altar Soul Core screen: the tree with owned, buyable and locked nodes, the shard count, buying by touch or gamepad.
- [x] `Affinity` (pure): XP sources from data, level thresholds, bonus levels from lore, max 5. The player's Vessels read their level live; a level-up toast.
- [x] Unit tests on both.

## Files

- `src/progression/soul_core.gd`, `affinity.gd`, `src/ui/soul_core_view.gd`, `data/progression/soul_core.json`, `affinity.json`

---

## Completion

Decisions D-027 and D-028. Evidence: `production/qa/evidence/story-020-soul-core-affinity/`.
