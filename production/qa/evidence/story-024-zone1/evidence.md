# Evidence — Story 024: Zone 1, the Whispering Cavern

Run result: VERIFIED in the running game (`tools/playtest/zone1_walk.py`, 25 checks,
`run-output.txt`) and by tests.

The walk, from a new save: the wisp wakes in Awakening Hollow with the move tutorial (real keys,
"A / D to drift"); further in, the voice in the walls calls it a thief. In the Knight's Vigil the
far exit refuses the wisp ("Your light is too thin to go on alone..."); Caelan kneels dead on the
walkway with a faint pulse of soul-light, the prompt reads "Possess", and interacting binds him:
the wisp becomes Caelan, the voice answers ("You wear his face now?"), the save remembers it and
the exit opens. On the Aqueduct Steps the attack tutorial shows. All 14 rooms build. In the Hall
of the Branded the bars shut when Caelan walks in, the voice says "Kneel." and the parry tutorial
shows; when the Warden falls the bars open for good and the arena is saved as cleared.

| Shot | Shows |
| --- | --- |
| `01-wisp-wakes.png` | The wisp, the zone title and the move tutorial. |
| `02-thief.png` | The voice's first line. |
| `03-refused.png` | The Vigil's exit refusing the wisp. |
| `04-body.png` | Caelan's body and the Possess prompt. |
| `05-possessed.png` | Caelan taken, the voice's answer. |
| `06-warden-hall-locked.png`, `07-warden-fight.png`, `08-warden-falls.png` | The set-piece. |
| `room-z1_01.png` … `room-z1_14.png` | Every room. |

Tests: `tests/integration/world/zone1_story_test.gd` (8): the wisp takes the body (loadout,
flag, save); a taken body is gone on return; the wisp cannot leave the Vigil and is told why; after
possessing it can; the hall locks during the fight and opens after; a cleared hall stays open; a
tutorial fires once per save; the wisp gets no attack tutorial. Full suite 223 pass, smoke ok,
M1 combat playtest 44/44.

Shadow-veil secrets: four pockets for the return with Nyra (Broken Channel, Cistern Drop, Warden's
Approach, and a new ledge high in the Sunken Colonnade with a Standard Soul Shard).

Not covered here: the walk moves between rooms with the bridge's goto, not by platforming every
jump; the shield-ward gate on the critical path has its own story (023) and tests. Lines are text
subtitles: the addendum has no voice acting in v1.
