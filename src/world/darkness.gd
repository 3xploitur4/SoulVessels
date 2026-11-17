class_name Darkness
extends CanvasLayer
## A dark room (story 043; addendum Zone 4 "darkness (light radius)"). A screen overlay turns
## everything near black except: a circle of light around the player (the soul's own glow, which
## grows with the Soul Gauge), the room's lamps, and any enemy showing an attack cue, so a
## telegraph is never hidden. It is drawn under the HUD and adds no 3D lights (the 3-light budget
## stands). The Leviathan's phase 2 turns it on for its arena.
##
##     var d := Darkness.new()
##     d.player = player; d.lamps = [Vector3(10, 3, 0)]
##     add_child(d)

const SHADER := preload("res://src/world/darkness.gdshader")
const MAX_HOLES := 8

var player: Player
## Lamp positions (world) and the radius each lights, in metres.
var lamps: Array[Vector3] = []
var lamp_radius_m: float = 3.0
## Extra lit points supplied by others each frame (the Leviathan's eyes): world position -> radius.
var glow_points: Callable
var config: Dictionary = {}
## 0..1: how dark it is (fades in and out).
var amount: float = 1.0

var _rect: ColorRect
var _mat: ShaderMaterial
var _target: float = 1.0


## Light radius around the player: `base` metres plus `per_ratio` times the Soul Gauge's fullness.
static func radius_for(base: float, per_ratio: float, gauge_ratio: float) -> float:
	return base + per_ratio * clampf(gauge_ratio, 0.0, 1.0)


func _ready() -> void:
	layer = 4
	if config.is_empty():
		var c: Variant = Balance.combat("darkness")
		config = c if c is Dictionary else {}
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_rect.material = _mat
	add_child(_rect)


## Fade the darkness to `to` (0 = none, 1 = full) over `seconds`.
func fade(to: float, seconds: float) -> void:
	_target = to
	if seconds <= 0.0:
		amount = to


func _process(delta: float) -> void:
	amount = move_toward(amount, _target, delta / maxf(float(config.get("fade_s", 1.0)), 0.01))
	_rect.visible = amount > 0.01
	var cam := get_viewport().get_camera_3d()
	if cam == null or not _rect.visible:
		return
	var holes: Array[Vector4] = []
	var px_per_m := _pixels_per_metre(cam)
	if player != null and is_instance_valid(player):
		var r := radius_for(float(config.get("radius_m", 3.5)), float(config.get("gauge_bonus_m", 2.0)),
			player.gauge.value / maxf(player.gauge.max_value, 1.0))
		_add(holes, cam, player.global_position + Vector3(0.0, 1.0, 0.0), r * px_per_m)
	for l in lamps:
		_add(holes, cam, l, lamp_radius_m * px_per_m)
	if player != null and player.world != null:
		var foes: Array[Node3D] = []
		player.world.members_of(CombatWorld.TEAM_ENEMY, foes)
		for e in foes:
			if e is EnemyBase and (e as EnemyBase).state == EnemyBase.STATE_TELEGRAPH:
				_add(holes, cam, e.global_position + Vector3(0.0, 1.2, 0.0), float(config.get("cue_radius_m", 2.2)) * px_per_m)
	if glow_points.is_valid():
		var pts: Dictionary = glow_points.call()
		for p: Vector3 in pts.keys():
			_add(holes, cam, p, float(pts[p]) * px_per_m)
	var arr := PackedVector4Array()
	for i in range(MAX_HOLES):
		arr.append(holes[i] if i < holes.size() else Vector4(0, 0, 0, 0))
	_mat.set_shader_parameter("holes", arr)
	_mat.set_shader_parameter("count", mini(holes.size(), MAX_HOLES))
	_mat.set_shader_parameter("darkness", amount * float(config.get("depth", 0.94)))
	_mat.set_shader_parameter("screen", get_viewport().get_visible_rect().size)


func _add(holes: Array[Vector4], cam: Camera3D, world: Vector3, radius_px: float) -> void:
	if holes.size() >= MAX_HOLES or cam.is_position_behind(world):
		return
	var s := cam.unproject_position(world)
	holes.append(Vector4(s.x, s.y, radius_px, 1.0))


func _pixels_per_metre(cam: Camera3D) -> float:
	var at := Vector3(cam.global_position.x, cam.global_position.y, 0.0)
	var a := cam.unproject_position(at)
	var b := cam.unproject_position(at + Vector3(1.0, 0.0, 0.0))
	return maxf(a.distance_to(b), 1.0)
