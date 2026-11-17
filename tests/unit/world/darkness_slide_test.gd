extends TestCase
## Story 043: darkness with a light radius that grows with the Soul Gauge, and sliding floors that
## push downhill, slow running uphill, and can tilt over time (the Guardian's elevator).


func test_the_light_radius_grows_with_the_soul_gauge() -> void:
	assert_almost(Darkness.radius_for(3.5, 2.0, 0.0), 3.5)
	assert_almost(Darkness.radius_for(3.5, 2.0, 0.5), 4.5)
	assert_almost(Darkness.radius_for(3.5, 2.0, 1.0), 5.5)


func test_a_flat_floor_does_not_slide() -> void:
	assert_almost(SlideZone.slide_accel(0.0, 30.0, 0.6), 0.0)


func test_a_slope_pushes_downhill() -> void:
	var a := SlideZone.slide_accel(15.0, 30.0, 0.6)
	assert_almost(a, 30.0 * sin(deg_to_rad(15.0)) * 0.6, 0.001)
	assert_gt(a, 0.0, "a positive angle slides right")
	assert_lt(SlideZone.slide_accel(-15.0, 30.0, 0.6), 0.0, "a negative angle slides left")


func test_running_uphill_is_slower() -> void:
	assert_almost(SlideZone.run_speed(6.0, 15.0, 1, 1.5), 6.0, 0.001, "downhill keeps full speed")
	assert_lt(SlideZone.run_speed(6.0, 15.0, -1, 1.5), 6.0)
	assert_gt(SlideZone.run_speed(6.0, 15.0, -1, 1.5), 0.0, "but never stops you")


func test_a_zone_tilts_over_time() -> void:
	var z := SlideZone.new()
	z.setup(Vector2(0.0, 20.0), Vector2(0.0, 6.0), 0.0)
	z.tilt_to(15.0, 2.0)
	z.step(1.0)
	assert_almost(z.angle, 7.5, 0.01)
	z.step(5.0)
	assert_almost(z.angle, 15.0, 0.01)
	z.free()


func test_a_zone_covers_its_rect() -> void:
	var z := SlideZone.new()
	z.setup(Vector2(4.0, 10.0), Vector2(1.0, 4.0), 10.0)
	assert_true(z.covers(Vector2(5.0, 2.0)))
	assert_false(z.covers(Vector2(11.0, 2.0)))
	z.free()
