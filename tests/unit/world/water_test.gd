extends TestCase
## Story 031: water (addendum Zone 3: water levels; the tide puzzle; the Sovereign's rising water).
## A surface that can rise or fall over time, buoyancy toward the surface, and Frost freezing a
## patch of the surface into a platform that keeps its height when the water moves.

const CFG := {
	"gravity_mult": 0.35, "buoyancy": 16.0, "float_depth": 1.2, "max_sink_mps": 3.0,
	"max_rise_mps": 4.0, "drag": 2.0, "freeze_s": 8.0, "freeze_reach_m": 2.0, "patch_thickness_m": 0.4,
}


func _water(level: float) -> Water:
	var w := Water.new()
	w.config = CFG
	w.setup("pool", Vector2(2.0, 12.0), 0.0, level)
	return add_node(w) as Water


func test_depth_is_zero_outside_the_pool_or_above_the_surface() -> void:
	var w := _water(3.0)
	assert_almost(w.depth_at(Vector2(5.0, 1.0)), 2.0)
	assert_almost(w.depth_at(Vector2(5.0, 3.5)), 0.0, 0.001, "above the surface")
	assert_almost(w.depth_at(Vector2(13.0, 1.0)), 0.0, 0.001, "beside the pool")


func test_surface_rises_to_its_target_over_the_given_time() -> void:
	var w := _water(1.0)
	w.rise_to(2.5, 3.0)
	w.step(1.5)
	assert_almost(w.level, 1.75, 0.001, "halfway after half the time")
	w.step(5.0)
	assert_almost(w.level, 2.5, 0.001, "stops at the target")


func test_surface_can_fall_too() -> void:
	var w := _water(3.0)
	w.rise_to(1.0, 1.0)
	w.step(2.0)
	assert_almost(w.level, 1.0)


func test_buoyancy_pushes_a_deep_body_up() -> void:
	var vy := Water.swim_vy(0.0, 3.0, 0.1, 30.0, CFG)
	assert_gt(vy, 0.0, "deeper than float depth rises")


func test_a_body_at_float_depth_sinks_only_slowly() -> void:
	var vy := 0.0
	for i in range(60):
		vy = Water.swim_vy(vy, 1.0, 1.0 / 60.0, 30.0, CFG)
	assert_gt(vy, -3.01, "sink speed is capped")
	assert_lt(vy, 0.0, "above float depth it settles downward")


func test_a_fast_fall_into_water_is_slowed() -> void:
	var vy := Water.swim_vy(-20.0, 0.5, 1.0 / 60.0, 30.0, CFG)
	assert_gt(vy, -20.0)


func test_frost_over_the_surface_freezes_a_patch_at_the_current_height() -> void:
	var w := _water(2.0)
	assert_true(w.try_freeze(Rect2(4.0, 1.8, 4.0, 1.4), 3.0))
	assert_eq(w.patches.size(), 1)
	assert_almost(w.patches[0].top, 2.0)
	assert_almost(w.patches[0].x0, 4.0)
	assert_almost(w.patches[0].x1, 8.0)


func test_a_frozen_patch_keeps_its_height_when_the_water_rises() -> void:
	var w := _water(2.0)
	w.try_freeze(Rect2(4.0, 1.8, 4.0, 1.4), 3.0)
	w.rise_to(3.5, 1.0)
	w.step(1.0)
	assert_almost(w.patches[0].top, 2.0)


func test_a_patch_is_clipped_to_the_pool() -> void:
	var w := _water(2.0)
	w.try_freeze(Rect2(10.0, 1.8, 4.0, 1.4), 3.0)
	assert_almost(w.patches[0].x1, 12.0)


func test_frost_far_above_the_surface_does_not_freeze_it() -> void:
	var w := _water(1.0)
	assert_false(w.try_freeze(Rect2(4.0, 4.0, 4.0, 1.4), 3.0))
	assert_false(w.try_freeze(Rect2(20.0, 0.8, 4.0, 1.4), 3.0), "beside the pool")


func test_a_patch_melts_after_freeze_s() -> void:
	var w := _water(2.0)
	w.try_freeze(Rect2(4.0, 1.8, 4.0, 1.4), 3.0)
	w.step(7.9)
	assert_eq(w.patches.size(), 1)
	w.step(0.2)
	assert_eq(w.patches.size(), 0)


func test_room_json_water_is_read() -> void:
	var d := {"map": [0, 0, 1, 1], "grid": ["#....#", "######"],
		"water": [{"id": "pool", "x": [1, 5], "level": 0.5, "floor": 1.0}]}
	var r := RoomData.parse("t", "z", d)
	assert_eq(r.water.size(), 1)
	assert_eq(str(r.water[0].get("id")), "pool")


func test_a_jump_out_of_the_water_keeps_its_speed() -> void:
	# Found in the swim test: the rise cap clipped a jump from the surface to 4 m/s.
	var vy := Water.swim_vy(10.9, 1.2, 1.0 / 60.0, 30.0, CFG)
	assert_gt(vy, 10.0)
