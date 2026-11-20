# Story 058 evidence: Caelan's drawn attack frames

Cut from `docs/design/concept-art/attacks/Caelan_attack.jpg` by
`godot --headless --path . -s tools/art/slice_frames.gd` (15 frames, `builds/art/frames_caelan.png`).

- storyboard-combo.png: the ground chain (cut, backhand, rising diagonal, spinning finisher), each
  row sampled at 8 points through the move, as played in the game (`tools/art/rig_preview.gd`).
- storyboard-moves.png: air cut 1 and 2, dash slash, rising cut.
- attack_*.png: each move on its own.
- In game: `tools/playtest/combo_check.py` (7 checks pass), shots in `../story-057-combo/`.

Tests: `tests/unit/vfx/attack_frames_test.gd` (6); full suite 460 passed; drive, drive_m3 and
weapons_check pass.
