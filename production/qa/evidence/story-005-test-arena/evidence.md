# Evidence — Story 005: Test arena

Run result: VERIFIED (windowed Movie Maker captures, 1280x720 window, 1920x1080 viewport).

| Shot | Shows |
| --- | --- |
| `01-arena-first-pass.png` | First build: depth layers present, but a dark ceiling band, a floor-level foreground block over the fight, and dark characters on a dark set. 174 draw calls. |
| `02-arena-readability-pass.png` | Brighter play plane, darker fogged far layers, rim-lit characters, no floor-level foreground. Wave 3 (Warden, Watcher, 3 Crawlers): 155 draws. |
| `03-arena-final-wave3.png` | Same frame after limiting shadow casters to each body's torso and legs: **119 draw calls** with 5 enemies and the player on screen. |

Acceptance criteria:

- [x] 40 m+ floor at z = 0, two ledges (top 1.6 m, under the 2.2 m jump apex), side walls; layers at z = -6 (broken columns), -14 (aqueduct arches with a teal channel), -30 (cavern wall with crystals); thin stalactites at z = +4 for foreground parallax.
- [x] Every material comes from `src/arenas/arena_materials.gd` (swap point for final art).
- [x] WorldEnvironment: depth fog, AgX tonemap, glow; one shadowed directional key, two unshadowed omnis (torch, rune) — 3 dynamic lights, the addendum budget.
- [x] SideCamera: FOV 35°, 14 m back, look-ahead, vertical dead zone, interpolated follow, arena clamp, shake with a 0–100 % scale, ultimate zoom.
- [x] Draw calls < 150: 119 in the busiest wave (static decoration merged into one mesh per material; shadows only near the play plane).
- [x] 60 FPS on the Windows dev PC with the debug HUD (live runs: 60–61 FPS, see story 013 shots).

Not verified here: 60 FPS on the target phone (no Snapdragon 778-class device attached; the emulator renders in software).
