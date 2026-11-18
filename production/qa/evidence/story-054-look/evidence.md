# Story 054 evidence: pixel look, zoomed-out camera, layered rooms, the world map

`bash tools/python.sh tools/playtest/look_check.py`

- room-*.png: one room per zone at the new framing (360-row pixel art, camera 18 m back).
- upper-*.png: standing on the new upper levels (ledges, balconies, chains, candles, depth layers).
- map.png: the new world map in the pause menu.

Tests: `tests/unit/world/upper_levels_test.gd` (7), `tests/integration/world/spikes_test.gd` (1);
full suite 432 passed; smoke ok.
Generator: `bash tools/python.sh tools/world/build_upper.py` (47 rooms with upper levels; every new
reward and doorway checked reachable by a jump/fall walker).
