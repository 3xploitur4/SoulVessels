# Evidence — Story 022: Calcified Husk and Fungal Stalker

Run result: VERIFIED in the running game (bridge, `run-output.txt`) and by tests.

In the game: in the Glowcap Path a Husk woke when Caelan came within 3.5 m, puffed spores and
root-snared him; the prompt read "Rooted! Tap to break free (6)" and six attack taps freed him.
In the Canopy Ledge a Stalker hung at y 9.2 until Caelan passed beneath, then dropped to the floor
(y 2.0) and went on fighting; the drop cost 21 HP.

| Shot | Shows |
| --- | --- |
| `01-husk-statue.png` | A dormant Husk in stone colours. |
| `02-husk-spore-telegraph.png` | The spore telegraph (crimson X). |
| `03-rooted.png` | Caelan rooted, the break-free prompt. |
| `04-stalker-hanging.png`, `05-stalker-drop.png`, `06-stalker-landed.png` | The Stalker above the frame, falling, landed. |

Tests: `tests/integration/enemies/husk_stalker_test.gd` (5): the Husk sleeps until the player is
close; spores root the player, walking does nothing, 5 taps do not free, the 6th does; the snare
wears off on its own; Nyra's Shadowstep breaks it at once; the Stalker hangs, drops on a player
beneath and lands. `tests/unit/combat/root_snare_test.gd` (9, written by the opencode helper).

Fixed while looking: the Stalker's drop warning showed above the visible frame (it hangs over
the camera's view), so it now shows 4.5 m below it while it hangs; the snare prompt no longer
shows the interact key.

Stand-in: the Fungal Stalker uses the Husk painting, smaller and tinted violet, until it has its
own concept art (`docs/design/art-direction.md`).
