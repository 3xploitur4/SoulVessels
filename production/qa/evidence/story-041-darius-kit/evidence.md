# Story 041 evidence: Darius's kit

Run: `bash tools/python.sh tools/playtest/darius_check.py` (room z1_03). Log: `run-output.txt`, 5 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-hammer.png | The hammer combo, which has hyper-armor |
| 02-crushing-blow.png | Crushing Blow through a Branded Warden's shield (150 posture) |
| 03-groundbreaker.png | Groundbreaker killing four Crawlers outright |
| 04-shoulder-charge.png | The shoulder-charge dodge |
| 05-meteor-drop.png | Meteor Drop on swap-in |
| 06-worldbreaker.png | Worldbreaker breaking the guard of every enemy in range |

Unit tests: `tests/unit/vessels/darius_kit_test.gd` (9). They first failed to load because `DariusKit` did not exist. They cover:
- the hyper-armored combo;
- the Last Survivor formula and its cap, and its effect on his hits;
- Crushing Blow's shield, masonry and posture;
- the 1 HP Sync Guard;
- a Crawler killed outright by heavy AoE, and not by a plain AoE;
- Worldbreaker;
- the distrust multiplier switching off.

Not covered: his own animation clips (story 051). Until then he uses Caelan's.
