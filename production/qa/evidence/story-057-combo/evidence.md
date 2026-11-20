# Story 057 evidence: horizontal slashes and combo moves

`bash tools/python.sh tools/playtest/combo_check.py` (7 checks pass), each shot as the blow lands:

- 1-cut, 2-backhand, 3-rising, 4-finisher: the ground chain.
- 5-air-cut: an attack in the air.
- 6-dash-slash: an attack out of a dodge.
- 7-rising-cut: up + attack.

Rig clips checked frame by frame with `tools/art/rig_preview.gd` (attack_0-3, attack_air_0/1,
attack_dash, attack_up). Tests: `tests/unit/vessels/combo_moves_test.gd` (4); full suite 454 passed.
