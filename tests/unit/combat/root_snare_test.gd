extends TestCase
## Story: RootSnare — Calcified Husk root-snare on the player. Duration 2.5 s, break early
## with 6 taps, break at once with break_now, inactive state clean.


func test_defaults_from_empty_data_are_2_5_s_and_6_taps() -> void:
	var snare := RootSnare.from_data({})
	assert_almost(snare.duration_s, 2.5)
	assert_eq(snare.taps_to_break, 6)


func test_from_data_reads_custom_values() -> void:
	var snare := RootSnare.from_data({"duration_s": 4.0, "taps_to_break": 3})
	assert_almost(snare.duration_s, 4.0)
	assert_eq(snare.taps_to_break, 3)


func test_apply_makes_it_active_with_full_time() -> void:
	var snare := RootSnare.from_data({})
	snare.apply()
	assert_true(snare.is_active())
	assert_almost(snare.left, 2.5)
	assert_eq(snare.taps, 0)


func test_tick_counts_down_and_ends_exactly_at_the_duration() -> void:
	var snare := RootSnare.from_data({})
	snare.apply()
	var t: float = 0.0
	while t < 2.5:
		snare.tick(0.1)
		t += 0.1
	assert_false(snare.is_active())
	assert_almost(snare.left, 0.0)


func test_five_taps_do_not_break_and_the_sixth_does_and_returns_true() -> void:
	var snare := RootSnare.from_data({})
	snare.apply()
	for _i in range(5):
		assert_false(snare.tap())
	assert_true(snare.is_active())
	assert_true(snare.tap())
	assert_false(snare.is_active())
	assert_almost(snare.left, 0.0)


func test_tap_when_not_active_returns_false_and_changes_nothing() -> void:
	var snare := RootSnare.from_data({})
	assert_false(snare.tap())
	assert_false(snare.is_active())
	assert_eq(snare.taps, 0)
	assert_almost(snare.left, 0.0)


func test_break_now_ends_it_at_once() -> void:
	var snare := RootSnare.from_data({})
	snare.apply()
	snare.tap()
	snare.tap()
	snare.break_now()
	assert_false(snare.is_active())
	assert_almost(snare.left, 0.0)
	assert_eq(snare.taps, 0)


func test_taps_left_counts_down_from_6_and_is_0_when_inactive() -> void:
	var snare := RootSnare.from_data({})
	assert_eq(snare.taps_left(), 0)
	snare.apply()
	for i in range(6):
		assert_eq(snare.taps_left(), 6 - i)
		snare.tap()
	assert_eq(snare.taps_left(), 0)


func test_apply_after_a_partial_escape_resets_the_tap_count() -> void:
	var snare := RootSnare.from_data({})
	snare.apply()
	snare.tap()
	snare.tap()
	snare.tap()
	snare.apply()
	assert_eq(snare.taps, 0)
	assert_almost(snare.left, 2.5)
	for _i in range(6):
		snare.tap()
	assert_false(snare.is_active())
