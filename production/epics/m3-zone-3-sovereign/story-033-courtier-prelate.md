# Story 033: Enemies — Drowned Courtier and Choir Prelate

> **Epic**: M3 — Zone 3 and the Weeping Sovereign · **Status**: Ready · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Enemy and boss stats":
- **Drowned Courtier** (common): HP 110, ATK 24, posture 50, weak to Frost (freezes in water). Swims, then surfaces with a gold-flash slash.
- **Choir Prelate** (elite): HP 700, ATK 40 (orbs), posture 160, weak to Aether (Unravel strips its buffs). A golden aura gives allies within 8 m +30 % ATK and DEF; it teleports away when approached. It drops the Tarnished Censer Shard (Rare).

Each attack uses the standard telegraphs (gold ring = parryable, crimson X = unblockable, violet diamond = magic projectile).

## Acceptance Criteria

- [ ] `data/balance/enemies/drowned_courtier.json` and `choir_prelate.json` with the stats above and all timings.
- [ ] Courtier: hidden under water, rises with a parryable slash when the player is near, dives back; Frost while it is in water freezes it in place for the Freeze duration.
- [ ] Prelate: keeps its distance and teleports to a marked point when the player comes within range; fires magic orbs; its aura buffs allies in 8 m; Unravel removes the aura for its duration.
- [ ] Both drop loot through the existing loot tables; the Prelate counts as an elite for the pity rule.
- [ ] Unit tests: the aura applies and is stripped by Unravel, the teleport trigger range, the Courtier freezing only while in water. Each seen failing first.
- [ ] Both appear in the sandbox and in the bridge's `spawn` command.

## Files

- `src/enemies/drowned_courtier.gd`, `choir_prelate.gd`, `enemy_factory.gd`
- `data/balance/enemies/`, `data/progression/loot.json`, `items.json`
- `tests/unit/enemies/courtier_prelate_test.gd`
