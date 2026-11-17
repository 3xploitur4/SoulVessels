# Story 044 evidence: the Guardian Below

Run: `bash tools/python.sh tools/playtest/guardian_check.py`. Log: `run-output.txt`, 7 checks, 0 failed. The stage is z1_03 with a slide floor laid by the bridge; Zone 4's elevator comes in story 049.

| Shot | Shows |
| --- | --- |
| 01-p1-*.png | Phase 1: the chest laser and the seismic wave, telegraphed; the boss bar shows the 65 % and 30 % marks |
| 02-p2-tilted.png | Phase 2: the elevator tilts 15 degrees; the camera rolls with it and the floor's streaks run downhill |
| 03-p2-boulder.png | Darius has slid to the low end; one boulder rolled in the 10 s (checked) |
| 04-p3-core.png | Phase 3: the core opens, attacks at +40 % speed, warm tint |
| 05-fallen.png | It falls: Heart of the Guardian, 3 Greater Shards, the Greatsword unlock |

Tests:
- `tests/unit/enemies/guardian_test.gd` (7). They first failed to load because the class did not exist. They cover:
  - which zone builds posture in which phase;
  - the 2/2/1 attack rule per phase;
  - fist posture, with the core armoured until phase 3;
  - the core opening;
  - the tilt;
  - the faster attacks in phase 3;
  - boulders from phase 2.
- `tests/integration/enemies/guardian_fight_test.gd` (1): the arena locks; three phases; the tilt; the win opens the bars, drops the Heart, sets `unlock_greatsword` and is saved.

Not covered:
- Its own animation clips per attack (story 051).
- Its music, Track 10 (story 048). Until then it plays the zone track.
