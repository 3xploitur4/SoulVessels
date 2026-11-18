class_name RoomDecor
extends RefCounted
## Dresses a room after its zone painting (story 028, decision D-033). Nothing here collides:
## it is the look behind and in front of the play plane.
##
## Layers by depth (z): the zone painting itself as the far backdrop (-34); a far arcade or
## giant mushrooms (-15); nearer ruins or mushrooms (-6.5); rubble, pools and sprouts on the
## back of the floor (-2.5 to -4); stalactites and vines at the ceiling; black silhouettes
## toward the camera (+3.4). Everything is seeded by the room id, so a room always looks the same.
##
##     RoomDecor.build(room_builder, room_data, theme, rng)

const Z_BACKDROP := -34.0
const Z_FAR := -15.0
const Z_MID := -6.5
const Z_FRONT := 3.4

var root: Node3D
var data: RoomData
var theme: Dictionary
var rng: RandomNumberGenerator

var _w: float
var _h: float


static func build(builder: Node3D, room: RoomData, room_theme: Dictionary, random: RandomNumberGenerator) -> void:
	var d := RoomDecor.new()
	d.root = builder
	d.data = room
	d.theme = room_theme
	d.rng = random
	d._w = float(room.cols)
	d._h = float(room.rows)
	d._backdrop()
	match str(room_theme.get("decor", "aqueduct")):
		"mushrooms":
			d._mycelium()
		_:
			d._cavern()
	d._depth_layers()


# --- Backdrop ---------------------------------------------------------------------------------

## The zone painting, mirror-tiled, far behind everything. Unshaded and outside the fog so it
## keeps its own colours; a tint pushes it back so the play plane stays brightest.
func _backdrop() -> void:
	var path := str(theme.get("backdrop", ""))
	if path == "" or not ResourceLoader.exists(path):
		_box(Vector3(_w * 0.5, _h * 0.5, -30.0), Vector3(_w + 110.0, _h + 50.0, 2.0), "cavern_wall")
		return
	var tex := TexBank.get_tex(path)
	# About one painting per screen-height of view at this depth; shafts scale it up a little
	# rather than stretching it across their whole height.
	var tall := maxf(34.0, _h + 12.0)
	var pair_w := tall * float(tex.get_width()) / float(tex.get_height())
	var wide := _w + 76.0
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(wide, tall)
	quad.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = tex
	mat.albedo_color = Color(str(theme.get("backdrop_tint", "#909090")))
	mat.uv1_scale = Vector3(wide / pair_w, 1.0, 1.0)
	mat.uv1_offset = Vector3(rng.randf(), 0.0, 0.0)
	mat.disable_fog = true
	quad.material_override = mat
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.position = Vector3(_w * 0.5, _h * 0.5 + (3.0 if _h <= 14.0 else 0.0), Z_BACKDROP)
	quad.set_meta("dynamic", true)
	root.add_child(quad)


# --- Zone 1: The Whispering Cavern ------------------------------------------------------------

func _cavern() -> void:
	# The far aqueduct is the painting itself; a few dark arches stand between it and the room
	# for parallax, sparse enough that the painting shows through.
	var span := 7.5
	var x := -26.0 + rng.randf_range(0.0, 20.0)
	while x < _w + 26.0:
		_arch(Vector3(x, -3.0, Z_FAR), span, clampf(_h - 4.0, 7.0, 11.0), "z1_ruin_far", rng.randf() < 0.5)
		x += span * float(rng.randi_range(3, 5))
	# Middle: broken columns and the odd lone arch.
	x = rng.randf_range(-3.0, 3.0)
	while x < _w + 3.0:
		if rng.randf() < 0.22:
			_arch(Vector3(x, 0.0, Z_MID - 1.0), 5.0, rng.randf_range(4.0, 6.5), "z1_ruin_mid", true)
			x += 7.0
		else:
			_column(Vector3(x, 0.0, Z_MID + rng.randf_range(-0.6, 0.6)), rng.randf_range(3.5, minf(9.5, _h)), rng.randf() < 0.45)
		x += rng.randf_range(5.0, 9.0)
	# Floor dressing on the back of deep ground: rubble blocks and glowing pools.
	for top in _deep_tops():
		var count := int(top.size.x / 7.0) + (1 if rng.randf() < 0.5 else 0)
		for i in range(count):
			var rx := rng.randf_range(top.position.x + 0.6, top.end.x - 0.6)
			var block := _box(Vector3(rx, top.position.y + 0.2, rng.randf_range(-3.9, -2.4)),
				Vector3(rng.randf_range(0.5, 1.3), rng.randf_range(0.35, 0.7), rng.randf_range(0.5, 0.9)), "z1_ledge")
			block.rotation_degrees = Vector3(rng.randf_range(-8.0, 8.0), rng.randf_range(-35.0, 35.0), rng.randf_range(-14.0, 14.0))
		if top.size.x >= 8.0 and rng.randf() < 0.7:
			var pw := rng.randf_range(2.6, minf(5.5, top.size.x - 3.0))
			var px := rng.randf_range(top.position.x + pw * 0.5 + 1.0, top.end.x - pw * 0.5 - 1.0)
			var pool := _cylinder(Vector3(px, top.position.y + 0.03, -3.3), pw * 0.5, pw * 0.5, 0.05, "z1_pool", 16)
			pool.scale = Vector3(1.0, 1.0, 0.36)
	_stalactites("z1_rock")
	_silhouettes()
	_shafts(3)
	_motes(Color(0.75, 0.85, 1.0, 0.55), 0.06)
	_mist_bands()


## A stone arch: two piers, a ring of voussoirs, and the wall above up to the deck. `ruined`
## drops the right half and leaves a stump.
func _arch(base: Vector3, span: float, pier_h: float, mat: String, ruined: bool) -> void:
	var r := span * 0.5 - 0.55
	var spring := base.y + pier_h
	_box(base + Vector3(-span * 0.5, pier_h * 0.5, 0.0), Vector3(1.1, pier_h, 1.4), mat)
	if not ruined:
		_box(base + Vector3(span * 0.5, pier_h * 0.5, 0.0), Vector3(1.1, pier_h, 1.4), mat)
	else:
		_box(base + Vector3(span * 0.5, pier_h * 0.22, 0.0), Vector3(1.1, pier_h * 0.44, 1.4), mat)
	var stones := 9
	for i in range(stones):
		var t := (float(i) + 0.5) / float(stones)
		if ruined and t < 0.45:
			continue
		var a := PI * t
		var v := _box(Vector3(base.x + cos(a) * r, spring + sin(a) * r, base.z), Vector3(0.8, 1.0, 1.3), mat)
		v.rotation.z = a - PI * 0.5
	if not ruined:
		_box(Vector3(base.x, spring + r + 0.95, base.z), Vector3(span + 1.1, 1.0, 1.5), mat)
		for side: float in [-1.0, 1.0]:
			_box(Vector3(base.x + side * span * 0.39, spring + r * 0.62, base.z), Vector3(span * 0.24, r * 0.9, 1.25), mat)
	else:
		_box(Vector3(base.x - span * 0.3, spring + r + 0.95, base.z), Vector3(span * 0.5, 1.0, 1.5), mat)


## A fluted column on a base, whole with a capital or snapped with its drum fallen beside it.
func _column(base: Vector3, height: float, broken: bool) -> void:
	var h := height * (0.45 if broken else 1.0)
	_box(base + Vector3(0.0, 0.2, 0.0), Vector3(1.5, 0.4, 1.5), "z1_ruin_mid")
	_cylinder(base + Vector3(0.0, 0.4 + h * 0.5, 0.0), 0.5, 0.56, h, "z1_ruin_mid", 10)
	if broken:
		var drum := _cylinder(base + Vector3(1.5, 0.5, 0.7), 0.5, 0.5, 1.7, "z1_ruin_mid", 10)
		drum.rotation_degrees = Vector3(0.0, rng.randf_range(-30.0, 30.0), 90.0)
	else:
		_box(base + Vector3(0.0, 0.4 + h + 0.2, 0.0), Vector3(1.5, 0.4, 1.5), "z1_ruin_mid")


# --- Zone 2: The Luminous Mycelium Forest -----------------------------------------------------

func _mycelium() -> void:
	# Far: towering mushrooms.
	var x := -30.0 + rng.randf_range(0.0, 6.0)
	while x < _w + 30.0:
		var violet := rng.randf() < 0.45
		_mushroom(Vector3(x, -5.0, Z_FAR + rng.randf_range(-2.0, 2.0)), rng.randf_range(11.0, 21.0), rng.randf_range(3.6, 6.2),
			"z2_stalk_far", "z2_cap_far_violet" if violet else "z2_cap_far_teal")
		x += rng.randf_range(8.0, 13.0)
	# Middle: the forest the room stands in.
	x = rng.randf_range(-2.0, 3.0)
	while x < _w + 2.0:
		var violet := rng.randf() < 0.4
		_mushroom(Vector3(x, 0.0, Z_MID + rng.randf_range(-1.2, 0.8)), rng.randf_range(3.0, minf(8.5, _h)), rng.randf_range(1.2, 2.3),
			"z2_stalk", "z2_cap_violet" if violet else "z2_cap_teal")
		if rng.randf() < 0.5:
			_mushroom(Vector3(x + rng.randf_range(1.0, 1.8), 0.0, Z_MID + 1.2), rng.randf_range(1.2, 2.4), rng.randf_range(0.5, 0.8),
				"z2_stalk", "z2_cap_teal" if violet else "z2_cap_violet")
		x += rng.randf_range(5.0, 8.5)
	# Floor dressing: clusters of glowing sprouts.
	for top in _deep_tops():
		var count := int(top.size.x / 4.0)
		for i in range(count):
			var sx := rng.randf_range(top.position.x + 0.4, top.end.x - 0.4)
			var sz := rng.randf_range(-3.9, -2.2)
			for k in range(rng.randi_range(2, 4)):
				var sh := rng.randf_range(0.25, 0.7)
				var stem := Vector3(sx + rng.randf_range(-0.3, 0.3), top.position.y + sh * 0.5, sz + rng.randf_range(-0.2, 0.2))
				_cylinder(stem, 0.03, 0.04, sh, "z2_vine", 5)
				_sphere(stem + Vector3(0.0, sh * 0.5 + 0.06, 0.0), rng.randf_range(0.08, 0.15), "z2_sprout" if k % 2 == 0 else "spore_glow")
	_vines()
	_stalactites("z2_rock")
	_silhouettes()
	_shafts(2)
	_motes(Color(0.55, 1.0, 0.85, 0.9), 0.12)
	_mist_bands()


## A mushroom: tapered stalk, a wide domed cap with spots, and dark gills beneath.
func _mushroom(base: Vector3, height: float, cap_r: float, stalk_mat: String, cap_mat: String) -> void:
	var stalk_r := cap_r * 0.16
	_cylinder(base + Vector3(0.0, height * 0.5, 0.0), stalk_r * 0.7, stalk_r, height, stalk_mat, 9)
	var cap := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = cap_r
	dome.height = cap_r
	dome.is_hemisphere = true
	dome.radial_segments = 18
	dome.rings = 6
	cap.mesh = dome
	cap.scale = Vector3(1.0, 0.62, 1.0)
	cap.position = base + Vector3(0.0, height - 0.05, 0.0)
	cap.material_override = ArenaMaterials.get_material(cap_mat)
	cap.set_meta("cast_shadow", false)
	root.add_child(cap)
	var gills := _cylinder(base + Vector3(0.0, height - 0.12, 0.0), cap_r * 0.96, cap_r * 0.3, 0.3, "z2_gill", 14)
	gills.set_meta("cast_shadow", false)


## Vines hanging from the ceiling, each ending in a glowing bulb.
func _vines() -> void:
	for z: float in [-2.6, Z_FRONT]:
		var x := rng.randf_range(1.0, 6.0)
		while x < _w - 1.0:
			var length := rng.randf_range(1.6, minf(5.5, _h * 0.4))
			_cylinder(Vector3(x, _h - 1.0 - length * 0.5, z), 0.035, 0.05, length, "z2_vine" if z < 0.0 else "silhouette", 5)
			_sphere(Vector3(x, _h - 1.0 - length - 0.1, z), 0.13, "spore_glow" if z < 0.0 else "z2_sprout")
			x += rng.randf_range(4.0, 9.0)


## Drifting motes (dust in the cavern, spores in the forest): one small CPU particle system
## across the room (one draw call). `per_m2` sets how many per square metre of room.
func _motes(color: Color, per_m2: float) -> void:
	var p := CPUParticles3D.new()
	p.name = "Motes"
	p.amount = int(clampf(_w * _h * per_m2, 16.0, 90.0))
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(_w * 0.5, _h * 0.5, 2.5)
	p.direction = Vector3(0.2, 1.0, 0.0)
	p.spread = 35.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.08
	p.initial_velocity_max = 0.3
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SpriteArt.blob()
	mat.albedo_color = color
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = mat
	p.mesh = q
	p.position = Vector3(_w * 0.5, _h * 0.5, -1.0)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.set_meta("dynamic", true)
	root.add_child(p)


## Shafts of pale light slanting down from the ceiling, behind the play plane.
func _shafts(count: int) -> void:
	var shader := load("res://src/vfx/spatial_env_shaft.gdshader") as Shader
	var tint := Color(str(theme.get("shaft", "#9cc8ff")))
	var n := maxi(1, int(round(float(count) * _w / 30.0)))
	for i in range(n):
		var tall := minf(_h - 1.0, rng.randf_range(7.0, 11.0))
		var quad := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(rng.randf_range(1.8, 3.4), tall)
		quad.mesh = mesh
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("tint", tint)
		mat.set_shader_parameter("strength", rng.randf_range(0.1, 0.2))
		mat.set_shader_parameter("phase", rng.randf() * TAU)
		quad.material_override = mat
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		quad.position = Vector3(rng.randf_range(2.0, _w - 2.0), _h - 1.0 - tall * 0.5, rng.randf_range(-5.5, -3.2))
		quad.rotation_degrees.z = rng.randf_range(-24.0, -12.0)
		quad.set_meta("dynamic", true)
		root.add_child(quad)


## Ground mist: one band behind the play plane and a thinner one just in front of it, along
## the floor most of the room stands on.
func _mist_bands() -> void:
	var tops := _deep_tops()
	if tops.is_empty():
		return
	# The floor height with the most walkable width.
	var widths: Dictionary[float, float] = {}
	for t in tops:
		widths[t.position.y] = float(widths.get(t.position.y, 0.0)) + t.size.x
	var floor_y := 0.0
	var best := -1.0
	for y: float in widths.keys():
		if widths[y] > best:
			best = widths[y]
			floor_y = y
	var shader := load("res://src/vfx/spatial_env_mist.gdshader") as Shader
	var clouds := TexBank.get_tex("res://assets/art/textures/mist.png")
	var tint := Color(str(theme.get("mist", "#8fb0d0")))
	var layers := [[-2.9, 3.6, 1.1, 0.3, 0.008], [0.9, 1.4, 0.4, 0.12, -0.012]]
	for l: Array in layers:
		var quad := MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(_w + 14.0, float(l[1]))
		quad.mesh = mesh
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("clouds", clouds)
		mat.set_shader_parameter("tint", tint)
		mat.set_shader_parameter("density", float(l[3]) * float(theme.get("mist_density", 1.0)))
		mat.set_shader_parameter("repeats", (_w + 14.0) / 16.0)
		mat.set_shader_parameter("speed", float(l[4]))
		quad.material_override = mat
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		quad.position = Vector3(_w * 0.5, floor_y + float(l[2]), float(l[0]))
		quad.set_meta("dynamic", true)
		root.add_child(quad)


# --- Shared -----------------------------------------------------------------------------------

## Walkable tops that sit on deep rock (floors and big ledges), where floor dressing can stand.
func _deep_tops() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for t in data.trims:
		var probe := Vector2(t.position.x + 0.5, t.position.y - 0.5)
		for s in data.solids:
			if s.has_point(probe):
				var edge := s.position.x <= 0.0 or s.position.y <= 0.0 or s.end.x >= _w or s.end.y >= _h
				if edge and t.size.x >= 3.0:
					out.append(t)
				break
	return out


# --- Depth (story 054) ---------------------------------------------------------------------

## Layers that make the taller, zoomed-out rooms read as deep gothic spaces: a second tier of far
## arches (or towering mushrooms) and full-height columns where the room is tall, chains with
## cages hanging from the ceiling, dark pillars in front framing the room's ends, and candles on
## ledges.
func _depth_layers() -> void:
	var forest := str(theme.get("decor", "")) == "mushrooms"
	if _h > 14.0:
		var x := -18.0 + rng.randf_range(0.0, 8.0)
		while x < _w + 18.0:
			if forest:
				var violet := rng.randf() < 0.45
				_mushroom(Vector3(x, _h * 0.35, Z_FAR + 2.0), rng.randf_range(6.0, 12.0), rng.randf_range(2.6, 4.4),
					"z2_stalk_far", "z2_cap_far_violet" if violet else "z2_cap_far_teal")
				x += rng.randf_range(9.0, 14.0)
			else:
				_arch(Vector3(x, _h * 0.42, Z_FAR + 1.5), 6.5, clampf(_h * 0.3, 4.0, 9.0), "z1_ruin_far", rng.randf() < 0.35)
				x += 6.5 * float(rng.randi_range(2, 4))
		if not forest:
			x = rng.randf_range(3.0, 9.0)
			while x < _w - 2.0:
				_column(Vector3(x, 0.0, Z_MID - 1.6), _h - 0.8, rng.randf() < 0.25)
				x += rng.randf_range(10.0, 16.0)
	_chains()
	_front_pillars(forest)
	if not forest:
		_candles()


## Chains from the ceiling, some ending in a cage or a lantern; most behind the play plane, a few
## black ones in front.
func _chains() -> void:
	var x := rng.randf_range(2.0, 7.0)
	while x < _w - 1.0:
		var length := rng.randf_range(2.0, minf(7.0, _h * 0.45))
		var front := rng.randf() < 0.3
		var z := Z_FRONT - 0.4 if front else rng.randf_range(-2.8, -1.6)
		var mat := "silhouette" if front else "iron_dark"
		for i in range(int(length / 0.32)):
			var link := _box(Vector3(x, _h - 0.2 - 0.32 * float(i) - 0.16, z), Vector3(0.07, 0.26, 0.05 if i % 2 == 0 else 0.12), mat)
			link.rotation_degrees.y = 90.0 * float(i % 2)
		var end_y := _h - 0.2 - length
		var roll := rng.randf()
		if roll < 0.3:
			# A hanging cage: a ring top and bottom, four bars.
			for k in range(4):
				var a := TAU * float(k) / 4.0
				_box(Vector3(x + cos(a) * 0.32, end_y - 0.55, z + sin(a) * 0.32), Vector3(0.05, 1.1, 0.05), mat)
			_cylinder(Vector3(x, end_y - 0.02, z), 0.38, 0.38, 0.06, mat, 10)
			_cylinder(Vector3(x, end_y - 1.1, z), 0.38, 0.38, 0.06, mat, 10)
		elif roll < 0.55 and not front:
			# A lantern: an iron frame round a warm glow.
			_box(Vector3(x, end_y - 0.25, z), Vector3(0.3, 0.45, 0.3), "iron_dark")
			_sphere(Vector3(x, end_y - 0.25, z + 0.18), 0.12, "flame_glow")
		x += rng.randf_range(5.0, 11.0)


## Dark pillars (or giant stalks) just in front of the play plane at the room's two ends, framing
## the view without crossing the play.
func _front_pillars(forest: bool) -> void:
	for x: float in [rng.randf_range(0.2, 0.9), _w - rng.randf_range(0.2, 0.9)]:
		if forest:
			_cylinder(Vector3(x, _h * 0.5, Z_FRONT + 0.8), 0.32, 0.5, _h + 2.0, "silhouette", 8)
		else:
			_box(Vector3(x, _h * 0.5, Z_FRONT + 0.8), Vector3(0.7, _h + 2.0, 0.6), "silhouette")
			for y: float in [0.25, _h * 0.55, _h - 0.6]:
				_box(Vector3(x, y, Z_FRONT + 0.8), Vector3(1.1, 0.35, 0.8), "silhouette")


## Candles on ledges and floors: little warm flames on wax stubs.
func _candles() -> void:
	for t in data.trims:
		if t.size.x < 2.0 or rng.randf() > 0.35:
			continue
		var x := rng.randf_range(t.position.x + 0.4, t.end.x - 0.4)
		for k in range(rng.randi_range(1, 3)):
			var cx := x + float(k) * 0.22
			var h := rng.randf_range(0.18, 0.4)
			_cylinder(Vector3(cx, t.position.y + h * 0.5, -0.5), 0.05, 0.06, h, "candle_wax", 6)
			_sphere(Vector3(cx, t.position.y + h + 0.06, -0.5), 0.05, "flame_glow")


## Stone teeth under the ceiling: small ones just behind the play plane, black ones in front.
func _stalactites(mat: String) -> void:
	var x := rng.randf_range(1.5, 5.0)
	while x < _w - 1.0:
		var length := rng.randf_range(0.8, 2.2)
		_cone(Vector3(x, _h - 1.0 - length * 0.5, rng.randf_range(-3.5, -1.8)), rng.randf_range(0.25, 0.5), length, mat)
		x += rng.randf_range(2.5, 6.0)
	# Front silhouettes stay short: closer to the camera they look bigger, and they must never
	# hang over an upper ledge.
	x = rng.randf_range(3.0, 9.0)
	while x < _w:
		var length := rng.randf_range(0.9, 1.7)
		var c := _cone(Vector3(x, _h - 0.3 - length * 0.5, Z_FRONT), rng.randf_range(0.25, 0.45), length, "silhouette")
		c.rotation_degrees.z = rng.randf_range(-6.0, 6.0)
		x += rng.randf_range(9.0, 16.0)


## Black rocks toward the camera along the bottom edge. Only in rooms about one screen tall:
## in a shaft they would sit in front of the lower platforms.
func _silhouettes() -> void:
	var x := rng.randf_range(-2.0, 4.0)
	while x < _w + 2.0:
		# A clump of two or three black stalagmites.
		for k in range(rng.randi_range(2, 3)):
			var h := rng.randf_range(1.3, 2.6)
			var spike := _cylinder(Vector3(x + float(k) * rng.randf_range(0.5, 0.9), h * 0.5 - 0.5, Z_FRONT), 0.0,
				rng.randf_range(0.45, 0.8), h, "silhouette", 6)
			spike.rotation_degrees.z = rng.randf_range(-7.0, 7.0)
		x += rng.randf_range(8.0, 14.0)


func _box(pos: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = ArenaMaterials.get_material(material)
	mesh.set_meta("cast_shadow", false)
	root.add_child(mesh)
	return mesh


func _cylinder(pos: Vector3, top_r: float, bottom_r: float, height: float, material: String, segments: int = 12) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bottom_r
	cyl.height = height
	cyl.radial_segments = segments
	cyl.rings = 1
	mesh.mesh = cyl
	mesh.position = pos
	mesh.material_override = ArenaMaterials.get_material(material)
	mesh.set_meta("cast_shadow", false)
	root.add_child(mesh)
	return mesh


## A downward-pointing cone (stalactite).
func _cone(pos: Vector3, radius: float, length: float, material: String) -> MeshInstance3D:
	return _cylinder(pos, radius, 0.0, length, material, 7)


func _sphere(pos: Vector3, radius: float, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 8
	s.rings = 4
	mesh.mesh = s
	mesh.position = pos
	mesh.material_override = ArenaMaterials.get_material(material)
	mesh.set_meta("cast_shadow", false)
	root.add_child(mesh)
	return mesh
