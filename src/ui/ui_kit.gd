class_name UiKit
extends RefCounted
## Shared look for every menu (story 016): one Theme built in code, button and label helpers,
## rarity colours, and the name of a control on the device the player is using, so tutorial
## text says "J", "X" or "the Attack button" as appropriate.
##
##     menu.theme = UiKit.theme()
##     var b := UiKit.button(tr("UI_RESUME"))
##     var text := UiKit.format_controls(tr("TUT_ATTACK"), router.device)

const COL_TEXT := Color(0.92, 0.9, 0.85)
const COL_DIM := Color(0.62, 0.63, 0.68)
const COL_ACCENT := Color(0.44, 0.83, 0.91)
const COL_GOLD := Color(0.95, 0.78, 0.35)
const COL_PANEL := Color(0.03, 0.04, 0.07, 0.92)
const RARITY_COLORS := {
	"common": Color(0.85, 0.85, 0.82),
	"rare": Color(0.38, 0.64, 1.0),
	"epic": Color(0.74, 0.45, 1.0),
	"legendary": Color(1.0, 0.78, 0.3),
}
## Gamepad button names (Xbox layout, as in the addendum's control table).
const PAD_BUTTONS := {
	0: "A", 1: "B", 2: "X", 3: "Y", 4: "View", 5: "Guide", 6: "Menu", 7: "LS", 8: "RS",
	9: "LB", 10: "RB", 11: "D-pad Up", 12: "D-pad Down", 13: "D-pad Left", 14: "D-pad Right",
}
const PAD_AXES := {4: "LT", 5: "RT"}

static var _theme: Theme
static var _display: Font


## The display face for titles and headings: an old-style serif from the device (nothing is
## shipped, so no font licence is needed). Falls back through common serifs to the generic one.
static func display_font() -> Font:
	if _display == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Palatino Linotype", "Book Antiqua", "Constantia", "Georgia",
			"Noto Serif", "DejaVu Serif", "serif"])
		f.font_weight = 600
		_display = f
	return _display


## A heading in the display face, gold by default.
static func heading(text: String, size: int = 44, color: Color = COL_GOLD) -> Label:
	var l := label(text, size, color)
	l.add_theme_font_override("font", display_font())
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	return l


## A thin gold rule with a diamond at its centre, to sit under a heading.
static func rule(width: float = 420.0) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 18.0)
	c.draw.connect(func() -> void:
		var mid := c.size * 0.5
		var col := Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.8)
		c.draw_line(Vector2(mid.x - width * 0.5, mid.y), Vector2(mid.x - 12.0, mid.y), col, 1.5)
		c.draw_line(Vector2(mid.x + 12.0, mid.y), Vector2(mid.x + width * 0.5, mid.y), col, 1.5)
		c.draw_colored_polygon(PackedVector2Array([mid + Vector2(0, -6), mid + Vector2(7, 0), mid + Vector2(0, 6),
			mid + Vector2(-7, 0)]), col))
	return c


## The shared menu theme (built once).
static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 28
	t.set_font_size("font_size", "Button", 30)
	t.set_color("font_color", "Button", COL_TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", COL_ACCENT)
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.45, 0.5))
	# Dark slate plates with a worn gold edge; focus and hover brighten the gold.
	t.set_stylebox("normal", "Button", _box(Color(0.045, 0.055, 0.085, 0.9), Color(0.55, 0.45, 0.25, 0.75), 2))
	t.set_stylebox("hover", "Button", _box(Color(0.09, 0.1, 0.14, 0.96), Color(0.95, 0.78, 0.35), 2))
	t.set_stylebox("pressed", "Button", _box(Color(0.14, 0.11, 0.05, 0.96), Color(1.0, 0.86, 0.5), 3))
	t.set_stylebox("focus", "Button", _box(Color(0.95, 0.78, 0.35, 0.07), Color(1.0, 0.84, 0.45), 3))
	t.set_stylebox("disabled", "Button", _box(Color(0.04, 0.05, 0.07, 0.7), Color(0.25, 0.26, 0.3), 2))
	t.set_color("font_color", "Label", COL_TEXT)
	t.set_stylebox("panel", "PanelContainer", _box(COL_PANEL, Color(0.55, 0.45, 0.25, 0.7), 2, 14))
	t.set_constant("separation", "VBoxContainer", 14)
	t.set_constant("separation", "HBoxContainer", 14)
	_theme = t
	return t


static func _box(bg: Color, border: Color, width: int, pad: int = 10) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	sb.content_margin_left = pad + 8
	sb.content_margin_right = pad + 8
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad
	return sb


## A menu button at least `min_width` wide (touch targets stay large).
static func button(text: String, min_width: float = 380.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_width, 64.0)
	# Keep its own width in a column that a wide heading has stretched.
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_ALL
	return b


static func label(text: String, size: int = 28, color: Color = COL_TEXT,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


## A centred full-screen column for a menu page.
static func centre_column(parent: Control) -> VBoxContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(c)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(v)
	return v


## Chain focus neighbours so up/down wrap through `buttons`, and focus the first.
static func link_focus(buttons: Array[Control], grab: bool = true) -> void:
	var n := buttons.size()
	for i in range(n):
		var b := buttons[i]
		b.focus_neighbor_top = b.get_path_to(buttons[(i - 1 + n) % n])
		b.focus_neighbor_bottom = b.get_path_to(buttons[(i + 1) % n])
	if grab and n > 0 and buttons[0].is_inside_tree():
		buttons[0].grab_focus.call_deferred()


## The control for `action` on `device` ("keyboard", "gamepad", "touch").
static func action_name(action: String, device: String) -> String:
	if device == "touch":
		return TranslationServer.translate("TOUCH_BUTTON") % TranslationServer.translate("UI_" + action.to_upper())
	if not InputMap.has_action(action):
		return action
	for ev: InputEvent in InputMap.action_get_events(action):
		if device == "keyboard" and ev is InputEventKey:
			var k := ev as InputEventKey
			return OS.get_keycode_string(k.physical_keycode if k.physical_keycode != 0 else k.keycode)
		if device == "gamepad" and ev is InputEventJoypadButton:
			return PAD_BUTTONS.get(int((ev as InputEventJoypadButton).button_index), "?")
		if device == "gamepad" and ev is InputEventJoypadMotion:
			var m := ev as InputEventJoypadMotion
			if PAD_AXES.has(int(m.axis)):
				return PAD_AXES[int(m.axis)]
			return TranslationServer.translate("PAD_LEFT_STICK_UP" if m.axis_value < 0.0 else "PAD_LEFT_STICK_DOWN")
	return action


## Replace {action} placeholders (e.g. "{attack}") with the control names for `device`.
static func format_controls(text: String, device: String) -> String:
	var out := text
	var start := out.find("{")
	while start >= 0:
		var end := out.find("}", start)
		if end < 0:
			break
		var action := out.substr(start + 1, end - start - 1)
		var name := action_name(action, device)
		out = out.substr(0, start) + name + out.substr(end + 1)
		start = out.find("{", start + name.length())
	return out


## "1:05:09" style play time.
static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]
