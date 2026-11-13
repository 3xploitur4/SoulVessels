# Evidence — Story 016: Game flow

Run result: VERIFIED in the running game, driven through the bridge (`ui_press` presses the same
buttons a tap, click or gamepad A press would; D-pad down moved focus Slot 1 -> Slot 2).

| Shot | Shows |
| --- | --- |
| `01-title-slots.png` | Title over the Altar of the Fallen Aqueduct; three empty slot cards, first one focused. |
| `02-difficulty.png` | Story / Normal with their rules, Abyssal disabled ("Unlocks after Chapter I"), Back. |
| `03-run-start-wisp.png` | New game: the wisp in Awakening Hollow, zone title card, HUD with Essence counter, touch layer showing Jump only (the wisp cannot attack). |
| `04-pause-map.png` | Pause: Resume, Map, Inventory, Lore, Save and quit; the map with the one visited room and the you-are-here dot. |
| `05-pause-inventory.png` | Inventory page (Essence, empty list). |
| `06-used-slot.png` | After Save and quit: slot 1 shows the room name, play time, Essence, difficulty; Continue / Delete / Back. |
| `07-delete-confirm.png` | Delete asks first. |

Integration tests (`tests/integration/game/game_flow_test.gd`, 5/5): boots to the title with three
empty slots; a new game starts the wisp in z1_01 and writes the slot; the Android suspend
notification saves a resume point and Continue starts there exactly once; pause stops the tree;
showing the title twice keeps one title (regression test, seen failing on the old code: 3 titles).

The M1 combat sandbox moved to `src/sandbox/sandbox.tscn`; its playtest still passes 44/44.

Not verified here: the Android back button and a real backgrounding on a phone (the same
notifications are sent by the test; device check in story 026).
