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
## Freeze the game for `duration` seconds of real time (hitstop on hits and parries).
signal hitstop_requested(duration: float)
## Add camera shake (0..1 trauma).
signal camera_shake_requested(trauma: float)
## A big effect: "final_stand", "dance_of_shadows", "slash"... at `where`, `size` metres.
signal ultimate_fx_requested(kind: String, where: Vector3, size: float)
## Vanishing Act started (true) or ended (false).
signal stealth_changed(hidden: bool)
## A hit landed somewhere: for sparks and damage numbers. `crit` and `blocked` style the effect.
signal hit_fx_requested(where: Vector3, amount: float, crit: bool, blocked: bool)
## Seris's Frost Binding landed on `rect` (world X/Y) for `seconds`: water under it freezes (story 030/031).
signal frost_field_cast(rect: Rect2, seconds: float)
## A boss fight began (story 034): the HUD shows its bars, the music director its track.
signal boss_started(boss: Node)
## A boss moved to `phase` (0-based); the music moves to the next clip.
signal boss_phase_changed(boss: Node, phase: int)
## A boss fell.
signal boss_defeated(boss: Node)
## A heavy slam landed over `rect` (world X/Y); `info` says what it can break ("breaks_masonry"). Story 041/042.
signal slam_landed(rect: Rect2, info: Dictionary)
