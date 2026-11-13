class_name Prompts
extends CanvasLayer
## On-screen messages over the game (story 016): the interact prompt, the tutorial banner (with
## the current device's control names), item toasts, the zone title card and subtitles with
## speaker colours (addendum accessibility). Display only.
##
##     prompts.tutorial(tr("TUT_ATTACK"))          # "{attack}" becomes J / X / the Attack button
##     prompts.toast(tr("ITEM_LESSER_SOUL_SHARD"), UiKit.RARITY_COLORS["common"])
##     prompts.subtitle(tr("SPEAKER_SOVEREIGN"), tr("LINE_THIEF"), Color(0.6, 0.75, 1.0))

const TOAST_S := 3.0
const TUTORIAL_S := 7.0
const SUBTITLE_S := 4.5
const MAX_TOASTS := 4

## Used to name controls in tutorial text.
var router: InputRouter

var _root: Control
var _interact: Label
var _tutorial: Label
var _tutorial_raw: String = ""
var _tutorial_left: float = 0.0
var _card: Label
var _card_left: float = 0.0
var _subtitle: Label
var _subtitle_left: float = 0.0
var _toasts: VBoxContainer


func _ready() -> void:
	layer = 8
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_interact = _make_label(30, Vector2(0.5, 0.78), Vector2(900, 60))
	_tutorial = _make_label(30, Vector2(0.5, 0.2), Vector2(1100, 120))
	_tutorial.add_theme_color_override("font_color", Color(0.95, 0.92, 0.82))
	_card = _make_label(72, Vector2(0.5, 0.36), Vector2(1600, 120))
	_card.add_theme_color_override("font_color", Color(0.9, 0.88, 0.82))
	_subtitle = _make_label(30, Vector2(0.5, 0.88), Vector2(1400, 90))
	_toasts = VBoxContainer.new()
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.anchor_left = 1.0
	_toasts.anchor_right = 1.0
	_toasts.anchor_top = 0.3
	_toasts.offset_left = -560.0
	_toasts.offset_right = -40.0
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	_root.add_child(_toasts)
	if router != null:
		router.device_changed.connect(func(_d: String) -> void: _refresh_tutorial())


func _make_label(size: int, anchor: Vector2, box: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.anchor_left = anchor.x
	l.anchor_right = anchor.x
	l.anchor_top = anchor.y
	l.anchor_bottom = anchor.y
	l.offset_left = -box.x * 0.5
	l.offset_right = box.x * 0.5
	l.offset_top = -box.y * 0.5
	l.offset_bottom = box.y * 0.5
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.visible = false
	_root.add_child(l)
	return l


## Show "[control] Verb" for the nearest interactable; "" hides it.
func show_interact(verb: String) -> void:
	if verb == "":
		_interact.visible = false
		return
	_interact.text = "%s  %s" % [_control("interact"), verb]
	_interact.visible = true


func interact_text() -> String:
	return _interact.text if _interact.visible else ""


## Show a tutorial line; "{action}" placeholders become this device's controls.
func tutorial(text: String) -> void:
	_tutorial_raw = text
	_tutorial_left = TUTORIAL_S
	_refresh_tutorial()


func tutorial_text() -> String:
	return _tutorial.text if _tutorial.visible else ""


func toast(text: String, color: Color = UiKit.COL_TEXT) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	l.set_meta("left", TOAST_S)
	_toasts.add_child(l)
	while _toasts.get_child_count() > MAX_TOASTS:
		var old := _toasts.get_child(0)
		_toasts.remove_child(old)
		old.queue_free()


## Recent toast texts (bridge checks).
func toast_texts() -> PackedStringArray:
	var out := PackedStringArray()
	for c in _toasts.get_children():
		out.append((c as Label).text)
	return out


## A large centred title (zone names), fading out after a few seconds.
func title_card(text: String) -> void:
	_card.text = text
	_card_left = 3.5
	_card.visible = true


func subtitle(speaker: String, text: String, color: Color) -> void:
	_subtitle.text = "%s: %s" % [speaker, text] if speaker != "" else text
	_subtitle.add_theme_color_override("font_color", color)
	_subtitle_left = SUBTITLE_S
	_subtitle.visible = true


func subtitle_text() -> String:
	return _subtitle.text if _subtitle.visible else ""


func clear() -> void:
	_interact.visible = false
	_tutorial.visible = false
	_tutorial_left = 0.0
	_card.visible = false
	_subtitle.visible = false
	for c in _toasts.get_children():
		c.queue_free()


func _process(delta: float) -> void:
	_tutorial_left = _fade(_tutorial, _tutorial_left, delta)
	_card_left = _fade(_card, _card_left, delta)
	_subtitle_left = _fade(_subtitle, _subtitle_left, delta)
	for c in _toasts.get_children():
		var left := float(c.get_meta("left")) - delta
		c.set_meta("left", left)
		(c as Label).modulate.a = clampf(left / 0.5, 0.0, 1.0)
		if left <= 0.0:
			c.queue_free()


func _fade(l: Label, left: float, delta: float) -> float:
	if not l.visible:
		return 0.0
	left -= delta
	l.modulate.a = clampf(left / 0.6, 0.0, 1.0)
	if left <= 0.0:
		l.visible = false
	return left


func _refresh_tutorial() -> void:
	if _tutorial_left <= 0.0:
		return
	_tutorial.text = UiKit.format_controls(_tutorial_raw, router.device if router != null else "keyboard")
	_tutorial.visible = true


func _control(action: String) -> String:
	var device := router.device if router != null else "keyboard"
	return "[%s]" % UiKit.action_name(action, device)
