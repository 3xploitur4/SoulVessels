extends TestCase
## Story 015: room grids parse into rects, markers and exits.


func _room(grid: Array, extra: Dictionary = {}) -> RoomData:
	var d := {"grid": grid}
	d.merge(extra)
	return RoomData.parse("t_01", "zone1", d)


func test_merge_rects_makes_few_large_boxes() -> void:
	var r := _room([
		"######",
		"#....#",
		"######",
	])
	# Top row, the two side columns (grown down), and the rest of the bottom row.
	assert_eq(r.solids.size(), 4)
	assert_true(r.solids.has(Rect2(0, 2, 6, 1)), "top row at y 2..3")
	assert_true(r.solids.has(Rect2(0, 0, 1, 2)), "left column grows down to y 0")
	var area := 0.0
	for s in r.solids:
		area += s.get_area()
	assert_almost(area, 14.0, 0.001, "every rock cell covered exactly once")


func test_block_merges_into_one_rect() -> void:
	var r := _room([
		"....",
		".##.",
		".##.",
	])
	assert_eq(r.solids, [Rect2(1, 0, 2, 2)] as Array[Rect2])


func test_exit_rect_arrival_and_targets() -> void:
	var r := _room([
		"#####",
		"0...1",
		"0...1",
		"#####",
	], {"exits": {"0": {"to": "a", "exit": "1"}, "1": {"to": "b", "exit": "0"}}})
	var left: Dictionary = r.exits["0"]
	assert_eq(left["rect"], Rect2(0, 1, 1, 2))
	assert_eq(left["arrive"], Vector2(2, 1), "one metre inside, standing on the floor")
	assert_eq(str(left["to"]), "a")
	assert_eq(r.exits["1"]["arrive"], Vector2(3, 1))
	assert_eq(r.exit_at(Vector2(0.5, 1.9)), "0")
	assert_eq(r.exit_at(Vector2(2.5, 1.9)), "")


func test_arrive_override_and_bottom_exit_boost() -> void:
	var r := _room([
		"#...#",
		"##2##",
	], {"exits": {"2": {"to": "a", "exit": "0", "arrive": [1.0, 1.0]}}})
	assert_eq(r.exits["2"]["arrive"], Vector2(1, 1))
	assert_true(bool(r.exits["2"]["boost"]), "entering from below pops the player up")


func test_markers_spawns_pickups_and_events() -> void:
	var r := _room([
		"#######",
		"#@A*cE#",
		"#######",
	], {"pickups": ["lesser_soul_shard"], "events": [{"vessel": "caelan", "kind": "possess"}]})
	assert_eq(r.markers["start"], Vector2(1.5, 1))
	assert_eq(r.markers["altar"], Vector2(2.5, 1))
	assert_eq(str(r.pickups[0]["item"]), "lesser_soul_shard")
	assert_eq(str(r.pickups[0]["pickup_id"]), "t_01:0")
	assert_eq(str(r.spawns[0]["id"]), "echo_crawler")
	assert_eq(str(r.spawns[0]["spawn_id"]), "t_01:0")
	assert_eq(str(r.events[0]["vessel"]), "caelan")


func test_oneway_gates_and_trims() -> void:
	var r := _room([
		"..VV..",
		"..====",
		"######",
	])
	assert_eq(r.oneway, [Rect2(2, 2, 4, 0)] as Array[Rect2], "platform top at the cell top")
	assert_eq((r.gate_rects["veil"] as Array).size(), 1)
	assert_eq(r.trims.size(), 1, "rock tops with open space above get a trim")


func test_errors_reported_for_bad_rows_and_missing_targets() -> void:
	var errors: Array[String] = []
	RoomData.parse("bad", "zone1", {"grid": ["###", "0.", "###"]}, errors)
	assert_gt(errors.size(), 1, "row length and the exit without a target")
