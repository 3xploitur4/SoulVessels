class_name DustFx
extends RefCounted
## Dust and grit kicked off the ground (story 054, decision D-062): footsteps while running, a
## spray on take-off and landing, a skid on turns and dodges, a scuff on every grounded strike
## and a burst with flying grit on heavy blows. Each burst is a one-shot CPU particle system that
## frees itself when done. Shapes and counts come from data/art/dust.json; the colour is the
## room's (`tint`, set when a room is built from its theme's "dust").
##
##     DustFx.spawn(self, "land", global_position)            # both ways
##     DustFx.spawn(self, "skid", global_position, -facing)   # one way

const PATH := "res://data/art/dust.json"

## Colour of the current room's dust.
static var tint: Color = Color(0.62, 0.65, 0.72)

static var _cfg: Dictionary = {}
static var _puff_mat: StandardMaterial3D
static var _chip_mat: StandardMaterial3D


## Every kind's settings plus "step_every_s" (read once).
static func config() -> Dictionary:
	if _cfg.is_empty() and FileAccess.file_exists(PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if d is Dictionary:
			_cfg = d
	return _cfg


## Settings of burst `kind` ({} when unknown).
static func kind(name: String) -> Dictionary:
	return (config().get("kinds", {}) as Dictionary).get(name, {})


## Seconds between footstep puffs at run speed share `speed` (1 = full run).
static func step_interval(speed: float) -> float:
	return float(config().get("step_every_s", 0.3)) / clampf(speed, 0.6, 1.4)


## Throw a burst of `kind` at world point `at` (the feet). `dir` is +1 / -1 for a one-way spray
## (ignored by kinds that spray both ways); `strength` scales the count and the speed. Added
## to the running scene next to `near`; returns the emitters made (empty when `near` is not in a
## scene tree or the kind is unknown).
static func spawn(near: Node, name: String, at: Vector3, dir: float = 1.0, strength: float = 1.0) -> Array[CPUParticles3D]:
	var out: Array[CPUParticles3D] = []
	var k := kind(name)
	if k.is_empty() or near == null or not near.is_inside_tree():
		return out
	var tree := near.get_tree()
	var parent: Node = tree.current_scene if tree.current_scene != null else tree.root
	var sides: Array[float] = []
	if bool(k.get("both", false)):
		sides.assign([-1.0, 1.0])
	else:
		sides.append(signf(dir) if dir != 0.0 else 1.0)
	var count := maxi(1, int(round(float(k.get("amount", 6)) * strength / float(sides.size()))))
	for side in sides:
		out.append(_emitter(parent, at, side, k, count, strength, false))
		var chips := int(round(float(k.get("chips", 0)) * strength / float(sides.size())))
		if chips > 0:
			out.append(_emitter(parent, at, side, k, chips, strength, true))
	return out


static func _emitter(parent: Node, at: Vector3, side: float, k: Dictionary, count: int, strength: float, chips: bool) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "Dust"
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.85
	p.amount = count
	p.lifetime = float(k.get("life", 0.5)) * (1.4 if chips else 1.0)
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.18, 0.03, 0.12)
	var lift := float(k.get("lift", 0.3))
	p.direction = Vector3(side, lift + (0.9 if chips else 0.0), 0.0).normalized()
	p.spread = float(k.get("spread", 25.0)) * (1.6 if chips else 1.0)
	p.flatness = 0.7
	var speed: Array = k.get("chip_speed" if chips else "speed", [1.0, 2.0])
	p.initial_velocity_min = float(speed[0]) * sqrt(strength)
	p.initial_velocity_max = float(speed[1]) * sqrt(strength)
	if chips:
		p.gravity = Vector3(0.0, -15.0, 0.0)
		p.damping_min = 0.4
		p.damping_max = 0.8
		p.angular_velocity_min = -540.0
		p.angular_velocity_max = 540.0
	else:
		p.gravity = Vector3(0.0, float(k.get("rise", 0.4)), 0.0)
		p.damping_min = float(k.get("damping", 3.0)) * 0.8
		p.damping_max = float(k.get("damping", 3.0)) * 1.2
		p.angle_min = 0.0
		p.angle_max = 360.0
	var size: Array = k.get("chip_size" if chips else "size", [0.12, 0.24])
	p.scale_amount_min = float(size[0]) * sqrt(strength)
	p.scale_amount_max = float(size[1]) * sqrt(strength)
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 1.0 if chips else 0.55))
	grow.add_point(Vector2(1.0, 0.8 if chips else 1.35))
	p.scale_amount_curve = grow
	var a := float(k.get("alpha", 0.6))
	var fade := Gradient.new()
	if chips:
		var c := tint.darkened(0.55)
		fade.set_color(0, Color(c.r, c.g, c.b, 1.0))
		fade.set_color(1, Color(c.r, c.g, c.b, 0.0))
		fade.add_point(0.75, Color(c.r, c.g, c.b, 1.0))
	else:
		# Dust is unshaded, so it is dimmed a little to sit in the room's light.
		var dim := tint.darkened(0.18)
		fade.set_color(0, Color(dim.r, dim.g, dim.b, a))
		fade.set_color(1, Color(dim.r, dim.g, dim.b, 0.0))
		fade.add_point(0.35, Color(dim.r, dim.g, dim.b, a * 0.75))
	p.color_ramp = fade
	var q := QuadMesh.new()
	q.size = Vector2.ONE
	q.material = _chip_material() if chips else _puff_material()
	p.mesh = q
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(p)
	# Just in front of the feet so the puffs read over the slabs.
	p.global_position = at + Vector3(0.0, 0.12, 0.35)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


static func _puff_material() -> StandardMaterial3D:
	if _puff_mat == null:
		_puff_mat = StandardMaterial3D.new()
		_puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_puff_mat.vertex_color_use_as_albedo = true
		_puff_mat.albedo_texture = SpriteArt.blob()
		_puff_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_puff_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _puff_mat


static func _chip_material() -> StandardMaterial3D:
	if _chip_mat == null:
		_chip_mat = StandardMaterial3D.new()
		_chip_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_chip_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_chip_mat.vertex_color_use_as_albedo = true
		# A near-solid disc: an untextured billboard-particle material drew each chip as a
		# full-size grey square (Godot 4.7).
		_chip_mat.albedo_texture = SpriteArt.disc(0.8)
		_chip_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_chip_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _chip_mat
