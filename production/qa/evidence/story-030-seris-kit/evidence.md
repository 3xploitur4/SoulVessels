# Story 030 evidence: Seris's kit

Run: `bash tools/python.sh tools/playtest/seris_check.py` (room z1_03, loadout Seris + Caelan).
Log: `seris-run-output.txt`, 8 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-idle.png | Seris active, a Crawler 9 m away |
| 02-arcane-bolt-flight.png | An Arcane Bolt in flight (three bolts kill the Crawler) |
| 03-frost-binding.png | The Frost Binding field: a frost sheet and a row of ice crystals; the Crawler inside takes the Frost build-up |
| 04-aether-shield.png | The Aether Shield bubble around Seris (3 s) |
| 05-rift-step.png | Rift Step out of a root-snare (the snare breaks at once) |
| 06-aether-burst.png | Swapping back to Seris plays Aether Burst |
| 07-cataclysm.png | Cataclysm Fused: a meteor falling onto the Crawlers |

Unit tests: `tests/unit/vessels/seris_kit_test.gd` (11). They first failed to load because
`SerisKit` and `FrostField` did not exist; all pass after the kit was written.

Not covered here: Seris's cast and swim animations (story 039); she still plays her rig's generic
attack clip while casting. Water freezing from Frost Binding is wired (`GameEvents.frost_field_cast`)
but needs water (story 031).
