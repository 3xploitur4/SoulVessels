extends TestCase
## Story 002: device classification and the LT+RT ultimate chord.


func test_touch_event_classifies_as_touch() -> void:
	var touch := InputEventScreenTouch.new()
	assert_eq(InputRouter.classify_event(touch, 0.3), InputRouter.DEVICE_TOUCH)
	var drag := InputEventScreenDrag.new()
	assert_eq(InputRouter.classify_event(drag, 0.3), InputRouter.DEVICE_TOUCH)


func test_joypad_button_classifies_as_gamepad() -> void:
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	assert_eq(InputRouter.classify_event(button, 0.3), InputRouter.DEVICE_GAMEPAD)


func test_small_stick_drift_is_ignored() -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 0.1
	assert_eq(InputRouter.classify_event(motion, 0.3), "", "drift below threshold is not a device switch")
	motion.axis_value = -0.8
	assert_eq(InputRouter.classify_event(motion, 0.3), InputRouter.DEVICE_GAMEPAD)


func test_key_classifies_as_keyboard_and_mouse_is_ignored() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	assert_eq(InputRouter.classify_event(key, 0.3), InputRouter.DEVICE_KEYBOARD)
	var mouse := InputEventMouseMotion.new()
	assert_eq(InputRouter.classify_event(mouse, 0.3), "")


func test_ultimate_chord_needs_both_triggers() -> void:
	assert_true(InputRouter.ultimate_chord_down(1.0, 1.0, 0.5))
	assert_true(InputRouter.ultimate_chord_down(0.5, 0.6, 0.5), "threshold is inclusive")
	assert_false(InputRouter.ultimate_chord_down(1.0, 0.2, 0.5), "RT alone is ability 2")
	assert_false(InputRouter.ultimate_chord_down(0.2, 1.0, 0.5), "LT alone is nothing")
	assert_false(InputRouter.ultimate_chord_down(0.0, 0.0, 0.5))


func test_project_input_map_has_every_action() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "jump", "attack", "dodge",
			"ability_1", "ability_2", "ultimate", "swap_prev", "swap_next", "flask", "pause", "map",
			"debug_hud"]:
		assert_true(InputMap.has_action(action), "missing action %s" % action)
	var attack_has_x := false
	for ev in InputMap.action_get_events("attack"):
		if ev is InputEventJoypadButton and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_X:
			attack_has_x = true
	assert_true(attack_has_x, "attack is X on the gamepad")
