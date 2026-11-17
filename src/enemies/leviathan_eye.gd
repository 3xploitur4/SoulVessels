class_name LeviathanEye
extends Node3D
## One of the Abyssal Leviathan's twelve eyes (story 045): a glowing target of 300 HP on its body.
## Hits pass to `AbyssalLeviathan.eye_hit`. Its rect follows the body and mirrors with its facing.

var leviathan: AbyssalLeviathan
## Position relative to the Leviathan's feet when it faces right, in metres.
var offset: Vector2
var hp: float = 300.0
var team: int = CombatWorld.TEAM_ENEMY

## Taller than wide, reaching down: the eyes sit high on its head, so jump attacks find them.
const SIZE := Vector2(0.8, 1.3)

var _glow: Node3D
## The rig part this eye rides ("head" or "neck"), its position in that part's space, and whether
## it has been attached yet (at rest, the first frame the rig exists).
var bone_name: String = "head"
## The eye's pixel in the painting (set from data); where it sits on its part.
var paint_px: Vector2 = Vector2(-1.0, -1.0)
var _bone: Node3D
var _local: Vector3


func _ready() -> void:
	_glow = VfxShapes.bolt(Color(0.45, 0.95, 1.0), 0.11, 1.4)
	add_child(_glow)
	if leviathan != null and leviathan.world != null:
		leviathan.world.register(self)


func _exit_tree() -> void:
	if leviathan != null and leviathan.world != null:
		leviathan.world.unregister(self)


func _process(_delta: float) -> void:
	if leviathan == null:
		return
	if _bone == null:
		var x := offset.x * float(leviathan.facing)
		position = Vector3(x, offset.y, 0.45)
		_attach()
		return
	if is_instance_valid(_bone):
		global_position = _bone.to_global(_local)


## Ride the rig part: remember where the eye sits in that part's space, so it follows every pose.
func _attach() -> void:
	var vis := leviathan.visual as EnemySpriteVisual
	if vis == null or not (vis.body is RigBody):
		return
	var b := (vis.body as RigBody).bone(bone_name)
	if b == null or not b.is_inside_tree():
		return
	_bone = b
	if paint_px.x >= 0.0:
		_local = (vis.body as RigBody).part_point(bone_name, paint_px)
	else:
		_local = b.to_local(global_position)


func hurt_rect() -> Rect2:
	var c := Vector2(global_position.x, global_position.y)
	return Rect2(c - SIZE * 0.5, SIZE)


func is_alive() -> bool:
	return hp > 0.0 and leviathan != null and is_instance_valid(leviathan) and leviathan.is_alive()


func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	return leviathan.eye_hit(self, p)


## The eye bursts and goes dark.
func burst() -> void:
	if _glow != null:
		_glow.visible = false
	GameEvents.ultimate_fx_requested.emit("slash", global_position, 1.0)
	Sfx.play("posture_break")


func _get(property: StringName) -> Variant:
	if property in [&"posture", &"status", &"facing", &"health", &"data", &"tier"] and leviathan != null:
		return leviathan.get(property)
	return null
