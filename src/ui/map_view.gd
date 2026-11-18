class_name MapView
extends Control
## The world map (story 016; redrawn in story 054, decision D-061). Every visited room as a dark
## blood-red block of map cells placed by `WorldMap` from the real doorways, with its cell grid,
## a worn-gold outline and gaps where its doorways are; rooms next to a visited one show as faint
## outlines (seen, not entered). Icons: kindled and cold altars, bosses (fallen ones crossed out),
## the Soul Echo, and the player. A gothic double frame with corner studs; a legend underneath.
## Drag (mouse or touch) pans, the wheel zooms. Display only.
##
##     var m := MapView.new()
##     m.visited = state.visited_rooms; m.current = state.current_room
##     m.lit_altars = state.lit_altars; m.echo_room = str(state.echo.get("room", ""))

const COL_BG := Color(0.045, 0.035, 0.04)
const COL_ROOM := Color(0.2, 0.08, 0.07)
const COL_ROOM_HERE := Color(0.36, 0.13, 0.09)
const COL_GRID := Color(0.3, 0.13, 0.1)
const COL_EDGE := Color(0.79, 0.64, 0.36)
const COL_SEEN := Color(0.45, 0.38, 0.28, 0.55)
const COL_DOOR := Color(0.95, 0.88, 0.62)
const COL_BOSS := Color(0.86, 0.18, 0.14)
const COL_ECHO := Color(0.55, 0.9, 1.0)

## Kept for callers of the first map; the map now shows the whole world.
var zone: String = "zone1"
var visited: Array[String] = []
var current: String = ""
var lit_altars: Array[String] = []
var echo_room: String = ""
## Save flags, to cross out fallen bosses.
var flags: Dictionary = {}
## Where the player stands in the current room (metres); negative x = the room's centre.
var player_pos: Vector2 = Vector2(-1.0, -1.0)
## Pixels per map cell.
var cell_px: float = 42.0

var _time: float = 0.0
var _pan: Vector2 = Vector2.ZERO
var _dragging: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			cell_px = minf(cell_px * 1.15, 110.0)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cell_px = maxf(cell_px / 1.15, 16.0)
	elif event is InputEventMouseMotion and _dragging:
		_pan += (event as InputEventMouseMotion).relative
	elif event is InputEventScreenDrag:
		_pan += (event as InputEventScreenDrag).relative


## Which rooms show, and how: "visited", "seen" (beside a visited one), or "" (hidden).
func room_state(id: String) -> String:
	if visited.has(id):
		return "visited"
	for v in visited:
		var r := WorldData.room(v)
		if r == null:
			continue
		for d: String in r.exits.keys():
			if str(r.exits[d].get("to", "")) == id:
				return "seen"
	return ""


## The room's rectangle on screen.
func room_px(id: String) -> Rect2:
	var cr := WorldMap.cell_rect(id)
	var focus := WorldMap.cell_rect(current if current != "" else WorldMap.START)
	var fc := Vector2(focus.position) + Vector2(focus.size) * 0.5
	var centre := size * 0.5 + _pan
	var x := centre.x + (float(cr.position.x) - fc.x) * cell_px
	var y := centre.y - (float(cr.position.y + cr.size.y) - fc.y) * cell_px
	return Rect2(x, y, float(cr.size.x) * cell_px, float(cr.size.y) * cell_px)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COL_BG)
	# Faint parchment grain: a sparse grid of dots.
	var step := cell_px
	var off := Vector2(fposmod(_pan.x + size.x * 0.5, step), fposmod(_pan.y + size.y * 0.5, step))
	for gx in range(-1, int(size.x / step) + 2):
		for gy in range(-1, int(size.y / step) + 2):
			draw_rect(Rect2(off + Vector2(gx, gy) * step, Vector2(2, 2)), Color(0.2, 0.15, 0.12, 0.5))
	var ids := WorldMap.rooms()
	for id in ids:
		if room_state(id) == "seen":
			_draw_seen(id)
	for id in ids:
		if room_state(id) == "visited":
			_draw_room(id)
	_draw_frame()
	_draw_legend()


func _draw_seen(id: String) -> void:
	var r := room_px(id).grow(-3.0)
	_dashed_rect(r, COL_SEEN)


func _draw_room(id: String) -> void:
	var room := WorldData.room(id)
	var r := room_px(id).grow(-2.0)
	var here := id == current
	draw_rect(r, COL_ROOM_HERE if here else COL_ROOM)
	# The room's cells.
	var cr := WorldMap.cell_rect(id)
	for i in range(1, cr.size.x):
		var x := r.position.x + float(i) * cell_px
		draw_line(Vector2(x, r.position.y + 2), Vector2(x, r.end.y - 2), COL_GRID, 1.0)
	for j in range(1, cr.size.y):
		var y := r.position.y + float(j) * cell_px
		draw_line(Vector2(r.position.x + 2, y), Vector2(r.end.x - 2, y), COL_GRID, 1.0)
	draw_rect(r, COL_EDGE.lerp(Color.WHITE, 0.25) if here else COL_EDGE, false, 2.0)
	# Doorways: a gap in the outline with a bright sill.
	var k := r.size / room.size()
	for d: String in room.exits.keys():
		var e: Rect2 = room.exits[d]["rect"]
		var a := Vector2(r.position.x + e.position.x * k.x, r.end.y - e.end.y * k.y)
		var b := Vector2(r.position.x + e.end.x * k.x, r.end.y - e.position.y * k.y)
		var gap := Rect2(a, b - a).grow(1.5)
		draw_rect(gap, COL_BG)
		if e.position.x <= 0.0 or e.end.x >= room.size().x:
			draw_line(Vector2(gap.get_center().x, gap.position.y), Vector2(gap.get_center().x, gap.end.y), COL_DOOR, 2.0)
		else:
			draw_line(Vector2(gap.position.x, gap.get_center().y), Vector2(gap.end.x, gap.get_center().y), COL_DOOR, 2.0)
	var c := r.get_center()
	var altar: Dictionary = room.raw.get("altar", {})
	if not altar.is_empty():
		_altar_icon(c, lit_altars.has(str(altar.get("id", ""))))
	var boss := str(room.raw.get("boss", ""))
	if boss != "":
		_boss_icon(c + Vector2(cell_px * 0.3, 0.0), bool(flags.get("boss_" + boss, false)))
	if id == echo_room:
		_diamond(c + Vector2(-cell_px * 0.3, 0.0), 6.0, Color(COL_ECHO.r, COL_ECHO.g, COL_ECHO.b, 0.6 + 0.4 * sin(_time * 4.0)))
	if here:
		var p := c
		if player_pos.x >= 0.0:
			p = Vector2(r.position.x + player_pos.x * k.x, r.end.y - player_pos.y * k.y)
		var pulse := 4.0 + 1.5 * sin(_time * 5.0)
		draw_circle(p, pulse + 3.0, Color(1.0, 0.95, 0.8, 0.25))
		draw_circle(p, pulse, Color(1.0, 0.97, 0.88))


func _altar_icon(c: Vector2, lit: bool) -> void:
	var col := UiKit.COL_GOLD if lit else Color(0.45, 0.42, 0.4)
	# A small kneeler with a flame: a step and a teardrop.
	draw_rect(Rect2(c + Vector2(-7, 4), Vector2(14, 4)), col)
	var flame := PackedVector2Array([c + Vector2(0, -9), c + Vector2(5, 0), c + Vector2(0, 3), c + Vector2(-5, 0)])
	draw_colored_polygon(flame, col)


func _boss_icon(c: Vector2, fallen: bool) -> void:
	draw_circle(c, 7.0, COL_BOSS if not fallen else Color(0.35, 0.12, 0.1))
	draw_circle(c + Vector2(-2.5, -1.0), 1.6, COL_BG)
	draw_circle(c + Vector2(2.5, -1.0), 1.6, COL_BG)
	if fallen:
		draw_line(c + Vector2(-8, -8), c + Vector2(8, 8), COL_EDGE, 2.0)
		draw_line(c + Vector2(8, -8), c + Vector2(-8, 8), COL_EDGE, 2.0)


func _diamond(c: Vector2, s: float, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), col)


func _dashed_rect(r: Rect2, col: Color) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in range(4):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := int(a.distance_to(b) / 8.0)
		for j in range(0, n, 2):
			draw_line(a.lerp(b, float(j) / float(n)), a.lerp(b, float(j + 1) / float(n)), col, 1.0)


## A gothic double frame with studs at the corners and the region's name.
func _draw_frame() -> void:
	var outer := Rect2(Vector2(4, 4), size - Vector2(8, 8))
	draw_rect(outer, COL_EDGE, false, 2.0)
	draw_rect(outer.grow(-6.0), Color(COL_EDGE.r, COL_EDGE.g, COL_EDGE.b, 0.45), false, 1.0)
	for corner: Vector2 in [outer.position, Vector2(outer.end.x, outer.position.y), outer.end, Vector2(outer.position.x, outer.end.y)]:
		_diamond(corner, 7.0, COL_EDGE)
		_diamond(corner, 3.0, COL_BG)
	var zone_id := WorldData.zone_of(current) if current != "" else zone
	var title := tr(str(WorldData.zone(zone_id).get("title", "")))
	var font := UiKit.display_font()
	draw_rect(Rect2(Vector2(18, 14), Vector2(font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x + 24, 40)), Color(COL_BG.r, COL_BG.g, COL_BG.b, 0.9))
	draw_string(font, Vector2(30, 44), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, UiKit.COL_GOLD)
	if current != "":
		var room_name := tr(WorldData.room(current).name_key)
		draw_string(font, Vector2(30, 70), room_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UiKit.COL_DIM)


func _draw_legend() -> void:
	var font := UiKit.display_font()
	var y := size.y - 22.0
	var x := 26.0
	var entries := [["altar", "MAP_ALTAR"], ["boss", "MAP_BOSS"], ["echo", "MAP_ECHO"], ["you", "MAP_YOU"], ["seen", "MAP_SEEN"]]
	draw_rect(Rect2(Vector2(14, y - 18), Vector2(size.x - 28, 30)), Color(COL_BG.r, COL_BG.g, COL_BG.b, 0.85))
	for e: Array in entries:
		var c := Vector2(x, y - 3)
		match str(e[0]):
			"altar":
				_altar_icon(c, true)
			"boss":
				_boss_icon(c, false)
			"echo":
				_diamond(c, 6.0, COL_ECHO)
			"you":
				draw_circle(c, 5.0, Color(1.0, 0.97, 0.88))
			"seen":
				_dashed_rect(Rect2(c - Vector2(9, 7), Vector2(18, 14)), COL_SEEN.lerp(Color.WHITE, 0.2))
		var label := tr(str(e[1]))
		draw_string(font, Vector2(x + 14, y + 4), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UiKit.COL_DIM)
		x += 34.0 + font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
