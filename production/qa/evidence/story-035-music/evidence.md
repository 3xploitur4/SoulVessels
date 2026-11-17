# Story 035 evidence: Track 05 and boss Track 08

This story is audio, so its evidence is the run log and the files, not screenshots.

- `assets/audio/music/zone3/`: Track 05 "Drowned Court", 72 BPM 4/4, 8 bars (26.7 s). Bed, pulse, combat and elite stems plus a lead for each of the five Vessels.
- `assets/audio/music/boss_sovereign/`: Track 08 "Tears of the Sovereign", three phase clips, each 8 bars at 76 BPM (25.3 s):
  - p1: a solo cello over a drone.
  - p2: strings and choir.
  - p3: double time, the 152 BPM feel.
- Synthesise them with `bash tools/python.sh tools/audio/synth_stems.py --only zone3,boss_sovereign`. Real recordings drop in under the same names.
- The Seris lead was already in Tracks 01 and 03.

In-game run: `bash tools/python.sh tools/playtest/sovereign_check.py`, log copied here as `sovereign-run-output.txt` (10 checks, 0 failed). It shows:
- Her track starts at phase 1 when the fight begins.
- The phase 2 clip comes in on the 4-bar boundary at 12.63 s.
- The zone track returns after she falls.

Unit tests: `tests/unit/audio/boss_music_test.gd` (6). They first failed with script errors because the boss methods did not exist.

Not covered: a listen by ear. The stems are synthesised placeholders.
