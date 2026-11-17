extends TestCase
## Unit tests for the shield ward math helpers.


func test_reflect_dir_left_beam_returns_up_right() -> void:
	var direction: Vector2 = WardMath.reflect_dir(-1.0, 45.0)
	assert_almost(direction.x, 0.7071, 0.001)
	assert_almost(direction.y, 0.7071, 0.001)


func test_reflect_dir_right_beam_returns_up_left() -> void:
	var direction: Vector2 = WardMath.reflect_dir(1.0, 30.0)
	assert_almost(direction.x, -0.866, 0.001)
	assert_almost(direction.y, 0.5, 0.001)


func test_beam_end_x_left_beam_stops_at_near_face() -> void:
	var blockers: Array[Rect2] = [Rect2(0.0, 0.0, 1.0, 12.0)]
	assert_almost(WardMath.beam_end_x(Vector2(20.0, 3.0), -1.0, 30.0, blockers), 1.0)


func test_beam_end_x_left_beam_picks_nearest_blocker() -> void:
	var blockers: Array[Rect2] = [Rect2(0.0, 0.0, 1.0, 12.0), Rect2(10.0, 2.0, 1.0, 2.0)]
	assert_almost(WardMath.beam_end_x(Vector2(20.0, 3.0), -1.0, 30.0, blockers), 11.0)


func test_beam_end_x_ignores_blocker_above_beam() -> void:
	var blockers: Array[Rect2] = [Rect2(10.0, 5.0, 1.0, 2.0)]
	assert_almost(WardMath.beam_end_x(Vector2(20.0, 3.0), -1.0, 30.0, blockers), -10.0)


func test_beam_end_x_ignores_blocker_behind_origin() -> void:
	var blockers: Array[Rect2] = [Rect2(25.0, 0.0, 1.0, 12.0)]
	assert_almost(WardMath.beam_end_x(Vector2(20.0, 3.0), -1.0, 5.0, blockers), 15.0)


func test_ray_hits_reflected_beam_crosses_crystal() -> void:
	var direction: Vector2 = WardMath.reflect_dir(-1.0, 45.0)
	assert_true(WardMath.ray_hits(Vector2(19.5, 3.2), direction, 20.0, Rect2(25.0, 8.0, 1.0, 1.5)))


func test_ray_hits_reflected_beam_misses_crystal() -> void:
	var direction: Vector2 = WardMath.reflect_dir(-1.0, 45.0)
	assert_false(WardMath.ray_hits(Vector2(14.0, 3.2), direction, 20.0, Rect2(25.0, 8.0, 1.0, 1.5)))
