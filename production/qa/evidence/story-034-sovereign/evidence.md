# Story 034 evidence: boss framework and the Weeping Sovereign

Run: `bash tools/python.sh tools/playtest/sovereign_check.py`. Log: `run-output.txt`, 7 checks, 0 failed.
The stage is room z1_03 with a pool poured by the bridge; her throne hall is built in story 038.
The bridge's `boss` command sets her health to walk the phases.

| Shot | Shows |
| --- | --- |
| 01-sovereign-bars.png | Her name and health bar across the top, with the 60 % and 25 % phase marks; falling tears |
| 02-p1-*.png | Phase 1 attacks, telegraphed (grief wave, veil sweep) |
| 03-p2-water-rising.png / 04-p2-flooded.png | Phase 2: the arena water rises 1.5 m |
| 05-p3-ember_sweep.png | Phase 3: an Ember attack with its gold parry cue |
| 06-fallen.png | She falls |

Tests:
- `tests/unit/enemies/boss_test.gd` (8): phases by health, the transition stretched to the music boundary by at most 1 s, 2/2/1 attacks per phase, Ember in phase 3, the invulnerable change, 4 s open at 2x after a posture break, the water rise, and the full loot list.
- `tests/integration/enemies/sovereign_fight_test.gd` (2): the arena locks, the HUD shows her bars, three phases, the win opens the bars, the Crown Fragment drops, Caelan gets +1 Affinity and his line, the result is saved and she stays dead. Leaving mid-fight restarts her at phase 1.

The unit tests first failed to load: the classes did not exist.

Not covered:
- Her look per phase; her blades stay blue in phase 3 (story 039).
- The phase music (story 035). Until then she keeps the zone track, and the change uses the 1.5 s base time with no music boundary.
- How long the fight takes by hand (the target is 3-5 min on Normal), which needs a real playthrough.
