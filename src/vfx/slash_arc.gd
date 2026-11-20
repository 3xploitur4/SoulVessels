class_name SlashArc
extends Node3D
## A weapon arc of light (story 027; horizontal sweeps in story 057, decision D-068): a crescent
## that sweeps and fades in front of a painted character, so a cut-out rig still reads as a
## swing, with a fainter smear trailing behind the blade. `flat` squashes the sweep into an
## ellipse: about 0.3 is a horizontal slash seen from the side (the blade passing in front of the
## body), 1 a round vertical arc. `tilt_deg` turns the whole sweep for diagonal cuts. A sweep of
## 360 degrees or more is a spin. Additive and unshaded; one per character, reused for every
## attack (no allocation in combat).
##
##     arc.play(Color("#d6e6ff"), 2.3, 70.0, -50.0, 0.16)                 # a vertical chop
##     arc.play(Color("#d6e6ff"), 2.3, 160.0, -40.0, 0.16, 0.32)          # a horizontal slash
##     arc.play(Color("#d6e6ff"), 2.0, -120.0, 70.0, 0.18, 0.45, 35.0)    # a rising diagonal

const SEGMENTS := 16
const SPAN_RAD := 2.2
## How far behind the blade the smear trails (share of the sweep) and how bright it is.
const SMEAR_LAG := 0.22
const SMEAR_ALPHA := 0.35

var _blade: MeshInstance3D
var _smear: MeshInstance3D
var _mat: StandardMaterial3D
var _smear_mat: StandardMaterial3D
var _t: float = 1.0
var _duration: float = 0.16
var _from: float = 0.0
var _to: float = 0.0
var _radius: float = 1.0
var _color: Color = Color.WHITE


func _ready() -> void:
	var crescent := _crescent()
	_mat = _material()
	_smear_mat = _material()
	_blade = _part(crescent, _mat)
	_smear = _part(crescent, _smear_mat)
	visible = false


## Sweep an arc of `radius` metres from `from_deg` to `to_deg` (0 = straight ahead, positive = up)
## over `seconds`, squashed by `flat` (1 = round) and turned by `tilt_deg`.
func play(color: Color, radius: float, from_deg: float, to_deg: float, seconds: float, flat: float = 1.0,
		tilt_deg: float = 0.0) -> void:
	_color = color
	_radius = radius
	_from = deg_to_rad(from_deg)
	_to = deg_to_rad(to_deg)
	_duration = maxf(seconds, 0.05)
	_t = 0.0
	scale = Vector3(radius, radius * clampf(flat, 0.08, 1.0), radius)
	rotation.z = deg_to_rad(tilt_deg)
	visible = true
	_apply()


## Is an arc still showing (tests)?
func playing() -> bool:
	return visible


## The blade's current angle in radians (tests).
func blade_angle() -> float:
	return _blade.rotation.z if _blade != null else 0.0


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
	var ks := maxf(k - SMEAR_LAG, 0.0) / (1.0 - SMEAR_LAG)
	_blade.rotation.z = lerpf(_from, _to, k)
	_smear.rotation.z = lerpf(_from, _to, ks)
	_blade.scale = Vector3.ONE * lerpf(0.88, 1.06, k)
	_smear.scale = Vector3.ONE * lerpf(0.8, 0.97, ks)
	_mat.albedo_color = Color(_color.r, _color.g, _color.b, (1.0 - _t) * 0.8)
	_smear_mat.albedo_color = Color(_color.r, _color.g, _color.b, (1.0 - _t) * SMEAR_ALPHA)


func _material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _part(mesh: ArrayMesh, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


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
		var inner := outer * (1.0 - 0.28 * body)
		st.set_color(Color(1, 1, 1, body))
		st.add_vertex(outer)
		st.set_color(Color(1, 1, 1, 0.0))
		st.add_vertex(inner)
	return st.commit()
