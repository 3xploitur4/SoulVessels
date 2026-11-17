# Story 043 evidence: darkness and sliding floors

Run: `bash tools/python.sh tools/playtest/dark_slide_check.py` (room z1_03, using the bridge's `dark` and `slide` commands; Zone 4 uses both for real in story 049). Log: `run-output.txt`, 3 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-dark-empty-gauge.png | A dark room: a circle of light around Darius and a lamp's pool; the rest near black |
| 02-dark-full-gauge.png | With a full Soul Gauge the light around him is wider |
| 03-cue-in-the-dark.png | A Crawler's attack cue (the crimson X and its tell) lit through the dark |
| 04-slope.png | A 15 degree sliding floor: a slick strip whose streaks run downhill; standing still carries him 6 m |

Tests:
- `tests/unit/world/darkness_slide_test.gd` (6): the light radius against the gauge, the slope push, slower uphill running, tilting over time, and the zone's area. These first failed to load because the classes did not exist.
- `tests/integration/world/darkness_slide_room_test.gd` (4): a slope carries a standing player, uphill is slower, and dark rooms build their overlay with lamps (lit rooms have none).

One bug found in the tests and fixed: braking on a slope cancelled the slide when standing still. On a slope with no input there is now no braking, with a cap of 7 m/s.

How the darkness is made: a screen overlay with up to 8 light holes, drawn under the HUD. It adds no 3D lights, so the 3-lights-per-screen budget holds.
