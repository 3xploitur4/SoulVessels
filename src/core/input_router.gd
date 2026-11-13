class_name InputRouter
extends Node
## Single entry point for player input (story 002). Reads the project's input actions, adds the
## touch joystick axis (set by the touch UI), the LT+RT ultimate chord, and tracks which device
## the player used last so the touch UI can hide on a gamepad and return on a touch.
## Touch buttons press the same actions through `Input.action_press`, so gameplay code only ever
## asks this node and never cares where a press came from.

## Emitted when the last meaningful input device changes: "touch", "gamepad" or "keyboard".
signal device_changed(kind: String)

const DEVICE_TOUCH := "touch"
const DEVICE_GAMEPAD := "gamepad"
const DEVICE_KEYBOARD := "keyboard"
## Stick motion below this is noise and does not count as "the player used a gamepad".
const GAMEPAD_MOTION_THRESHOLD := 0.3
## Both triggers past this is the ultimate chord.
const TRIGGER_CHORD_THRESHOLD := 0.5

## The last device used: one of the DEVICE_* constants. Starts as touch on handheld builds.
var device: String = DEVICE_TOUCH if OS.has_feature("mobile") else DEVICE_KEYBOARD
## Axis fed by the floating joystick; zero when no finger is down.
var touch_axis := Vector2.ZERO
## When true, input is ignored by gameplay (ultimates, cutscenes). Readers check it.
var locked := false

var _chord_was_down := false
var _chord_just_pressed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	var kind := classify_event(event, GAMEPAD_MOTION_THRESHOLD)
	if kind != "" and kind != device:
		device = kind
		device_changed.emit(kind)
		GameEvents.input_device_changed.emit(kind)


func _process(_delta: float) -> void:
	var down := ultimate_chord_down(
		Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT),
		Input.get_joy_axis(0, JOY_AXIS_TRIGGER_RIGHT),
		TRIGGER_CHORD_THRESHOLD)
	_chord_just_pressed = down and not _chord_was_down
	_chord_was_down = down


## Horizontal/vertical movement in -1..1, from keys, stick or the touch joystick.
func move_axis() -> Vector2:
	if locked:
		return Vector2.ZERO
	var v := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_axis.length_squared() > v.length_squared():
		v = touch_axis
	return v.limit_length(1.0)


## True on the frame the ultimate is triggered: the `ultimate` action, or LT+RT together.
func ultimate_just_pressed() -> bool:
	if locked:
		return false
	return Input.is_action_just_pressed("ultimate") or _chord_just_pressed


## Ability 2 shares RT with the ultimate chord, so it is suppressed while LT is held.
func ability_2_just_pressed() -> bool:
	if locked:
		return false
	if Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > TRIGGER_CHORD_THRESHOLD:
		return false
	return Input.is_action_just_pressed("ability_2")


func just_pressed(action: StringName) -> bool:
	return not locked and Input.is_action_just_pressed(action)


func pressed(action: StringName) -> bool:
	return not locked and Input.is_action_pressed(action)


func just_released(action: StringName) -> bool:
	return not locked and Input.is_action_just_released(action)


## Which device an event comes from, or "" when it is not a deliberate player input
## (mouse moves, tiny stick drift). Pure, so the unit test can feed synthetic events.
static func classify_event(event: InputEvent, motion_threshold: float) -> String:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return DEVICE_TOUCH
	if event is InputEventJoypadButton:
		return DEVICE_GAMEPAD
	if event is InputEventJoypadMotion:
		var motion := event as InputEventJoypadMotion
		return DEVICE_GAMEPAD if absf(motion.axis_value) >= motion_threshold else ""
	if event is InputEventKey:
		return DEVICE_KEYBOARD
	return ""


## The LT+RT chord: both triggers past the threshold. Pure.
static func ultimate_chord_down(left_trigger: float, right_trigger: float, threshold: float) -> bool:
	return left_trigger >= threshold and right_trigger >= threshold
