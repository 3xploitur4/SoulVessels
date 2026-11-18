extends TestCase
## Story 054 (D-062): the ground's darkness by depth, its settings per zone, and a built room
## carries the dressing.


func test_distance_counts_cells_to_the_nearest_open_one() -> void:
	# 5 x 5 rock with one open cell in the middle.
	var solid := PackedByteArray()
	solid.resize(25)
	solid.fill(1)
	solid[12] = 0
	var d := GroundDresser.distance_field(solid, 5, 5)
	assert_eq(d[12], 0, "the open cell")
	assert_eq(d[7], 1, "beside it")
	assert_eq(d[6], 1, "diagonal counts as beside")
	assert_eq(d[0], 2, "the corner is two away")


func test_rock_with_no_air_is_as_deep_as_it_gets() -> void:
	var solid := PackedByteArray()
	solid.resize(4)
	solid.fill(1)
	var d := GroundDresser.distance_field(solid, 2, 2)
	assert_eq(d[0], 4)


func test_darkness_grows_with_depth_and_stops_at_the_last_value() -> void:
	var table := [0.0, 0.5, 0.8, 0.95]
	assert_almost(GroundDresser.shade_alpha(0, table), 0.0, 0.001, "the lit surface")
	assert_almost(GroundDresser.shade_alpha(2, table), 0.8, 0.001)
	assert_almost(GroundDresser.shade_alpha(40, table), 0.95, 0.001, "deep rock")
	assert_almost(GroundDresser.shade_alpha(3, []), 0.0, 0.001, "no table, no darkness")


func test_a_zone_overrides_single_keys_of_the_defaults() -> void:
	var palace := GroundDresser.config("palace")
	var cavern := GroundDresser.config("cavern")
	assert_eq(str(palace["accent"]), "gold")
	assert_eq(str(cavern["accent"]), "moss")
	assert_eq(int(palace["margin_cells"]), int(cavern["margin_cells"]), "unchanged keys come from the defaults")
	assert_true(GroundDresser.config("no_such_theme").has("shade"), "an unknown theme gets the defaults")


func test_a_built_room_has_its_darkness_and_dressing() -> void:
	var b := RoomBuilder.new()
	b.data = WorldData.room("z1_02")
	add_node(b)
	var shade := b.find_child("GroundShade", true, false) as MeshInstance3D
	assert_true(shade != null, "the darkness mesh")
	assert_gt(shade.mesh.get_surface_count(), 0)
	# The ground is drawn past the room's floor, so the camera never shows a void below it.
	var lowest := 0.0
	for m: Node in b.find_children("*", "MeshInstance3D", true, false):
		var aabb := (m as MeshInstance3D).get_aabb()
		lowest = minf(lowest, ((m as MeshInstance3D).global_transform * aabb).position.y)
	assert_lt(lowest, -4.0, "rock under the floor")
