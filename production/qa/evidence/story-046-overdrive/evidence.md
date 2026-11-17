# Story 046 evidence: Overdrive

Run: `bash tools/python.sh tools/playtest/overdrive_check.py` (room z1_03, Darius and Caelan; Overdrive is unlocked by the bridge's `overdrive` command, which in play comes from the Leviathan's flag). Log: `run-output.txt`, 3 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-overdrive-ready.png | A full gauge with Overdrive unlocked: the gauge label reads OVERDRIVE in pulsing gold |
| 02-darius-worldbreaker.png | Step 1: Darius's Worldbreaker |
| 03-caelan-final-stand.png | Step 2: a free swap and Caelan's Final Stand |
| 04-finisher.png | Step 3: the combined finisher |

Unit tests: `tests/unit/player/overdrive_test.gd` (4). These first failed to load because the functions did not exist.
- When it may start.
- Two bars give a plain Ultimate.
- The chain runs both Ultimates in order, then the finisher, invulnerable throughout.
- Ready needs the unlock.

Two bugs were found by the tests and fixed:
- The free swap was refused because the state still read "ultimate".
- The next step now starts from the frame loop whenever the current step has ended, rather than from one way of ending.

Rule: with Overdrive unlocked and a full 3-bar gauge, the Ultimate input (the touch button or LT+RT) is Overdrive; with 2 bars it is the plain Ultimate (decision D-053).
