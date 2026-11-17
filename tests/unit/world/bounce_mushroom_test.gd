extends TestCase
## Story 021 addendum: BounceMushroom.catches() — a falling body on the cap is caught,
## rising, off-side, above or below bodies are not.


func _mushroom() -> BounceMushroom:
	var m := BounceMushroom.new()
	add_node(m)
	m.global_position = Vector3(5.0, 1.0, 0.0)
	return m


func test_falling_on_cap_top_centred_is_caught() -> void:
	var m := _mushroom()
	assert_true(m.catches(Vector3(5.0, 1.0 + BounceMushroom.CAP_TOP, 0.0), -5.0))


func test_rising_fast_is_not_caught() -> void:
	var m := _mushroom()
	assert_false(m.catches(Vector3(5.0, 1.0 + BounceMushroom.CAP_TOP, 0.0), 3.0))


func test_body_beside_cap_is_not_caught() -> void:
	var m := _mushroom()
	var x: float = 5.0 + BounceMushroom.CAP_HALF + 0.2
	assert_false(m.catches(Vector3(x, 1.0 + BounceMushroom.CAP_TOP, 0.0), -5.0))


func test_body_above_cap_is_not_caught() -> void:
	var m := _mushroom()
	var y: float = 1.0 + BounceMushroom.CAP_TOP + 0.2
	assert_false(m.catches(Vector3(5.0, y, 0.0), -5.0))


func test_body_far_below_cap_is_not_caught() -> void:
	var m := _mushroom()
	var y: float = 1.0 + BounceMushroom.CAP_TOP - 0.5
	assert_false(m.catches(Vector3(5.0, y, 0.0), -5.0))
