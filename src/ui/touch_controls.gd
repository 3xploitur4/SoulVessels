class_name TouchControls
extends CanvasLayer
## Mobile touch layer (story 011): a floating joystick that appears where the thumb lands on the
## left 40 % of the screen, and a bottom-right button arc (Attack, Jump, Dodge, Ability 1,
## Ability 2, Ultimate) with cooldown sweeps. Buttons press the same input actions as keys and
## pads (`Input.action_press`), so gameplay never knows the source. Multi-touch: each finger is
## tracked by index. Hidden on the first gamepad input, shown again on the first touch.
##
##     var tc := TouchControls.new()
##     tc.router = input_router; tc.player = player
##     add_child(tc)

const JOY_RADIUS := 120.0
const JOY_DEAD := 0.15
const LEFT_ZONE := 0.4

## [action, offset from the bottom-right safe corner, radius, label key]
const BUTTONS := [
	["attack", Vector2(-215, -200), 92.0, "UI_ATTACK"],
	["dodge", Vector2(-62, -88), 62.0, "UI_DODGE"],
	["jump", Vector2(-62, -292), 62.0, "UI_JUMP"],
	["ability_1", Vector2(-372, -92), 58.0, "UI_ABILITY_1"],
	["ability_2", Vector2(-398, -262), 58.0, "UI_ABILITY_2"],
	["ultimate", Vector2(-238, -400), 58.0, "UI_ULTIMATE"],
]

var router: InputRouter
var player: Player
## Verb of the contextual interact button ("Rest", "Possess"); "" hides it.
var context_label: String = ""
## Offset and radius of the contextual button (left of the arc).
const CONTEXT_OFFSET := Vector2(-560, -130)
const CONTEXT_RADIUS := 60.0
## Accessibility: scale and opacity of the whole layout.
var ui_scale: float = 1.0
var opacity: float = 0.75

var _canvas: Control
var _font: Font
## finger index -> action name ("joystick" for the stick finger).
var _fingers: Dictionary[int, String] = {}
var _joy_origin: Vector2 = Vector2.ZERO
var _joy_pos: Vector2 = Vector2.ZERO
var _joy_active: bool = false


func _ready() -> void:
	layer = 6
	_font = ThemeDB.fallback_font
	_canvas = Control.new()
	_canvas.name = "TouchCanvas"
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_controls)
	add_child(_canvas)
	if router != null:
		router.device_changed.connect(_on_device_changed)
		visible = router.device == InputRouter.DEVICE_TOUCH or not OS.has_feature("mobile") and router.device != InputRouter.DEVICE_GAMEPAD


func _on_device_changed(kind: String) -> void:
	if kind == InputRouter.DEVICE_GAMEPAD:
		_release_all()
		visible = false
	elif kind == InputRouter.DEVICE_TOUCH:
		visible = true


func _process(_delta: float) -> void:
	if visible:
		_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		var pos := _to_canvas(t.position)
		if t.pressed:
			_finger_down(t.index, pos)
		else:
			_finger_up(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if _fingers.get(d.index, "") == "joystick":
			_joy_pos = _to_canvas(d.position)
			_update_axis()


## Button centre in canvas coordinates (tests, the bridge).
func button_centre(action: String) -> Vector2:
	var corner := _corner()
	if action == "interact":
		return corner + CONTEXT_OFFSET * ui_scale
	for b: Array in BUTTONS:
		if b[0] == action:
			return corner + (b[1] as Vector2) * ui_scale
	return Vector2.ZERO


func _finger_down(index: int, pos: Vector2) -> void:
	if context_label != "" and pos.distance_to(_corner() + CONTEXT_OFFSET * ui_scale) <= CONTEXT_RADIUS * ui_scale * 1.1:
		_fingers[index] = "interact"
		Input.action_press("interact")
		get_viewport().set_input_as_handled()
		return
	for b: Array in BUTTONS:
		if not _button_shown(str(b[0])):
			continue
		var centre := _corner() + (b[1] as Vector2) * ui_scale
		if pos.distance_to(centre) <= float(b[2]) * ui_scale * 1.1:
			_fingers[index] = str(b[0])
			Input.action_press(str(b[0]))
			get_viewport().set_input_as_handled()
			return
	if pos.x < _canvas.size.x * LEFT_ZONE and pos.y > _canvas.size.y * 0.22 and not _joy_active:
		_fingers[index] = "joystick"
		_joy_active = true
		_joy_origin = pos
		_joy_pos = pos
		_update_axis()
		get_viewport().set_input_as_handled()


func _finger_up(index: int) -> void:
	if not _fingers.has(index):
		return
	var what := _fingers[index]
	_fingers.erase(index)
	if what == "joystick":
		_joy_active = false
		if router != null:
			router.touch_axis = Vector2.ZERO
	else:
		Input.action_release(what)


func _release_all() -> void:
	for index: int in _fingers.keys():
		_finger_up(index)


func _update_axis() -> void:
	if router == null:
		return
	var off := (_joy_pos - _joy_origin) / (JOY_RADIUS * ui_scale)
	if off.length() > 1.0:
		_joy_origin = _joy_pos - off.normalized() * JOY_RADIUS * ui_scale
		off = off.normalized()
	router.touch_axis = off if off.length() > JOY_DEAD else Vector2.ZERO


func _to_canvas(screen_pos: Vector2) -> Vector2:
	return _canvas.get_global_transform_with_canvas().affine_inverse() * screen_pos


func _corner() -> Vector2:
	return _canvas.size - Vector2(36.0, 30.0)


func _draw_controls() -> void:
	var a := opacity
	if _joy_active:
		_canvas.draw_circle(_joy_origin, JOY_RADIUS * ui_scale, Color(1, 1, 1, 0.1 * a))
		_canvas.draw_arc(_joy_origin, JOY_RADIUS * ui_scale, 0.0, TAU, 48, Color(1, 1, 1, 0.35 * a), 3.0)
		var knob := _joy_origin + (router.touch_axis if router != null else Vector2.ZERO) * JOY_RADIUS * ui_scale
		_canvas.draw_circle(knob, 48.0 * ui_scale, Color(0.8, 0.9, 1.0, 0.45 * a))
	else:
		# A faint hint where the stick lives.
		var hint := Vector2(_canvas.size.x * 0.14, _canvas.size.y * 0.74)
		_canvas.draw_arc(hint, JOY_RADIUS * ui_scale * 0.8, 0.0, TAU, 48, Color(1, 1, 1, 0.12 * a), 2.0)
	if context_label != "":
		var cc := _corner() + CONTEXT_OFFSET * ui_scale
		var cr := CONTEXT_RADIUS * ui_scale
		_canvas.draw_circle(cc, cr, Color(0.1, 0.12, 0.08, 0.6 * a))
		_canvas.draw_arc(cc, cr, 0.0, TAU, 48, Color(0.95, 0.8, 0.35, 0.9 * a), 3.0)
		var cw := _font.get_string_size(context_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		_canvas.draw_string(_font, cc + Vector2(-cw * 0.5, 8.0), context_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
			Color(1.0, 0.92, 0.7, a))
	for b: Array in BUTTONS:
		var action := str(b[0])
		if not _button_shown(action):
			continue
		var centre := _corner() + (b[1] as Vector2) * ui_scale
		var r := float(b[2]) * ui_scale
		var pressed := Input.is_action_pressed(action)
		_canvas.draw_circle(centre, r, Color(0.05, 0.07, 0.1, (0.65 if pressed else 0.45) * a))
		_canvas.draw_arc(centre, r, 0.0, TAU, 48, Color(0.85, 0.85, 0.8, 0.7 * a), 2.5)
		var cd := _cooldown_ratio(action)
		if cd > 0.0:
			var pts := PackedVector2Array([centre])
			for i in range(33):
				var ang := -PI * 0.5 + TAU * cd * float(i) / 32.0
				pts.append(centre + Vector2(cos(ang), sin(ang)) * r)
			if pts.size() >= 3:
				_canvas.draw_colored_polygon(pts, Color(0, 0, 0, 0.55 * a))
		_draw_icon(action, centre, r * 0.45, Color(0.95, 0.93, 0.88, 0.9 * a))
		var label := tr(str(b[3]))
		var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
		_canvas.draw_string(_font, centre + Vector2(-tw * 0.5, r + 18.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			Color(0.9, 0.9, 0.85, 0.6 * a))


## The bare wisp can only move and jump, so only Jump is drawn.
func _button_shown(action: String) -> bool:
	return player == null or not player.is_wisp() or action == "jump"


## 0..1 of the remaining cooldown (or 1 when the action cannot be used).
func _cooldown_ratio(action: String) -> float:
	if player == null:
		return 0.0
	var slot := player.loadout.active()
	match action:
		"ability_1", "ability_2":
			var keys := slot.kit.ability_cooldown_keys()
			var key := keys[0] if action == "ability_1" else keys[1]
			var total := _cooldown_total(slot, action)
			return slot.cooldown_left(key) / total if total > 0.0 else 0.0
		"ultimate":
			var need := float(Balance.combat_f("sync_ultimate.cost_bars")) * player.gauge.bar_size
			return clampf(1.0 - player.gauge.value / need, 0.0, 1.0)
		"dodge":
			return 1.0 if slot.stamina.is_exhausted() else 0.0
	return 0.0


func _cooldown_total(slot: VesselSlot, action: String) -> float:
	var block: Dictionary = slot.data.get(action, {})
	return float(block.get("cooldown_s", 0.0))


## Shape icons, no glyphs: sword, chevron, curved arrow, diamond, triple dart, star.
func _draw_icon(action: String, c: Vector2, s: float, col: Color) -> void:
	match action:
		"attack":
			_canvas.draw_line(c + Vector2(-0.7, 0.7) * s, c + Vector2(0.75, -0.75) * s, col, 6.0)
			_canvas.draw_line(c + Vector2(-0.55, 0.15) * s, c + Vector2(-0.15, 0.55) * s, col, 6.0)
		"jump":
			_canvas.draw_polyline(PackedVector2Array([c + Vector2(-0.6, 0.35) * s, c + Vector2(0, -0.35) * s,
				c + Vector2(0.6, 0.35) * s]), col, 6.0)
		"dodge":
			_canvas.draw_arc(c, 0.55 * s, PI * 0.9, PI * 2.2, 16, col, 5.0)
			_canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(0.55, 0.2) * s, c + Vector2(0.95, -0.25) * s,
				c + Vector2(0.2, -0.3) * s]), col)
		"ability_1":
			_canvas.draw_polyline(PackedVector2Array([c + Vector2(0, -0.7) * s, c + Vector2(0.6, 0) * s,
				c + Vector2(0, 0.7) * s, c + Vector2(-0.6, 0) * s, c + Vector2(0, -0.7) * s]), col, 5.0)
		"ability_2":
			for k in range(3):
				var y := (-0.5 + 0.5 * float(k)) * s
				_canvas.draw_line(c + Vector2(-0.6 * s, y), c + Vector2(0.6 * s, y * 0.6), col, 4.0)
		"ultimate":
			var pts := PackedVector2Array()
			for i in range(11):
				var ang := -PI * 0.5 + TAU * float(i) / 10.0
				var rr := s * (0.85 if i % 2 == 0 else 0.38)
				pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
			_canvas.draw_colored_polygon(pts, col)
