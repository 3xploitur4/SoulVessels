class_name VesselVisual
extends Node3D
## Placeholder Vessel body built from primitives (story 008), posed procedurally by state. Each
## Vessel reads from its `silhouette` data: height, build, colours and props (shield, cape,
## pauldron, hood, daggers...), so Caelan and Nyra have different outlines at play size. A cyan
## soul core in the chest is the Intruder inside; it brightens with the Soul Gauge. Swappable:
## final art replaces `build()` and keeps `pose()`'s signature.
##
##     var vis := VesselVisual.build(Balance.vessel("caelan"))
##     add_child(vis)
##     vis.pose("run", 0.0, 1, 1.0, delta)

const BUILD_WIDTH := {"heavy": 1.2, "slim": 0.82, "graceful": 0.9, "massive": 1.4, "lean": 0.95}
const SOUL_COLOR := Color(0.44, 0.83, 0.91)

var _s: float = 1.0
var _body: Node3D
var _arm_front: Node3D
var _arm_back: Node3D
var _leg_front: Node3D
var _leg_back: Node3D
var _cape: Node3D
var _core_mat: StandardMaterial3D
var _meshes: Array[MeshInstance3D] = []
var _base_materials: Array[Material] = []
var _hidden_mat: StandardMaterial3D
var _is_hidden: bool = false
var _phase: float = 0.0
var _time: float = 0.0
var _is_dagger_user: bool = false


## Build the body for a Vessel's data block.
static func build(vessel_data: Dictionary) -> VesselVisual:
	if str(vessel_data.get("silhouette", {}).get("style", "")) == "wisp":
		return WispVisual.build_wisp(vessel_data)
	# Painted art wins over the primitive placeholder whenever a sprite exists (story 027).
	if SpriteArt.has(str(vessel_data.get("id", ""))):
		return VesselSpriteVisual.build_sprite(vessel_data)
	var v := VesselVisual.new()
	v.name = "Vessel_%s" % str(vessel_data.get("id", "unknown"))
	v._build(vessel_data.get("silhouette", {}))
	return v


func _build(sil: Dictionary) -> void:
	_s = float(sil.get("height_m", 1.8)) / 1.8
	var w: float = BUILD_WIDTH.get(str(sil.get("build", "lean")), 1.0)
	var primary := Color(str(sil.get("primary_color", "#444444")))
	var secondary := Color(str(sil.get("secondary_color", "#888888")))
	var accent := Color(str(sil.get("accent_color", "#ffffff")))
	var props: Array = sil.get("props", [])
	var skin := Color(0.72, 0.6, 0.52)
	var m_primary := ArenaMaterials.character(primary, 0.22)
	var m_secondary := ArenaMaterials.character(secondary, 0.15)
	var m_accent := ArenaMaterials.character(accent, 0.1)
	var m_skin := ArenaMaterials.character(skin, 0.0)
	var m_steel := ArenaMaterials.character(Color(0.7, 0.74, 0.8), 0.05)
	_hidden_mat = ArenaMaterials.flat(Color(0.15, 0.1, 0.25, 0.35), 0.4, false, true)

	_body = Node3D.new()
	_body.position.y = 0.92 * _s
	add_child(_body)
	_box(_body, Vector3(0.0, 0.36, 0.0), Vector3(0.30 * w, 0.62, 0.40 * w), m_primary).set_meta("shadow", true)
	_box(_body, Vector3(0.0, 0.06, 0.0), Vector3(0.32 * w, 0.14, 0.42 * w), m_secondary)  # belt
	_sphere(_body, Vector3(0.0, 0.82, 0.0), 0.13, m_skin)
	_core_mat = ArenaMaterials.flat(SOUL_COLOR, 2.0).duplicate() as StandardMaterial3D
	_sphere(_body, Vector3(0.16 * w, 0.42, 0.0), 0.065, _core_mat)

	_leg_front = _limb(_body, Vector3(0.0, 0.0, 0.11 * w), Vector3(0.16, 0.9, 0.16) * Vector3(w, 1, w), m_secondary)
	_leg_back = _limb(_body, Vector3(0.0, 0.0, -0.11 * w), Vector3(0.16, 0.9, 0.16) * Vector3(w, 1, w), m_secondary)
	_meshes[_meshes.size() - 1].set_meta("shadow", true)
	_meshes[_meshes.size() - 2].set_meta("shadow", true)
	_arm_front = _limb(_body, Vector3(0.0, 0.62, 0.27 * w), Vector3(0.12, 0.6, 0.12) * Vector3(w, 1, w), m_primary)
	_arm_back = _limb(_body, Vector3(0.0, 0.62, -0.27 * w), Vector3(0.12, 0.6, 0.12) * Vector3(w, 1, w), m_primary)

	if props.has("pauldron_left"):
		var p := _sphere(_body, Vector3(0.0, 0.66, -0.29 * w), 0.16, m_steel)
		p.scale = Vector3(1.0, 0.7, 1.0)
	if props.has("cape"):
		_cape = Node3D.new()
		_cape.position = Vector3(-0.17 * w, 0.66, 0.0)
		_body.add_child(_cape)
		_box(_cape, Vector3(-0.03, -0.55, 0.0), Vector3(0.04, 1.1, 0.46 * w), m_accent)
	if props.has("shield"):
		_box(_arm_back, Vector3(0.14, -0.42, -0.06), Vector3(0.08, 0.78, 0.56), m_steel)
		_box(_arm_back, Vector3(0.19, -0.42, -0.06), Vector3(0.02, 0.5, 0.34), m_accent)
	if props.has("hood"):
		var hood := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.03
		cone.bottom_radius = 0.18
		cone.height = 0.34
		cone.radial_segments = 10
		hood.mesh = cone
		hood.position = Vector3(-0.03, 0.9, 0.0) * _s
		hood.rotation_degrees.z = 14.0
		hood.material_override = m_secondary
		_body.add_child(hood)
		_meshes.append(hood)
		_box(_body, Vector3(-0.12, 0.45, 0.0), Vector3(0.05, 0.75, 0.38 * w), m_secondary)  # short cloak
	if props.has("dagger_left") or props.has("dagger_right"):
		_is_dagger_user = true
		_box(_arm_front, Vector3(0.0, -0.78, 0.0), Vector3(0.04, 0.4, 0.05), m_steel)
		_box(_arm_back, Vector3(0.0, -0.78, 0.0), Vector3(0.04, 0.4, 0.05), m_steel)
		_box(_arm_front, Vector3(0.0, -0.62, 0.0), Vector3(0.07, 0.08, 0.08), m_accent)
	else:
		# Longsword: continues the arm line so the shoulder swing reads as a sword arc.
		_box(_arm_front, Vector3(0.0, -1.12, 0.0), Vector3(0.05, 1.0, 0.09), m_steel)
		_box(_arm_front, Vector3(0.0, -0.62, 0.0), Vector3(0.08, 0.06, 0.28), m_accent)
	# Shadows only from the torso and legs: limbs and props would each add a shadow draw call.
	for i in range(_meshes.size()):
		var mi := _meshes[i]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if mi.has_meta("shadow") 			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_base_materials.append(mi.material_override)


## Pose for `state` ("idle", "run", "primary_2", "dodge", "block"...). `progress` is 0..1 through
## the current action, `speed` the run speed as a fraction of max.
func pose(state: String, progress: float, facing: int, speed: float, delta: float) -> void:
	_time += delta
	rotation.y = 0.0 if facing > 0 else PI
	var k := minf(delta * 18.0, 1.0)
	var front := 0.25
	var back := -0.15
	var leg_f := 0.0
	var leg_b := 0.0
	var lean := 0.0
	var spin := 0.0
	var lift := 0.0
	var cape := 0.15
	if state == "run":
		_phase += delta * 11.0 * clampf(speed, 0.3, 1.4)
		leg_f = sin(_phase) * 0.75
		leg_b = -leg_f
		front = -sin(_phase) * 0.5 + 0.2
		back = sin(_phase) * 0.5
		lean = -0.14
		cape = 0.45 + 0.1 * sin(_phase * 2.0)
		lift = absf(sin(_phase)) * 0.05
	elif state == "jump" or state == "fall":
		leg_f = 0.7
		leg_b = -0.25
		front = 1.2
		back = 0.8
		cape = 0.7 if state == "jump" else -0.2
	elif state.begins_with("primary"):
		var idx := int(state.get_slice("_", 1))
		if _is_dagger_user:
			var jab := sin(clampf(progress, 0.0, 1.0) * PI)
			if idx % 2 == 0:
				front = lerpf(0.4, 1.75, jab)
			else:
				back = lerpf(0.0, 1.75, jab)
			lean = -0.2 * jab
		else:
			front = _swing(progress)
			back = 0.5
			lean = -0.18 if progress > 0.35 else 0.05
		leg_f = 0.35
		leg_b = -0.25
	elif state in ["counterstrike", "oathbreaker_lunge", "severing_arrival", "shadow_counter",
			"kings_judgment", "final_stand", "dance_of_shadows", "phantom_blades"]:
		front = _swing(progress)
		back = 1.4 if state == "oathbreaker_lunge" else 0.6
		lean = -0.3
		leg_f = 0.5
		leg_b = -0.4
		if state == "final_stand":
			front = lerpf(3.4, 0.4, clampf(progress * 2.5, 0.0, 1.0))
			lift = -0.15 * clampf(progress * 3.0, 0.0, 1.0)
	elif state == "block" or state == "sync_guard":
		back = 1.5
		front = 2.1
		lean = -0.08
		leg_f = 0.35
		leg_b = -0.35
		lift = -0.06
	elif state == "dodge":
		spin = -TAU * clampf(progress / 0.75, 0.0, 1.0)
		leg_f = 1.4
		leg_b = 1.2
		front = 1.6
		back = 1.6
		lift = -0.3 * sin(clampf(progress / 0.75, 0.0, 1.0) * PI)
	elif state == "air_dash" or state == "shadowstep":
		lean = -0.6
		front = -0.6
		back = -0.8
		leg_f = -0.4
		leg_b = -0.7
		cape = 1.2
	elif state == "hurt" or state == "guard_break":
		lean = 0.35
		front = -0.5
		back = 0.9
		leg_f = -0.3
	elif state == "flask":
		front = 2.7
		back = 0.2
	else:
		lift = sin(_time * 2.2) * 0.015
	_body.rotation.z = lerp_angle(_body.rotation.z, lean + spin, 1.0 if spin != 0.0 else k)
	_body.position.y = 0.92 * _s + lift
	_arm_front.rotation.z = lerpf(_arm_front.rotation.z, front, k)
	_arm_back.rotation.z = lerpf(_arm_back.rotation.z, back, k)
	_leg_front.rotation.z = lerpf(_leg_front.rotation.z, leg_f, k)
	_leg_back.rotation.z = lerpf(_leg_back.rotation.z, leg_b, k)
	if _cape != null:
		_cape.rotation.z = lerpf(_cape.rotation.z, cape, k * 0.5)


## Stealth look: every part swaps to a translucent shadow material.
func set_hidden_look(hidden_on: bool) -> void:
	if hidden_on == _is_hidden:
		return
	_is_hidden = hidden_on
	for i in range(_meshes.size()):
		_meshes[i].material_override = _hidden_mat if hidden_on else _base_materials[i]


## Soul core brightness (1 = idle, ~2.5 with a full gauge).
func set_glow(energy: float) -> void:
	_core_mat.emission_energy_multiplier = energy * 2.0


## Longsword arc: raise behind (3.6 rad) during windup, sweep down through forward.
func _swing(progress: float) -> float:
	if progress < 0.35:
		return lerpf(0.3, 3.6, progress / 0.35)
	return lerpf(3.6, 0.9, clampf((progress - 0.35) / 0.25, 0.0, 1.0))


func _limb(parent: Node3D, pivot: Vector3, size: Vector3, mat: Material) -> Node3D:
	var p := Node3D.new()
	p.position = pivot * _s
	parent.add_child(p)
	_box(p, Vector3(0.0, -size.y * 0.5, 0.0), size, mat)
	return p


func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size * _s
	mi.mesh = b
	mi.position = pos * _s
	mi.material_override = mat
	parent.add_child(mi)
	_meshes.append(mi)
	return mi


func _sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius * _s
	s.height = radius * 2.0 * _s
	s.radial_segments = 12
	s.rings = 6
	mi.mesh = s
	mi.position = pos * _s
	mi.material_override = mat
	parent.add_child(mi)
	_meshes.append(mi)
	return mi
