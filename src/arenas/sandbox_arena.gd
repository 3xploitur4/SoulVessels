class_name SandboxArena
extends Node3D
## The M1 test arena (story 005): a 42 m cavern floor at z = 0, two ledges, side walls and
## parallax depth layers built from primitives (decision D-004). Depth layers sit at z = -6
## (broken columns), -14 (aqueduct arches) and -30 (cavern wall); a few dark foreground shapes
## at z = +4 pass in front of the camera. Lights stay within the addendum budget: one shadowed
## directional key and two unshadowed omnis.
##
##     var arena := SandboxArena.new()
##     add_child(arena)
##     camera.bounds = Vector2(arena.left_bound, arena.right_bound)

## Play-space limits for the camera and spawners (inner faces of the side walls).
var left_bound: float = -21.0
var right_bound: float = 21.0
## Floor surface height.
var floor_y: float = 0.0
## Ledge tops, for spawners and bots: [Rect2(x, top_y, width, 0)].
var ledges: Array[Rect2] = []

const FLOOR_WIDTH := 46.0
const FLOOR_DEPTH := 8.0
const WALL_HEIGHT := 14.0
const LEDGE_HEIGHT := 1.6


func _ready() -> void:
	_build_environment()
	_build_lights()
	_build_floor()
	_build_ledge(-12.5, 5.0)
	_build_ledge(12.0, 4.0)
	_build_walls()
	_build_columns_layer(-6.0)
	_build_arches_layer(-14.0)
	_build_back_wall(-30.0)
	_build_foreground(4.0)
	_merge_static_meshes()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.02, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.42, 0.55)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_agx_contrast = 1.35
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.06, 0.09, 0.14)
	env.fog_depth_begin = 15.0
	env.fog_depth_end = 46.0
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
	key.light_color = Color(0.62, 0.72, 0.95)
	key.light_energy = 1.25
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 40.0
	key.rotation_degrees = Vector3(-38.0, -28.0, 0.0)
	add_child(key)
	_add_omni("TorchLight", Vector3(-15.0, 3.2, -2.0), Color(1.0, 0.58, 0.28), 2.6, 11.0)
	_add_omni("RuneLight", Vector3(14.0, 2.6, -3.0), Color(0.35, 0.85, 1.0), 2.2, 10.0)
	# The torch and rune themselves, so the light has a visible source.
	_box(Vector3(-15.0, 2.4, -2.2), Vector3(0.25, 1.6, 0.25), "marble_dark")
	_sphere(Vector3(-15.0, 3.35, -2.2), 0.22, "torch_warm")
	_box(Vector3(14.0, 1.6, -3.4), Vector3(1.6, 3.2, 0.3), "marble_dark")
	_box(Vector3(14.0, 1.9, -3.2), Vector3(0.9, 0.9, 0.05), "rune_cyan")


func _add_omni(node_name: String, pos: Vector3, color: Color, energy: float, light_range: float) -> void:
	var omni := OmniLight3D.new()
	omni.name = node_name
	omni.position = pos
	omni.light_color = color
	omni.light_energy = energy
	omni.omni_range = light_range
	omni.shadow_enabled = false
	add_child(omni)


func _build_floor() -> void:
	_static_box(Vector3(0.0, floor_y - 0.5, 0.0), Vector3(FLOOR_WIDTH, 1.0, FLOOR_DEPTH), "slate_floor")
	# Marble trim along the play edge and a moss strip at the back, for depth reading.
	_box(Vector3(0.0, floor_y + 0.02, 1.6), Vector3(FLOOR_WIDTH, 0.06, 0.3), "marble")
	_box(Vector3(0.0, floor_y + 0.03, -2.6), Vector3(FLOOR_WIDTH, 0.08, 1.2), "moss")
	# A dark water channel behind the floor.
	_box(Vector3(0.0, floor_y - 0.4, -4.6), Vector3(FLOOR_WIDTH, 0.1, 2.8), "water_dark")


func _build_ledge(x: float, width: float) -> void:
	var top := floor_y + LEDGE_HEIGHT
	_static_box(Vector3(x, top - LEDGE_HEIGHT * 0.5, 0.0), Vector3(width, LEDGE_HEIGHT, 3.0), "marble_dark")
	_box(Vector3(x, top + 0.03, 0.0), Vector3(width + 0.2, 0.08, 3.1), "marble")
	ledges.append(Rect2(x - width * 0.5, top, width, 0.0))


func _build_walls() -> void:
	for side: float in [-1.0, 1.0]:
		var x := side * (right_bound + 1.0)
		_static_box(Vector3(x, WALL_HEIGHT * 0.5, 0.0), Vector3(2.0, WALL_HEIGHT, FLOOR_DEPTH), "slate")
	# Ceiling slab above the frame: it closes the cavern for lights without a band on screen.
	_box(Vector3(0.0, 14.5, -4.0), Vector3(FLOOR_WIDTH, 1.5, 8.0), "cavern_wall")


func _build_columns_layer(z: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7001
	var x := -24.0
	while x < 24.0:
		var height := rng.randf_range(2.5, 8.0)
		var broken := rng.randf() < 0.45
		var h := height * (0.45 if broken else 1.0)
		_cylinder(Vector3(x, h * 0.5, z), 0.55, h, "marble_far")
		_box(Vector3(x, h + 0.15, z), Vector3(1.5, 0.3, 1.5), "pier_far")
		if broken:
			# The fallen drum lies beside the stump.
			var drum := _cylinder(Vector3(x + 1.4, 0.45, z + 0.6), 0.5, 1.6, "marble_far")
			drum.rotation_degrees = Vector3(0.0, rng.randf_range(-30.0, 30.0), 90.0)
		x += rng.randf_range(5.0, 8.0)


func _build_arches_layer(z: float) -> void:
	var span := 7.0
	var x := -35.0
	while x <= 35.0:
		_box(Vector3(x, 4.5, z), Vector3(1.4, 9.0, 1.4), "pier_far")
		x += span
	# The aqueduct channel across the tops, with a teal trickle.
	_box(Vector3(0.0, 9.6, z), Vector3(80.0, 1.2, 1.8), "pier_far")
	_box(Vector3(0.0, 10.25, z + 0.2), Vector3(80.0, 0.12, 1.0), "teal_glow")
	# Arch heads: a shallow box under the channel between piers reads as an arch at distance.
	x = -35.0 + span * 0.5
	while x <= 35.0:
		_box(Vector3(x, 8.6, z), Vector3(span - 2.4, 0.8, 1.2), "pier_far")
		x += span


func _build_back_wall(z: float) -> void:
	_box(Vector3(0.0, 8.0, z), Vector3(140.0, 30.0, 2.0), "cavern_wall")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7002
	for i in range(14):
		var px := rng.randf_range(-60.0, 60.0)
		var py := rng.randf_range(-1.0, 16.0)
		var crystal := _box(Vector3(px, py, z + 1.2), Vector3(0.6, rng.randf_range(1.5, 3.5), 0.6), "teal_glow")
		crystal.rotation_degrees.z = rng.randf_range(-35.0, 35.0)


func _build_foreground(z: float) -> void:
	# Thin stalactites between camera and play, high up so they never cover the fight: they
	# slide fastest and sell the depth. Nothing at floor level in front of the play plane.
	for x: float in [-18.0, -4.0, 9.5, 20.0]:
		var drip := _box(Vector3(x, 9.6, z), Vector3(0.5, 2.6, 0.5), "foreground")
		drip.rotation_degrees.z = 8.0 if x > 0.0 else -6.0


## Merge decoration into one mesh per material (see MeshMerger).
func _merge_static_meshes() -> void:
	MeshMerger.merge(self)


func _static_box(pos: Vector3, size: Vector3, material: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = ArenaMaterials.get_material(material)
	body.add_child(mesh)
	add_child(body)
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
