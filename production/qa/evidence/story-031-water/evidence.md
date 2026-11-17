# Story 031 evidence: water

Run: `bash tools/python.sh tools/playtest/water_check.py`. A pool is poured into room z1_03 with the
bridge's `water` command, because Zone 3's real pools arrive with story 038. Log:
`water-run-output.txt`, 7 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-pool.png | The pool: a translucent body with a moving glint on the surface |
| 02-swimming.png | Seris floating with her head above the surface |
| 03-frozen-patch.png | Frost Binding cast from the water freezes the surface |
| 04-on-the-ice.png | Seris standing on the ice slab at the old surface height |
| 05-water-rising.png / 06-risen.png | The surface rising 1.5 m over 2 s (the Sovereign's phase 2) while the ice stays where it froze |

Tests:
- `tests/unit/world/water_test.gd` (13). They first failed to load because `Water` did not exist.
- `tests/integration/world/water_swim_test.gd` (6).

Two bugs were found in play, and each now has a test that was seen failing first:
1. The buoyancy rise cap clipped a jump out of the water to 4 m/s.
2. Walking into water over flat ground never floated, because standing on the bottom skipped the water rule.

Not covered: a swim animation (story 039). Seris stands upright in the water.
