# Story 054 evidence: pixel look, zoomed-out camera, layered rooms, the world map

`bash tools/python.sh tools/playtest/look_check.py`

- room-*.png: one room per zone at the new framing (360-row pixel art, camera 18 m back).
- upper-*.png: standing on the new upper levels (ledges, balconies, chains, candles, depth layers).
- map.png: the new world map in the pause menu.

Tests: `tests/unit/world/upper_levels_test.gd` (7), `tests/integration/world/spikes_test.gd` (1);
full suite 432 passed; smoke ok.
Generator: `bash tools/python.sh tools/world/build_upper.py` (47 rooms with upper levels; every new
reward and doorway checked reachable by a jump/fall walker).

## Second pass (2026-11-18, decision D-062): ground, shadows, dust, run

- Every shot above was retaken at the new framing: camera 23 m back, flatter angle, 400 pixel rows,
  at most 0.6 m of ground under the floor.
- room-*.png / upper-*.png: the new ground (worn slab edge, carved face, darkness by depth, rock
  teeth, zone accents: moss, roots with glowing drips, gold moulding, embers).
- action-run.png: footstep dust behind the feet, shadow under the body.
- action-jump.png: take-off dust on the floor, the shadow left on the ground under the jump.
- action-land.png: landing dust both ways.
- action-attack.png: a scuff of dust at the front foot as the blow lands.

Tests: `tests/unit/world/ground_dresser_test.gd` (5), `tests/unit/vfx/dust_fx_test.gd` (6, incl.
the shadow on the floor and shrinking with height); full suite 443 passed; smoke ok; drive (44),
drive_m2, drive_m3, drive_m4, zone4_walk, weapons_check and art_v2_check all pass.
Run cycle checked with `tools/art/rig_preview.gd` (caelan, darius).
