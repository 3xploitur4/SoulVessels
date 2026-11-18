class_name WorldMap
extends RefCounted
## Where every room sits on the world map (story 054, decision D-061). Laid out from the rooms'
## real doorways, starting at the first room: a room joined through a side doorway sits beside
## its neighbour with the two doorways level; one joined through the floor or ceiling sits
## below or above it. Positions are in metres (x right, y up), then snapped to map cells, so the
## map draws as a grid of blocks the size of a screen or two. Static and cached: pure data.
##
##     var cell := WorldMap.cell_rect("z1_05")   # Rect2i in map cells

## Metres per map cell (about one screen width at the play camera).
const CELL := Vector2(12.0, 12.0)
const START := "z1_01"

static var _origin: Dictionary[String, Vector2] = {}
static var _cells: Dictionary[String, Rect2i] = {}


## The room's rectangle in map cells (x right, y up). Zero-size when the room is unknown.
static func cell_rect(room_id: String) -> Rect2i:
	_ensure()
	return _cells.get(room_id, Rect2i())


## The room's bottom-left corner in world metres.
static func origin(room_id: String) -> Vector2:
	_ensure()
	return _origin.get(room_id, Vector2.ZERO)


## Every placed room id.
static func rooms() -> Array[String]:
	_ensure()
	var out: Array[String] = []
	out.assign(_cells.keys())
	return out


## Drop the cache (tests, or after editing rooms).
static func reset() -> void:
	_origin.clear()
	_cells.clear()


## Where the neighbour's corner goes so that its doorway meets `rect` (a doorway of `room` whose
## corner is at `at`) across the shared wall.
static func neighbour_origin(room: RoomData, at: Vector2, rect: Rect2, other: RoomData, other_rect: Rect2) -> Vector2:
	var a := at + rect.position
	if rect.position.x <= 0.0:
		# Our left wall: the neighbour's right-wall doorway is just to the left.
		return Vector2(a.x - other.size().x, a.y - other_rect.position.y)
	if rect.end.x >= room.size().x:
		return Vector2(at.x + room.size().x, a.y - other_rect.position.y)
	if rect.position.y <= 0.0:
		# Our floor: the neighbour is below, its ceiling doorway over ours.
		return Vector2(a.x - other_rect.position.x, at.y - other.size().y)
	return Vector2(a.x - other_rect.position.x, at.y + room.size().y)


static func _ensure() -> void:
	if not _cells.is_empty():
		return
	var all := WorldData.room_ids()
	if all.is_empty():
		return
	var start := START if all.has(START) else all[0]
	_origin[start] = Vector2.ZERO
	var queue: Array[String] = [start]
	while not queue.is_empty():
		var id: String = queue.pop_front()
		var room := WorldData.room(id)
		if room == null:
			continue
		for digit: String in room.exits.keys():
			var ex: Dictionary = room.exits[digit]
			var to := str(ex.get("to", ""))
			if to == "" or _origin.has(to):
				continue
			var other := WorldData.room(to)
			if other == null or not other.exits.has(str(ex.get("exit", ""))):
				continue
			var other_rect: Rect2 = other.exits[str(ex.get("exit", ""))]["rect"]
			_origin[to] = neighbour_origin(room, _origin[id], ex["rect"], other, other_rect)
			queue.append(to)
	# Rooms no doorway reaches (none in Chapter I) go in a row below the rest.
	var stray_x := 0.0
	for id in all:
		if not _origin.has(id):
			_origin[id] = Vector2(stray_x, -60.0)
			stray_x += WorldData.room(id).size().x + 12.0
	for id: String in _origin.keys():
		var r := WorldData.room(id)
		var o := _origin[id]
		var cx := int(roundf(o.x / CELL.x))
		var cy := int(roundf(o.y / CELL.y))
		var w := maxi(1, int(roundf(r.size().x / CELL.x)))
		var h := maxi(1, int(roundf(r.size().y / CELL.y)))
		_cells[id] = Rect2i(cx, cy, w, h)
