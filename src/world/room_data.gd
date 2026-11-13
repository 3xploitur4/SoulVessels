class_name RoomData
extends RefCounted
## One room parsed from its text grid (story 015, decision D-023). Pure data: no nodes, so tests
## and tools read rooms without a scene tree. `RoomBuilder` turns it into geometry and
## `RoomManager` into a playable room.
##
## The grid is a list of equal-length strings, one character per 1 m cell, top row first. Room
## coordinates: x grows right from the grid's left edge, y grows up from the grid's bottom edge,
## so cell (col, row) spans x in [col, col + 1] and y in [rows - 1 - row, rows - row].
##
## Legend (anything else is empty space):
##   #  solid rock                       =  one-way platform (top of the cell)
##   0-9  exit cells (same digit = one exit)
##   @  new-game start                   A  Soul Altar
##   *  pickup (items listed in `pickups`, reading order)
##   E  event body (Vessel to possess or free, from `events`, reading order)
##   c  Echo Crawler   w  Subterranean Watcher   W  Branded Warden
##   h  Calcified Husk t  Fungal Stalker (hangs under the ceiling)
##   M  bounce mushroom (stands on the cell below)
##   V  shadow veil curtain (solid except to a Shadowstep)
##   G  shield-ward bars   S  ward statue (beam origin)   O  receiver crystal
##   L  arena lock bars (solid only while the room's arena runs)
##   R  light-rune door   K  cracked masonry   F  flooded stair (sealed in M2)
##   X  rift scar (decor, not solid)
##   T  warm light   Y  cool light   (at most 2 per room)

const ENEMY_CODES := {
	"c": "echo_crawler",
	"w": "subterranean_watcher",
	"W": "branded_warden",
	"h": "calcified_husk",
	"t": "fungal_stalker",
}
## Characters that build collision (with the gate kind they belong to; "" = plain rock).
const SOLID_CODES := {"#": "", "G": "ward", "V": "veil", "L": "lock", "R": "rune", "K": "masonry", "F": "flood"}

var id: String = ""
var zone: String = ""
## Translation key of the room name.
var name_key: String = ""
## Rect on the zone map, in map cells: [x, y, w, h].
var map_rect: Rect2i = Rect2i()
var theme: String = "cavern"
var music: String = ""
var cols: int = 0
var rows: int = 0
## Merged solid rock rects in room metres (x, y = bottom-left).
var solids: Array[Rect2] = []
## Gate kind -> merged rects ("ward", "veil", "lock", "rune", "masonry", "flood").
var gate_rects: Dictionary[String, Array] = {}
## Exposed tops of rock (a cell of rock with open space above): Rect2(x, top_y, width, 0).
var trims: Array[Rect2] = []
## One-way platforms: Rect2(x, top_y, width, 0).
var oneway: Array[Rect2] = []
## Exit digit -> {"rect": Rect2, "to": room id, "exit": digit, "arrive": Vector2, "boost": bool}.
var exits: Dictionary[String, Dictionary] = {}
## [{"id": enemy id, "pos": Vector2, "ceiling_y": float, "spawn_id": "room:index", "elite": bool}].
var spawns: Array[Dictionary] = []
## [{"item": id, "pos": Vector2, "pickup_id": "room:index"}].
var pickups: Array[Dictionary] = []
## [{"vessel": id, "kind": "possess" | "roots", "pos": Vector2}].
var events: Array[Dictionary] = []
## Single-cell markers: "start", "altar", "statue", "crystal" -> Vector2 (cell bottom centre).
var markers: Dictionary[String, Vector2] = {}
var mushrooms: Array[Vector2] = []
var rift_scars: Array[Vector2] = []
## [{"pos": Vector3, "warm": bool}].
var lights: Array[Dictionary] = []
## Raw JSON for features that read their own keys (altar, ward, arena, tutorials, lines).
var raw: Dictionary = {}


## Parse room `room_id` of `zone_id` from its JSON entry. Problems are reported in `errors`.
static func parse(room_id: String, zone_id: String, d: Dictionary, errors: Array[String] = []) -> RoomData:
	var r := RoomData.new()
	r.id = room_id
	r.zone = zone_id
	r.raw = d
	r.name_key = str(d.get("name", "ROOM_" + room_id.to_upper()))
	r.theme = str(d.get("theme", "cavern"))
	r.music = str(d.get("music", zone_id))
	var m: Array = d.get("map", [0, 0, 1, 1])
	if m.size() == 4:
		r.map_rect = Rect2i(int(m[0]), int(m[1]), int(m[2]), int(m[3]))
	var grid: Array = d.get("grid", [])
	r.rows = grid.size()
	for line: Variant in grid:
		r.cols = maxi(r.cols, str(line).length())
	if r.rows == 0 or r.cols == 0:
		errors.append("%s: empty grid" % room_id)
		return r
	var cells: Array[PackedStringArray] = []
	for line: Variant in grid:
		var s := str(line)
		if s.length() != r.cols:
			errors.append("%s: row length %d, expected %d" % [room_id, s.length(), r.cols])
			s = s.rpad(r.cols, ".")
		var row := PackedStringArray()
		for i in range(r.cols):
			row.append(s[i])
		cells.append(row)
	r._read_cells(cells, errors)
	return r


func _read_cells(cells: Array[PackedStringArray], errors: Array[String]) -> void:
	solids = merge_rects(cells, "#", rows)
	for code: String in SOLID_CODES.keys():
		var kind: String = SOLID_CODES[code]
		if kind != "":
			var rects := merge_rects(cells, code, rows)
			if not rects.is_empty():
				gate_rects[kind] = rects
	oneway = _oneway_runs(cells)
	trims = _trim_runs(cells)
	var exit_cells: Dictionary[String, Rect2] = {}
	var item_list: Array = raw.get("pickups", [])
	var event_list: Array = raw.get("events", [])
	var enemy_index := 0
	var pickup_index := 0
	var event_index := 0
	var light_count := 0
	for row in range(rows):
		for col in range(cols):
			var c := cells[row][col]
			var pos := Vector2(float(col) + 0.5, float(rows - 1 - row))
			if c.is_valid_int():
				var cell_rect := Rect2(float(col), float(rows - 1 - row), 1.0, 1.0)
				exit_cells[c] = exit_cells[c].merge(cell_rect) if exit_cells.has(c) else cell_rect
			elif ENEMY_CODES.has(c):
				var eid: String = ENEMY_CODES[c]
				spawns.append({
					"id": eid,
					"pos": pos,
					"ceiling_y": float(rows - row),
					"spawn_id": "%s:%d" % [id, enemy_index],
					"elite": c == "W",
				})
				enemy_index += 1
			elif c == "*":
				var item := str(item_list[pickup_index]) if pickup_index < item_list.size() else ""
				if item == "":
					errors.append("%s: pickup %d has no item" % [id, pickup_index])
				pickups.append({"item": item, "pos": pos, "pickup_id": "%s:%d" % [id, pickup_index]})
				pickup_index += 1
			elif c == "E":
				var ev: Dictionary = event_list[event_index] if event_index < event_list.size() else {}
				if ev.is_empty():
					errors.append("%s: event %d undefined" % [id, event_index])
				events.append({"vessel": str(ev.get("vessel", "")), "kind": str(ev.get("kind", "possess")), "pos": pos})
				event_index += 1
			else:
				match c:
					"@":
						markers["start"] = pos
					"A":
						markers["altar"] = pos
					"S":
						markers["statue"] = pos
					"O":
						markers["crystal"] = pos
					"M":
						mushrooms.append(pos)
					"X":
						rift_scars.append(pos)
					"T", "Y":
						light_count += 1
						if light_count <= 2:
							lights.append({"pos": Vector3(pos.x, pos.y + 0.5, -1.5), "warm": c == "T"})
						else:
							errors.append("%s: more than 2 lights" % id)
	if pickup_index < item_list.size():
		errors.append("%s: %d pickups listed, %d placed" % [id, item_list.size(), pickup_index])
	var exit_defs: Dictionary = raw.get("exits", {})
	for digit: String in exit_cells.keys():
		var def: Dictionary = exit_defs.get(digit, {})
		if def.is_empty():
			errors.append("%s: exit %s has no target" % [id, digit])
		var rect := exit_cells[digit]
		var arrive := arrival_point(rect)
		var over: Variant = def.get("arrive")
		if over is Array and (over as Array).size() == 2:
			arrive = Vector2(float(over[0]), float(over[1]))
		exits[digit] = {
			"rect": rect,
			"to": str(def.get("to", "")),
			"exit": str(def.get("exit", "")),
			"arrive": arrive,
			"boost": rect.position.y <= 0.0,
		}
	for digit: Variant in exit_defs.keys():
		if not exit_cells.has(str(digit)):
			errors.append("%s: exit %s defined but not drawn" % [id, digit])


## Where the player stands when entering through an exit occupying `rect`: one metre inside a
## side exit at its floor, under a top exit, or just above a bottom exit (with a jump boost).
func arrival_point(rect: Rect2) -> Vector2:
	var centre_x := rect.position.x + rect.size.x * 0.5
	if rect.position.x <= 0.0:
		return Vector2(rect.end.x + 1.0, rect.position.y)
	if rect.end.x >= float(cols):
		return Vector2(rect.position.x - 1.0, rect.position.y)
	if rect.end.y >= float(rows):
		return Vector2(centre_x, rect.position.y - 2.5)
	return Vector2(centre_x, rect.end.y + 0.2)


## The exit whose cells contain room point `p`, or "".
func exit_at(p: Vector2) -> String:
	for digit: String in exits.keys():
		if (exits[digit]["rect"] as Rect2).has_point(p):
			return digit
	return ""


## Size of the room in metres.
func size() -> Vector2:
	return Vector2(float(cols), float(rows))


## Greedy merge of every `code` cell into rectangles (room metres, bottom-left origin): grow
## right along the row, then down while the whole span matches. Few, large boxes keep collision
## and draw calls low.
static func merge_rects(cells: Array[PackedStringArray], code: String, row_count: int) -> Array[Rect2]:
	var out: Array[Rect2] = []
	if cells.is_empty():
		return out
	var width := cells[0].size()
	var used: Array[PackedByteArray] = []
	for r in range(cells.size()):
		var b := PackedByteArray()
		b.resize(width)
		used.append(b)
	for row in range(cells.size()):
		for col in range(width):
			if cells[row][col] != code or used[row][col] == 1:
				continue
			var w := 1
			while col + w < width and cells[row][col + w] == code and used[row][col + w] == 0:
				w += 1
			var h := 1
			var grow := true
			while grow and row + h < cells.size():
				for k in range(w):
					if cells[row + h][col + k] != code or used[row + h][col + k] == 1:
						grow = false
						break
				if grow:
					h += 1
			for rr in range(row, row + h):
				for k in range(w):
					used[rr][col + k] = 1
			out.append(Rect2(float(col), float(row_count - row - h), float(w), float(h)))
	return out


func _trim_runs(cells: Array[PackedStringArray]) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for row in range(cells.size()):
		var col := 0
		while col < cols:
			if _exposed_rock(cells, row, col):
				var start := col
				while col < cols and _exposed_rock(cells, row, col):
					col += 1
				out.append(Rect2(float(start), float(rows - row), float(col - start), 0.0))
			else:
				col += 1
	return out


func _exposed_rock(cells: Array[PackedStringArray], row: int, col: int) -> bool:
	if cells[row][col] != "#":
		return false
	return row > 0 and not SOLID_CODES.has(cells[row - 1][col])


func _oneway_runs(cells: Array[PackedStringArray]) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for row in range(cells.size()):
		var col := 0
		while col < cols:
			if cells[row][col] == "=":
				var start := col
				while col < cols and cells[row][col] == "=":
					col += 1
				out.append(Rect2(float(start), float(rows - row), float(col - start), 0.0))
			else:
				col += 1
	return out
