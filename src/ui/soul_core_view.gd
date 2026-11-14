class_name SoulCoreView
extends Control
## The Soul Core tree on the altar screen (story 020): every node as a button placed by its grid
## cell, lines to the nodes it requires, and an info line for the focused node. Owned nodes are
## gold, buyable ones bright, locked ones dark; each state also shows a word in the info line, so
## nothing relies on colour alone. Display only: pressing a buyable node emits `buy_requested`.
##
##     var view := SoulCoreView.new()
##     view.core = soul_core; view.state = game_state
##     view.buy_requested.connect(game.buy_core)

signal buy_requested(node_id: String)

const CELL := 82.0
const NODE := 66.0

var core: SoulCore
var state: GameState
## Buttons by node id (focus and tests).
var buttons: Dictionary[String, Button] = {}

var _info: Label
var _shards: Label
var _origin: Vector2
var _min: Vector2i
var _max: Vector2i


func _ready() -> void:
	_min = Vector2i(99, 99)
	_max = Vector2i(-99, -99)
	for id in core.order:
		var p := _cell(id)
		_min = Vector2i(mini(_min.x, p.x), mini(_min.y, p.y))
		_max = Vector2i(maxi(_max.x, p.x), maxi(_max.y, p.y))
	var grid := Vector2(_max - _min + Vector2i.ONE) * CELL
	custom_minimum_size = Vector2(maxf(grid.x, 900.0), grid.y + 96.0)
	_origin = Vector2((custom_minimum_size.x - grid.x) * 0.5, 0.0)
	for id in core.order:
		var b := Button.new()
		b.name = "Core_" + id
		b.custom_minimum_size = Vector2(NODE, NODE)
		b.size = Vector2(NODE, NODE)
		b.position = _origin + Vector2(_cell(id) - _min) * CELL + Vector2(CELL - NODE, CELL - NODE) * 0.5
		b.add_theme_font_size_override("font_size", 18)
		b.text = tr("CORE_SHORT_" + _effect_key(id).to_upper())
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_on_pressed.bind(id))
		b.focus_entered.connect(_show_info.bind(id))
		b.mouse_entered.connect(_show_info.bind(id))
		add_child(b)
		buttons[id] = b
	_shards = UiKit.label("", 26, ItemDb.color(core.shard_item), HORIZONTAL_ALIGNMENT_CENTER)
	_shards.position = Vector2(0.0, grid.y + 6.0)
	_shards.size = Vector2(custom_minimum_size.x, 34.0)
	add_child(_shards)
	_info = UiKit.label("", 24, UiKit.COL_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_info.position = Vector2(0.0, grid.y + 44.0)
	_info.size = Vector2(custom_minimum_size.x, 40.0)
	add_child(_info)
	refresh()


## Recolour every node from the state (after a purchase) and update the shard count.
func refresh() -> void:
	for id in core.order:
		var b := buttons[id]
		var st := core.status(state, id)
		var bg := Color(0.05, 0.06, 0.09, 0.95)
		var border := Color(0.3, 0.3, 0.36)
		var text := Color(0.5, 0.5, 0.56)
		match st:
			"owned":
				bg = Color(0.42, 0.32, 0.1, 0.98)
				border = UiKit.COL_GOLD
				text = Color(1.0, 0.95, 0.8)
			"buyable":
				bg = Color(0.06, 0.16, 0.2, 0.98)
				border = UiKit.COL_ACCENT
				text = Color.WHITE
			"no_shard":
				border = Color(0.45, 0.6, 0.65)
				text = Color(0.75, 0.8, 0.85)
		for style_name: String in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(style_name, _style(bg, border, 2))
		b.add_theme_stylebox_override("focus", _style(Color(1, 1, 1, 0.06), Color.WHITE, 3))
		b.add_theme_color_override("font_color", text)
		b.add_theme_color_override("font_hover_color", text)
		b.add_theme_color_override("font_focus_color", text)
	_shards.text = tr("CORE_SHARDS") % state.item_count(core.shard_item)
	queue_redraw()


## Focus the first node worth looking at: a buyable one, else the root.
func focus_first() -> void:
	for id in core.order:
		if core.status(state, id) == "buyable":
			buttons[id].grab_focus.call_deferred()
			return
	if not core.order.is_empty():
		buttons[core.order[0]].grab_focus.call_deferred()


func _draw() -> void:
	for id in core.order:
		var a := _centre(id)
		for req: Variant in core.nodes[id].get("requires", []):
			var owned := state.soul_core.has(id) and state.soul_core.has(str(req))
			draw_line(a, _centre(str(req)), UiKit.COL_GOLD if owned else Color(0.35, 0.36, 0.42), 4.0 if owned else 2.0)


func _on_pressed(id: String) -> void:
	_show_info(id)
	if core.can_buy(state, id):
		buy_requested.emit(id)


func _show_info(id: String) -> void:
	var effect: Dictionary = core.nodes[id].get("effect", {})
	var key := _effect_key(id)
	var amount := float(effect.get(key, 0.0))
	# Fractions show as percentages.
	var shown := int(round(amount * 100.0)) if amount < 1.0 else int(amount)
	_info.text = "%s   ·   %s" % [tr("CORE_EFFECT_" + key.to_upper()) % shown,
		tr("CORE_STATUS_" + core.status(state, id).to_upper())]


func _effect_key(id: String) -> String:
	var effect: Dictionary = core.nodes[id].get("effect", {})
	for k: Variant in effect.keys():
		return str(k)
	return ""


func _cell(id: String) -> Vector2i:
	var p: Array = core.nodes[id].get("pos", [0, 0])
	return Vector2i(int(p[0]), int(p[1]))


func _centre(id: String) -> Vector2:
	return _origin + Vector2(_cell(id) - _min) * CELL + Vector2(CELL, CELL) * 0.5


func _style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(width)
	sb.set_corner_radius_all(int(NODE * 0.5))
	return sb
