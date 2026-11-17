class_name RoomBuilder
extends Node3D
## Builds one room's set from its `RoomData` (stories 015 and 028): collision and textured meshes
## for rock, one-way platforms and gates, a slab cap along every walkable top, the environment,
## the key light and up to two omni lights, then `RoomDecor` dresses it after the zone painting.
## Room coordinates are world coordinates (x from 0 at the left edge, y from 0 at the bottom),
## so only one room is in the tree at a time.
##
##     var b := RoomBuilder.new()
##     b.data = WorldData.room("z1_03")
##     add_child(b)
##     b.gate_bodies["ward"]   # bodies a gate feature removes when it opens

## Rock touching the room's edge reaches back to this z (floors and walls read as solid ground).
const BACK_Z := -4.5
## Floating rock (platforms, pillars inside the room) stays shallow so it reads as a ledge.
const FLOAT_BACK_Z := -2.2
## Front face of rock blocks.
const FRONT_Z := 1.2
## Collision layers (project.godot layer names).
const LAYER_WORLD := 1
const LAYER_ONEWAY := 1 << 8
const LAYER_VEIL := 1 << 9
## Invisible walls at the room's sides that stop enemies, not the player (exits stay open).
const LAYER_ENEMY_WALL := 1 << 10

var data: RoomData
## Gate kind -> the StaticBody3D nodes built for it ("ward", "veil", "lock", "rune", ...).
var gate_bodies: Dictionary[String, Array] = {}
## One-way platform bodies (the player toggles collision with each).
var oneway_bodies: Array[StaticBody3D] = []
var theme: Dictionary = {}

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	theme = WorldData.theme(data.theme)
	_rng.seed = hash(data.id)
	_build_environment()
	_build_lights()
	_build_rock()
	_build_oneway()
	_build_gates()
	_build_enemy_walls()
	RoomDecor.build(self, data, theme, _rng)
	MeshMerger.merge(self)


# --- Environment and lights -----------------------------------------------------------------

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(str(theme.get("background", "#04060a")))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(str(theme.get("ambient", "#5c6b8c")))
	env.ambient_light_energy = float(theme.get("ambient_energy", 0.55))
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_agx_contrast = 1.35
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(str(theme.get("fog", "#0f1724")))
	env.fog_depth_begin = float(theme.get("fog_begin", 15.0))
	env.fog_depth_end = float(theme.get("fog_end", 46.0))
	env.fog_depth_curve = 1.2
	env.glow_enabled = true
	env.glow_intensity = float(theme.get("glow", 0.45))
	env.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)


func _build_lights() -> void:
	var key := DirectionalLight3D.new()
	key.name = "KeyLight"
	key.light_color = Color(str(theme.get("key_color", "#9eb8f2")))
	key.light_energy = float(theme.get("key_energy", 1.2))
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 40.0
	var rot: Array = theme.get("key_rotation", [-38.0, -28.0, 0.0])
	key.rotation_degrees = Vector3(float(rot[0]), float(rot[1]), float(rot[2]))
	add_child(key)
	var fungal := str(theme.get("decor", "")) == "mushrooms"
	for l: Dictionary in data.lights:
		var omni := OmniLight3D.new()
		omni.position = l["pos"]
		var warm: bool = l["warm"]
		omni.light_color = Color(str(theme.get("warm_light" if warm else "cool_light", "#ffffff")))
		omni.light_energy = 2.8 if warm else 2.4
		omni.omni_range = 11.0
		omni.shadow_enabled = false
		add_child(omni)
		# The visible source of the light: a brazier on a stand, or a cluster of glowing caps.
		var pos: Vector3 = l["pos"]
		var at := Vector3(pos.x, pos.y, pos.z - 0.4)
		if fungal:
			for k in range(3):
				var off := Vector3(-0.3 + 0.3 * float(k), -0.5 + 0.18 * float(k % 2), 0.0)
				_cylinder(at + off + Vector3(0.0, -0.2, 0.0), 0.04, 0.4, "z2_vine")
				_sphere(at + off, 0.16, "mushroom_cap" if warm else "spore_glow")
		else:
			_cylinder(at + Vector3(0.0, -1.0, 0.0), 0.07, 1.6, "brazier")
			var bowl := _cylinder(at + Vector3(0.0, -0.18, 0.0), 0.3, 0.18, "brazier")
			bowl.scale = Vector3(1.0, 1.0, 1.0)
			_sphere(at + Vector3(0.0, 0.08, 0.0), 0.2, "torch_warm" if warm else "rune_cyan")


# --- Collision geometry ---------------------------------------------------------------------

func _build_rock() -> void:
	var rock := str(theme.get("rock", "slate_floor"))
	var ledge := str(theme.get("ledge", rock))
	var trim := str(theme.get("trim", "marble"))
	for r in data.solids:
		var deep := _touches_edge(r)
		var body := _body(r, LAYER_WORLD, rock if deep else ledge, BACK_Z if deep else FLOAT_BACK_Z, FRONT_Z)
		body.name = "Rock"
	# A slab cap on every walkable top: the bright line the eye follows.
	for t in data.trims:
		var back := BACK_Z if _is_deep_at(Vector2(t.position.x + 0.5, t.position.y - 0.5)) else FLOAT_BACK_Z
		var depth := FRONT_Z + 0.06 - back
		var cap := _box(Vector3(t.position.x + t.size.x * 0.5, t.position.y + 0.04, back + depth * 0.5),
			Vector3(t.size.x + 0.06, 0.1, depth), trim)
		cap.set_meta("cast_shadow", false)


func _touches_edge(r: Rect2) -> bool:
	return r.position.x <= 0.0 or r.position.y <= 0.0 or r.end.x >= float(data.cols) or r.end.y >= float(data.rows)


func _is_deep_at(p: Vector2) -> bool:
	for s in data.solids:
		if s.has_point(p):
			return _touches_edge(s)
	return false


func _build_oneway() -> void:
	for r in data.oneway:
		var body := StaticBody3D.new()
		body.name = "OneWay"
		body.collision_layer = LAYER_ONEWAY
		body.collision_mask = 0
		body.position = Vector3(r.position.x + r.size.x * 0.5, r.position.y - 0.125, 0.0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(r.size.x, 0.25, 2.0)
		shape.shape = box
		body.add_child(shape)
		add_child(body)
		# A plank walkway hung on ropes (the zone 2 painting's bridge).
		var mid := Vector3(r.position.x + r.size.x * 0.5, r.position.y - 0.1, -0.4)
		var deck := _box(mid, Vector3(r.size.x, 0.2, 2.4), "planks")
		deck.set_meta("cast_shadow", true)
		for side: float in [-1.0, 1.0]:
			var post := Vector3(mid.x + side * (r.size.x * 0.5 - 0.12), r.position.y + 0.35, -1.5)
			_cylinder(post, 0.06, 0.9, "rope").set_meta("cast_shadow", false)
		_box(Vector3(mid.x, r.position.y + 0.72, -1.5), Vector3(r.size.x - 0.2, 0.05, 0.05), "rope").set_meta("cast_shadow", false)
		oneway_bodies.append(body)


## Gate bodies: collision here, the look from `GateLook`; the gate features (story 023) add
## behaviour and open them.
func _build_gates() -> void:
	for kind: String in data.gate_rects.keys():
		var bodies: Array = []
		for r: Rect2 in data.gate_rects[kind]:
			var layer := LAYER_VEIL if kind == "veil" else LAYER_WORLD
			var body := _body(r, layer, "", -0.6, 0.6)
			body.name = "Gate_%s" % kind
			body.set_meta("dynamic", true)
			GateLook.dress(body, kind, r)
			bodies.append(body)
		gate_bodies[kind] = bodies


## Enemies stay in the room: exits are openings in the side walls, and only the player may pass.
func _build_enemy_walls() -> void:
	for x: float in [-0.5, float(data.cols) + 0.5]:
		var body := StaticBody3D.new()
		body.name = "EnemyWall"
		body.collision_layer = LAYER_ENEMY_WALL
		body.collision_mask = 0
		body.position = Vector3(x, float(data.rows) * 0.5, 0.0)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, float(data.rows) + 4.0, 2.0)
		shape.shape = box
		body.add_child(shape)
		add_child(body)


## Turn gate `kind` on or off without removing it (arena lock bars: open until the fight starts,
## shut while it runs). Off means no collision and not drawn.
func set_gate_active(kind: String, on: bool) -> void:
	for b: Node in gate_bodies.get(kind, []):
		if not is_instance_valid(b):
			continue
		(b as Node3D).visible = on
		for c: Node in b.get_children():
			if c is CollisionShape3D:
				(c as CollisionShape3D).set_deferred("disabled", not on)


## Is gate `kind` present and switched on?
func gate_active(kind: String) -> bool:
	var list: Array = gate_bodies.get(kind, [])
	return not list.is_empty() and is_instance_valid(list[0]) and (list[0] as Node3D).visible


## Remove every body of gate `kind` (opened for good, or an arena that ended).
func open_gate(kind: String) -> void:
	for b: Node in gate_bodies.get(kind, []):
		if is_instance_valid(b):
			b.queue_free()
	gate_bodies.erase(kind)


func _body(r: Rect2, layer: int, material: String, back: float, front: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	var depth := front - back
	body.position = Vector3(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5, (front + back) * 0.5)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	# Collision stays thin around the play plane; the visible block is deep.
	box.size = Vector3(r.size.x, r.size.y, 2.0)
	shape.shape = box
	shape.position.z = -body.position.z
	body.add_child(shape)
	add_child(body)
	if material == "":
		return body
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(r.size.x, r.size.y, depth)
	mesh.mesh = bm
	mesh.material_override = ArenaMaterials.get_material(material)
	mesh.set_meta("cast_shadow", true)
	body.add_child(mesh)
	return body


func _box(pos: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = ArenaMaterials.get_material(material)
	add_child(mesh)
	return mesh


func _cylinder(pos: Vector3, radius: float, height: float, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius * 1.08
	cyl.height = height
	cyl.radial_segments = 10
	cyl.rings = 1
	mesh.mesh = cyl
	mesh.position = pos
	mesh.material_override = ArenaMaterials.get_material(material)
	add_child(mesh)
	return mesh


func _sphere(pos: Vector3, radius: float, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 12
	s.rings = 6
	mesh.mesh = s
	mesh.position = pos
	mesh.material_override = ArenaMaterials.get_material(material)
	add_child(mesh)
	return mesh
