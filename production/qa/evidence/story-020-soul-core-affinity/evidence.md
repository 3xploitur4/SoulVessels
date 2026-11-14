# Evidence — Story 020: Soul Core tree and Affinity progression

Run result: VERIFIED in the running game (bridge, `run-output.txt`) and by tests.

In the game, at the Altar of the Fallen Aqueduct with 5 Lesser Soul Shards: bound Core Heart,
Vitality I, Vessel I and Endurance I. Max HP 420 -> 450, flasks 3 -> 4, 1 shard left. Pressing the
locked Vitality V did nothing. Then 36 kills' worth of Affinity XP in three steps: "Caelan:
Affinity 1" and "A memory of Caelan stirs. Read it at a Soul Altar." (the memory joined the lore),
then "Caelan: Affinity 2" and "Sync Guard awakened".

| Shot | Shows |
| --- | --- |
| `01-tree-empty.png` | The tree with only the Core Heart available. |
| `02-tree-four-bound.png` | Four nodes bound (gold), the next ones available (bright ring), the rest locked (dark); shard count and the focused node's effect and state in words. |
| `03-affinity-toasts.png` | The Affinity level-up toasts. |

Tests: `tests/unit/progression/soul_core_test.gd` (7: 20 nodes at 1 shard, requirements, refusals,
summed modifiers, flask nodes reach 6 charges), `affinity_test.gd` (5: thresholds, per-Vessel XP,
memory bonus and cap, combat seconds, the wisp earns nothing) and
`tests/integration/progression/soul_core_game_test.gd` (5: HP nodes raise max HP and heal the
gain and save; a locked node is refused; flask, gauge and stamina nodes apply; bonuses survive a
reload; XP unlocks Sync Guard and the memory, and reading the memory adds a level).

Decisions D-027 (tree layout) and D-028 (XP rates, provisional).
