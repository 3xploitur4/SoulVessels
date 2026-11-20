class_name SpriteBody
extends Node3D
## One painted character or enemy standing in the 3D world (story 027): the sprite on a bendable
## quad (see spatial_char_sprite_body.gdshader), a soft shadow cast on the ground under it (story
## 054), and an optional additive glow where the enemy's own tell lives (spine sacs, eye,
## brand). The owner sets targets (`lean`, `stride`, `crouch`...) and calls `tick`; the body
## eases toward them so poses blend.
##
##     var body := SpriteBody.create("echo_crawler")
##     add_child(body)
##     body.stride = 1.0; body.tick(delta)
##     body.flash(Color.GOLD, 0.2)

## Targets, eased every `tick`.
var lean: float = 0.0          # metres of shear at the head, positive = forward
var stride: float = 0.0        # 0 standing .. 1 full walk cycle
var crouch: float = 0.0        # 0..1 squash down
var stretch: float = 0.0       # 0..1 stretch along the move (dashes)
var roll: float = 0.0          # radians about the body centre (dodge roll)
var lift: float = 0.0          # metres above the ground (hops, lunges)
var forward: float = 0.0       # metres toward the facing (attack lunge)
var ghost: float = 0.0         # 0..1 stealth look
var glow: float = 0.0          # extra self-light
var tell: float = 0.0          # 0..1 strength of the enemy tell glow
## Walk cycle speed in radians per second at stride 1.
var step_rate: float = 11.0
## Up-and-down bob of the walk cycle (share of half the height). Rigs bob from their own clips
## (in step with the feet), so a RigBody sets this to 0.
var step_bob: float = 0.05
## While true the body leaves fading afterimages behind it (dashes, lunges, Shadowstep).
var trailing: bool = false
## Colour of the afterimages.
var trail_color: Color = Color(0.55, 0.7, 1.0)

## Afterimage pool size, spacing and life.
const GHOSTS := 5
const GHOST_EVERY_S := 0.03
const GHOST_LIFE_S := 0.24
## Story 054 (D-062): the ground shadow is cast down onto whatever ground is under the body (rock
## and plank walkways), shrinking and fading with height, so a jump keeps its shadow on the floor.
const SHADOW_MASK := 1 | (1 << 8)
const SHADOW_REACH_M := 14.0
## Opacity of the shadow on the ground, and the height (m) at which it is smallest and faintest.
const SHADOW_ALPHA := 0.7
const SHADOW_FADE_M := 7.0
## Height above the walkable surface (the slabs stand 0.09 proud of the collision).
const SHADOW_LIFT_M := 0.11

var spec: Dictionary = {}
var height_m: float = 2.0
var width_m: float = 1.0

var _mat: ShaderMaterial
var _pivot: Node3D
var _mesh: MeshInstance3D
var _shadow: MeshInstance3D
var _tell_glow: MeshInstance3D
var _tell_mat: StandardMaterial3D
var _phase: float = 0.0
var _flash_left: float = 0.0
var _flash_total: float = 0.0
var _cur: Dictionary[String, float] = {"lean": 0.0, "crouch": 0.0, "stretch": 0.0, "lift": 0.0, "forward": 0.0, "step": 0.0}
var _centre_y: float = 1.0
var _ghosts: Array[MeshInstance3D] = []
var _ghost_left: Array[float] = []
var _ghost_next: int = 0
var _ghost_timer: float = 0.0
var _shadow_mat: StandardMaterial3D
var _shadow_size: Vector2 = Vector2.ONE
var _shadow_on: bool = true
## The whole painting (afterimages are drawn from it).
var _tex: Texture2D


## A body for sprite `id` (see data/art/sprites.json). Null when there is no art for it.
static func create(id: String) -> SpriteBody:
	if not SpriteArt.has(id):
		return null
	# A cut-out rig (story 029) when the painting has been cut into parts, else the whole painting.
	var b: SpriteBody = RigBody.new() if RigBody.has_rig(id) else SpriteBody.new()
	b.name = "Sprite_%s" % id
	b.spec = SpriteArt.spec(id)
	b._build(id)
	return b


func _build(id: String) -> void:
	var tex := SpriteArt.texture(id)
	_tex = tex
	height_m = float(spec.get("height_m", 2.0))
	width_m = height_m * float(tex.get_width()) / float(tex.get_height())
	var centred := str(spec.get("anchor", "feet")) == "centre"
	var foot := float(spec.get("foot_gap", 0.0)) * height_m
	_centre_y = 0.0 if centred else height_m * 0.5 - foot
	_pivot = Node3D.new()
	_pivot.position = Vector3(0.0, _centre_y, 0.0)
	add_child(_pivot)
	var plane := PlaneMesh.new()
	plane.orientation = PlaneMesh.FACE_Z
	plane.size = Vector2(width_m, height_m)
	plane.subdivide_width = 7
	plane.subdivide_depth = 11
	_mesh = MeshInstance3D.new()
	_mesh.mesh = plane
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The painting may face left on its sheet; the game's "forward" is +x.
	_mesh.scale.x = float(spec.get("faces", 1))
	_mat = ShaderMaterial.new()
	_mat.shader = SpriteArt.shader()
	_mat.set_shader_parameter("tex", tex)
	_mat.set_shader_parameter("height_m", height_m)
	_mat.set_shader_parameter("emission_amount", float(spec.get("emission", SpriteArt.num("emission", 0.62))))
	_mat.set_shader_parameter("leg_height", float(spec.get("leg_height", 0.42)))
	_mat.set_shader_parameter("wind", float(spec.get("wind", 0.02)))
	if spec.has("tint"):
		_mat.set_shader_parameter("tint", Color(str(spec["tint"])))
	step_rate = float(spec.get("step_rate", step_rate))
	_mesh.material_override = _mat
	_pivot.add_child(_mesh)
	if bool(spec.get("shadow", true)):
		# A dark ellipse flat on the ground. The camera sees the floor almost edge-on, so it is
		# deep (front to back) to read as an oval under the feet rather than a line.
		_shadow = _blob_quad(Color(0, 0, 0, SHADOW_ALPHA), false)
		_shadow_mat = _shadow.material_override as StandardMaterial3D
		_shadow_mat.albedo_texture = SpriteArt.disc(0.45)
		var w := clampf(float(spec.get("shadow_w", maxf(height_m * 0.5, width_m * 0.5))), 0.6, 4.5)
		_shadow_size = Vector2(w, clampf(w * 1.15, 0.9, 1.8))
		_shadow.rotation_degrees.x = -90.0
		_shadow.scale = Vector3(_shadow_size.x, _shadow_size.y, 1.0)
		_shadow.top_level = true
		_shadow.visible = false
		add_child(_shadow)
	# Afterimages: copies of the sprite left in the world, additive and fading. They live at
	# the top level so they stay where they were dropped while the body moves on.
	for i in range(GHOSTS):
		var g := MeshInstance3D.new()
		var gq := QuadMesh.new()
		gq.size = Vector2(width_m, height_m)
		g.mesh = gq
		var gm := StandardMaterial3D.new()
		gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gm.albedo_texture = tex
		gm.cull_mode = BaseMaterial3D.CULL_DISABLED
		g.material_override = gm
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.top_level = true
		g.visible = false
		add_child(g)
		_ghosts.append(g)
		_ghost_left.append(0.0)
	var t: Dictionary = spec.get("tell", {})
	if not t.is_empty():
		_tell_glow = _blob_quad(Color(str(t.get("color", "#ffffff"))), true)
		_tell_mat = _tell_glow.material_override as StandardMaterial3D
		var pos: Array = t.get("pos", [0.5, 0.5])
		_tell_glow.position = Vector3((float(pos[0]) - 0.5) * width_m * float(spec.get("faces", 1)),
			(0.5 - float(pos[1])) * height_m, 0.05)
		_tell_glow.set_meta("size", float(t.get("size_m", 0.6)))
		_tell_glow.visible = false
		_pivot.add_child(_tell_glow)


func _blob_quad(color: Color, additive: bool) -> MeshInstance3D:
	var q := MeshInstance3D.new()
	var m := QuadMesh.new()
	m.size = Vector2.ONE
	q.mesh = m
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SpriteArt.blob()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	q.material_override = mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return q


## Tint the whole body `color` for `seconds`, fading out (hit flash, telegraph cue).
func flash(color: Color, seconds: float) -> void:
	_flash_total = maxf(seconds, 0.01)
	_flash_left = _flash_total
	_mat.set_shader_parameter("flash_color", color)


## 0..1: burn the body away in soul-light.
func set_dissolve(progress: float) -> void:
	_mat.set_shader_parameter("dissolve", clampf(progress, 0.0, 1.0))
	_shadow_on = progress < 0.3


## Does the painting stand on its feet (not a floating or centred body)? Only those kick up dust.
func stands() -> bool:
	return str(spec.get("anchor", "feet")) != "centre" and float(spec.get("float_m", 0.0)) == 0.0


## Multiply the painting by `c` (stone disguise, variants), on top of the sprite's own tint.
func set_tint(c: Color) -> void:
	var base := Color(str(spec.get("tint", "#ffffff")))
	_mat.set_shader_parameter("tint", Color(base.r * c.r, base.g * c.g, base.b * c.b, 1.0))


## Dust sprayed both ways from the feet (landing, a heavy step); `strength` scales it.
func puff(strength: float = 1.0) -> void:
	if stands():
		DustFx.spawn(self, "land", global_position, 1.0, strength * clampf(height_m * global_basis.get_scale().y / 1.9, 0.7, 2.6))


## Lay the shadow on the ground under the body, smaller and fainter the higher the body is.
func _tick_shadow() -> void:
	if _shadow == null:
		return
	if not _shadow_on or not is_inside_tree() or get_world_3d() == null:
		_shadow.visible = false
		return
	var from := global_position + Vector3(0.0, 0.3, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, from - Vector3(0.0, SHADOW_REACH_M, 0.0), SHADOW_MASK)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		_shadow.visible = false
		return
	var ground: Vector3 = hit["position"]
	var h := maxf(global_position.y - ground.y, 0.0)
	var k := clampf(h / SHADOW_FADE_M, 0.0, 1.0)
	_shadow.visible = true
	_shadow.global_position = Vector3(global_position.x, ground.y + SHADOW_LIFT_M, 0.1)
	# A body drawn bigger (a boss's visual_scale) throws a bigger shadow.
	var gs := global_basis.get_scale().y
	_shadow.scale = Vector3(_shadow_size.x * gs * lerpf(1.0, 0.45, k), _shadow_size.y * minf(gs, 1.4) * lerpf(1.0, 0.45, k), 1.0)
	_shadow_mat.albedo_color.a = SHADOW_ALPHA * lerpf(1.0, 0.3, k)


## Ease toward the targets and push them to the shader. Call once per frame.
func tick(delta: float) -> void:
	var k := minf(delta * 16.0, 1.0)
	_cur["lean"] = lerpf(_cur["lean"], lean, k)
	_cur["crouch"] = lerpf(_cur["crouch"], crouch, k)
	_cur["stretch"] = lerpf(_cur["stretch"], stretch, k)
	_cur["lift"] = lerpf(_cur["lift"], lift, k)
	_cur["forward"] = lerpf(_cur["forward"], forward, minf(delta * 26.0, 1.0))
	_cur["step"] = lerpf(_cur["step"], stride, k)
	_phase += delta * step_rate * maxf(_cur["step"], 0.0)
	var bob := absf(sin(_phase)) * step_bob * _cur["step"] * height_m * 0.5
	bob += sin(Time.get_ticks_msec() * 0.002) * float(spec.get("float_m", 0.0))
	_pivot.position = Vector3(_cur["forward"], _centre_y + _cur["lift"] + bob - _cur["crouch"] * height_m * 0.06, 0.0)
	_pivot.rotation.z = roll
	_pivot.scale = Vector3(1.0 + _cur["stretch"] * 0.25 + _cur["crouch"] * 0.05,
		1.0 - _cur["crouch"] * 0.12 - _cur["stretch"] * 0.08, 1.0)
	_mat.set_shader_parameter("lean", _cur["lean"] * float(spec.get("faces", 1)))
	_mat.set_shader_parameter("step_phase", _phase)
	_mat.set_shader_parameter("step_amount", _cur["step"] * float(spec.get("step_m", 0.09)))
	_mat.set_shader_parameter("breath", 0.006 * sin(Time.get_ticks_msec() * 0.0022) * (1.0 - _cur["step"]))
	_mat.set_shader_parameter("ghost", ghost)
	_mat.set_shader_parameter("glow", glow)
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		_mat.set_shader_parameter("flash", 0.85 * _flash_left / _flash_total)
	_tick_ghosts(delta)
	_tick_shadow()
	if _tell_glow != null:
		_tell_glow.visible = tell > 0.02
		if _tell_glow.visible:
			var size := float(_tell_glow.get_meta("size")) * lerpf(0.5, 1.6, tell)
			_tell_glow.scale = Vector3(size, size, 1.0)
			_tell_mat.albedo_color.a = clampf(0.35 + tell, 0.0, 1.0)


## Leave afterimage `g` where the body is drawn now (a RigBody showing drawn frames leaves the
## frame instead, story 058).
func _drop_ghost(g: MeshInstance3D) -> void:
	g.global_transform = _mesh.global_transform
	(g.mesh as QuadMesh).size = Vector2(width_m, height_m)
	(g.material_override as StandardMaterial3D).albedo_texture = _tex


func _tick_ghosts(delta: float) -> void:
	if trailing:
		_ghost_timer -= delta
		if _ghost_timer <= 0.0:
			_ghost_timer = GHOST_EVERY_S
			var g := _ghosts[_ghost_next]
			_ghost_left[_ghost_next] = GHOST_LIFE_S
			_ghost_next = (_ghost_next + 1) % GHOSTS
			_drop_ghost(g)
			g.visible = true
	else:
		_ghost_timer = 0.0
	for i in range(GHOSTS):
		if _ghost_left[i] <= 0.0:
			continue
		_ghost_left[i] = maxf(_ghost_left[i] - delta, 0.0)
		var a := 0.8 * _ghost_left[i] / GHOST_LIFE_S
		(_ghosts[i].material_override as StandardMaterial3D).albedo_color = Color(trail_color.r, trail_color.g, trail_color.b, a)
		_ghosts[i].visible = _ghost_left[i] > 0.0
