class_name InventoryView
extends HBoxContainer
## The inventory page of the pause menu (story 060, decision D-071): every item carried as a tile
## with its painted icon (recoloured per item, data/progression/item_icons.json), a frame in its
## rarity colour, a soft glow and the count; the Essence above. Selecting a tile (focus, hover or
## a tap) shows it large on the right with its name, rarity and description. Display only.
##
##     var v := InventoryView.new()
##     v.state = game_state
##     add_child(v)

const ICONS_PATH := "res://data/progression/item_icons.json"
const ART_DIR := "res://assets/art/props/item_"
const TILE := 132.0
const COLS := 5

var state: GameState
## Item id of each tile, in order (tests).
var tiles: Array[String] = []

static var _icons: Dictionary = {}
static var _shader: Shader

var _big: TextureRect
var _name: Label
var _rarity: Label
var _desc: Label
var _grid: GridContainer


## The icon settings of `id`: {"art", "tint", "amount", "glow"}.
static func icon_spec(id: String) -> Dictionary:
	if _icons.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(ICONS_PATH))
		_icons = (d as Dictionary).get("icons", {}) if d is Dictionary else {}
	if _icons.has(id):
		return _icons[id]
	var art := Pickup.icon_for(id).trim_prefix("item_")
	return {"art": art, "tint": "#ffffff", "amount": 0.0, "glow": "#c8a870"}


## A TextureRect showing item `id`'s icon, `size` pixels square, recoloured.
static func icon_rect(id: String, size: float) -> TextureRect:
	var spec := icon_spec(id)
	var t := TextureRect.new()
	t.texture = TexBank.get_tex(ART_DIR + str(spec.get("art", "core")) + ".png")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(size, size)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _shader == null:
		_shader = load("res://src/ui/canvas_icon_tint.gdshader") as Shader
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("tint", Color(str(spec.get("tint", "#ffffff"))))
	m.set_shader_parameter("amount", float(spec.get("amount", 0.0)))
	t.material = m
	return t


func _ready() -> void:
	add_theme_constant_override("separation", 36)
	var left := VBoxContainer.new()
	add_child(left)
	var essence := HBoxContainer.new()
	left.add_child(essence)
	var gem := Label.new()
	gem.text = "◆"
	gem.add_theme_font_size_override("font_size", 30)
	gem.add_theme_color_override("font_color", UiKit.COL_ACCENT)
	essence.add_child(gem)
	var amount := UiKit.label("%s   %d" % [tr("HUD_ESSENCE"), state.essence if state != null else 0], 30,
		UiKit.COL_ACCENT, HORIZONTAL_ALIGNMENT_LEFT)
	amount.autowrap_mode = TextServer.AUTOWRAP_OFF
	essence.add_child(amount)
	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	left.add_child(_grid)
	var buttons: Array[Button] = []
	for id in ItemDb.ids():
		var n := state.item_count(id) if state != null else 0
		if n <= 0:
			continue
		var b := _tile(id, n)
		_grid.add_child(b)
		buttons.append(b)
		tiles.append(id)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 420.0
	add_child(right)
	if tiles.is_empty():
		var empty := UiKit.label(tr("UI_INVENTORY_EMPTY"), 26, UiKit.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
		empty.autowrap_mode = TextServer.AUTOWRAP_OFF
		left.add_child(empty)
		return
	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(260, 260)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	right.add_child(frame)
	_big = TextureRect.new()
	_big.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_big.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_big.custom_minimum_size = Vector2(230, 230)
	frame.add_child(_big)
	_name = UiKit.label("", 32, UiKit.COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	right.add_child(_name)
	_rarity = UiKit.label("", 22, UiKit.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	right.add_child(_rarity)
	_desc = UiKit.label("", 24, UiKit.COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_desc.custom_minimum_size.x = 420.0
	right.add_child(_desc)
	show_item(tiles[0])


## Show item `id` large with its name, rarity and description.
func show_item(id: String) -> void:
	if _big == null:
		return
	var r := icon_rect(id, 230.0)
	_big.texture = r.texture
	_big.material = r.material
	r.free()
	_name.text = tr(ItemDb.name_key(id))
	_name.add_theme_color_override("font_color", ItemDb.color(id))
	_rarity.text = tr("RARITY_" + ItemDb.rarity(id).to_upper())
	_desc.text = tr(ItemDb.desc_key(id))


## The first tile, to take the focus (a gamepad entering the page).
func focus_first() -> void:
	if _grid != null and _grid.get_child_count() > 0:
		(_grid.get_child(0) as Control).grab_focus()


func _tile(id: String, count: int) -> Button:
	var b := Button.new()
	b.name = "Item_" + id
	b.custom_minimum_size = Vector2(TILE, TILE)
	b.focus_mode = Control.FOCUS_ALL
	var col := ItemDb.color(id)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.035, 0.06, 0.95)
	sb.border_color = col.darkened(0.25)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	b.add_theme_stylebox_override("normal", sb)
	var hover := sb.duplicate() as StyleBoxFlat
	hover.border_color = col.lightened(0.2)
	hover.set_border_width_all(3)
	hover.bg_color = Color(col.r, col.g, col.b, 0.12)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", hover)
	# A soft glow behind the icon, in the item's own colour.
	var glow := TextureRect.new()
	glow.texture = SpriteArt.blob()
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	glow.modulate = Color(str(icon_spec(id).get("glow", "#c8a870")))
	glow.modulate.a = 0.35
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(glow)
	var icon := icon_rect(id, TILE - 26.0)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 13
	icon.offset_top = 13
	icon.offset_right = -13
	icon.offset_bottom = -13
	b.add_child(icon)
	if count > 1:
		var n := UiKit.label("x%d" % count, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT)
		n.autowrap_mode = TextServer.AUTOWRAP_OFF
		n.add_theme_constant_override("outline_size", 6)
		n.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		n.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		n.offset_left = -60
		n.offset_top = -36
		n.offset_right = -6
		n.offset_bottom = -2
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(n)
	b.focus_entered.connect(show_item.bind(id))
	b.mouse_entered.connect(show_item.bind(id))
	b.pressed.connect(show_item.bind(id))
	return b
