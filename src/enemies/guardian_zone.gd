class_name GuardianZone
extends Node3D
## One hittable part of the Guardian Below (story 044): a fist or its core. A target in the combat
## world whose rect follows the Guardian (mirrored with its facing); hits pass to
## `GuardianBelow.zone_hit` with the zone's name, which decides posture and armour.

var guardian: GuardianBelow
## "fist" or "core".
var zone: String = "fist"
## The rect relative to the Guardian's feet when it faces right (x mirrors when it faces left).
var offset: Rect2
var team: int = CombatWorld.TEAM_ENEMY


func _ready() -> void:
	if guardian != null and guardian.world != null:
		guardian.world.register(self)


func _exit_tree() -> void:
	if guardian != null and guardian.world != null:
		guardian.world.unregister(self)


func hurt_rect() -> Rect2:
	var g := guardian.global_position
	var x := offset.position.x if guardian.facing >= 0 else -offset.position.x - offset.size.x
	return Rect2(g.x + x, g.y + offset.position.y, offset.size.x, offset.size.y)


func is_alive() -> bool:
	return guardian != null and is_instance_valid(guardian) and guardian.is_alive()


func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	return guardian.zone_hit(p, zone)


## For effects and the bridge: posture, status and facing are the Guardian's.
func _get(property: StringName) -> Variant:
	if property in [&"posture", &"status", &"facing", &"health", &"data", &"tier"] and guardian != null:
		return guardian.get(property)
	return null
