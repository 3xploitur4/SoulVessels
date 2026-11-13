class_name MapView
extends Control
## The zone map (story 016): every visited room of the zone as a block placed by its `map` rect,
## the current room highlighted, lit altars marked, the Soul Echo marked. Unvisited rooms are not
## drawn. Display only.
##
##     var m := MapView.new()
##     m.zone = "zone1"; m.visited = state.visited_rooms; m.current = state.current_room
##     m.lit_altars = state.lit_altars; m.echo_room = str(state.echo.get("room", ""))

var zone: String = "zone1"
var visited: Array[String] = []
var current: String = ""
var lit_altars: Array[String] = []
var echo_room: String = ""

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var ids := WorldData.room_ids(zone)
	if ids.is_empty():
		return
	var bounds := Rect2i()
	var first := true
	for id in ids:
		var mr := WorldData.room(id).map_rect
		bounds = mr if first else bounds.merge(mr)
		first = false
	var pad := 24.0
	var area := Rect2(Vector2(pad, pad), size - Vector2(pad, pad) * 2.0)
	var cell := minf(area.size.x / float(bounds.size.x), area.size.y / float(bounds.size.y))
	cell = minf(cell, 90.0)
	var used := Vector2(bounds.size) * cell
	var origin := area.position + (area.size - used) * 0.5
	var font := ThemeDB.fallback_font
	for id in ids:
		if not visited.has(id):
			continue
		var r := WorldData.room(id)
		var mr := r.map_rect
		# Map y grows up; screen y grows down.
		var top_left := Vector2(float(mr.position.x - bounds.position.x),
			float(bounds.end.y - mr.end.y)) * cell
		var rect := Rect2(origin + top_left + Vector2(3, 3), Vector2(mr.size) * cell - Vector2(6, 6))
		var is_here := id == current
		var fill := Color(0.18, 0.24, 0.32, 0.95) if not is_here else Color(0.25, 0.42, 0.5, 0.95)
		draw_rect(rect, fill)
		draw_rect(rect, Color(0.7, 0.75, 0.8, 0.9) if not is_here else UiKit.COL_ACCENT, false, 2.0 if not is_here else 3.0)
		var altar: Dictionary = r.raw.get("altar", {})
		if not altar.is_empty():
			var lit := lit_altars.has(str(altar.get("id", "")))
			var c := rect.get_center()
			var flame := PackedVector2Array([c + Vector2(0, -12), c + Vector2(9, 6), c + Vector2(-9, 6)])
			draw_colored_polygon(flame, UiKit.COL_GOLD if lit else Color(0.45, 0.45, 0.5))
		if id == echo_room:
			draw_circle(rect.get_center() + Vector2(rect.size.x * 0.3, 0), 7.0, Color(0.55, 0.9, 1.0, 0.6 + 0.4 * sin(_time * 4.0)))
		if is_here:
			var pulse := 6.0 + 2.0 * sin(_time * 5.0)
			draw_circle(rect.get_center() + Vector2(-rect.size.x * 0.3, 0), pulse, Color(1, 1, 1, 0.95))
	var title := tr(str(WorldData.zone(zone).get("title", "")))
	draw_string(font, Vector2(pad, size.y - 8.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UiKit.COL_DIM)
