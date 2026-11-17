class_name ShieldWard
extends Node3D
## The shield ward gate (story 023, addendum gate table): a golden statue fires a steady beam
## along the floor. The beam burns whoever stands in it, unless Caelan blocks facing the statue:
## his shield then throws the beam back up at an angle, and if that ray lands on the receiver
## crystal long enough, the golden bars open for good. Numbers in `combat.json` `shield_ward`.
##
##     var w := ShieldWard.new()
##     w.room = room_data; w.manager = room_manager; w.player = player; w.state = game_state
##     features_root.add_child(w)

signal opened

var room: RoomData
var manager: RoomManager
var player: Player
var state: GameState
## Save id of this gate ("z1_08:ward").
var gate_id: String = ""
var is_open: bool = false
## 0..1 crystal charge.
var charge: float = 0.0

var _cfg: Dictionary = {}
var _statue: Vector2
var _crystal: Rect2
var _beam: MeshInstance3D
var _reflect: MeshInstance3D
var _crystal_mesh: MeshInstance3D
var _crystal_mat: StandardMaterial3D
var _tick_left: float = 0.0
var _hum_left: float = 0.0


func _ready() -> void:
	_cfg = Balance.combat("shield_ward")
	gate_id = "%s:ward" % room.id
	_statue = room.markers.get("statue", Vector2.ZERO)
	var c: Vector2 = room.markers.get("crystal", Vector2.ZERO)
	var size: Array = _cfg.get("crystal_size_m", [1.0, 1.5])
	_crystal = Rect2(c.x - float(size[0]) * 0.5, c.y, float(size[0]), float(size[1]))
	is_open = state != null and state.opened_gates.has(gate_id)
	_build_statue()
	_build_crystal()
	_beam = _beam_mesh(0.14, Color(1.0, 0.82, 0.38))
	_reflect = _beam_mesh(0.1, Color(1.0, 0.95, 0.7))
	if is_open:
		manager.builder.open_gate("ward")
		_set_charge(1.0)


## Where the beam starts (room metres).
func beam_origin() -> Vector2:
	return Vector2(_statue.x - 0.55, _statue.y + float(_cfg.get("beam_height_m", 1.2)))


func _physics_process(delta: float) -> void:
	_beam.visible = false
	_reflect.visible = false
	if is_open or player == null or not is_instance_valid(player):
		return
	var o := beam_origin()
	var end_x := WardMath.beam_end_x(o, -1.0, float(_cfg.get("beam_length_m", 40.0)), room.solids)
	var pr := player.hurt_rect()
	var player_in_beam := player.is_alive() and o.y >= pr.position.y and o.y <= pr.end.y \
		and pr.end.x <= o.x and pr.end.x >= end_x
	var charging := false
	if player_in_beam:
		var facing_statue := player.facing == 1
		end_x = pr.end.x if not (player.is_blocking() and facing_statue) else player.global_position.x + 0.45
		if player.is_blocking() and facing_statue:
			# The shield throws the beam back up toward the statue's side.
			var from := Vector2(end_x, o.y)
			var dir := WardMath.reflect_dir(-1.0, float(_cfg.get("deflect_angle_deg", 45.0)))
			var length := float(_cfg.get("reflect_length_m", 20.0))
			charging = WardMath.ray_hits(from, dir, length, _crystal) and not _ray_blocked(from, dir)
			_show_segment(_reflect, from, from + dir * _reflect_length(from, dir, length))
			_hum(delta)
		else:
			_burn(delta)
	_show_segment(_beam, o, Vector2(end_x, o.y))
	if charging:
		_set_charge(charge + delta / maxf(float(_cfg.get("charge_s", 1.0)), 0.05))
		if charge >= 1.0:
			_open()
	else:
		_set_charge(maxf(charge - delta * float(_cfg.get("charge_decay_per_s", 0.5)), 0.0))


## Does the statue or the bars stand between the shield and the crystal along `dir`?
func _ray_blocked(from: Vector2, dir: Vector2) -> bool:
	var reach := from.distance_to(_crystal.get_center())
	var blockers: Array[Rect2] = [Rect2(_statue.x - 0.55, _statue.y, 1.1, 2.2)]
	for r: Rect2 in room.gate_rects.get("ward", []):
		blockers.append(r)
	for r in blockers:
		if WardMath.ray_hits(from, dir, reach, r):
			return true
	return false


## The reflected ray stops at the crystal or at the first rock it meets.
func _reflect_length(from: Vector2, dir: Vector2, length: float) -> float:
	var step := 0.25
	var d := 0.0
	while d < length:
		var p := from + dir * d
		if _crystal.has_point(p):
			return d + 0.2
		if manager.is_solid(p):
			return d
		d += step
	return length


func _burn(delta: float) -> void:
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = float(_cfg.get("tick_s", 0.5))
	if not player.is_invulnerable():
		player.hurt_by_world(float(_cfg.get("damage", 12.0)))
		GameEvents.hit_fx_requested.emit(player.global_position + Vector3(0.0, 1.2, 0.3), 0.0, false, false)


func _hum(delta: float) -> void:
	_hum_left -= delta
	if _hum_left <= 0.0:
		_hum_left = 0.5
		Sfx.play("ward_hum")


func _open() -> void:
	is_open = true
	if state != null:
		GameState.add_unique(state.opened_gates, gate_id)
	manager.builder.open_gate("ward")
	_set_charge(1.0)
	Sfx.play("gate_open")
	GameEvents.camera_shake_requested.emit(0.4)
	opened.emit()


func _set_charge(v: float) -> void:
	charge = clampf(v, 0.0, 1.0)
	if _crystal_mat != null:
		_crystal_mat.emission_energy_multiplier = lerpf(0.6, 5.0, charge)
		_crystal_mesh.scale = Vector3.ONE * lerpf(1.0, 1.25, charge)


func _build_statue() -> void:
	# A kneeling golden guardian on a plinth: plinth, robed body, head, and the glowing eye
	# the beam comes from.
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.1, 2.2, 2.0)
	shape.shape = box
	shape.position = Vector3(0.0, 1.1, 0.0)
	body.add_child(shape)
	add_child(body)
	body.global_position = Vector3(_statue.x, _statue.y, 0.0)
	_part(body, Vector3(0.0, 0.25, -0.2), Vector3(1.3, 0.5, 1.2), "ward_gold", "box")
	_part(body, Vector3(0.0, 1.05, -0.2), Vector3(0.5, 1.1, 0.5), "ward_gold", "cyl")
	_part(body, Vector3(0.0, 1.85, -0.2), Vector3(0.3, 0.3, 0.3), "ward_gold", "sphere")
	_part(body, Vector3(-0.55, float(_cfg.get("beam_height_m", 1.2)), 0.0), Vector3(0.16, 0.16, 0.16), "gold_light", "sphere")


func _build_crystal() -> void:
	_crystal_mesh = MeshInstance3D.new()
	var m := PrismMesh.new()
	m.size = Vector3(_crystal.size.x * 0.8, _crystal.size.y, 0.6)
	_crystal_mesh.mesh = m
	_crystal_mat = (ArenaMaterials.get_material("crystal") as StandardMaterial3D).duplicate() as StandardMaterial3D
	_crystal_mesh.material_override = _crystal_mat
	_crystal_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_crystal_mesh)
	_crystal_mesh.global_position = Vector3(_crystal.get_center().x, _crystal.get_center().y, 0.0)


func _beam_mesh(thickness: float, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(1.0, thickness, thickness)
	m.mesh = b
	m.material_override = ArenaMaterials.flat(color, 5.0, true)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.top_level = true
	m.visible = false
	add_child(m)
	return m


func _show_segment(m: MeshInstance3D, a: Vector2, b: Vector2) -> void:
	var d := b - a
	if d.length() < 0.05:
		return
	m.visible = true
	# Rotate, then stretch along the beam's own length (scaling in local space).
	m.global_transform = Transform3D(Basis(Vector3.BACK, d.angle()) * Basis.from_scale(Vector3(d.length(), 1.0, 1.0)),
		Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.05))


func _part(parent: Node3D, pos: Vector3, size: Vector3, material: String, kind: String) -> void:
	var m := MeshInstance3D.new()
	match kind:
		"box":
			var b := BoxMesh.new()
			b.size = size
			m.mesh = b
		"cyl":
			var c := CylinderMesh.new()
			c.top_radius = size.x * 0.6
			c.bottom_radius = size.x
			c.height = size.y
			c.radial_segments = 10
			m.mesh = c
		_:
			var s := SphereMesh.new()
			s.radius = size.x
			s.height = size.x * 2.0
			s.radial_segments = 10
			s.rings = 5
			m.mesh = s
	m.position = pos
	m.material_override = ArenaMaterials.get_material(material)
	parent.add_child(m)
