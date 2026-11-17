# Evidence — Story 021: Traversal

Run result: VERIFIED in the running game (bridge, `run-output.txt`) and by tests.

| Check | Observed |
| --- | --- |
| Bounce mushroom (Glowcap Path) | Feet peak 9.17 m; data says cap top 2.9 + 6.5 = 9.4 m (the capture samples every 0.08 s, so it can miss the exact apex). |
| Void fall (Collapsed Bridge gap) | HP 460 -> 414 (10 % of max), back on the ledge at x 15. |
| Wall-jump (Mycelium Shaft chimney) | From the shelf at y 11 to y 21.2 by alternating wall-jumps; the chimney walls end at y 21. |

Screenshots: `01-bounce-mushroom.png`, `02-bounced.png`, `03-wall-jump-chimney.png`.

Tests: `tests/integration/player/traversal_test.gd` (6): wall-jump climbs a 12 m shaft past 9 m;
wall slide caps the fall; mushroom apex within 0.6 m of data; one-way platform passes up, holds,
drops with down + jump; a fall is reported once; safe ground needs floor under the feet.
`tests/unit/world/bounce_mushroom_test.gd` (5, written by the opencode helper and reviewed): the
cap catch rule.

Bug found in the game: the first capture returned the player to y -14 after a void fall. The
bridge teleport left the body flagged "on floor" for one frame over the pit, so the pit became
"safe ground". Fixed by requiring real floor under the feet (`RoomManager.has_ground`). The new
regression test passes, but it also passed before the fix: the headless test does not reproduce
the one-frame flag. The in-game rerun is the proof (back at x 15).
