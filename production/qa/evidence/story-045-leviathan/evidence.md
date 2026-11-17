# Story 045 evidence: the Abyssal Leviathan

Run: `bash tools/python.sh tools/playtest/leviathan_check.py`. Log: `run-output.txt`, 6 checks, 0 failed. The stage is z1_03 with a sea poured by the bridge; the Starless Shore comes in story 049.

| Shot | Shows |
| --- | --- |
| 01-p1-eyes.png | Phase 1: twelve eye glints on the eyes painted on its head and neck |
| 02-eyes-struck.png | Darius's jump attacks burst eyes (4 of 12 gone, checked) |
| 03-p2-dark-eyes.png | Phase 2: the shore goes dark; only Darius's light and its glowing eyes show the Leviathan |
| 04-p2-blindside.png | A blindside bite telegraphed behind the player in the dark (checked); the eyes ride its head through the pose |
| 05-p3-rifts.png | Phase 3: the dark lifts, rift beams and roars |
| 06-fallen.png | It falls: Overdrive unlocked and the rift opens (checked) |

Tests:
- `tests/unit/enemies/leviathan_test.gd` (9). These first failed to load because the class did not exist. They cover:
  - 12 eyes of 300 HP;
  - every 3rd eye staggering it for 5 s;
  - eye damage also wounding it;
  - body hits building no posture;
  - the 2/2/1 attack rule per phase;
  - phase 2 dark lit only by live eyes;
  - phase 3 lifting the dark;
  - where a blindside bite lands;
  - its on-defeat flags.
- `tests/integration/enemies/leviathan_fight_test.gd` (1): through the game, from eyes and stagger, through dark and light, to the win. Darius's distrust ends, the Matrix drops, and the result is saved.

Problems found while playing it, now fixed:
- The eyes first showed as big white balls beside its body. They are now small glints placed on the painted eyes, from their pixel positions on the painting, and they ride the rig's head and neck parts. The sprite went from 6.5 m to 5 m so jump attacks reach the eyes.
- The blindside could never be chosen: its strike reach was also its choice range. Choice range and reach are now separate.

Not covered: Track 13 (story 048) and its own animation clips (story 051).
