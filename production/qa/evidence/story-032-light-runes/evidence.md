# Story 032 evidence: light-rune doors and puzzles

Run: `bash tools/python.sh tools/playtest/rune_check.py`. Log: `rune-run-output.txt`, 7 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-z1-door-dark.png | z1_02: the secret rune door, its rune dark |
| 02-z1-door-open.png | One Arcane Bolt lights it; the door is gone (saved as `z1_02_rune`), and the shard behind it is taken |
| 03-z2-sequence-mural.png | z2_12: the three-rune sequence and its mural (the layout in miniature, numbered 1-3) |
| 04-z2-wrong-rune-flash.png | A bolt from the right reaches rune 2 first: every rune flashes red and goes dark |
| 05-z2-two-lit.png | From the left, runes 1 and 2 lit in order (a lit rune lets bolts through) |
| 06-z2-mirror-bounce.png / 07-z2-solved.png | A mirror-shield under rune 3 turns the third bolt upward into it; the door opens |

Tests:
- `tests/unit/world/light_rune_test.gd` (11): the sequence and "all" rules, the mirror angles, and turning a mirror.
- `tests/integration/world/rune_puzzles_test.gd` (8): a door opening and saving, staying open on return, a sequence reset, a sequence in a row, the mirror bounce, bolts stopping at rock, turning a mirror, and the tide rune lit from ice.

All of them first failed to load: the classes did not exist.

Secrets added: z1_02 (Standard Soul Shard), z1_03 (Echoing Relic) and z2_12 (a 3-rune sequence, Standard Soul Shard). The fourth rune door, in z2_04, stays sealed.

Not covered: a Watcher beam bouncing off a mirror (decision D-041); the tide puzzle in a real room (story 038).
