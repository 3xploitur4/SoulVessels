class_name EnemyVisual
extends Node3D
## Placeholder enemy bodies built from primitives, one distinct silhouette per kind (story 010):
## the Echo Crawler is a low slate arachnid with green spine sacs, the Subterranean Watcher a
## porcelain sphere with a cyan eye, the Branded Warden a 2.6 m iron guard with a tower shield
## and halberd. `tell(on)` lights the enemy-specific tell; `flash(color)` tints for the standard
## cue. Final art replaces `build()` and keeps the methods.
##
##     var vis := EnemyVisual.build(Balance.enemy("echo_crawler"))

var kind: String = ""
## Parts that animate.
var legs: Array[Node3D] = []
var shield: Node3D
var weapon: Node3D
var eye: MeshInstance3D
var beam: MeshInstance3D
var aim_line: MeshInstance3D

var _tell_parts: Array[MeshInstance3D] = []
var _tell_mat: StandardMaterial3D
var _flash_mat: StandardMaterial3D
var _body_parts: Array[MeshInstance3D] = []
var _base_mats: Array[Material] = []
var _flash_left: float = 0.0
## Index in _body_parts of the one part that casts a shadow.
var _shadow_part: int = 0
var _time: float = 0.0
var _phase: float = 0.0


static func build(enemy_data: Dictionary) -> EnemyVisual:
	# Painted art wins over the primitive placeholder whenever a sprite exists (story 027).
	if SpriteArt.has(str(enemy_data.get("id", ""))):
		return EnemySpriteVisual.build_sprite(enemy_data)
	var v := EnemyVisual.new()
	var sil: Dictionary = enemy_data.get("silhouette", {})
	v.kind = str(sil.get("kind", "arachnid"))
	v.name = "Visual_%s" % str(enemy_data.get("id", ""))
	match v.kind:
		"arachnid":
			v._build_crawler(sil)
		"sphere":
			v._build_watcher(sil)
		"humanoid_giant":
			v._build_warden(sil)
	# One shadow caster per enemy (the first, main body part): legs and props cast none.
	for i in range(v._body_parts.size()):
		var mi := v._body_parts[i]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if i == v._shadow_part 			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		v._base_mats.append(mi.material_override)
	return v


func _build_crawler(sil: Dictionary) -> void:
	var stone := ArenaMaterials.character(Color(str(sil.get("primary_color", "#4b5058"))), 0.15)
	var dark := ArenaMaterials.character(Color(0.18, 0.19, 0.22), 0.1)
	_tell_mat = ArenaMaterials.flat(Color(str(sil.get("accent_color", "#4cff6a"))), 0.6).duplicate() as StandardMaterial3D
	var body := _part(self, _sphere_mesh(0.42), Vector3(0.0, 0.45, 0.0), stone)
	body.scale = Vector3(1.5, 0.7, 1.0)
	var head := _part(self, _sphere_mesh(0.22), Vector3(0.62, 0.42, 0.0), dark)
	head.scale = Vector3(1.1, 0.8, 1.0)
	# Mandibles.
	for z: float in [-0.1, 0.1]:
		var m := _part(self, _box_mesh(Vector3(0.28, 0.05, 0.05)), Vector3(0.84, 0.34, z), dark)
		m.rotation_degrees.z = -20.0
	# Three spine sacs: the green flare tell.
	for i in range(3):
		var sac := _part(self, _sphere_mesh(0.11), Vector3(-0.25 + 0.22 * float(i), 0.78, 0.0), _tell_mat)
		_tell_parts.append(sac)
	# Six legs, three per side, as jointed pivots.
	for side: float in [-1.0, 1.0]:
		for i in range(3):
			var pivot := Node3D.new()
			pivot.position = Vector3(-0.35 + 0.35 * float(i), 0.42, 0.28 * side)
			add_child(pivot)
			var leg := _part(pivot, _box_mesh(Vector3(0.06, 0.6, 0.06)), Vector3(0.0, -0.22, 0.12 * side), dark)
			leg.rotation_degrees.x = -35.0 * side
			legs.append(pivot)


func _build_watcher(sil: Dictionary) -> void:
	var porcelain := ArenaMaterials.character(Color(str(sil.get("primary_color", "#efe9e1"))), 0.0)
	var crack := ArenaMaterials.character(Color(0.35, 0.33, 0.32), 0.0)
	var cyan := Color(str(sil.get("accent_color", "#39d7ff")))
	_tell_mat = ArenaMaterials.flat(cyan, 1.2).duplicate() as StandardMaterial3D
	var r := float(sil.get("radius_m", 0.6))
	_part(self, _sphere_mesh(r), Vector3.ZERO, porcelain)
	# A cracked band and an orbiting ring.
	var band := _part(self, _box_mesh(Vector3(r * 2.02, 0.05, r * 2.02)), Vector3(0.0, 0.08, 0.0), crack)
	band.rotation_degrees.z = 12.0
	var ring := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = r * 1.25
	t.outer_radius = r * 1.38
	ring.mesh = t
	ring.material_override = crack
	ring.rotation_degrees = Vector3(70.0, 0.0, 15.0)
	add_child(ring)
	weapon = ring
	eye = _part(self, _sphere_mesh(r * 0.32), Vector3(r * 0.85, 0.0, 0.0), _tell_mat)
	_tell_parts.append(eye)
	_build_lines(cyan)


## The Watcher's beam and aim line (thin boxes scaled along x by the enemy script).
func _build_lines(cyan: Color) -> void:
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(1.0, 0.22, 0.22)
	beam = MeshInstance3D.new()
	beam.mesh = beam_mesh
	beam.material_override = ArenaMaterials.flat(cyan, 6.0, true)
	beam.visible = false
	add_child(beam)
	var aim_mesh := BoxMesh.new()
	aim_mesh.size = Vector3(1.0, 0.03, 0.03)
	aim_line = MeshInstance3D.new()
	aim_line.mesh = aim_mesh
	aim_line.material_override = ArenaMaterials.flat(Color(0.6, 0.4, 1.0), 2.5, true)
	aim_line.visible = false
	add_child(aim_line)


func _build_warden(sil: Dictionary) -> void:
	var iron := ArenaMaterials.character(Color(str(sil.get("primary_color", "#3b3a37"))), 0.2)
	var rust := ArenaMaterials.character(Color(str(sil.get("secondary_color", "#7a5a2e"))), 0.15)
	var brand := Color(str(sil.get("accent_color", "#d8a23a")))
	_tell_mat = ArenaMaterials.flat(brand, 0.8).duplicate() as StandardMaterial3D
	var h := float(sil.get("height_m", 2.6))
	var s := h / 2.6
	# Legs and plated body.
	for z: float in [-0.22, 0.22]:
		var leg := Node3D.new()
		leg.position = Vector3(0.0, 1.15 * s, z * s)
		add_child(leg)
		_part(leg, _box_mesh(Vector3(0.3, 1.15, 0.3) * s), Vector3(0.0, -0.57 * s, 0.0), iron)
		legs.append(leg)
	_shadow_part = _body_parts.size()
	_part(self, _box_mesh(Vector3(0.6, 0.95, 0.75) * s), Vector3(0.0, 1.7 * s, 0.0), iron)
	_part(self, _box_mesh(Vector3(0.66, 0.2, 0.8) * s), Vector3(0.0, 1.22 * s, 0.0), rust)
	var helm := _part(self, _box_mesh(Vector3(0.36, 0.42, 0.34) * s), Vector3(0.05, 2.38 * s, 0.0), iron)
	helm.rotation_degrees.z = -4.0
	# The brand on the helm glows on the gold thrust tell.
	var brand_mark := _part(self, _box_mesh(Vector3(0.04, 0.16, 0.16) * s), Vector3(0.24 * s, 2.4 * s, 0.0), _tell_mat)
	_tell_parts.append(brand_mark)
	# Tower shield, held forward on the near side.
	shield = Node3D.new()
	shield.position = Vector3(0.42 * s, 1.55 * s, 0.38 * s)
	add_child(shield)
	_part(shield, _box_mesh(Vector3(0.14, 1.9, 0.95) * s), Vector3.ZERO, rust)
	_part(shield, _box_mesh(Vector3(0.05, 1.5, 0.12) * s), Vector3(0.08 * s, 0.0, 0.0), _tell_mat)
	# Halberd on the far side.
	weapon = Node3D.new()
	weapon.position = Vector3(0.1 * s, 1.75 * s, -0.42 * s)
	add_child(weapon)
	_part(weapon, _box_mesh(Vector3(0.08, 3.0, 0.08) * s), Vector3(0.0, 0.3 * s, 0.0), rust)
	var blade := _part(weapon, _box_mesh(Vector3(0.5, 0.4, 0.05) * s), Vector3(0.2 * s, 1.65 * s, 0.0), iron)
	blade.rotation_degrees.z = 10.0


## Light the enemy-specific tell (spine sacs, eye charge, brand) with `strength` 0..1.
func tell(strength: float) -> void:
	if _tell_mat == null:
		return
	_tell_mat.emission_energy_multiplier = lerpf(0.6, 7.0, clampf(strength, 0.0, 1.0))
	for p in _tell_parts:
		p.scale = Vector3.ONE * lerpf(1.0, 1.45, clampf(strength, 0.0, 1.0))


## Tint the whole body for `seconds` (the standard cue flash, a hit flash).
func flash(color: Color, seconds: float) -> void:
	_flash_mat = ArenaMaterials.flat(color, 2.5, true)
	_flash_left = seconds
	for mi in _body_parts:
		if not _tell_parts.has(mi):
			mi.material_override = _flash_mat


## Per-frame animation. `state` is the enemy's state name, `speed` its |vx|.
func animate(state: String, facing: int, speed: float, delta: float) -> void:
	_time += delta
	rotation.y = 0.0 if facing > 0 else PI
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			for i in range(_body_parts.size()):
				_body_parts[i].material_override = _base_mats[i]
	match kind:
		"arachnid":
			_phase += delta * (14.0 if speed > 0.2 else 2.0)
			for i in range(legs.size()):
				legs[i].rotation.z = sin(_phase + float(i) * 1.7) * (0.45 if speed > 0.2 else 0.08)
		"sphere":
			if weapon != null:
				weapon.rotation.y += delta * (4.0 if state == "telegraph" else 0.8)
		"humanoid_giant":
			_phase += delta * (6.0 if speed > 0.2 else 0.0)
			for i in range(legs.size()):
				legs[i].rotation.z = sin(_phase + PI * float(i)) * 0.35 if speed > 0.2 else 0.0


## Shrink-and-sink death (no alpha blending, so no extra pipeline at death time).
func dissolve(progress: float) -> void:
	var k := clampf(1.0 - progress, 0.0, 1.0)
	scale = Vector3(1.0 + 0.3 * progress, k, 1.0 + 0.3 * progress)
	position.y = -0.3 * progress


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	_body_parts.append(mi)
	return mi


func _box_mesh(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _sphere_mesh(radius: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 14
	s.rings = 7
	return s
