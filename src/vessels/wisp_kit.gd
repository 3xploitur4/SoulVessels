class_name WispKit
extends VesselKit
## The bare Intruder (story 024): a wisp that moves and jumps. No attack, no dodge, no abilities,
## no Resonance, no Sync. Every hook returns nothing so the player's input code needs no special
## case.


func combo_length() -> int:
	return 0


func primary_action(_player: Player, _index: int) -> PlayerAction:
	return null


func dodge_action(_player: Player) -> PlayerAction:
	return null


func air_dash_action(_player: Player) -> PlayerAction:
	return null


func ability_cooldown_keys() -> PackedStringArray:
	return PackedStringArray(["", ""])
