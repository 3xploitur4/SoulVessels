extends TestCase
## Story 015: every authored room parses cleanly and every exit leads to a room whose exit leads
## back (the world graph has no one-way doors and no dead links).


func test_zone_room_counts_match_the_addendum() -> void:
	assert_eq(WorldData.room_ids("zone1").size(), 14, "Zone 1: 14 rooms")
	assert_eq(WorldData.room_ids("zone2").size(), 16, "Zone 2: 16 rooms")


func test_every_room_parses_without_errors() -> void:
	for id in WorldData.room_ids():
		var errors := WorldData.room_errors(id)
		assert_eq(errors.size(), 0, "%s: %s" % [id, ", ".join(errors)])


func test_every_exit_links_back() -> void:
	for id in WorldData.room_ids():
		var r := WorldData.room(id)
		for digit: String in r.exits.keys():
			var ex: Dictionary = r.exits[digit]
			var target := WorldData.room(str(ex["to"]))
			assert_not_null(target, "%s exit %s -> %s" % [id, digit, ex["to"]])
			if target == null:
				continue
			var back: Dictionary = target.exits.get(str(ex["exit"]), {})
			assert_false(back.is_empty(), "%s exit %s arrives at %s exit %s, which does not exist" % [id, digit, target.id, ex["exit"]])
			assert_eq(str(back.get("to", "")), id, "%s exit %s: the way back from %s leads elsewhere" % [id, digit, target.id])


func test_arrival_points_are_in_open_space() -> void:
	for id in WorldData.room_ids():
		var r := WorldData.room(id)
		for digit: String in r.exits.keys():
			var p: Vector2 = r.exits[digit]["arrive"]
			for s in r.solids:
				assert_false(s.has_point(p + Vector2(0, 0.5)), "%s exit %s arrives inside rock at %s" % [id, digit, p])


func test_altar_count_per_zone() -> void:
	for zone_id: String in ["zone1", "zone2"]:
		var count := 0
		for id in WorldData.room_ids(zone_id):
			if WorldData.room(id).markers.has("altar"):
				count += 1
		assert_eq(count, 2, "%s has 2 Soul Altars" % zone_id)
