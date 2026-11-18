class_name GroundDresser
extends RefCounted
## Gives a room's ground a shape (story 054, decisions D-062 and D-064), after the ground of
## Blasphemous: nothing machine-made, nothing clean. Every walkable edge is a row of worn slabs of
## their own lengths and colours, some broken, a crumbling lip where the ground ends; every rock
## face near open air is laid with single stones (cut courses, or rough chunks in the forest and
## the rift), each its own colour, depth and chipped corners, a few fallen out; water stains run
## down from the edges and cracks split the face; candles in clusters, skulls, bones, rubble,
## broken column stumps and gravestones lie on the ground behind the play plane; rock teeth hang
## under every overhang; a zone accent runs along the edges (moss, roots with glowing drips, a gold
## moulding, embers in the joints). Darkness is laid over the rock by distance from open air, so
## the lit edge is what the eye follows and the mass beneath falls to black, and rock is drawn
## around the room so a wide view never shows a void. Nothing here collides. Values come from
## data/art/ground.json; everything is seeded by the room. Stones are built into one mesh per
## material, tinted stone by stone through vertex colour.
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
var _dist := PackedInt32Array()
## Stones by material, and the stains and cracks that go into the darkness mesh.
var _batches: Dictionary = {}
var _mv := PackedVector3Array()
var _mc := PackedColorArray()


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
	g._dist = distance_field(g._solid, g._w, g._h)
	g._surround()
	g._slabs()
	g._masonry()
	g._edges()
	g._marks()
	g._clutter()
	g._teeth()
	g._commit_stones()
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


# --- Stones -------------------------------------------------------------------------------------

## Vertices of one material's stones, built into a single mesh at the end (one draw call).
class Batch:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()


## The batch for material `name` (tinted stone by stone).
func _batch(name: String) -> Batch:
	if not _batches.has(name):
		_batches[name] = Batch.new()
	return _batches[name]


## One stone: the front outline is a rectangle (x0..x1, y0..y1) with each corner knocked off by up
## to `cut` metres, pushed back from z1 to z0. Sides come out a little darker than the face.
## Triangles wind clockwise as seen from outside (Godot's front face), or the lit side flips.
## `top_only` keeps the bottom corners square (slabs sitting on rock).
func _stone(b: Batch, x0: float, y0: float, x1: float, y1: float, z0: float, z1: float, cut: float, col: Color,
		top_only: bool = false) -> void:
	var lim := minf(x1 - x0, y1 - y0) * 0.45
	var c := PackedFloat32Array()
	for i in range(4):
		var k := 0.0 if top_only and i < 2 else rng.randf_range(0.0, cut)
		c.append(minf(k, lim))
	var p := PackedVector2Array([Vector2(x0 + c[0], y0), Vector2(x1 - c[1], y0), Vector2(x1, y0 + c[1]), Vector2(x1, y1 - c[2]),
		Vector2(x1 - c[2], y1), Vector2(x0 + c[3], y1), Vector2(x0, y1 - c[3]), Vector2(x0, y0 + c[0])])
	var mid := Vector2((x0 + x1) * 0.5, (y0 + y1) * 0.5)
	var side := col.darkened(0.22)
	for i in range(8):
		var a := p[i]
		var q := p[(i + 1) % 8]
		if a.distance_squared_to(q) < 0.000001:
			continue
		b.v.append_array(PackedVector3Array([Vector3(mid.x, mid.y, z1), Vector3(q.x, q.y, z1), Vector3(a.x, a.y, z1)]))
		b.n.append_array(PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK]))
		b.c.append_array(PackedColorArray([col, col, col]))
		var e := (q - a).normalized()
		var nrm := Vector3(e.y, -e.x, 0.0)
		# Faces that look up catch the light; the rest stay in the stone's own shadow.
		var sc := col.lightened(0.06) if nrm.y > 0.5 else side
		b.v.append_array(PackedVector3Array([Vector3(a.x, a.y, z1), Vector3(q.x, q.y, z1), Vector3(q.x, q.y, z0),
			Vector3(a.x, a.y, z1), Vector3(q.x, q.y, z0), Vector3(a.x, a.y, z0)]))
		b.n.append_array(PackedVector3Array([nrm, nrm, nrm, nrm, nrm, nrm]))
		b.c.append_array(PackedColorArray([sc, sc, sc, sc, sc, sc]))


## A colour for the next stone: one of the zone's tints, a little brighter or duller.
func _tint() -> Color:
	var tints: Array = cfg.get("tints", ["#ffffff"])
	var base := Color(str(tints[rng.randi() % tints.size()]))
	var j := float(cfg.get("tint_jitter", 0.1))
	var k := rng.randf_range(1.0 - j, 1.0 + j)
	return Color(base.r * k, base.g * k, base.b * k, 1.0)


## Is room cell (x, y) rock close enough to open air to be faced with stones?
func _skin(x: int, y: int) -> bool:
	var gx := x + _m
	var gy := y + _m
	if gx < 0 or gy < 0 or gx >= _w or gy >= _h or _solid[gx + gy * _w] == 0:
		return false
	return _dist[gx + gy * _w] <= int(cfg.get("skin_cells", 2))


## Slabs along every walkable top, from behind the play plane to just past the rock face: each its
## own length and colour, some with a broken front, a crumbling lip where the ground ends.
func _slabs() -> void:
	var b := _batch(str(theme.get("trim", "marble")))
	var ledge := str(theme.get("ledge", theme.get("rock", "slate_floor")))
	var back := float(cfg.get("cap_back_z", -0.75))
	var front := FRONT_Z + 0.07
	var lens: Array = cfg.get("slab_len", [0.6, 1.6])
	var chip := float(cfg.get("chip_chance", 0.15))
	var cut := float(cfg.get("slab_cut", 0.08))
	for t in data.trims:
		var x := t.position.x
		while x < t.end.x - 0.05:
			var slab_len := minf(rng.randf_range(float(lens[0]), float(lens[1])), t.end.x - x)
			if t.end.x - (x + slab_len) < 0.35:
				slab_len = t.end.x - x
			var f := front
			if rng.randf() < chip:
				f -= rng.randf_range(0.12, 0.34)
			var top := t.position.y + 0.09 + rng.randf_range(-0.015, 0.015)
			var gap := 0.04 if x + slab_len < t.end.x - 0.01 else 0.0
			_stone(b, x, top - 0.13, x + slab_len - gap, top, back, f, cut, _tint().lightened(0.08), true)
			x += slab_len
		var y := int(t.position.y) - 1
		for side: int in [-1, 1]:
			var cx := int(t.position.x) - 1 if side < 0 else int(t.end.x)
			if solid_at(cx, y) or solid_at(cx, y + 1):
				continue
			var ex := t.position.x if side < 0 else t.end.x
			var chunk := _box(Vector3(ex + float(side) * 0.05, t.position.y - 0.28, rng.randf_range(0.2, 0.8)), Vector3(0.34, 0.26, 0.6), ledge)
			chunk.rotation_degrees = Vector3(0.0, rng.randf_range(-15.0, 15.0), float(side) * rng.randf_range(-38.0, -18.0))
			var bit := _box(Vector3(ex - float(side) * 0.25, t.position.y - 0.62, rng.randf_range(0.4, 1.0)), Vector3(0.2, 0.18, 0.3), ledge)
			bit.rotation_degrees.z = rng.randf_range(-30.0, 30.0)


## Every rock face near open air laid with stones: courses of cut stone ('masonry', two to a metre,
## the joints falling where they will) or rough chunks ('rock'), each stone its own colour, depth
## and broken corners, a few fallen out. Embers glow in some joints in the rift.
func _masonry() -> void:
	var b := _batch(str(cfg.get("stone", "z1_stone")))
	var rough := str(cfg.get("style", "masonry")) == "rock"
	var sw: Array = cfg.get("stone_w", [0.35, 1.15])
	var cut := float(cfg.get("stone_cut", 0.09))
	var out: Array = cfg.get("stone_out", [0.02, 0.13])
	var missing := float(cfg.get("missing", 0.05))
	var embers := str(cfg.get("accent", "")) == "embers"
	for y in range(-1, data.rows + 1):
		var x := -1
		while x <= data.cols:
			if not _skin(x, y):
				x += 1
				continue
			var start := x
			while x <= data.cols and _skin(x, y):
				x += 1
			# The courses of this run: under a walkable top the first sits just below the slabs.
			var courses: Array[Vector2] = []
			var top := float(y + 1)
			if not solid_at(start, y + 1):
				top -= 0.06
			if rough:
				courses.append(Vector2(float(y) + rng.randf_range(0.0, 0.08), top - rng.randf_range(0.0, 0.08)))
			else:
				var split := float(y) + rng.randf_range(0.4, 0.6)
				courses.append(Vector2(float(y), split))
				courses.append(Vector2(split, top))
			for c in courses:
				var sx := float(start) + rng.randf_range(-0.2, 0.0)
				while sx < float(x):
					var w := rng.randf_range(float(sw[0]), float(sw[1]))
					var x1 := minf(sx + w, float(x))
					if x1 - sx > 0.15 and rng.randf() >= missing:
						var z1 := FRONT_Z + rng.randf_range(float(out[0]), float(out[1]))
						_stone(b, sx + 0.025, c.x + 0.025, x1 - 0.025, c.y - 0.025, FRONT_Z - 0.15, z1, cut * (1.6 if rough else 1.0), _tint())
					if embers and rng.randf() < 0.18:
						_box(Vector3(x1, (c.x + c.y) * 0.5, FRONT_Z + 0.02), Vector3(0.04, (c.y - c.x) * 0.8, 0.05), "vein_orange")
					sx = x1


## Zone accents along each edge and loose stones on the lip.
func _edges() -> void:
	var stone := str(cfg.get("stone", "z1_stone"))
	var accent := str(cfg.get("accent", ""))
	var every: Array = cfg.get("accent_every", [1.5, 4.0])
	var pebbles: Array = cfg.get("pebbles_every", [2.0, 5.0])
	for t in data.trims:
		var top := t.position.y
		match accent:
			"gold":
				_box(Vector3(t.position.x + t.size.x * 0.5, top - 0.19, FRONT_Z + 0.16), Vector3(t.size.x, 0.07, 0.22), "z3_top")
				_box(Vector3(t.position.x + t.size.x * 0.5, top - 0.29, FRONT_Z + 0.12), Vector3(t.size.x, 0.05, 0.12), "z3_top")
			"moss", "roots":
				var x := t.position.x + rng.randf_range(0.2, float(every[0]))
				while x < t.end.x - 0.15:
					_hang(Vector3(x, top - 0.02, FRONT_Z + rng.randf_range(0.1, 0.2)), accent == "roots")
					x += rng.randf_range(float(every[0]), float(every[1]))
		var px := t.position.x + rng.randf_range(0.3, float(pebbles[1]))
		while px < t.end.x - 0.3:
			var s := rng.randf_range(0.05, 0.1)
			var p := _box(Vector3(px, top + 0.09 + s * 0.4, rng.randf_range(0.95, 1.2)), Vector3(s * 1.4, s, s * 1.1), stone)
			p.rotation_degrees = Vector3(rng.randf_range(-20.0, 20.0), rng.randf_range(0.0, 90.0), rng.randf_range(-25.0, 25.0))
			px += rng.randf_range(float(pebbles[0]), float(pebbles[1]))


## Water stains running down from each edge and cracks in the face, drawn into the darkness mesh.
func _marks() -> void:
	var stains: Array = cfg.get("stains_every", [1.4, 3.6])
	var cracks: Array = cfg.get("cracks_every", [0.9, 2.6])
	var z := FRONT_Z + 0.15
	for t in data.trims:
		var depth := 0
		while depth < 3 and solid_at(int(t.position.x + t.size.x * 0.5), int(t.position.y) - 1 - depth):
			depth += 1
		var room := maxf(float(depth) - 0.2, 0.3)
		var x := t.position.x + rng.randf_range(0.2, float(stains[1]))
		while x < t.end.x - 0.2:
			var w := rng.randf_range(0.12, 0.38)
			var drip := minf(rng.randf_range(0.4, 1.5), room)
			var y0 := t.position.y - 0.14
			_quad(_mv, _mc, Vector3(x, y0 - drip, z), Vector3(x + w, y0 - drip, z), Vector3(x + w * 0.8, y0, z), Vector3(x + w * 0.1, y0, z),
				0.0, 0.0, 0.42, 0.42)
			x += rng.randf_range(float(stains[0]), float(stains[1]))
		x = t.position.x + rng.randf_range(0.2, float(cracks[1]))
		while x < t.end.x - 0.2:
			var p := Vector2(x, t.position.y - 0.12)
			for k in range(rng.randi_range(2, 4)):
				var q := p + Vector2(rng.randf_range(-0.14, 0.14), -rng.randf_range(0.12, 0.3))
				if q.y < t.position.y - room:
					break
				var s := 0.014
				_quad(_mv, _mc, Vector3(p.x - s, p.y, z), Vector3(q.x - s, q.y, z), Vector3(q.x + s, q.y, z), Vector3(p.x + s, p.y, z),
					0.75, 0.75, 0.75, 0.75)
				p = q
			x += rng.randf_range(float(cracks[0]), float(cracks[1]))


## What lies on the walkable tops, behind the play plane so it never hides a foot: clusters of
## candles, skulls, bones, rubble, broken column stumps and gravestones (the last two on the
## deep ground only).
func _clutter() -> void:
	var weights: Dictionary = cfg.get("clutter", {})
	var every: Array = cfg.get("clutter_every", [1.1, 3.2])
	var stone := str(cfg.get("stone", "z1_stone"))
	var ledge := str(theme.get("ledge", stone))
	var total := 0.0
	for k: String in weights.keys():
		total += float(weights[k])
	if total <= 0.0:
		return
	for t in data.trims:
		if t.size.x < 1.5:
			continue
		var deep := _deep_under(t)
		var x := t.position.x + rng.randf_range(0.4, float(every[1]))
		while x < t.end.x - 0.4:
			var pick := rng.randf() * total
			var kind := ""
			for k: String in weights.keys():
				pick -= float(weights[k])
				if pick <= 0.0:
					kind = k
					break
			var y := t.position.y + 0.09
			match kind:
				"candles":
					var z := rng.randf_range(-0.7, -0.45)
					_cylinder(Vector3(x, y + 0.01, z), 0.24, 0.26, 0.02, "candle_wax")
					for i in range(rng.randi_range(3, 7)):
						var h := rng.randf_range(0.12, 0.55)
						var cx := x + rng.randf_range(-0.22, 0.22)
						var cz := z + rng.randf_range(-0.12, 0.12)
						_cylinder(Vector3(cx, y + h * 0.5, cz), 0.035, 0.045, h, "candle_wax")
						_sphere(Vector3(cx, y + h + 0.045, cz), 0.035, "flame_glow")
				"skull":
					var z := rng.randf_range(-0.7, -0.4)
					_sphere(Vector3(x, y + 0.1, z), 0.1, "bone")
					_box(Vector3(x + 0.05, y + 0.03, z), Vector3(0.1, 0.05, 0.12), "bone")
				"bones":
					for i in range(rng.randi_range(2, 3)):
						var bone := _cylinder(Vector3(x + rng.randf_range(-0.25, 0.25), y + 0.025, rng.randf_range(-0.8, -0.4)), 0.02, 0.02,
							rng.randf_range(0.25, 0.45), "bone")
						bone.rotation_degrees = Vector3(0.0, rng.randf_range(0.0, 180.0), 90.0)
				"rubble":
					for i in range(rng.randi_range(3, 6)):
						var s := rng.randf_range(0.08, 0.24)
						var r := _box(Vector3(x + rng.randf_range(-0.4, 0.4), y + s * 0.4, rng.randf_range(-1.1, -0.4)), Vector3(s * 1.3, s, s), stone)
						r.rotation_degrees = Vector3(rng.randf_range(-25.0, 25.0), rng.randf_range(0.0, 90.0), rng.randf_range(-25.0, 25.0))
				"stub":
					if deep:
						var h := rng.randf_range(0.5, 1.5)
						var col := _cylinder(Vector3(x, y + h * 0.5, rng.randf_range(-2.0, -1.4)), 0.32, 0.36, h, ledge)
						col.rotation_degrees.z = rng.randf_range(-6.0, 6.0)
				"grave":
					if deep:
						var z := rng.randf_range(-3.0, -1.8)
						var g := _box(Vector3(x, y + 0.4, z), Vector3(0.55, 0.8, 0.16), stone)
						g.rotation_degrees = Vector3(rng.randf_range(-6.0, 6.0), rng.randf_range(-15.0, 15.0), rng.randf_range(-9.0, 9.0))
						var cap := _cylinder(Vector3(x, y + 0.8, z), 0.275, 0.275, 0.16, stone)
						cap.rotation_degrees = Vector3(90.0, g.rotation_degrees.y, g.rotation_degrees.z)
			x += rng.randf_range(float(every[0]), float(every[1]))


## Every batch as one mesh per material.
func _commit_stones() -> void:
	for name: String in _batches.keys():
		var b: Batch = _batches[name]
		if b.v.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = b.v
		arrays[Mesh.ARRAY_NORMAL] = b.n
		arrays[Mesh.ARRAY_COLOR] = b.c
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mi := MeshInstance3D.new()
		mi.name = "Stones_%s" % name
		mi.mesh = mesh
		mi.material_override = ArenaMaterials.tinted(name)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.set_meta("dynamic", true)
		root.add_child(mi)


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
	var dist := _dist
	var z := FRONT_Z + float(cfg.get("shade_z", 0.34))
	# Darkness at every grid corner, read once.
	var cw := _w + 1
	var corner := PackedFloat32Array()
	corner.resize(cw * (_h + 1))
	for cy in range(_h + 1):
		for cx in range(cw):
			corner[cx + cy * cw] = shade_alpha(_corner(dist, cx, cy), table)
	var verts := _mv
	var cols := _mc
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


func _cylinder(pos: Vector3, top_r: float, bottom_r: float, height: float, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bottom_r
	cyl.height = height
	cyl.radial_segments = 8
	cyl.rings = 1
	mesh.mesh = cyl
	mesh.position = pos
	mesh.material_override = ArenaMaterials.get_material(material)
	mesh.set_meta("cast_shadow", false)
	root.add_child(mesh)
	return mesh


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
