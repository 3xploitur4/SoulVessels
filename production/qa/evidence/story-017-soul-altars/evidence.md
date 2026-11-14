# Evidence — Story 017: Soul Altars

Run result: VERIFIED in the running game (bridge) and by integration tests.

| Shot | Shows |
| --- | --- |
| `01-unlit-altar-prompt.png` | The dim altar in the Altar of the Fallen Aqueduct; prompt "[W] Kindle the altar" and the contextual touch button. |
| `02-altar-menu.png` | After kindling: the menu (Vessels, Soul Core, Lore, Leave), game paused, HP back to full, Track 02 playing. |
| `03-loadout.png` | Vessels page: Caelan slot 1, Nyra slot 2; tapping a Vessel removes it or adds it at the end. |
| `04-kindled-altar.png` | The lit soul flame, "Soul Altar kindled" toast, prompt now "Rest". |

`run-output.txt`: HP 120 -> 460 on rest; `lit_altars` and `rested_altar` set; music zone `altar`
while the menu is open and `zone1` after Leave; the loadout became Nyra, Caelan.

Integration tests (`tests/integration/world/altar_rest_test.gd`, 4/4): the altar room builds an
unlit altar; rest heals, refills flasks, lights, sets the respawn point and saves; after a rest
both Crawlers of z1_03 return and the killed Warden of z1_12 does not; locked Vessels are refused;
a Vessel memory grants +1 Affinity once.

Bug found and fixed: switching to a track with fewer stems crashed the mixer every frame (old lead
stems stayed in the volume tables). Regression test `test_switching_to_a_smaller_track_drops_the_old_stems`
was seen failing before the fix.

Not in M2 (addendum, later milestones): Reforge, Censer Core crafting, fast travel (needs all 7
altars). The Soul Core page is filled by story 020.
