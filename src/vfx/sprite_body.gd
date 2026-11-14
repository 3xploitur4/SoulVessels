class_name SpriteBody
extends Node3D
## One painted character or enemy standing in the 3D world (story 027): the sprite on a bendable
## quad (see spatial_char_sprite_body.gdshader), a soft ground shadow, and an optional additive glow where the
## enemy's own tell lives (spine sacs, eye, brand). The owner sets targets (`lean`, `stride`,
## `crouch`...) and calls `tick`; the body eases toward them so poses blend.
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


## A body for sprite `id` (see data/art/sprites.json). Null when there is no art for it.
static func create(id: String) -> SpriteBody:
	if not SpriteArt.has(id):
		return null
	var b := SpriteBody.new()
	b.name = "Sprite_%s" % id
	b.spec = SpriteArt.spec(id)
	b._build(id)
	return b


func _build(id: String) -> void:
	var tex := SpriteArt.texture(id)
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
		_shadow = _blob_quad(Color(0, 0, 0, 0.55), false)
		_shadow.rotation_degrees.x = -90.0
		_shadow.scale = Vector3(width_m * 0.95, width_m * 0.42, 1.0)
		_shadow.position = Vector3(0.0, 0.03, 0.1)
		add_child(_shadow)
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
	if _shadow != null:
		_shadow.visible = progress < 0.3


## Hide or show the ground shadow (airborne bodies).
func set_grounded(on: bool) -> void:
	if _shadow != null:
		_shadow.visible = on


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
	var bob := absf(sin(_phase)) * 0.05 * _cur["step"] * height_m * 0.5
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
	if _tell_glow != null:
		_tell_glow.visible = tell > 0.02
		if _tell_glow.visible:
			var size := float(_tell_glow.get_meta("size")) * lerpf(0.5, 1.6, tell)
			_tell_glow.scale = Vector3(size, size, 1.0)
			_tell_mat.albedo_color.a = clampf(0.35 + tell, 0.0, 1.0)
