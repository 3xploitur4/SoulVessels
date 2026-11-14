extends SceneTree
## Cut game sprites out of the concept sheets (story 027, decision D-032).
##
##   godot --headless --path . -s tools/art/slice_concepts.gd
##
## Reads `tools/art/slices.json`. For each sheet: finds the flat background by growing from the
## image border, clears enclosed background pockets (between legs, inside coils), labels what is
## left into connected figures, attaches small loose pieces (floating cloth, glows) to the
## nearest figure, and writes one trimmed RGBA PNG per figure plus `sprites.json` (size and the
## feet line). Zone paintings are cut into panels by rectangle. Rerun whenever better or larger
## art replaces a sheet: file names stay, so nothing in the game changes.

const STEP := 0.034      # max channel jump between neighbouring background pixels
const RANGE := 0.15      # max channel distance from the sheet's border colour
const POCKET := 0.02     # max distance from the local background for an enclosed pocket
const POCKET_MIN := 40   # px: smaller enclosed patches are left alone (eyes, highlights)

var _w: int
var _h: int
var _px: PackedColorArray
var _bg: PackedByteArray
## 1 where pocket clearing is not allowed (figures with no real gaps, from `protect` rects).
var _protect: PackedByteArray


func _init() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/slices.json"))
	var manifest := {}
	for sheet: Dictionary in cfg.get("sheets", []):
		_slice_sheet(sheet, manifest)
	for panel: Dictionary in cfg.get("panels", []):
		_cut_panels(panel)
	var out := FileAccess.open("res://assets/art/sprites/sprites.json", FileAccess.WRITE)
	out.store_string(JSON.stringify(manifest, "  ") + "\n")
	out.close()
	print("slice: wrote %d sprites" % manifest.size())
	_contact_sheet(manifest)
	quit()


## Every sprite on a bright background, to check the cut-outs by eye (builds/art/contact.png).
func _contact_sheet(manifest: Dictionary) -> void:
	var sheet := Image.create(2200, 1500, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.85, 0.2, 0.75))
	var x := 10
	var y := 10
	var row_h := 0
	for name: String in manifest.keys():
		var img := Image.load_from_file(ProjectSettings.globalize_path(str(manifest[name]["file"])))
		var k := 470.0 / float(img.get_height())
		img.resize(int(img.get_width() * k), 470, Image.INTERPOLATE_BILINEAR)
		if x + img.get_width() > sheet.get_width() - 10:
			x = 10
			y += row_h + 20
			row_h = 0
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x, y))
		x += img.get_width() + 20
		row_h = maxi(row_h, img.get_height())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/art"))
	sheet.save_png(ProjectSettings.globalize_path("res://builds/art/contact.png"))


func _slice_sheet(sheet: Dictionary, manifest: Dictionary) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://" + str(sheet["file"])))
	img.convert(Image.FORMAT_RGBA8)
	_w = img.get_width()
	_h = img.get_height()
	_px = PackedColorArray()
	_px.resize(_w * _h)
	for y in range(_h):
		for x in range(_w):
			_px[y * _w + x] = img.get_pixel(x, y)
	_bg = PackedByteArray()
	_bg.resize(_w * _h)
	for r: Array in sheet.get("erase", []):
		for y in range(int(r[1]), mini(int(r[1]) + int(r[3]), _h)):
			for x in range(int(r[0]), mini(int(r[0]) + int(r[2]), _w)):
				_bg[y * _w + x] = 1
	_protect = PackedByteArray()
	_protect.resize(_w * _h)
	for r: Array in sheet.get("protect", []):
		for y in range(int(r[1]), mini(int(r[1]) + int(r[3]), _h)):
			for x in range(int(r[0]), mini(int(r[0]) + int(r[2]), _w)):
				_protect[y * _w + x] = 1
	var ref := _border_mean()
	_grow_background(ref)
	_clear_pockets()
	var labels := PackedInt32Array()
	labels.resize(_w * _h)
	var comps := _label(labels)
	var min_area := int(sheet.get("min_area", 4000))
	var attach := float(sheet.get("attach_px", 30))
	var rows: Array = sheet.get("rows", [[0, _h]])
	var names: Array = sheet.get("names", [])
	# Main figures per row band, left to right.
	var mains: Array[Dictionary] = []
	for ri in range(rows.size()):
		var band: Array = rows[ri]
		var in_row: Array[Dictionary] = []
		for c in comps:
			var cy := float(c["sum_y"]) / float(c["area"])
			if int(c["area"]) >= min_area and cy >= float(band[0]) and cy < float(band[1]):
				in_row.append(c)
		in_row.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["x0"]) < int(b["x0"]))
		var row_names: Array = names[ri] if ri < names.size() else []
		for i in range(in_row.size()):
			if i < row_names.size():
				in_row[i]["name"] = str(row_names[i])
				in_row[i]["members"] = [int(in_row[i]["id"])]
				mains.append(in_row[i])
		if in_row.size() != row_names.size():
			push_warning("slice: %s row %d has %d figures, %d names" % [sheet["file"], ri, in_row.size(), row_names.size()])
	# Loose pieces join the nearest figure.
	for c in comps:
		if int(c["area"]) >= min_area or int(c["area"]) < 6:
			continue
		var best: Dictionary = {}
		var best_d := attach
		for m in mains:
			var d := _box_gap(c, m)
			if d < best_d:
				best_d = d
				best = m
		if not best.is_empty():
			(best["members"] as Array).append(int(c["id"]))
			best["x0"] = mini(int(best["x0"]), int(c["x0"]))
			best["y0"] = mini(int(best["y0"]), int(c["y0"]))
			best["x1"] = maxi(int(best["x1"]), int(c["x1"]))
			best["y1"] = maxi(int(best["y1"]), int(c["y1"]))
	var out_dir := "res://" + str(sheet.get("out", "assets/art/sprites"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var scale := int(sheet.get("upscale", 2))
	for m in mains:
		var member := {}
		for id: int in m["members"]:
			member[id] = true
		var x0 := int(m["x0"])
		var y0 := int(m["y0"])
		var cw := int(m["x1"]) - x0 + 1
		var ch := int(m["y1"]) - y0 + 1
		var pad := 2
		var sprite := Image.create(cw + pad * 2, ch + pad * 2, false, Image.FORMAT_RGBA8)
		sprite.fill(Color(0, 0, 0, 0))
		for y in range(ch):
			for x in range(cw):
				var i := (y0 + y) * _w + x0 + x
				if member.has(labels[i]):
					var c := _px[i]
					c.a = 1.0
					sprite.set_pixel(x + pad, y + pad, c)
		_soften_edge(sprite, ref)
		if scale > 1:
			sprite.resize(sprite.get_width() * scale, sprite.get_height() * scale, Image.INTERPOLATE_CUBIC)
		sprite.fix_alpha_edges()
		var path := "%s/%s.png" % [out_dir, m["name"]]
		sprite.save_png(ProjectSettings.globalize_path(path))
		manifest[str(m["name"])] = {"file": path, "width": sprite.get_width(), "height": sprite.get_height(),
			"source": str(sheet["file"]), "source_rect": [x0, y0, cw, ch]}
		print("slice: %-22s %4dx%-4d from (%d,%d)" % [m["name"], sprite.get_width(), sprite.get_height(), x0, y0])


func _border_mean() -> Color:
	var sum := Vector3.ZERO
	var n := 0
	for x in range(0, _w, 4):
		for y: int in [0, 1, _h - 2, _h - 1]:
			if _bg[y * _w + x] == 0:
				var c := _px[y * _w + x]
				sum += Vector3(c.r, c.g, c.b)
				n += 1
	for y in range(0, _h, 4):
		for x: int in [0, 1, _w - 2, _w - 1]:
			if _bg[y * _w + x] == 0:
				var c := _px[y * _w + x]
				sum += Vector3(c.r, c.g, c.b)
				n += 1
	sum /= float(maxi(n, 1))
	return Color(sum.x, sum.y, sum.z)


static func _dist(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))


## Region-grow the background from every border pixel and every erased pixel.
func _grow_background(ref: Color) -> void:
	var queue := PackedInt32Array()
	for x in range(_w):
		queue.append(x)
		queue.append((_h - 1) * _w + x)
	for y in range(_h):
		queue.append(y * _w)
		queue.append(y * _w + _w - 1)
	for i in range(_w * _h):
		if _bg[i] == 1:
			queue.append(i)
	for i in queue:
		if _dist(_px[i], ref) <= RANGE:
			_bg[i] = 1
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		if _bg[i] == 0:
			continue
		var x := i % _w
		var y := i / _w
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx := x + d.x
			var ny := y + d.y
			if nx < 0 or ny < 0 or nx >= _w or ny >= _h:
				continue
			var j := ny * _w + nx
			if _bg[j] == 1:
				continue
			if _dist(_px[j], _px[i]) <= STEP and _dist(_px[j], ref) <= RANGE:
				_bg[j] = 1
				queue.append(j)


## Background trapped inside a figure (between legs, inside a coil): flat patches whose colour
## matches the background nearby.
func _clear_pockets() -> void:
	var cell := 32
	var gw := _w / cell + 1
	var gh := _h / cell + 1
	var sums: Array[Vector3] = []
	var counts := PackedInt32Array()
	sums.resize(gw * gh)
	counts.resize(gw * gh)
	for i in range(gw * gh):
		sums[i] = Vector3.ZERO
	for y in range(_h):
		for x in range(_w):
			var i := y * _w + x
			if _bg[i] == 1:
				var g := (y / cell) * gw + x / cell
				var c := _px[i]
				sums[g] += Vector3(c.r, c.g, c.b)
				counts[g] += 1
	var seen := PackedByteArray()
	seen.resize(_w * _h)
	for start in range(_w * _h):
		if _bg[start] == 1 or seen[start] == 1 or _protect[start] == 1 or not _pocket_like(start, sums, counts, gw, gh, cell):
			continue
		var group := PackedInt32Array([start])
		seen[start] = 1
		var head := 0
		while head < group.size():
			var i := group[head]
			head += 1
			var x := i % _w
			var y := i / _w
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or ny < 0 or nx >= _w or ny >= _h:
					continue
				var j := ny * _w + nx
				if _bg[j] == 0 and seen[j] == 0 and _protect[j] == 0 and _pocket_like(j, sums, counts, gw, gh, cell):
					seen[j] = 1
					group.append(j)
		if group.size() >= POCKET_MIN:
			for i in group:
				_bg[i] = 1


func _pocket_like(i: int, sums: Array[Vector3], counts: PackedInt32Array, gw: int, gh: int, cell: int) -> bool:
	var gx := (i % _w) / cell
	var gy := (i / _w) / cell
	var sum := Vector3.ZERO
	var n := 0
	for r in range(1, 5):
		for yy in range(maxi(gy - r, 0), mini(gy + r + 1, gh)):
			for xx in range(maxi(gx - r, 0), mini(gx + r + 1, gw)):
				sum += sums[yy * gw + xx]
				n += counts[yy * gw + xx]
		if n > 200:
			break
		sum = Vector3.ZERO
		n = 0
	if n == 0:
		return false
	sum /= float(n)
	return _dist(_px[i], Color(sum.x, sum.y, sum.z)) <= POCKET


## 8-connected labelling of everything that is not background. Returns one record per figure.
func _label(labels: PackedInt32Array) -> Array[Dictionary]:
	var comps: Array[Dictionary] = []
	var next := 1
	for start in range(_w * _h):
		if _bg[start] == 1 or labels[start] != 0:
			continue
		var id := next
		next += 1
		var c := {"id": id, "area": 0, "x0": _w, "y0": _h, "x1": 0, "y1": 0, "sum_y": 0}
		var queue := PackedInt32Array([start])
		labels[start] = id
		var head := 0
		while head < queue.size():
			var i := queue[head]
			head += 1
			var x := i % _w
			var y := i / _w
			c["area"] = int(c["area"]) + 1
			c["sum_y"] = int(c["sum_y"]) + y
			c["x0"] = mini(int(c["x0"]), x)
			c["y0"] = mini(int(c["y0"]), y)
			c["x1"] = maxi(int(c["x1"]), x)
			c["y1"] = maxi(int(c["y1"]), y)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or ny < 0 or nx >= _w or ny >= _h:
						continue
					var j := ny * _w + nx
					if _bg[j] == 0 and labels[j] == 0:
						labels[j] = id
						queue.append(j)
		comps.append(c)
	return comps


static func _box_gap(a: Dictionary, b: Dictionary) -> float:
	var dx := maxf(0.0, maxf(float(int(a["x0"]) - int(b["x1"])), float(int(b["x0"]) - int(a["x1"]))))
	var dy := maxf(0.0, maxf(float(int(a["y0"]) - int(b["y1"])), float(int(b["y0"]) - int(a["y1"]))))
	return sqrt(dx * dx + dy * dy)


## Edge pixels that still carry background colour fade out, so no grey fringe shows in game.
func _soften_edge(sprite: Image, ref: Color) -> void:
	var w := sprite.get_width()
	var h := sprite.get_height()
	var edits: Array[Vector3i] = []
	for y in range(h):
		for x in range(w):
			var c := sprite.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var edge := false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h or sprite.get_pixel(nx, ny).a == 0.0:
					edge = true
					break
			if edge:
				var k := clampf((_dist(c, ref) - 0.05) / 0.2, 0.0, 1.0)
				edits.append(Vector3i(x, y, int(k * 255.0)))
	for e in edits:
		var c := sprite.get_pixel(e.x, e.y)
		c.a = float(e.z) / 255.0
		sprite.set_pixel(e.x, e.y, c)


func _cut_panels(panel: Dictionary) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://" + str(panel["file"])))
	img.convert(Image.FORMAT_RGBA8)
	var out_dir := "res://" + str(panel.get("out", "assets/art/backdrops"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var rects: Dictionary = panel.get("rects", {})
	for name: String in rects.keys():
		var r: Array = rects[name]
		var part := img.get_region(Rect2i(int(r[0]), int(r[1]), int(r[2]), int(r[3])))
		# Mirror-tile: the painting followed by its mirror image repeats without a seam.
		var wide := Image.create(part.get_width() * 2, part.get_height(), false, Image.FORMAT_RGBA8)
		wide.blit_rect(part, Rect2i(Vector2i.ZERO, part.get_size()), Vector2i.ZERO)
		var flipped := part.duplicate() as Image
		flipped.flip_x()
		wide.blit_rect(flipped, Rect2i(Vector2i.ZERO, part.get_size()), Vector2i(part.get_width(), 0))
		wide.resize(wide.get_width() * 2, wide.get_height() * 2, Image.INTERPOLATE_CUBIC)
		wide.save_png(ProjectSettings.globalize_path("%s/%s.png" % [out_dir, name]))
		print("slice: backdrop %-8s %dx%d" % [name, wide.get_width(), wide.get_height()])
