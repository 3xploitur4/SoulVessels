class_name GroundDresser
extends RefCounted
## Gives a room's ground a shape (story 054, decision D-062): the zoomed-out camera showed every
## floor as one flat lit box. Now each walkable edge is a strip of worn slabs (some chipped, a
## crumbling lip where a ledge ends), carved stone blocks stand out of the face beneath it, rock
## teeth hang under every overhang, a zone accent runs along the edge (moss, roots with glowing
## drips, a gold moulding, embers in the joints), and darkness is laid over the rock by distance
## from open air, so the lit edge is what the eye follows and the mass beneath falls to black.
## Rock is also drawn around the room so a wide view never shows a void past its edge.
## Nothing here collides. Values come from data/art/ground.json; everything is seeded by the room.
##
##     GroundDresser.build(room_builder, room_data, theme_id, theme, rng)

const PATH := "res://data/art/ground.json"
const BACK_Z := -4.5
const FLOAT_BACK_Z := -2.2
const FRONT_Z := 1.2

var root: Node3D
var data: RoomData
var theme: Dictionary
var cfg: Dictionary
var rng: RandomNumberGenerator

## Extended solid grid: the room plus `_m` cells of rock on every side, y up.
var _m: int = 8
var _w: int = 0
var _h: int = 0
var _solid := PackedByteArray()


## Ground settings for theme `theme_id`: the defaults with the theme's own keys on top.
static func config(theme_id: String) -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not d is Dictionary:
		return {}
	var out: Dictionary = ((d as Dictionary).get("default", {}) as Dictionary).duplicate()
	out.merge((d as Dictionary).get(theme_id, {}), true)
	return out


## Darkness for a corner `dist` cells from open air, read from the `shade` table (the last entry
## for anything deeper).
static func shade_alpha(dist: int, table: Array) -> float:
	if table.is_empty():
		return 0.0
	return float(table[clampi(dist, 0, table.size() - 1)])


## Cells from the nearest open cell (8 neighbours) for every cell of a `w` x `h` grid; open cells
## are 0. Solid cells with no open cell anywhere get `w + h`.
static func distance_field(solid: PackedByteArray, w: int, h: int) -> PackedInt32Array:
	var dist := PackedInt32Array()
	dist.resize(w * h)
	var queue := PackedInt32Array()
	for i in range(w * h):
		if solid[i] == 0:
			dist[i] = 0
			queue.append(i)
		else:
			dist[i] = w + h
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var x := i % w
		var y := i / w
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var nx := x + dx
				var ny := y + dy
				if (dx == 0 and dy == 0) or nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var n := nx + ny * w
				if dist[n] > dist[i] + 1:
					dist[n] = dist[i] + 1
					queue.append(n)
	return dist


static func build(builder: Node3D, room: RoomData, theme_id: String, room_theme: Dictionary, random: RandomNumberGenerator) -> void:
	var g := GroundDresser.new()
	g.root = builder
	g.data = room
	g.theme = room_theme
	g.cfg = config(theme_id)
	g.rng = random
	g._m = int(g.cfg.get("margin_cells", 8))
	g._grid()
	g._surround()
	g._caps()
	g._face()
	g._teeth()
	g._shade()


# --- The grid ---------------------------------------------------------------------------------

## Is room cell (x, y) solid rock? Outside the room counts as rock except straight out from an
## exit, which stays open so the doorway does not look walled up.
func solid_at(x: int, y: int) -> bool:
	var gx := x + _m
	var gy := y + _m
	if gx < 0 or gy < 0 or gx >= _w or gy >= _h:
		return true
	return _solid[gx + gy * _w] == 1


func _grid() -> void:
	_w = data.cols + 2 * _m
	_h = data.rows + 2 * _m
	_solid.resize(_w * _h)
	for gy in range(_h):
		for gx in range(_w):
			var inside := gx >= _m and gy >= _m and gx < _m + data.cols and gy < _m + data.rows
			_solid[gx + gy * _w] = 0 if inside else 1
	for r in data.solids:
		for x in range(int(r.position.x), int(r.end.x)):
			for y in range(int(r.position.y), int(r.end.y)):
				_solid[(x + _m) + (y + _m) * _w] = 1
	for digit: String in data.exits.keys():
		var e: Rect2 = data.exits[digit]["rect"]
		var x0 := int(e.position.x)
		var x1 := int(e.end.x)
		var y0 := int(e.position.y)
		var y1 := int(e.end.y)
		if e.position.x <= 0.0:
			x0 = -_m
		elif e.end.x >= float(data.cols):
			x1 = data.cols + _m
		elif e.position.y <= 0.0:
			y0 = -_m
		else:
			y1 = data.rows + _m
		for x in range(x0, x1):
			for y in range(y0, y1):
				var gx := x + _m
				var gy := y + _m
				if gx >= 0 and gy >= 0 and gx < _w and gy < _h:
					_solid[gx + gy * _w] = 0


## Rock around the room: the margin's solid cells as a few big boxes, deep like the room's own.
func _surround() -> void:
	var rock := str(theme.get("rock", "slate_floor"))
	var used := PackedByteArray()
	used.resize(_w * _h)
	for gy in range(_h):
		for gx in range(_w):
			if not _margin_rock(gx, gy) or used[gx + gy * _w] == 1:
				continue
			var w := 1
			while gx + w < _w and _margin_rock(gx + w, gy) and used[gx + w + gy * _w] == 0:
				w += 1
			var h := 1
			var grow := true
			while grow and gy + h < _h:
				for k in range(w):
					if not _margin_rock(gx + k, gy + h) or used[gx + k + (gy + h) * _w] == 1:
						grow = false
						break
				if grow:
					h += 1
			for yy in range(gy, gy + h):
				for k in range(w):
					used[gx + k + yy * _w] = 1
			var box := _box(Vector3(float(gx - _m) + float(w) * 0.5, float(gy - _m) + float(h) * 0.5, (BACK_Z + FRONT_Z) * 0.5),
				Vector3(float(w), float(h), FRONT_Z - BACK_Z), rock)
			box.set_meta("cast_shadow", false)


func _margin_rock(gx: int, gy: int) -> bool:
	var inside := gx >= _m and gy >= _m and gx < _m + data.cols and gy < _m + data.rows
	return not inside and _solid[gx + gy * _w] == 1


# --- Walkable edges -----------------------------------------------------------------------------

## Slabs along every walkable top, from the play plane's back to just past the rock face.
func _caps() -> void:
	var trim := str(theme.get("trim", "marble"))
	var ledge := str(theme.get("ledge", theme.get("rock", "slate_floor")))
	var back := float(cfg.get("cap_back_z", -0.75))
	var front := FRONT_Z + 0.07
	var lens: Array = cfg.get("slab_len", [0.8, 2.1])
	var chip := float(cfg.get("chip_chance", 0.15))
	for t in data.trims:
		var x := t.position.x
		while x < t.end.x - 0.05:
			var slab_len := minf(rng.randf_range(float(lens[0]), float(lens[1])), t.end.x - x)
			if t.end.x - (x + slab_len) < 0.45:
				slab_len = t.end.x - x
			var f := front
			if rng.randf() < chip:
				f -= rng.randf_range(0.12, 0.32)
			var top := t.position.y + 0.09 + rng.randf_range(-0.012, 0.012)
			var gap := 0.035 if x + slab_len < t.end.x - 0.01 else 0.0
			var slab := _box(Vector3(x + (slab_len - gap) * 0.5, top - 0.06, (back + f) * 0.5), Vector3(slab_len - gap, 0.12, f - back), trim)
			if rng.randf() < 0.12:
				slab.rotation_degrees = Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.2, 1.2))
			x += slab_len
		# A crumbling lip where the ground ends in open air.
		var y := int(t.position.y) - 1
		for side: int in [-1, 1]:
			var cx := int(t.position.x) - 1 if side < 0 else int(t.end.x)
			if solid_at(cx, y) or solid_at(cx, y + 1):
				continue
			var ex := t.position.x if side < 0 else t.end.x
			var chunk := _box(Vector3(ex + float(side) * 0.05, t.position.y - 0.28, rng.randf_range(0.2, 0.8)),
				Vector3(0.34, 0.26, 0.6), ledge)
			chunk.rotation_degrees = Vector3(0.0, rng.randf_range(-15.0, 15.0), float(side) * rng.randf_range(-38.0, -18.0))
			var bit := _box(Vector3(ex - float(side) * 0.25, t.position.y - 0.62, rng.randf_range(0.4, 1.0)),
				Vector3(0.2, 0.18, 0.3), ledge)
			bit.rotation_degrees.z = rng.randf_range(-30.0, 30.0)


## The face under each edge: carved blocks standing out of the rock, the zone accent, and loose
## stones on the lip.
func _face() -> void:
	var stone := str(theme.get("ledge", theme.get("rock", "slate_floor")))
	var bw: Array = cfg.get("block_w", [0.45, 1.3])
	var bh: Array = cfg.get("block_h", [0.26, 0.5])
	var skip := float(cfg.get("block_skip", 0.12))
	var row2 := float(cfg.get("block_row2", 0.5))
	var accent := str(cfg.get("accent", ""))
	var every: Array = cfg.get("accent_every", [1.5, 4.0])
	var pebbles: Array = cfg.get("pebbles_every", [2.0, 5.0])
	for t in data.trims:
		var top := t.position.y
		# Row one, right under the slabs.
		var x := t.position.x + rng.randf_range(0.0, 0.2)
		while x < t.end.x - 0.25:
			var w := minf(rng.randf_range(float(bw[0]), float(bw[1])), t.end.x - x)
			if rng.randf() >= skip and w > 0.2:
				var h := rng.randf_range(float(bh[0]), float(bh[1]))
				var out := rng.randf_range(0.02, 0.14)
				var b := _box(Vector3(x + w * 0.5, top - 0.1 - rng.randf_range(0.0, 0.05) - h * 0.5, FRONT_Z + out - 0.18),
					Vector3(w - 0.05, h, 0.36), stone)
				b.rotation_degrees.z = rng.randf_range(-1.8, 1.8)
				if accent == "embers" and rng.randf() < 0.5:
					_box(Vector3(x + w, top - 0.12 - h * 0.5, FRONT_Z + 0.03), Vector3(0.035, h * 0.9, 0.04), "vein_orange")
			x += w
		# Row two, where the rock goes on down.
		x = t.position.x + rng.randf_range(0.2, 0.6)
		while x < t.end.x - 0.4:
			var w := minf(rng.randf_range(float(bw[0]) + 0.15, float(bw[1]) + 0.2), t.end.x - x)
			if rng.randf() < row2 and solid_at(int(x + w * 0.5), int(top) - 2) and w > 0.3:
				var h := rng.randf_range(float(bh[0]) + 0.05, float(bh[1]) + 0.08)
				_box(Vector3(x + w * 0.5, top - 0.66 - h * 0.5, FRONT_Z + rng.randf_range(0.0, 0.1) - 0.18),
					Vector3(w - 0.06, h, 0.36), stone)
			x += w
		match accent:
			"gold":
				# A moulding under the slabs, the whole length of the edge.
				_box(Vector3(t.position.x + t.size.x * 0.5, top - 0.17, FRONT_Z + 0.1), Vector3(t.size.x, 0.07, 0.22), "z3_top")
				_box(Vector3(t.position.x + t.size.x * 0.5, top - 0.27, FRONT_Z + 0.04), Vector3(t.size.x, 0.05, 0.12), "z3_top")
			"moss", "roots":
				x = t.position.x + rng.randf_range(0.2, float(every[0]))
				while x < t.end.x - 0.15:
					_hang(Vector3(x, top - 0.02, FRONT_Z + rng.randf_range(0.04, 0.16)), accent == "roots")
					x += rng.randf_range(float(every[0]), float(every[1]))
		# Loose stones on the lip, small enough never to hide a foot.
		x = t.position.x + rng.randf_range(0.4, float(pebbles[1]))
		while x < t.end.x - 0.3:
			var s := rng.randf_range(0.06, 0.11)
			var p := _box(Vector3(x, top + 0.09 + s * 0.4, rng.randf_range(0.95, 1.18)), Vector3(s * 1.4, s, s * 1.1), stone)
			p.rotation_degrees = Vector3(rng.randf_range(-20.0, 20.0), rng.randf_range(0.0, 90.0), rng.randf_range(-25.0, 25.0))
			x += rng.randf_range(float(pebbles[0]), float(pebbles[1]))


## A clump hanging over an edge: moss strands, or roots ending in glowing drips.
func _hang(at: Vector3, roots: bool) -> void:
	for k in range(rng.randi_range(2, 4)):
		var drop := rng.randf_range(0.18, 0.75)
		var off := Vector3(rng.randf_range(-0.22, 0.22), 0.0, rng.randf_range(-0.03, 0.05))
		if roots:
			var r := _box(at + off + Vector3(0.0, -drop * 0.5, 0.0), Vector3(0.045, drop, 0.045), "z2_vine")
			r.rotation_degrees.z = rng.randf_range(-12.0, 12.0)
			if rng.randf() < 0.55:
				_box(at + off + Vector3(0.0, -drop - 0.04, 0.0), Vector3(0.07, 0.09, 0.07), "spore_glow" if k % 2 == 0 else "z2_sprout")
		else:
			var m := _box(at + off + Vector3(0.0, -drop * 0.5, 0.0), Vector3(rng.randf_range(0.05, 0.11), drop, 0.04), "moss")
			m.rotation_degrees.z = rng.randf_range(-6.0, 6.0)


## Rock teeth under every overhang (ledges and ceilings), a few large ones behind the play plane
## and small ones in front, never longer than part of the free space below.
func _teeth() -> void:
	var stone := str(theme.get("ledge", theme.get("rock", "slate_floor")))
	var every: Array = cfg.get("teeth_every", [0.5, 1.3])
	var lens: Array = cfg.get("teeth_len", [0.2, 0.8])
	var room := float(cfg.get("teeth_room", 0.35))
	var roots := str(cfg.get("accent", "")) == "roots"
	for y in range(data.rows):
		var x := 0
		while x < data.cols:
			if not (solid_at(x, y) and not solid_at(x, y - 1)) or y == 0:
				x += 1
				continue
			var start := x
			while x < data.cols and solid_at(x, y) and not solid_at(x, y - 1):
				x += 1
			var free := 0
			while free < 6 and not solid_at(start, y - 1 - free) and not _oneway_at(start, y - 1 - free) and y - 1 - free >= 0:
				free += 1
			var max_len := maxf(float(free) * room, 0.15)
			var tx := float(start) + rng.randf_range(0.15, 0.5)
			while tx < float(x) - 0.15:
				var tooth := minf(rng.randf_range(float(lens[0]), float(lens[1])), max_len)
				var front := rng.randf() < 0.4
				var z := rng.randf_range(0.5, 1.0) if front else rng.randf_range(-1.0, -0.2)
				if front:
					tooth *= 0.6
				var c := _cone(Vector3(tx, float(y) - tooth * 0.5 + 0.02, z), rng.randf_range(0.1, 0.24) * (0.7 if front else 1.0), tooth, stone)
				c.rotation_degrees.z = rng.randf_range(-7.0, 7.0)
				if roots and rng.randf() < 0.3:
					_box(Vector3(tx + 0.2, float(y) - tooth * 0.8, z + 0.1), Vector3(0.04, tooth * 1.4, 0.04), "z2_vine")
				tx += rng.randf_range(float(every[0]), float(every[1]))


# --- Darkness -----------------------------------------------------------------------------------

## One mesh of darkness over every solid cell's face, by distance from open air, and over the top
## of the rock behind the slabs.
func _shade() -> void:
	var table: Array = cfg.get("shade", [0.0, 0.5, 0.8, 0.92, 0.97])
	var dist := distance_field(_solid, _w, _h)
	var z := FRONT_Z + float(cfg.get("shade_z", 0.34))
	# Darkness at every grid corner, read once.
	var cw := _w + 1
	var corner := PackedFloat32Array()
	corner.resize(cw * (_h + 1))
	for cy in range(_h + 1):
		for cx in range(cw):
			corner[cx + cy * cw] = shade_alpha(_corner(dist, cx, cy), table)
	var verts := PackedVector3Array()
	var cols := PackedColorArray()
	for gy in range(_h):
		for gx in range(_w):
			if _solid[gx + gy * _w] == 0:
				continue
			var a00 := corner[gx + gy * cw]
			var a10 := corner[gx + 1 + gy * cw]
			var a01 := corner[gx + (gy + 1) * cw]
			var a11 := corner[gx + 1 + (gy + 1) * cw]
			if maxf(maxf(a00, a10), maxf(a01, a11)) < 0.01:
				continue
			var x0 := float(gx - _m)
			var y0 := float(gy - _m)
			_quad(verts, cols, Vector3(x0, y0, z), Vector3(x0 + 1.0, y0, z), Vector3(x0 + 1.0, y0 + 1.0, z), Vector3(x0, y0 + 1.0, z),
				a00, a10, a11, a01)
	var top: Array = cfg.get("top_shade", [0.35, 0.88])
	var cap_back := float(cfg.get("cap_back_z", -0.75))
	for t in data.trims:
		var back := BACK_Z if _deep_under(t) else FLOAT_BACK_Z
		var y := t.position.y + 0.012
		var fa := float(top[0])
		var ba := float(top[1]) * (1.0 if back == BACK_Z else 0.8)
		_quad(verts, cols, Vector3(t.position.x, y, cap_back), Vector3(t.end.x, y, cap_back), Vector3(t.end.x, y, back),
			Vector3(t.position.x, y, back), fa, fa, ba, ba)
	if verts.is_empty():
		return
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(str(theme.get("background", "#04060a")))
	var mi := MeshInstance3D.new()
	mi.name = "GroundShade"
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta("dynamic", true)
	root.add_child(mi)


## The smallest distance among the (up to four) cells meeting at grid corner (cx, cy).
func _corner(dist: PackedInt32Array, cx: int, cy: int) -> int:
	var best := 1 << 20
	for dy in range(-1, 1):
		for dx in range(-1, 1):
			var x := cx + dx
			var y := cy + dy
			if x >= 0 and y >= 0 and x < _w and y < _h:
				best = mini(best, dist[x + y * _w])
	return best


## Two triangles, corners p0..p3 with darkness a0..a3.
func _quad(verts: PackedVector3Array, cols: PackedColorArray, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3,
		a0: float, a1: float, a2: float, a3: float) -> void:
	verts.append_array(PackedVector3Array([p0, p1, p2, p0, p2, p3]))
	cols.append_array(PackedColorArray([Color(1, 1, 1, a0), Color(1, 1, 1, a1), Color(1, 1, 1, a2),
		Color(1, 1, 1, a0), Color(1, 1, 1, a2), Color(1, 1, 1, a3)]))


## Is room cell (x, y) a one-way plank walkway?
func _oneway_at(x: int, y: int) -> bool:
	for r in data.oneway:
		if is_equal_approx(r.position.y, float(y + 1)) and float(x) >= r.position.x and float(x) < r.end.x:
			return true
	return false


## Is the rock under walkable top `t` part of a mass touching the room's edge (a floor or a big
## wall) rather than a floating ledge?
func _deep_under(t: Rect2) -> bool:
	var p := Vector2(t.position.x + 0.5, t.position.y - 0.5)
	for s in data.solids:
		if s.has_point(p):
			return s.position.x <= 0.0 or s.position.y <= 0.0 or s.end.x >= float(data.cols) or s.end.y >= float(data.rows)
	return false


# --- Meshes -------------------------------------------------------------------------------------

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


## A downward-pointing cone.
func _cone(pos: Vector3, radius: float, length: float, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = 0.0
	cyl.height = length
	cyl.radial_segments = 6
	cyl.rings = 1
	mesh.mesh = cyl
	mesh.position = pos
	mesh.material_override = ArenaMaterials.get_material(material)
	mesh.set_meta("cast_shadow", false)
	root.add_child(mesh)
	return mesh
