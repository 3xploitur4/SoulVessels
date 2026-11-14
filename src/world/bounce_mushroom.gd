class_name BounceMushroom
extends Node3D
## A bounce mushroom (story 021, addendum Zone 2): land on its cap and it throws you up to a
## height set in `combat.json` `traversal.bounce_height_m`. A fat pink cap on a short stalk, so it
## never reads as one of the teal or violet decor mushrooms. It has no collision: the cap catches
## a falling player by position, which is cheaper and cannot snag a dash.
##
##     var m := BounceMushroom.new()
##     m.player = player
##     features_root.add_child(m)

## Cap top above the base, and half its width, in metres.
const CAP_TOP := 0.9
const CAP_HALF := 0.8

var player: Player
## Launch speed in m/s (from the bounce height and gravity).
var launch_speed: float = 19.7

var _cap: MeshInstance3D
var _squash: float = 0.0
var _cooldown: float = 0.0


func _ready() -> void:
	var stalk := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.2
	cyl.bottom_radius = 0.3
	cyl.height = CAP_TOP - 0.3
	cyl.radial_segments = 8
	stalk.mesh = cyl
	stalk.position = Vector3(0.0, (CAP_TOP - 0.3) * 0.5, -0.2)
	stalk.material_override = ArenaMaterials.get_material("z2_stalk")
	add_child(stalk)
	_cap = MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = CAP_HALF
	dome.height = CAP_HALF
	dome.is_hemisphere = true
	dome.radial_segments = 16
	dome.rings = 5
	_cap.mesh = dome
	_cap.position = Vector3(0.0, CAP_TOP - 0.45, -0.2)
	_cap.scale = Vector3(1.0, 0.6, 1.0)
	_cap.material_override = ArenaMaterials.get_material("mushroom_cap")
	add_child(_cap)


## Is a body at `pos` moving at vertical speed `vy` landing on the cap?
func catches(pos: Vector3, vy: float) -> bool:
	var top := global_position.y + CAP_TOP
	return absf(pos.x - global_position.x) <= CAP_HALF + 0.15 and pos.y <= top + 0.15 and pos.y >= top - 0.45 and vy <= 0.5


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	_squash = maxf(_squash - delta * 4.0, 0.0)
	_cap.scale = Vector3(1.0 + 0.35 * _squash, 0.6 - 0.3 * _squash, 1.0 + 0.35 * _squash)
	if player == null or not is_instance_valid(player) or not player.is_alive() or _cooldown > 0.0:
		return
	if catches(player.global_position, player.velocity.y):
		player.bounce(launch_speed)
		_squash = 1.0
		_cooldown = 0.15
