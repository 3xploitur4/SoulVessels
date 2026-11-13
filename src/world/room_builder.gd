class_name RoomBuilder
extends Node3D
## Builds one room's set from its `RoomData` (story 015): collision and meshes for rock, one-way
## platforms and gates, a trim along every walkable top, theme decor on the parallax layers
## (z = -6, -14, -30 behind, +4 in front), the environment, the key light and up to two omni
## lights. Room coordinates are world coordinates (x from 0 at the left edge, y from 0 at the
## bottom), so only one room is in the tree at a time.
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
	match str(theme.get("decor", "aqueduct")):
		"mushrooms":
			_build_mycelium_decor()
		_:
			_build_aqueduct_decor()
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
	env.glow_intensity = 0.45
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
	for l: Dictionary in data.lights:
		var omni := OmniLight3D.new()
		omni.position = l["pos"]
		var warm: bool = l["warm"]
		omni.light_color = Color(str(theme.get("warm_light" if warm else "cool_light", "#ffffff")))
		omni.light_energy = 2.6 if warm else 2.2
		omni.omni_range = 11.0
		omni.shadow_enabled = false
		add_child(omni)
		# The visible source of the light: a brazier or a glowing growth.
		var pos: Vector3 = l["pos"]
		_box(Vector3(pos.x, pos.y - 0.6, pos.z - 0.2), Vector3(0.25, 1.2, 0.25), "marble_dark")
		_sphere(Vector3(pos.x, pos.y + 0.05, pos.z - 0.2), 0.22, "torch_warm" if warm else "rune_cyan")


# --- Collision geometry ---------------------------------------------------------------------

func _build_rock() -> void:
	var rock := str(theme.get("rock", "slate_floor"))
	var trim := str(theme.get("trim", "marble"))
	for r in data.solids:
		var back := BACK_Z if _touches_edge(r) else FLOAT_BACK_Z
		var body := _body(r, LAYER_WORLD, rock, back, FRONT_Z)
		body.name = "Rock"
	for t in data.trims:
		var strip := _box(Vector3(t.position.x + t.size.x * 0.5, t.position.y + 0.03, FRONT_Z - 0.6),
			Vector3(t.size.x, 0.08, 1.4), trim)
		strip.set_meta("cast_shadow", false)


func _touches_edge(r: Rect2) -> bool:
	return r.position.x <= 0.0 or r.position.y <= 0.0 or r.end.x >= float(data.cols) or r.end.y >= float(data.rows)


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
		var mesh := _box(Vector3(r.position.x + r.size.x * 0.5, r.position.y - 0.125, -0.6), Vector3(r.size.x, 0.25, 2.6), "plank")
		mesh.set_meta("cast_shadow", true)
		oneway_bodies.append(body)


## Gate bodies are built plainly here; the gate features (story 023) dress and open them.
func _build_gates() -> void:
	const MATERIALS := {"ward": "ward_gold", "veil": "foreground", "lock": "lock_bars", "rune": "rune_dark",
		"masonry": "masonry", "flood": "flood"}
	for kind: String in data.gate_rects.keys():
		var bodies: Array = []
		for r: Rect2 in data.gate_rects[kind]:
			var layer := LAYER_VEIL if kind == "veil" else LAYER_WORLD
			var front := 0.6 if kind in ["ward", "lock", "veil"] else FRONT_Z
			var back := -0.6 if kind in ["ward", "lock", "veil"] else BACK_Z
			var body := _body(r, layer, MATERIALS.get(kind, "slate"), back, front)
			body.name = "Gate_%s" % kind
			body.set_meta("dynamic", true)
			bodies.append(body)
		gate_bodies[kind] = bodies


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
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(r.size.x, r.size.y, depth)
	mesh.mesh = bm
	mesh.material_override = ArenaMaterials.get_material(material)
	mesh.set_meta("cast_shadow", true)
	body.add_child(mesh)
	add_child(body)
	return body


# --- Decor ----------------------------------------------------------------------------------

func _build_aqueduct_decor() -> void:
	var w := float(data.cols)
	var h := float(data.rows)
	# Broken columns standing on the floor's back extension.
	var x := _rng.randf_range(-2.0, 3.0)
	while x < w + 2.0:
		var height := _rng.randf_range(3.0, minf(10.0, h + 2.0))
		var broken := _rng.randf() < 0.45
		var ch := height * (0.5 if broken else 1.0)
		_cylinder(Vector3(x, ch * 0.5, -6.0), 0.55, ch, "marble_far")
		_box(Vector3(x, ch + 0.15, -6.0), Vector3(1.5, 0.3, 1.5), "pier_far")
		x += _rng.randf_range(5.0, 9.0)
	# Aqueduct arches with a teal trickle, across the whole visible span.
	var span := 7.0
	var top := maxf(h - 2.0, 9.0)
	x = -26.0
	while x <= w + 26.0:
		_box(Vector3(x, top * 0.5 - 2.0, -14.0), Vector3(1.4, top + 4.0, 1.4), "pier_far")
		_box(Vector3(x + span * 0.5, top - 1.0, -14.0), Vector3(span - 2.4, 0.8, 1.2), "pier_far")
		x += span
	_box(Vector3(w * 0.5, top, -14.0), Vector3(w + 60.0, 1.2, 1.8), "pier_far")
	_box(Vector3(w * 0.5, top + 0.65, -13.8), Vector3(w + 60.0, 0.12, 1.0), "teal_glow")
	_back_wall("cavern_wall", "teal_glow")
	# Thin stalactites in front, high up so they never cover the fight.
	x = _rng.randf_range(2.0, 8.0)
	while x < w:
		var drip := _box(Vector3(x, h - 1.2, 4.0), Vector3(0.45, 2.4, 0.45), "foreground")
		drip.rotation_degrees.z = _rng.randf_range(-9.0, 9.0)
		x += _rng.randf_range(9.0, 16.0)


func _build_mycelium_decor() -> void:
	var w := float(data.cols)
	var h := float(data.rows)
	# Giant mushrooms on the near layer: pale stalks, glowing caps.
	# Dim, so a cap behind the play plane never reads as a platform; the bright ones are far.
	var x := _rng.randf_range(-1.0, 4.0)
	while x < w + 2.0:
		var stalk_h := _rng.randf_range(3.0, minf(8.0, h))
		_cylinder(Vector3(x, stalk_h * 0.5, -7.0), 0.3, stalk_h, "stalk_far")
		var cap := _cylinder(Vector3(x, stalk_h, -7.0), _rng.randf_range(0.9, 1.5), 0.4, "cap_dim")
		cap.set_meta("cast_shadow", false)
		x += _rng.randf_range(4.5, 8.0)
	# Towering silhouettes further back.
	x = -24.0
	while x < w + 24.0:
		var big_h := _rng.randf_range(10.0, 22.0)
		_cylinder(Vector3(x, big_h * 0.5 - 4.0, -14.0), 0.9, big_h, "stalk_far")
		_cylinder(Vector3(x, big_h - 4.0, -14.0), _rng.randf_range(3.5, 5.5), 0.9, "cap_violet" if _rng.randf() < 0.5 else "cap_glow")
		x += _rng.randf_range(8.0, 13.0)
	_back_wall("myc_wall", "spore_glow")
	# Hanging strands in front, high up.
	x = _rng.randf_range(2.0, 6.0)
	while x < w:
		_box(Vector3(x, h - 1.4, 4.0), Vector3(0.12, 2.8, 0.12), "foreground")
		_sphere(Vector3(x, h - 2.9, 4.0), 0.14, "spore_glow")
		x += _rng.randf_range(6.0, 11.0)


## The far cavern wall with scattered glowing crystals or spores.
func _back_wall(wall_mat: String, glow_mat: String) -> void:
	var w := float(data.cols)
	var h := float(data.rows)
	_box(Vector3(w * 0.5, h * 0.5, -30.0), Vector3(w + 110.0, h + 50.0, 2.0), wall_mat)
	var count := int(clampf((w + h) * 0.25, 8.0, 24.0))
	for i in range(count):
		var px := _rng.randf_range(-40.0, w + 40.0)
		var py := _rng.randf_range(-6.0, h + 12.0)
		var c := _box(Vector3(px, py, -28.8), Vector3(0.6, _rng.randf_range(1.2, 3.2), 0.6), glow_mat)
		c.rotation_degrees.z = _rng.randf_range(-35.0, 35.0)


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
	cyl.radial_segments = 12
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
