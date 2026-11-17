class_name WeepingSovereign
extends Boss
## The Weeping Sovereign (addendum boss table; Narrative 3): Caelan's queen, mad with grief, the
## Zone Boss of the Sunken Palace. 4,500 HP, posture 500, phases at 60 % and 25 %. Phase 2 raises
## the throne hall's water 1.5 m; phase 3 sets her lance and tears alight (Ember). Every attack
## and number is in data/balance/enemies/weeping_sovereign.json; this class only names her.


func _init() -> void:
	enemy_id = "weeping_sovereign"
	turn_delay_s = 0.25


func _hurt_size() -> Vector2:
	return Vector2(1.5, 2.8)
