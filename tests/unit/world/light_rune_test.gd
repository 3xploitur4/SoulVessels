extends TestCase
## Story 032: light-rune puzzle rules (addendum "Light-rune puzzles"): a sequence must be lit in
## mural order and a wrong rune puts them all out; an "all" door opens once every rune is lit in
## any order; a mirror-shield bounces a bolt at the mirrored angle and turns in 45 degree steps.


func test_sequence_in_order_solves() -> void:
	var s := RuneSequence.new("sequence", 3)
	assert_eq(s.light(0), RuneSequence.LIT)
	assert_eq(s.light(1), RuneSequence.LIT)
	assert_eq(s.light(2), RuneSequence.SOLVED)
	assert_true(s.solved)


func test_a_wrong_rune_puts_the_sequence_out() -> void:
	var s := RuneSequence.new("sequence", 3)
	s.light(0)
	assert_eq(s.light(2), RuneSequence.WRONG)
	assert_eq(s.lit_count(), 0, "every rune is dark again")
	assert_false(s.is_lit(0))


func test_relighting_a_lit_rune_changes_nothing() -> void:
	var s := RuneSequence.new("sequence", 3)
	s.light(0)
	assert_eq(s.light(0), RuneSequence.ALREADY)
	assert_eq(s.lit_count(), 1)


func test_all_kind_takes_any_order() -> void:
	var s := RuneSequence.new("all", 3)
	assert_eq(s.light(2), RuneSequence.LIT)
	assert_eq(s.light(0), RuneSequence.LIT)
	assert_eq(s.light(1), RuneSequence.SOLVED)


func test_a_solved_puzzle_ignores_more_light() -> void:
	var s := RuneSequence.new("all", 1)
	s.light(0)
	assert_eq(s.light(0), RuneSequence.ALREADY)
	assert_true(s.solved)


func test_restored_solved_puzzle_shows_every_rune_lit() -> void:
	var s := RuneSequence.new("sequence", 4)
	s.restore_solved()
	assert_true(s.solved)
	assert_eq(s.lit_count(), 4)


func test_mirror_at_135_turns_a_rightward_bolt_upward() -> void:
	var v := WardMath.mirror_reflect(Vector2(10.0, 0.0), 135.0)
	assert_almost(v.x, 0.0, 0.001)
	assert_almost(v.y, 10.0, 0.001)


func test_mirror_at_45_turns_a_rightward_bolt_downward() -> void:
	var v := WardMath.mirror_reflect(Vector2(10.0, 0.0), 45.0)
	assert_almost(v.x, 0.0, 0.001)
	assert_almost(v.y, -10.0, 0.001)


func test_mirror_is_two_sided() -> void:
	var v := WardMath.mirror_reflect(Vector2(-10.0, 0.0), 135.0)
	assert_almost(v.y, -10.0, 0.001, "a leftward bolt off the same mirror goes down")


func test_mirror_at_0_sends_a_bolt_back() -> void:
	var v := WardMath.mirror_reflect(Vector2(10.0, 0.0), 0.0)
	assert_almost(v.x, -10.0, 0.001)


func test_mirror_turns_in_45_degree_steps_through_four_settings() -> void:
	var a := 45.0
	var seen: Array[float] = []
	for i in range(4):
		a = MirrorShield.next_angle(a)
		seen.append(a)
	assert_eq(seen, [90.0, 135.0, 0.0, 45.0])
