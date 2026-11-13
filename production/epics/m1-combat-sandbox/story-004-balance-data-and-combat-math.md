# Story 004: Balance data layer and combat math

> **Epic**: M1 — Combat Sandbox · **Status**: Done (2026-11-13) · **Layer**: Foundation · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Core combat systems" (HP, Stamina, Posture, dodge/parry timing, damage
formula, elements), "Vessel stats and ability kits" (base stats, ability table),
"Vessel switching, Resonance and Soul Sync" (gauge gains), "Enemy and boss stats".
**Decision**: D-003, D-005.

## Acceptance Criteria

- [ ] `data/balance/combat.json` holds every global number: soul HP 300, stamina costs (dodge 20, air-dash 25, heavy 15, block 10), regen 40/s after 0.6 s, exhausted 1.5 s, dodge 0.45 s roll / 0.25 s i-frames / 0.15 s cancel, parry window 0.18 s, perfect parry +15 stamina / 35 posture, stagger 2.5 s, riposte x2, posture drain 10/s after 2 s, player posture 100 / guard break 1 s, crit 1.5 (base 5 %), weakness 1.5 / resist 0.5, backstab 1.3, swap cooldown 1.5 s / 0.2 s i-frames, Soul Gauge 300 max with all gains, Sync Guard 90 s, difficulty table.
- [ ] `data/balance/vessels/caelan.json`, `nyra.json` (plus `seris.json`, `darius.json`, `ilyr.json` with stats only) carry the base-stat table, abilities with cooldowns, Resonance Strike, Echo Bonus, Sync Guard and Ultimate numbers.
- [ ] `data/balance/enemies/echo_crawler.json`, `subterranean_watcher.json`, `branded_warden.json` carry HP/ATK/posture/weakness/telegraph timings from the enemy table.
- [ ] `Balance` autoload loads all JSON at boot into typed dictionaries and exposes `combat(key)`, `vessel(id)`, `enemy(id)`; a missing key is a logged error, never a silent 0.
- [ ] `CombatMath` (static) implements the addendum damage formula plus status, crit and backstab multipliers; unit tests cover it with the table numbers (Caelan 40 ATK vs 0 DEF, Nyra backstab crit).
- [ ] The in-repo test runner (`tests/runner/test_runner.gd`, `tests/run_tests.sh`) discovers `tests/unit/**/*_test.gd`, runs every `test_*` method, prints a summary and exits non-zero on failure.

## Files

- `data/balance/combat.json`, `data/balance/vessels/*.json`, `data/balance/enemies/*.json`
- `src/core/balance.gd`, `src/combat/combat_math.gd`
- `tests/runner/test_runner.gd`, `tests/runner/test_case.gd`, `tests/run_tests.sh`, `tests/unit/combat/combat_math_test.gd`, `tests/unit/core/balance_test.gd`

## Test Evidence

Logic: the unit tests above pass under `tests/run_tests.sh`.

## Dependencies

- Depends on: `../m0-setup/story-001-godot-project-scaffold.md` · Unlocks: 006, 007, 008, 009, 010

---

## Completion

Runner discovers unit tests and, with `--integration`, tests/integration. Balance also has `get_value`/`set_value` for the bridge.
