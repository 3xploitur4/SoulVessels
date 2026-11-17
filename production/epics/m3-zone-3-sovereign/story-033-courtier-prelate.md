# Story 033: Enemies — Drowned Courtier and Choir Prelate

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Done (2026-11-17) · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Enemy and boss stats":
- **Drowned Courtier** (common): HP 110, ATK 24, posture 50, weak to Frost (freezes in water). Swims, then surfaces with a gold-flash slash.
- **Choir Prelate** (elite): HP 700, ATK 40 (orbs), posture 160, weak to Aether (Unravel strips its buffs). A golden aura gives allies within 8 m +30 % ATK and DEF; it teleports away when approached. It drops the Tarnished Censer Shard (Rare).

Each attack uses the standard telegraphs (gold ring = parryable, crimson X = unblockable, violet diamond = magic projectile).

## Acceptance Criteria

- [x] `data/balance/enemies/drowned_courtier.json` and `choir_prelate.json` with the stats above and all timings.
- [x] Courtier: hidden under water, rises with a parryable slash when the player is near, dives back; Frost while it is in water freezes it in place for the Freeze duration.
- [x] Prelate: keeps its distance and teleports to a marked point when the player comes within range; fires magic orbs; its aura buffs allies in 8 m; Unravel removes the aura for its duration.
- [x] Both drop loot through the existing loot tables; the Prelate counts as an elite for the pity rule.
- [x] Unit tests: the aura applies and is stripped by Unravel, the teleport trigger range, the Courtier freezing only while in water. Each seen failing first.
- [x] Both appear in the sandbox and in the bridge's `spawn` command.

## Files

- `src/enemies/drowned_courtier.gd`, `choir_prelate.gd`, `enemy_factory.gd`
- `data/balance/enemies/`, `data/progression/loot.json`, `items.json`
- `tests/unit/enemies/courtier_prelate_test.gd`

---

## Completion

Decision D-042. Evidence: `production/qa/evidence/story-033-courtier-prelate/`. Files added:
`src/enemies/drowned_courtier.gd`, `choir_prelate.gd`, `data/balance/enemies/drowned_courtier.json`,
`choir_prelate.json`, `tests/unit/enemies/courtier_prelate_test.gd`,
`tools/playtest/prelate_courtier_check.py`. EnemyBase gained ally buffs (`apply_buff`,
`buff_multiplier`) and now honours Freeze. Room grid codes `d` (Courtier) and `p` (Prelate).
