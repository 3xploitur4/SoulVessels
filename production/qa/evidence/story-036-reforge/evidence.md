# Story 036 evidence: reforging and Censer Core crafting

Run: `bash tools/python.sh tools/playtest/reforge_check.py` (the Zone 1 altar in z1_04; Essence and
materials given by the bridge). Log: `run-output.txt`, 4 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-reforge-page.png | The altar's Reforge page: each held Vessel's weapon level, the next level's Essence and materials against what is held (either-or options joined by "or"), a button per weapon, and the Censer Core recipe |
| 02-after-reforge-and-craft.png | After reforging Caelan to +1 (2000 to 1700 Essence, 3 stones spent) and crafting a Censer Core from 3 shards |

Tests:
- `tests/unit/progression/reforge_test.gd` (9): every level's cost, the either-or material rule at +3, too little Essence changes nothing, the exact spend, ATK x1.24 at +3, the coating slot from +3, no reforge past +5, the Censer Core recipe, and the save round trip. Written by the opencode helper; I fixed one wrong test, see below.
- `tests/integration/progression/reforge_game_test.gd` (2): ATK rises by 8 % at once and the level is saved; the page disables what cannot be paid.

These tests first failed to load: `Reforge` did not exist when they were written.

The fixed test: it expected a +0 weapon to reforge straight to +3 with resin. It now starts the weapon at +2.

Not covered: elemental coatings themselves (the slot opens at +3, but no coating exists yet).
