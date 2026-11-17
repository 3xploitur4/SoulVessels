# Story 042 evidence: cracked masonry

Run: `bash tools/python.sh tools/playtest/masonry_check.py`. Log: `run-output.txt`, 11 checks, 0 failed.

The run checks two things:
- Caelan's sword does not break the wall.
- Darius's Crushing Blow breaks all five new masonry secrets, and each reward behind them is taken:
  - z1_14: Standard Soul Shard
  - z1_06: Polished Basalt Core
  - z2_05: Greater Soul Shard
  - z2_14: Echoing Relic
  - z3_12: Polished Basalt Core

Shots:
- `01-cracked-wall.png`: the orange-veined wall and its Examine hint.
- `02-wall-broken.png`: the same wall gone after the blow.
- `03-z3-study-secret.png`: the secret in z3_12.

Integration tests: `tests/integration/world/masonry_test.gd` (5).
- A plain hit does nothing.
- Crushing Blow opens the wall; it is saved and stays open on return.
- A real Crushing Blow from Darius and a real Groundbreaker both break it.
- A masonry floor drops the player to the floor below.

The wall code was written in the same step as the tests, so I did not watch these tests fail first.

Two playtest-script errors are fixed: Crushing Blow's cooldown between walls, and checking a relic as a lore pickup rather than an inventory item.

Zone 4 (story 049) uses the floor case and z3_18's wall into Zone 4.
