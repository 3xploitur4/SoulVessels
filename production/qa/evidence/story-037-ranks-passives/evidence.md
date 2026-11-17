# Story 037 evidence: Vessel ability ranks and Sync passives

Run: `bash tools/python.sh tools/playtest/upgrade_check.py` (the Zone 1 altar; shards given by the
bridge). Log: `run-output.txt`, 4 checks, 0 failed.

| Shot | Shows |
| --- | --- |
| 01-upgrade-page.png | The altar's Upgrade page for Caelan: his four abilities with rank and the next rank's shard cost, and his three Sync passives with their buy cost |
| 02-after-buying.png | King's Judgment bought to rank 3 (2 + 3 Standard Shards) and King's Mercy bought and slotted |

How it works: every rank and passive is a data patch on the Vessel's balance numbers, applied when the Vessels are bound, so every ability already reads its new values. See `data/progression/ability_ranks.json` and `sync_passives.json`.

Tests:
- `tests/unit/progression/ranks_passives_test.gd` (11): the patch rules, rank costs 2/3, failed buys change nothing, rank-2 power and the rank-3 modifier, one passive slot, and the save round trip. Written by the opencode helper and reviewed.
- `tests/integration/progression/ranks_game_test.gd` (3): rank 3 King's Judgment reaches Caelan's kit; ranks and passive survive a reload; King's Mercy heals when a Sync Guard blocks a lethal blow.

These tests first failed to load: the classes did not exist.

Not covered:
- The rank-3 descriptions show only as tooltips, which touch screens cannot see.
- The addendum's own example, King's Judgment travelling along walls, is replaced by a wider, stronger wave (decision D-046).
