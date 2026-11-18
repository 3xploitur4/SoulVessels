# Story 050: Second weapons from Zone 4's drops

> **Epic**: M4 — Zone 4 and the Chapter I finale · **Status**: Done · **Layer**: Feature · **Type**: Logic · **Estimate**: M

## Context

**Design**: addendum "Weapon unlocks and Affinity 5 passives":
- Caelan: Greatsword, from the Guardian Below. No shield, 1.5x posture, parries with the blade.
- Nyra: Venom/Elemental Short Blades, from a Weapon Schematic dropped by a Warden.
- Seris: Floating Focus, from the Deep-Realm Rune. Casts while moving at full speed.
- Darius: Improvised Heavy, from Polished Basalt Cores. A random elemental slam.

Also the Affinity 5 passives:
- Sworn Shield: a perfect parry reflects magic.
- Ghost Step: Shadowstep resets on a backstab kill.
- Spellweave: every 3rd bolt copies the last spell.
- Unkillable: Sync Guard cooldown 45 s.

Not in the addendum's milestone list; built last in M4 and the first to cut (D-048).

## Acceptance Criteria

- [x] A per-Vessel weapon choice saved in GameState, switched at an altar once unlocked; each second weapon is a data patch on the Vessel (the story-037 mechanism) plus any kit hook it needs.
- [x] Unlock sources wired: the Guardian's flag, the Schematic, the Deep-Realm Rune, Basalt Cores.
- [x] The four Affinity 5 passives, active at Affinity 5.
- [x] Unit tests per weapon and passive; an altar screenshot.

## Files

- `data/balance/vessels/*.json`, `data/progression/weapons.json`, `src/progression/weapons.gd`, `src/ui/altar_menu.gd`
- `tests/unit/progression/weapons_test.gd`

---

## Completion

Decision D-056. Evidence: `production/qa/evidence/story-050-weapons/` (`weapons_check.py`, 6 checks; altar screenshots).
- `data/progression/weapons.json` and `src/progression/weapons.gd` (unlock, refresh, equip, patched); `GameState.weapons` in the save.
- Kit hooks: `VesselKit.primary_element` (Venom Blades, Improvised Heavy), Seris `primary.steer` (Floating Focus) and Spellweave, Nyra Ghost Step, Caelan Sworn Shield, Sync Guard cooldown from the Vessel's data (Unkillable).
- The game applies the weapon and signature patches after ranks and passives, re-binds at Affinity 5, and refreshes unlocks when an altar opens. The Upgrade page shows both weapons and the signature line.
- The Deep-Realm Rune is a pickup in z4_12.
- Tests: `tests/unit/progression/weapons_test.gd` (12). 421 tests pass; smoke ok; drive.py 44/44.
- Weapon looks added later (D-058): see 05-11 in the evidence folder.
