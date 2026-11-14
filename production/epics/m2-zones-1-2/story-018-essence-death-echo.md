# Story 018: Soul Essence, death and Soul Echo

> **Epic**: M2 — Zones 1–2 · **Status**: Done (2026-11-14) · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Progression" (Essence from every kill, lost on death) and "Death, saving":
respawn at the last rested altar; carried Essence stays as a Soul Echo where you died; touch it to
recover; die again first and it is lost. Story difficulty: never lost. Shards, items and Affinity
are never lost.

## Acceptance Criteria

- [x] Every kill adds the enemy's `essence` (data) to the carried total with a pop-up.
- [x] Death: Essence moves to a Soul Echo at the last safe ground in that room; an older echo is lost (Story: merged instead); respawn at the rested altar with full HP, flasks and ordinary enemies back.
- [x] Touching the echo returns its Essence and removes it; it survives save and reload.
- [x] Pure `DeathRules`, unit-tested: first death, second death, Story merge, recovery, zero Essence makes no echo.

## Files

- `src/progression/death_rules.gd`, `src/world/soul_echo.gd`
- `tests/unit/progression/death_rules_test.gd`, `tests/integration/progression/death_echo_test.gd`

---

## Completion

The sandbox keeps its in-place respawn (`Player.auto_respawn`); the game scene runs the echo and the altar respawn. Essence per enemy in each enemy JSON (`essence`). Evidence: `production/qa/evidence/story-018-essence-death-echo/`.
