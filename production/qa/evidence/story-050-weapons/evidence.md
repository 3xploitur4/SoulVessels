# Story 050 evidence: second weapons and signature passives

`bash tools/python.sh tools/playtest/weapons_check.py` -> `run-output.txt` (6 PASS).

- 01-altar-weapons-caelan: the Rift altar's Upgrade page with Caelan's two weapons and Sworn Shield.
- 02-greatsword-in-hand: the Greatsword taken up.
- 03-altar-weapons-nyra: Venom Blades offered (Weapon Schematic held).
- 04-altar-weapons-seris-locked: the Floating Focus locked without the Deep-Realm Rune.

Unit tests: `tests/unit/progression/weapons_test.gd` 12/12 (unlocks, the save, each patch, each kit hook).
Full suite 421/421; smoke ok; drive.py 44/44.
