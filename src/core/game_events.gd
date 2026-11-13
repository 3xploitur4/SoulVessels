extends Node
## Global signal bus (autoload `GameEvents`). Systems emit here and never reach across the tree.
## Keep it to events more than one system listens to; a one-to-one link belongs on the node.

## The player's soul HP changed. `current` and `maximum` are HP points.
signal player_hp_changed(current: float, maximum: float)
## The shared Soul Gauge changed. `value` is 0..max, `bars` the whole bars filled.
signal soul_gauge_changed(value: float, maximum: float, bars: int)
## The active Vessel changed. `vessel_id` is the data id ("caelan", "nyra", ...).
signal vessel_swapped(vessel_id: String, slot: int)
## An enemy noticed the player (true) or lost them (false).
signal enemy_aggro_changed(enemy: Node, aggro: bool)
## An enemy died.
signal enemy_died(enemy: Node)
## The player landed a perfect parry on `attacker`.
signal perfect_parry(attacker: Node)
## The player dodged through a hit with i-frames within the perfect window.
signal perfect_dodge(attacker: Node)
## The last meaningful input device changed: "touch", "gamepad" or "keyboard".
signal input_device_changed(kind: String)
## The music state changed: "explore", "alert", "combat", "elite".
signal music_state_changed(state: String)
## A standard telegraph cue fired: kind is "parryable", "unblockable" or "magic".
signal telegraph_fired(kind: String, source: Node)
