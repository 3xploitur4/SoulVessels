class_name Water
extends Node3D
## A body of water in a room (story 031; addendum Zone 3 "water levels", the tide puzzle, and the
## Weeping Sovereign's arena where water rises 1.5 m in phase 2). It spans `x_range` from `floor_y`
## up to `level`. The surface can rise or fall over time (`rise_to`). Frost over the surface
## (`GameEvents.frost_field_cast`, Seris's Frost Binding) freezes a patch into a standing ice
## platform that keeps its height when the water moves and melts after `freeze_s`.
##
## Swimming is the player's job; this class gives the depth and the vertical speed rule
## (`swim_vy`). Tuning lives in `combat.json` `water`.
##
##     var w := Water.new()
##     w.setup("pool", Vector2(4, 20), 0.0, 2.5)
##     rooms.features_root.add_child(w)
##     w.rise_to(4.0, 3.0)

## Every live Water node is in this group (the player looks it up each frame).
const GROUP := &"water"
const SURFACE_SHADER := preload("res://src/world/water_surface.gdshader")

## A frozen piece of surface.
class Patch:
	var x0: float
	var x1: float
	var top: float
	var left: float
	var body: StaticBody3D

var id: String = ""
var x_range: Vector2 = Vector2.ZERO
var floor_y: float = 0.0
var level: float = 0.0
var config: Dictionary = {}
var patches: Array[Patch] = []

var _target: float = 0.0
var _speed: float = 0.0
var _volume: MeshInstance3D
var _surface: MeshInstance3D



## Place the water. `xs` is (left, right) in room metres.
func setup(water_id: String, xs: Vector2, bottom: float, surface: float) -> void:
	id = water_id
	x_range = xs
	floor_y = bottom
	level = surface
	_target = surface
	if config.is_empty():
		var c: Variant = Balance.combat("water")
		config = c if c is Dictionary else {}


func _ready() -> void:
	add_to_group(GROUP)
	GameEvents.frost_field_cast.connect(_on_frost)
	_build_look()


func _physics_process(delta: float) -> void:
	step(delta)


## Move the surface to `target` over `seconds` (0 = at once).
func rise_to(target: float, seconds: float) -> void:
	_target = target
	if seconds <= 0.0:
		level = target
		_speed = 0.0
	else:
		_speed = absf(target - level) / seconds
	_update_look()


## Advance the surface and the frozen patches by `delta` seconds.
func step(delta: float) -> void:
	if level != _target:
		level = move_toward(level, _target, _speed * delta)
		_update_look()
	for i in range(patches.size() - 1, -1, -1):
		var p := patches[i]
		p.left -= delta
		if p.left <= 0.0:
			if p.body != null and is_instance_valid(p.body):
				p.body.queue_free()
			patches.remove_at(i)


## How far `pos` (room x, y) is under the surface; 0 when outside or above.
func depth_at(pos: Vector2) -> float:
	if pos.x < x_range.x or pos.x > x_range.y or pos.y < floor_y - 0.5:
		return 0.0
	return maxf(level - pos.y, 0.0)


## Freeze the part of the surface under a Frost field `rect` for `freeze_s` (the cast's own time
## is ignored: ice outlasts the field so a puzzle can be climbed). False when the field is
## beside the pool or too far above the surface.
func try_freeze(rect: Rect2, _seconds: float) -> bool:
	var x0 := maxf(rect.position.x, x_range.x)
	var x1 := minf(rect.end.x, x_range.y)
	if x1 - x0 < 0.3:
		return false
	var reach := float(config.get("freeze_reach_m", 2.0))
	# From the bank the field sits above the surface; from the water (floating) just below it.
	if level < rect.position.y - reach or level > rect.end.y + 0.6:
		return false
	var p := Patch.new()
	p.x0 = x0
	p.x1 = x1
	p.top = level
	p.left = float(config.get("freeze_s", 8.0))
	if is_inside_tree():
		p.body = _ice_body(p)
	patches.append(p)
	Sfx.play("frost")
	return true


## Vertical speed after `delta` for a body `depth` metres under the surface: gravity is weaker,
## buoyancy lifts anything deeper than `float_depth`, drag slows fast falls, and sink and rise
## speeds are capped. Pure, so the player and tests share it.
static func swim_vy(vy: float, depth: float, delta: float, gravity: float, cfg: Dictionary) -> float:
	var v := vy - gravity * float(cfg.get("gravity_mult", 0.35)) * delta
	if depth > float(cfg.get("float_depth", 1.2)):
		v += float(cfg.get("buoyancy", 16.0)) * delta
	v -= v * minf(float(cfg.get("drag", 2.0)) * delta, 1.0)
	# Buoyancy never lifts faster than max_rise_mps, but a jump or stroke keeps its own speed.
	var top := maxf(float(cfg.get("max_rise_mps", 4.0)), vy)
	return clampf(v, -float(cfg.get("max_sink_mps", 3.0)), top)


func _on_frost(rect: Rect2, seconds: float) -> void:
	try_freeze(rect, seconds)


# --- Look ------------------------------------------------------------------------------------

func _build_look() -> void:
	_volume = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.0, 1.0, 2.2)
	_volume.mesh = box
	_volume.material_override = ArenaMaterials.flat(Color(0.12, 0.32, 0.42, 0.5), 0.15, false, true)
	add_child(_volume)
	_surface = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.0, 2.2)
	plane.subdivide_width = 24
	_surface.mesh = plane
	_surface.material_override = _surface_material()
	add_child(_surface)
	for p in patches:
		if p.body == null:
			p.body = _ice_body(p)
	_update_look()


func _update_look() -> void:
	if _volume == null:
		return
	var w := x_range.y - x_range.x
	var h := maxf(level - floor_y, 0.01)
	_volume.scale = Vector3(w, h, 1.0)
	_volume.global_position = Vector3((x_range.x + x_range.y) * 0.5, floor_y + h * 0.5, -0.1)
	_volume.visible = level > floor_y + 0.01
	_surface.scale = Vector3(w, 1.0, 1.0)
	_surface.global_position = Vector3((x_range.x + x_range.y) * 0.5, level, -0.1)
	_surface.visible = _volume.visible


func _surface_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SURFACE_SHADER
	return m


func _ice_body(p: Patch) -> StaticBody3D:
	var thick := float(config.get("patch_thickness_m", 0.4))
	var body := StaticBody3D.new()
	body.name = "IcePatch"
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(p.x1 - p.x0, thick, 2.0)
	shape.shape = bs
	body.add_child(shape)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(p.x1 - p.x0, thick, 1.6)
	mi.mesh = bm
	mi.material_override = ArenaMaterials.flat(Color(0.78, 0.93, 1.0, 0.85), 0.8, false, true)
	body.add_child(mi)
	add_child(body)
	body.global_position = Vector3((p.x0 + p.x1) * 0.5, p.top - thick * 0.5, 0.0)
	return body
