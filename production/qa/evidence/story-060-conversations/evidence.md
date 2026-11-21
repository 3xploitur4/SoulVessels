# Story 060 evidence: conversations, item icons, crouch and slow walk, the up-attack spam

`bash tools/python.sh tools/playtest/story060_check.py` (8 checks pass):

- 1-conversation-nyra.png: freeing Nyra starts her conversation. Play pauses, and her painted
  head and line appear at the bottom.
- 2-memory-read.png: the same conversation reads her memory ("The Herding") in the narrating
  voice, with the relic icon.
- 3-line-in-passing.png: the Sovereign's voice in passing, in the compact box at the top. Play
  goes on and the player stays in view.
- 4-inventory.png: the inventory as icon tiles (rarity border, count) with the chosen item's
  painting, name, rarity and text.
- 5-crouch.png: S held on the ground crouches.
- 6-walk.png: Shift held walks slowly. 7-run.png: letting go runs again.
- The up-attack spammed 8 times plays 8 swings, counted by the slash sounds (before the fix it
  stopped after the first).

Tests: `tests/unit/ui/dialogue_test.gd` (7), `tests/unit/ui/inventory_view_test.gd` (4),
`tests/integration/player/stance_test.gd` (2), `tests/unit/vessels/combo_moves_test.gd` (spam
regression), `tests/unit/world/room_data_test.gd` (spawn on the floor; seen failing first).

Not checked here: the spoken voices (text-to-speech) by ear on Windows and Android.
