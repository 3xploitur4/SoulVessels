extends TestCase
## Story 024/026: tutorial text names the player's own controls on every device. Found on the
## Android emulator: "{move_left}" printed "the UI_MOVE_LEFT button" on touch.


func test_move_names_both_keys_on_keyboard() -> void:
	var s := UiKit.format_controls("{move} to drift.", "keyboard")
	assert_true(s.contains(" / "), s)
	assert_false(s.contains("{"), s)


func test_move_names_the_stick_on_touch_and_gamepad() -> void:
	assert_eq(UiKit.format_controls("Use {move}", "touch"), "Use " + tr("TOUCH_STICK"))
	assert_eq(UiKit.format_controls("Use {move}", "gamepad"), "Use " + tr("PAD_LEFT_STICK"))


func test_a_sentence_opening_with_a_control_starts_upper_case() -> void:
	var s := UiKit.format_controls("{move} to drift.", "touch")
	assert_eq(s.substr(0, 1), s.substr(0, 1).to_upper(), s)


func test_every_tutorial_placeholder_has_a_touch_name() -> void:
	# Each "{action}" used in the strings must translate on touch (no raw UI_ keys left).
	var text := FileAccess.get_file_as_string("res://assets/locale/strings.csv")
	var re := RegEx.new()
	re.compile("\\{([a-z_0-9]+)\\}")
	var seen := {}
	for m in re.search_all(text):
		seen[m.get_string(1)] = true
	for action: String in seen.keys():
		var name := UiKit.action_name(action, "touch")
		assert_false(name.contains("UI_"), "%s on touch reads '%s'" % [action, name])
