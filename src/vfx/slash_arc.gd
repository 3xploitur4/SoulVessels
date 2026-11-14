class_name SlashArc
extends MeshInstance3D
## A weapon arc of light (story 027): a crescent that sweeps and fades in front of a painted
## character, so a single-pose sprite still reads as a swing. Additive and unshaded; one per
## character, reused for every attack (no allocation in combat).
##
##     var arc := SlashArc.new()
##     visual.add_child(arc)
##     arc.play(Color("#d6e6ff"), 2.3, 70.0, -50.0, 0.16)

const SEGMENTS := 14
const SPAN_RAD := 2.2

var _mat: StandardMaterial3D
var _t: float = 1.0
var _duration: float = 0.16
var _from: float = 0.0
var _to: float = 0.0
var _radius: float = 1.0
var _color: Color = Color.WHITE


func _ready() -> void:
	mesh = _crescent()
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.vertex_color_use_as_albedo = true
	_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = _mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visible = false


## Sweep an arc of `radius` metres from `from_deg` to `to_deg` (0 = straight ahead, positive = up)
## over `seconds`.
func play(color: Color, radius: float, from_deg: float, to_deg: float, seconds: float) -> void:
	_color = color
	_radius = radius
	_from = deg_to_rad(from_deg)
	_to = deg_to_rad(to_deg)
	_duration = maxf(seconds, 0.05)
	_t = 0.0
	visible = true
	_apply()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta / _duration
	if _t >= 1.0:
		visible = false
		return
	_apply()


func _apply() -> void:
	var k := 1.0 - (1.0 - _t) * (1.0 - _t)
	rotation.z = lerpf(_from, _to, k)
	scale = Vector3.ONE * _radius * lerpf(0.85, 1.08, k)
	_mat.albedo_color = Color(_color.r, _color.g, _color.b, (1.0 - _t) * 0.7)


## A unit crescent centred on angle 0: thick in the middle, pointed at both ends, brightest at
## its outer edge.
func _crescent() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(SEGMENTS + 1):
		var t := float(i) / float(SEGMENTS)
		var a := (t - 0.5) * SPAN_RAD
		var body := sin(t * PI)
		var outer := Vector3(cos(a), sin(a), 0.0)
		var inner := outer * (1.0 - 0.24 * body)
		st.set_color(Color(1, 1, 1, body))
		st.add_vertex(outer)
		st.set_color(Color(1, 1, 1, 0.0))
		st.add_vertex(inner)
	return st.commit()
