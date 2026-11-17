# Evidence — Story 025: Zone 2, the Luminous Mycelium Forest

Run result: VERIFIED in the running game (`tools/playtest/zone2_walk.py`, 28 checks,
`run-output.txt`) and by tests.

The walk: the forest opens with the queen's line ("The forest drinks what falls"). In room 8 Nyra
hangs bound in thick roots and the tutorial says to cut them; six real attack taps cut the three
roots, she slumps free and the prompt reads "Free"; interacting binds her: "Nyra joins you", her
own line in her colour, and the swap tutorial. A real swap makes her active. At the veil on the
critical path (z2_11) she remarks on it, and a real Shadowstep carries her through (x 11.5 to
19.5). The Husk ambush gauntlet (z2_13) locks when she walks in, the queen calls them up, and three
waves come (2, then 3, then 3, the later ones already awake); after the last the hall opens and is
saved as cleared. All 16 rooms build; the flooded stair down to Zone 3 in z2_16 stays sealed and
the queen speaks of her palace beneath the water.

| Shot | Shows |
| --- | --- |
| `01-forest.png` | Zone entry. |
| `02-nyra-bound.png`, `03-roots-cut.png`, `04-nyra-freed.png`, `05-nyra-active.png` | Freeing Nyra and the first swap. |
| `06-veil.png`, `07-through-veil.png` | The veil and the Shadowstep through it. |
| `08-gauntlet-wave1.png` … `11-gauntlet-cleared.png` | The gauntlet. |
| `room-z2_01.png` … `room-z2_16.png` | Every room. |

Tests: `tests/integration/world/zone2_story_test.gd` (6): the roots must be cut first (3 hits,
then nothing left to cut); the player's attacks find the roots as a target; freeing Nyra adds her
and keeps Caelan in hand (and saves); a freed Nyra is not bound again; the gauntlet holds back its
later waves, locks, sends wave 2 and 3, then opens and saves; later waves come awake. Full suite
229 pass, smoke ok, M1 combat playtest 44/44.

Already in place from earlier stories and checked here: Track 03 stems (story 015, D-031), zone
entry autosave (story 016), bounce mushrooms and wall-jump (021), rift scar teases and the flood
seal (023). Not covered: the walk moves between rooms with the bridge's goto, not every jump.
