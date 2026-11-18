class_name WorldData
extends RefCounted
## The zone files in `res://data/world/` (story 015): rooms parsed once and cached, zone titles,
## themes. Static so menus, the map and tools can ask without a world in the tree.
##
##     var room := WorldData.room("z1_03")
##     for id in WorldData.room_ids("zone1"): ...

const ROOT := "res://data/world"
const ZONES: Array[String] = ["zone1", "zone2", "zone3", "zone4"]

static var _zones: Dictionary[String, Dictionary] = {}
static var _rooms: Dictionary[String, RoomData] = {}
static var _room_zone: Dictionary[String, String] = {}
static var _themes: Dictionary = {}


## The zone JSON (title, music, rooms), loading it on first use.
static func zone(zone_id: String) -> Dictionary:
	_ensure()
	return _zones.get(zone_id, {})


## Room ids of a zone in file order (or of every zone when `zone_id` is empty).
static func room_ids(zone_id: String = "") -> Array[String]:
	_ensure()
	var out: Array[String] = []
	for z: String in ZONES:
		if zone_id != "" and z != zone_id:
			continue
		var rooms: Dictionary = _zones.get(z, {}).get("rooms", {})
		for k: Variant in rooms.keys():
			out.append(str(k))
	return out


## The parsed room, or null (with an error) for an unknown id.
static func room(room_id: String) -> RoomData:
	_ensure()
	if _rooms.has(room_id):
		return _rooms[room_id]
	if not _room_zone.has(room_id):
		push_error("WorldData: unknown room %s" % room_id)
		return null
	var z := _room_zone[room_id]
	var errors: Array[String] = []
	var r := RoomData.parse(room_id, z, _zones[z]["rooms"][room_id], errors)
	for e in errors:
		push_error("WorldData: " + e)
	_rooms[room_id] = r
	return r


## Parse problems for `room_id` (used by tests; empty means clean).
static func room_errors(room_id: String) -> Array[String]:
	_ensure()
	var errors: Array[String] = []
	if not _room_zone.has(room_id):
		errors.append("unknown room %s" % room_id)
		return errors
	var z := _room_zone[room_id]
	RoomData.parse(room_id, z, _zones[z]["rooms"][room_id], errors)
	return errors


static func zone_of(room_id: String) -> String:
	_ensure()
	return _room_zone.get(room_id, "")


## A theme block from themes.json ("cavern", "mycelium").
static func theme(theme_id: String) -> Dictionary:
	_ensure()
	return _themes.get(theme_id, _themes.get("cavern", {}))


## Drop the cache (after editing data live).
static func reload() -> void:
	_zones.clear()
	_rooms.clear()
	_room_zone.clear()
	_themes.clear()
	_ensure()


## Story 054: stack each room's upper levels (data/world/upper/<zone>.json) on top of it. The upper
## rows replace the room's old ceiling row; base coordinates (y up from the floor) are unchanged.
## {"rooms": {id: {"rows": [...top first...], "pickups": [...], "exits": {...}, "lamps": [...]}}}
static func _merge_upper(zone_id: String, zone_data: Dictionary) -> void:
	var path := "%s/upper/%s.json" % [ROOT, zone_id]
	if not FileAccess.file_exists(path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("WorldData: %s does not parse" % path)
		return
	var rooms: Dictionary = zone_data.get("rooms", {})
	var ups: Dictionary = (parsed as Dictionary).get("rooms", {})
	for rid: Variant in ups.keys():
		if not rooms.has(rid):
			push_error("WorldData: upper level for unknown room %s" % rid)
			continue
		var base: Dictionary = rooms[rid]
		var up: Dictionary = ups[rid]
		var up_rows: Array = up.get("rows", [])
		if up_rows.is_empty():
			continue
		var grid: Array = []
		grid.append_array(up_rows)
		grid.append_array((base.get("grid", []) as Array).slice(1))
		base["grid"] = grid
		base["upper_rows"] = up_rows.size()
		var picks: Array = (base.get("pickups", []) as Array).duplicate()
		picks.append_array(up.get("pickups", []))
		if not picks.is_empty():
			base["pickups"] = picks
		var exits: Dictionary = (base.get("exits", {}) as Dictionary).duplicate()
		exits.merge(up.get("exits", {}), true)
		base["exits"] = exits
		if up.has("lamps"):
			var lamps: Array = (base.get("lamps", []) as Array).duplicate()
			lamps.append_array(up["lamps"])
			base["lamps"] = lamps


static func _ensure() -> void:
	if not _zones.is_empty():
		return
	for z: String in ZONES:
		var path := "%s/%s.json" % [ROOT, z]
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not parsed is Dictionary:
			push_error("WorldData: %s does not parse" % path)
			continue
		_zones[z] = parsed
		_merge_upper(z, parsed)
		var rooms: Dictionary = (parsed as Dictionary).get("rooms", {})
		for k: Variant in rooms.keys():
			_room_zone[str(k)] = z
	var tpath := ROOT + "/themes.json"
	if FileAccess.file_exists(tpath):
		var t: Variant = JSON.parse_string(FileAccess.get_file_as_string(tpath))
		if t is Dictionary:
			_themes = t
