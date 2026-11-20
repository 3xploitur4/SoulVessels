extends SceneTree
## Cut a sheet of animation poses into frames (story 058, decision D-069).
##
##   godot --headless --path . -s tools/art/slice_frames.gd
##
## Reads `tools/art/frames.json`. For each sheet (one character, poses on a plain flat background):
## the background colour is the median of the border; background is flood-filled in from the
## border (and enclosed pockets of background are cleared: between the legs, between blade and
## body); the figure's edge gets a soft alpha with the background colour unmixed from it, so a JPG
## leaves no grey fringe. What is left is labelled into connected pieces; big pieces are poses,
## small ones (a sword tip, a scrap of cape) join the nearest pose. Poses are numbered in reading
## order (rows by their vertical centre, then left to right) and each is written trimmed as
## f01.png, f02.png... with frames.json: size, and the anchor (the middle of the feet on the feet
## line), so frames of different widths stand on the same spot. Also builds/art/frames_<id>.png,
## every frame numbered on a bright background, to check the cut by eye.

var _w: int
var _h: int
var _img: Image
var _bg := Color()
var _mask := PackedByteArray()   # 1 = figure
var _alpha := PackedFloat32Array()


func _init() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/art/frames.json"))
	for sheet: Dictionary in cfg.get("sheets", []):
		_slice(sheet)
	quit()


func _slice(sheet: Dictionary) -> void:
	_img = Image.load_from_file(ProjectSettings.globalize_path("res://" + str(sheet["file"])))
	_img.convert(Image.FORMAT_RGBA8)
	_w = _img.get_width()
	_h = _img.get_height()
	_bg = _border_median()
	var rng := float(sheet.get("range", 0.1))
	var pocket := float(sheet.get("pocket", 0.05))
	var soft := float(sheet.get("soft", 0.1))
	_matte(rng, pocket, soft)
	var pieces := _label()
	var poses := _group(pieces, int(sheet.get("min_area", 2500)), int(sheet.get("attach_px", 26)))
	poses.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra := int((a["rect"] as Rect2i).get_center().y / (_h / 4))
		var rb := int((b["rect"] as Rect2i).get_center().y / (_h / 4))
		if ra != rb:
			return ra < rb
		return (a["rect"] as Rect2i).position.x < (b["rect"] as Rect2i).position.x)
	var out := str(sheet["out"])
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://" + out))
	var meta := {"height_m": float(sheet.get("height_m", 2.0)), "ref": str(sheet.get("ref", "f01")), "frames": {}}
	var i := 0
	for p: Dictionary in poses:
		i += 1
		var name := "f%02d" % i
		var r: Rect2i = p["rect"]
		var frame := Image.create(r.size.x, r.size.y, false, Image.FORMAT_RGBA8)
		var ids: Dictionary = p["ids"]
		var labels: PackedInt32Array = p["labels"]
		for y in range(r.size.y):
			for x in range(r.size.x):
				var gx := r.position.x + x
				var gy := r.position.y + y
				var k := gx + gy * _w
				if not ids.has(labels[k]):
					continue
				var a := _alpha[k]
				if a <= 0.0:
					continue
				var c := _img.get_pixel(gx, gy)
				# Unmix the background from edge pixels.
				if a < 1.0:
					c = Color((c.r - _bg.r * (1.0 - a)) / a, (c.g - _bg.g * (1.0 - a)) / a, (c.b - _bg.b * (1.0 - a)) / a)
					c = c.clamp()
				frame.set_pixel(x, y, Color(c.r, c.g, c.b, a))
		frame.save_png(ProjectSettings.globalize_path("res://%s/%s.png" % [out, name]))
		meta["frames"][name] = {"w": r.size.x, "h": r.size.y, "anchor": _anchor(frame)}
	var f := FileAccess.open("res://%s/frames.json" % out, FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "  ") + "\n")
	f.close()
	print("slice_frames: %s -> %d frames" % [sheet["id"], poses.size()])
	_contact(str(sheet["id"]), out, meta)


func _border_median() -> Color:
	var rs: Array[float] = []
	var gs: Array[float] = []
	var bs: Array[float] = []
	for x in range(0, _w, 4):
		for y in [0, _h - 1]:
			var c := _img.get_pixel(x, y)
			rs.append(c.r)
			gs.append(c.g)
			bs.append(c.b)
	for y in range(0, _h, 4):
		for x in [0, _w - 1]:
			var c := _img.get_pixel(x, y)
			rs.append(c.r)
			gs.append(c.g)
			bs.append(c.b)
	rs.sort()
	gs.sort()
	bs.sort()
	return Color(rs[rs.size() / 2], gs[gs.size() / 2], bs[bs.size() / 2])


func _dist(c: Color) -> float:
	return maxf(absf(c.r - _bg.r), maxf(absf(c.g - _bg.g), absf(c.b - _bg.b)))


## Background by flood from the border, enclosed pockets cleared, then a soft edge.
func _matte(rng: float, pocket: float, soft: float) -> void:
	var n := _w * _h
	var d := PackedFloat32Array()
	d.resize(n)
	for y in range(_h):
		for x in range(_w):
			d[x + y * _w] = _dist(_img.get_pixel(x, y))
	var bg := PackedByteArray()
	bg.resize(n)
	var queue := PackedInt32Array()
	for x in range(_w):
		for y in [0, _h - 1]:
			queue.append(x + y * _w)
	for y in range(_h):
		for x in [0, _w - 1]:
			queue.append(x + y * _w)
	var head := 0
	while head < queue.size():
		var k := queue[head]
		head += 1
		if bg[k] == 1 or d[k] > rng:
			continue
		bg[k] = 1
		var x := k % _w
		var y := k / _w
		if x > 0: queue.append(k - 1)
		if x < _w - 1: queue.append(k + 1)
		if y > 0: queue.append(k - _w)
		if y < _h - 1: queue.append(k + _w)
	# Enclosed pockets: background-coloured patches the flood could not reach.
	var seen := PackedByteArray()
	seen.resize(n)
	for s in range(n):
		if bg[s] == 1 or seen[s] == 1 or d[s] > pocket:
			continue
		var patch := PackedInt32Array([s])
		seen[s] = 1
		var h2 := 0
		while h2 < patch.size():
			var k := patch[h2]
			h2 += 1
			var x := k % _w
			var y := k / _w
			for nk in [k - 1 if x > 0 else -1, k + 1 if x < _w - 1 else -1, k - _w if y > 0 else -1, k + _w if y < _h - 1 else -1]:
				if nk >= 0 and seen[nk] == 0 and bg[nk] == 0 and d[nk] <= pocket:
					seen[nk] = 1
					patch.append(nk)
		if patch.size() >= 40:
			for k in patch:
				bg[k] = 1
	_mask.resize(n)
	_alpha.resize(n)
	for k in range(n):
		if bg[k] == 1:
			_mask[k] = 0
			_alpha[k] = 0.0
		else:
			_mask[k] = 1
			_alpha[k] = 1.0
	# A soft edge on figure pixels that touch the background.
	for k in range(n):
		if _mask[k] == 0:
			continue
		var x := k % _w
		var y := k / _w
		var edge := (x > 0 and bg[k - 1] == 1) or (x < _w - 1 and bg[k + 1] == 1) or (y > 0 and bg[k - _w] == 1) or (y < _h - 1 and bg[k + _w] == 1)
		if edge:
			_alpha[k] = clampf((d[k] - rng * 0.5) / maxf(soft, 0.01), 0.15, 1.0)


## Connected figure pieces (8 neighbours): label per pixel, and per label its area and rect.
func _label() -> Dictionary:
	var n := _w * _h
	var labels := PackedInt32Array()
	labels.resize(n)
	labels.fill(0)
	var areas: Dictionary = {}
	var rects: Dictionary = {}
	var next := 0
	for s in range(n):
		if _mask[s] == 0 or labels[s] != 0:
			continue
		next += 1
		labels[s] = next
		var stack := PackedInt32Array([s])
		var area := 0
		var x0 := _w
		var y0 := _h
		var x1 := 0
		var y1 := 0
		while not stack.is_empty():
			var k := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			area += 1
			var x := k % _w
			var y := k / _w
			x0 = mini(x0, x)
			y0 = mini(y0, y)
			x1 = maxi(x1, x)
			y1 = maxi(y1, y)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or ny < 0 or nx >= _w or ny >= _h:
						continue
					var nk := nx + ny * _w
					if _mask[nk] == 1 and labels[nk] == 0:
						labels[nk] = next
						stack.append(nk)
		areas[next] = area
		rects[next] = Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)
	return {"labels": labels, "areas": areas, "rects": rects}


## Big pieces are poses; small ones join the nearest pose within `attach` pixels, or are dropped.
func _group(pieces: Dictionary, min_area: int, attach: int) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	var areas: Dictionary = pieces["areas"]
	var rects: Dictionary = pieces["rects"]
	for id: int in areas.keys():
		if int(areas[id]) >= min_area:
			poses.append({"rect": rects[id], "ids": {id: true}, "labels": pieces["labels"]})
	for id: int in areas.keys():
		if int(areas[id]) >= min_area or int(areas[id]) < 6:
			continue
		var r: Rect2i = rects[id]
		var best := -1
		var best_d := float(attach)
		for i in range(poses.size()):
			var pr: Rect2i = poses[i]["rect"]
			var dx := maxf(0.0, maxf(float(pr.position.x - r.end.x), float(r.position.x - pr.end.x)))
			var dy := maxf(0.0, maxf(float(pr.position.y - r.end.y), float(r.position.y - pr.end.y)))
			var dd := sqrt(dx * dx + dy * dy)
			if dd <= best_d:
				best_d = dd
				best = i
		if best >= 0:
			poses[best]["ids"][id] = true
			poses[best]["rect"] = (poses[best]["rect"] as Rect2i).merge(r)
	return poses


## The middle of the feet on the feet line: the lowest solid row, and the middle of the solid
## pixels in the bottom fifth of the figure (both feet, also in a lunge).
func _anchor(frame: Image) -> Array:
	var w := frame.get_width()
	var h := frame.get_height()
	var bottom := h - 1
	var found := false
	for y in range(h - 1, -1, -1):
		for x in range(w):
			if frame.get_pixel(x, y).a > 0.6:
				bottom = y
				found = true
				break
		if found:
			break
	var band := maxi(4, int(h * 0.2))
	var x0 := w
	var x1 := 0
	for y in range(maxi(0, bottom - band), bottom + 1):
		for x in range(w):
			if frame.get_pixel(x, y).a > 0.6:
				x0 = mini(x0, x)
				x1 = maxi(x1, x)
	if x1 < x0:
		return [w / 2, h]
	return [int((x0 + x1) / 2), bottom + 1]


func _contact(id: String, out: String, meta: Dictionary) -> void:
	var names: Array = (meta["frames"] as Dictionary).keys()
	var cell := 260
	var cols := 8
	var rows := int(ceil(float(names.size()) / cols))
	var sheet := Image.create(cell * cols, cell * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.85, 0.2, 0.75))
	for i in range(names.size()):
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://%s/%s.png" % [out, names[i]]))
		var k := minf(float(cell - 20) / img.get_width(), float(cell - 20) / img.get_height())
		img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_BILINEAR)
		var at := Vector2i((i % cols) * cell + (cell - img.get_width()) / 2, (i / cols) * cell + cell - 10 - img.get_height())
		sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), at)
		# The anchor: a white tick under the feet.
		var a: Array = meta["frames"][names[i]]["anchor"]
		var ax := at.x + int(float(a[0]) * k)
		for t in range(-6, 7):
			sheet.set_pixel(clampi(ax + t, 0, sheet.get_width() - 1), mini((i / cols) * cell + cell - 6, sheet.get_height() - 1), Color.WHITE)
	sheet.save_png(ProjectSettings.globalize_path("res://builds/art/frames_%s.png" % id))
