class_name WispVisual
extends VesselVisual
## The wisp body (story 024): a glowing core with a pale halo and two trailing motes, all
## unshaded so it reads as light, not matter. Bobs while idle and stretches with speed.

var _core: MeshInstance3D
var _halo: MeshInstance3D
var _motes: Array[MeshInstance3D] = []
var _t: float = 0.0


static func build_wisp(vessel_data: Dictionary) -> WispVisual:
	var v := WispVisual.new()
	v.name = "Vessel_wisp"
	var sil: Dictionary = vessel_data.get("silhouette", {})
	var c1 := Color(str(sil.get("primary_color", "#bfe9ff")))
	var c2 := Color(str(sil.get("secondary_color", "#6fb7ff")))
	v._core = v._orb(Vector3(0, 0.9, 0), 0.22, ArenaMaterials.flat(c1, 4.0, true))
	v._halo = v._orb(Vector3(0, 0.9, 0), 0.42, ArenaMaterials.flat(Color(c2.r, c2.g, c2.b, 0.35), 1.5, true, true))
	for i in range(2):
		v._motes.append(v._orb(Vector3(-0.3 - 0.25 * float(i), 0.85, 0), 0.08 - 0.02 * float(i), ArenaMaterials.flat(c2, 3.0, true)))
	return v


func _orb(pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 16
	s.rings = 8
	m.mesh = s
	m.position = pos
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	return m


func pose(state: String, _progress: float, facing: int, speed: float, delta: float) -> void:
	_t += delta
	var bob := sin(_t * 3.0) * 0.08 if state in ["idle", "run"] else 0.0
	_core.position.y = 0.9 + bob
	_halo.position.y = 0.9 + bob
	_halo.scale = Vector3.ONE * (1.0 + 0.08 * sin(_t * 5.0))
	for i in range(_motes.size()):
		var lag := 0.3 + 0.25 * float(i) + 0.2 * speed
		_motes[i].position = Vector3(-lag * float(facing), 0.85 + sin(_t * 4.0 + float(i)) * 0.1 + bob, 0.0)


func set_hidden_look(_hidden_on: bool) -> void:
	pass


func set_glow(_energy: float) -> void:
	pass
