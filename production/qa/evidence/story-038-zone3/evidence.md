# Story 038 evidence: Zone 3, the Sunken Palace

Run: `bash tools/python.sh tools/playtest/zone3_walk.py`. Log: `run-output.txt`, 12 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-flooded-stair.png | Walking into the flooded stair at the end of Zone 2 leads into z3_01, where Track 05 plays |
| 02-seris-in-crystal.png | Seris sealed in crystal in room 4, with the break-it tutorial |
| 03-seris-freed.png | Caelan's real attacks break the crystal; Free; Seris joins and speaks |
| 04/05 murals | Puzzle 1 (Hall of Murals), solved with real bolts in mural order 2-1-3 |
| 06-mirror-solved.png | Puzzle 2 (Mirror Hall): turned three times by interacting, it lifts the bolt into the high rune |
| 07-tide-solved.png | Puzzle 3 (Tide Gate): the bolt from the bank passes over the rune; Frost Binding freezes the pool; from the ice the rune is in line |
| 08-throne-hall.png | The throne hall: the bars shut, the Sovereign wakes, her music starts |
| room-z3_01 .. room-z3_18 | Every room, entered through its west door (the zone atlas) |

Zone: `data/world/zone3.json`, generated from `tools/world/build_zone3.py`.
- 18 rooms and 2 altars (z3_03, z3_10).
- 6 rune puzzles: z3_05 sequence, z3_07 mirror, z3_09 tide, z3_11 four-rune sequence with jump shots, z3_13 two mirrors, z3_16 all three kinds together.
- Courtiers in 4 pools, Prelates in z3_08 and z3_14 (the second behind a Branded Warden), the Sovereign in z3_17, and the cracked-masonry seal to Zone 4 in z3_18.
- Lore: parchments 13-18, relics 4-5 and the Seris memory.

Tests: `tests/integration/world/zone3_story_test.gd` (6): room, altar and puzzle counts; the stair link; Seris freed and joining; the murals door; the throne hall with boss, water and arena; the sealed way to Zone 4.

Played by the script: puzzles 1-3 with real input, and the throne hall start. Not played: puzzles 4-6 and a full hand fight. Their rules are the same code the tests cover, but nobody has played their layouts by hand.
