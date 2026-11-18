extends TestCase
## Story 054: rooms grow upper levels (data/world/upper/<zone>.json, merged by WorldData) without
## moving anything the base room had: its doorways, its save ids for enemies and pickups. Spikes
## parse into strips; the world map places every room beside its neighbours; the look settings
## load.


func _base_grid(room_id: String) -> Array:
	var z := WorldData.zone_of(room_id)
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/%s.json" % z))
	return (parsed["rooms"] as Dictionary)[room_id]["grid"]


func test_upper_levels_raise_the_room_and_keep_its_base() -> void:
	var r := WorldData.room("z1_05")
	var base := _base_grid("z1_05")
	assert_gt(r.upper_rows, 0, "z1_05 has an upper level")
	assert_eq(r.rows, base.size() - 1 + r.upper_rows, "upper rows replace the old ceiling row")
	# The base doorways keep their place (y counts up from the floor).
	var raw := RoomData.parse("probe", "zone1", {"grid": base, "exits": {"0": {"to": "z1_04", "exit": "1"},
		"1": {"to": "z1_07", "exit": "0"}}})
	for d: String in raw.exits.keys():
		assert_eq((r.exits[d]["rect"] as Rect2), (raw.exits[d]["rect"] as Rect2), "doorway %s unmoved" % d)


func test_base_ids_come_first_and_upper_ones_after() -> void:
	for id: String in ["z1_05", "z2_09", "z3_04", "z4_05"]:
		var r := WorldData.room(id)
		var seen_upper := false
		for s: Dictionary in r.spawns:
			if s["upper"]:
				seen_upper = true
			else:
				assert_false(seen_upper, "%s: a base enemy numbered after an upper one" % id)
		seen_upper = false
		for p: Dictionary in r.pickups:
			if p["upper"]:
				seen_upper = true
			else:
				assert_false(seen_upper, "%s: a base pickup numbered after an upper one" % id)


func test_every_room_still_parses_cleanly() -> void:
	for id in WorldData.room_ids():
		assert_eq(WorldData.room_errors(id).size(), 0, "%s: %s" % [id, WorldData.room_errors(id)])


func test_upper_levels_bring_pickups_and_doorways() -> void:
	var picks := 0
	var doors := 0
	for id in WorldData.room_ids():
		var r := WorldData.room(id)
		for p: Dictionary in r.pickups:
			picks += 1 if p["upper"] else 0
		for d: String in r.exits.keys():
			doors += 1 if d == "7" or d == "8" else 0
	assert_gt(picks, 30, "rewards up high")
	assert_gt(doors, 6, "second routes between rooms")


func test_spikes_parse_into_strips() -> void:
	var grid := ["##########", "#........#", "#..^^^...#", "##########"]
	var r := RoomData.parse("spiky", "zone1", {"grid": grid})
	assert_eq(r.spikes.size(), 1)
	assert_eq(r.spikes[0], Rect2(3, 1, 3, 1))


func test_the_world_map_places_every_room_beside_its_neighbours() -> void:
	WorldMap.reset()
	var ids := WorldMap.rooms()
	assert_eq(ids.size(), WorldData.room_ids().size(), "every room is on the map")
	# Side doorways: the neighbour starts where this room ends (in metres, before snapping).
	var r := WorldData.room("z1_01")
	var right: Dictionary = r.exits["0"]
	assert_eq(str(right["to"]), "z1_02")
	assert_almost(WorldMap.origin("z1_02").x, WorldMap.origin("z1_01").x + r.size().x, 0.01)
	for id in ids:
		var c := WorldMap.cell_rect(id)
		assert_true(c.size.x >= 1 and c.size.y >= 1, id)


func test_the_look_settings_load() -> void:
	var cfg := PixelLook.config()
	assert_gt(float(cfg["camera"]["distance"]), 11.5, "the camera sits further back")
	assert_eq(PixelLook.virtual_height(), float(cfg["pixel"]["height"]), "the pixel grid comes from the data")
