extends TestCase
## Story 007: the three telegraph shapes are different shapes, not one shape recoloured
## (accessibility: shape + sound carry the meaning when colour cannot).


func _alpha(kind: String, x: int, y: int) -> float:
	return TelegraphIcons.texture(kind).get_image().get_pixel(x, y).a


func test_ring_is_hollow() -> void:
	assert_lt(_alpha("parryable", 64, 64), 0.1, "centre of the ring is empty")
	assert_gt(_alpha("parryable", 64 + 44, 64), 0.9, "the stroke at radius 44")


func test_x_is_filled_at_the_centre_and_empty_on_the_axes() -> void:
	assert_gt(_alpha("unblockable", 64, 64), 0.9)
	assert_lt(_alpha("unblockable", 64, 64 - 40), 0.1, "straight above the centre is empty")


func test_diamond_has_a_core_and_a_rim() -> void:
	assert_gt(_alpha("magic", 64, 64), 0.9, "inner core")
	assert_gt(_alpha("magic", 64, 64 - 46), 0.9, "outer rim on the vertical axis")
	assert_lt(_alpha("magic", 64 + 40, 64 - 40), 0.1, "outside the diamond and its rim, inside the square")


func test_textures_are_cached() -> void:
	assert_eq(TelegraphIcons.texture("magic"), TelegraphIcons.texture("magic"))


func test_telegraph_colours_and_sounds_come_from_data() -> void:
	assert_eq(Balance.combat("telegraph.parryable.sfx"), "telegraph_chime")
	assert_eq(Balance.combat("telegraph.unblockable.sfx"), "telegraph_boom")
	assert_eq(Balance.combat("telegraph.magic.sfx"), "telegraph_harmonic")
	assert_eq(Balance.combat("telegraph.parryable.icon"), "ring")
