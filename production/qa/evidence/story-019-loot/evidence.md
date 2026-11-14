# Evidence — Story 019: Loot

Run result: VERIFIED in the running game (bridge, `run-output.txt`) and by tests.

In the Warden's Approach with drops forced to 100 % for the capture: two Crawler kills dropped
Crude Stone (common) and a Standard Soul Shard (rare), which popped out and flew to the player;
walking onto the placed parchment unlocked "Faded Parchment: A Child's Lesson" and marked
`z1_11:1` taken.

| Shot | Shows |
| --- | --- |
| `01-placed-parchment.png` | A placed pickup orb on the floor. |
| `02-drops-homing.png` | "+12" Essence pop-up, toasts in rarity colours. |
| `03-toasts.png` | Lore-found toast. |
| `04-inventory.png` | Inventory with rarity colour plus the rarity word, and descriptions. |

Tests: `tests/unit/progression/loot_table_test.gd` (6): 10,000 seeded normal kills give a 35 %
drop rate and 70/25/5 rarities within 1.5 points; elites always drop at 20/65/15; the enemy's own
pool wins and the zone pool fills gaps; weights respected; pity gives an Epic on the 16th elite
kill and resets; every pool item exists with the right rarity. `tests/integration/progression/
loot_pickup_test.gd` (4): a placed pickup is taken once and never returns; parchments become lore
entries in order; lore overflow pays Essence; a drop 6 m away reaches the player.

Decision D-026. New sounds: pickup, altar kindle, echo recovery (and the M2 traversal and gate
sounds used by stories 021-023).
