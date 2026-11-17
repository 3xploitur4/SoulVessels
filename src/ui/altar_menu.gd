class_name AltarMenu
extends CanvasLayer
## The Soul Altar menu (story 017): rested message, Loadout (pick up to 3 unlocked Vessels, order
## = wheel order), Soul Core (story 020), Lore (read found entries), Leave. Pauses the tree. Reads
## the game state to display and emits requests; the game scene applies them (`ui-code` rule).
##
##     var m := AltarMenu.new()
##     m.state = game_state; m.altar_name = tr("ALTAR_Z1_A")
##     m.loadout_requested.connect(...)
##     add_child(m)

signal loadout_requested(vessel_ids: Array[String])
signal lore_read_requested(lore_id: String)
signal core_buy_requested(node_id: String)
signal leave_requested
## Reforge this Vessel's weapon (story 036).
signal reforge_requested(vessel_id: String)
## Craft one of this item.
signal craft_requested(item: String)

var state: GameState
## The Soul Core tree, to draw (never to change).
var soul_core: SoulCore
var reforge: Reforge
var altar_name: String = ""

var _root: Control
var _page: Control
var _working: Array[String] = []
var _core_view: SoulCoreView


func _ready() -> void:
	name = "AltarMenu"
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.theme = UiKit.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.02, 0.04, 0.78)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	show_main()


func show_main() -> void:
	var col := _new_page()
	var heading := UiKit.heading(altar_name, 56)
	heading.custom_minimum_size.x = 1100.0
	col.add_child(heading)
	col.add_child(UiKit.rule(520.0))
	col.add_child(UiKit.label(tr("ALTAR_RESTED"), 26, UiKit.COL_DIM))
	var items: Array[Control] = []
	var pages := [["ALTAR_LOADOUT", "Loadout", show_loadout], ["ALTAR_SOUL_CORE", "SoulCore", show_core],
		["ALTAR_REFORGE", "Reforge", show_reforge], ["ALTAR_LORE", "Lore", show_lore], ["ALTAR_LEAVE", "Leave", func() -> void: leave_requested.emit()]]
	for p: Array in pages:
		var b := UiKit.button(tr(str(p[0])), 520.0)
		b.name = str(p[1])
		b.pressed.connect(p[2] as Callable)
		col.add_child(b)
		items.append(b)
	UiKit.link_focus(items)


# --- Loadout --------------------------------------------------------------------------------

func show_loadout() -> void:
	_working = state.loadout.duplicate()
	_draw_loadout()


func _draw_loadout() -> void:
	var col := _new_page()
	col.add_child(UiKit.heading(tr("ALTAR_LOADOUT"), 48))
	col.add_child(UiKit.label(tr("ALTAR_LOADOUT_HELP"), 22, UiKit.COL_DIM))
	var items: Array[Control] = []
	for v in state.unlocked_vessels:
		var i := _working.find(v)
		var text := tr("VESSEL_" + v.to_upper())
		text = (tr("ALTAR_SLOT_N") % [i + 1, text]) if i >= 0 else (tr("ALTAR_RESTING") % text)
		var b := UiKit.button(text, 560.0)
		b.name = "Vessel_" + v
		b.pressed.connect(_toggle.bind(v))
		col.add_child(b)
		items.append(b)
	var confirm := UiKit.button(tr("ALTAR_CONFIRM"), 560.0)
	confirm.name = "ConfirmLoadout"
	confirm.disabled = _working.is_empty()
	confirm.pressed.connect(func() -> void:
		loadout_requested.emit(_working.duplicate())
		show_main())
	col.add_child(confirm)
	items.append(confirm)
	var back := UiKit.button(tr("UI_BACK"), 560.0)
	back.pressed.connect(show_main)
	col.add_child(back)
	items.append(back)
	UiKit.link_focus(items)


## Tap a Vessel: an equipped one leaves the wheel, a resting one joins at the end (max 3).
func _toggle(v: String) -> void:
	if _working.has(v):
		_working.erase(v)
	elif _working.size() < Loadout.MAX_SLOTS:
		_working.append(v)
	_draw_loadout()


# --- Soul Core --------------------------------------------------------------------------------

func show_core() -> void:
	var col := _new_page()
	col.add_child(UiKit.heading(tr("ALTAR_SOUL_CORE"), 48))
	var back := UiKit.button(tr("UI_BACK"), 520.0)
	back.name = "CoreBack"
	back.pressed.connect(show_main)
	_core_view = null
	if soul_core != null:
		_core_view = SoulCoreView.new()
		_core_view.name = "SoulCoreView"
		_core_view.core = soul_core
		_core_view.state = state
		_core_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_core_view.buy_requested.connect(func(id: String) -> void: core_buy_requested.emit(id))
		col.add_child(_core_view)
	col.add_child(back)
	if _core_view != null:
		_core_view.focus_first()
	else:
		UiKit.link_focus([back] as Array[Control])


## Redraw the tree after the game applied a purchase.
func refresh_core() -> void:
	if _core_view != null and is_instance_valid(_core_view):
		_core_view.refresh()


# --- Reforge (story 036) ------------------------------------------------------------------

## Each held Vessel's weapon: its level, the next level's cost against what is held, and a
## button; then the Censer Core recipe. The game applies a press and calls this again.
func show_reforge() -> void:
	var col := _new_page()
	col.add_child(UiKit.heading(tr("ALTAR_REFORGE"), 48))
	col.add_child(UiKit.label(tr("REFORGE_ESSENCE") % state.essence, 26, UiKit.COL_GOLD))
	var items: Array[Control] = []
	for v: String in state.unlocked_vessels:
		var lvl := reforge.level(state, v) if reforge != null else 0
		var name := tr("VESSEL_" + v.to_upper())
		var cost := reforge.next_cost(state, v) if reforge != null else {}
		var line := tr("REFORGE_ROW") % [name, lvl]
		if reforge != null and reforge.has_coating_slot(lvl):
			line += "   " + tr("REFORGE_COATING")
		col.add_child(UiKit.label(line, 28, UiKit.COL_TEXT))
		if cost.is_empty():
			col.add_child(UiKit.label(tr("REFORGE_MAX"), 24, UiKit.COL_DIM))
			continue
		var options: Array[String] = []
		for opt: Dictionary in cost.get("materials", []):
			var parts: Array[String] = []
			for item: String in opt.keys():
				parts.append("%s x%d (%d)" % [tr("ITEM_" + item.to_upper()), int(opt[item]), state.item_count(item)])
			options.append(", ".join(parts))
		col.add_child(UiKit.label(tr("REFORGE_NEXT") % [int(cost["level"]), int(cost["essence"]),
			tr("REFORGE_OR").join(options)], 22, UiKit.COL_DIM))
		var b := UiKit.button(tr("REFORGE_BUTTON") % [name, int(cost["level"])], 560.0)
		b.name = "Reforge_" + v
		b.disabled = not reforge.can_reforge(state, v)
		b.pressed.connect(func() -> void: reforge_requested.emit(v))
		col.add_child(b)
		items.append(b)
	if reforge != null and reforge.craft_recipes.has("censer_core"):
		var cb := UiKit.button(tr("CRAFT_CENSER") % state.item_count("tarnished_censer_shard"), 560.0)
		cb.name = "Craft_censer_core"
		cb.disabled = not reforge.can_craft(state, "censer_core")
		cb.pressed.connect(func() -> void: craft_requested.emit("censer_core"))
		col.add_child(cb)
		items.append(cb)
	var back := UiKit.button(tr("UI_BACK"), 560.0)
	back.name = "ReforgeBack"
	back.pressed.connect(show_main)
	col.add_child(back)
	items.append(back)
	var enabled: Array[Control] = []
	for c in items:
		if not (c as Button).disabled:
			enabled.append(c)
	UiKit.link_focus(enabled)


# --- Lore -----------------------------------------------------------------------------------

func show_lore() -> void:
	var col := _new_page()
	col.add_child(UiKit.heading(tr("ALTAR_LORE"), 48))
	var items: Array[Control] = []
	if state.lore_found.is_empty():
		col.add_child(UiKit.label(tr("UI_LORE_EMPTY"), 24, UiKit.COL_DIM))
	for id in state.lore_found:
		var unread := not state.lore_read.has(id)
		var b := UiKit.button(("• " if unread else "") + tr(LoreDb.title_key(id)), 640.0)
		b.name = "Lore_" + id
		b.pressed.connect(_read.bind(id))
		col.add_child(b)
		items.append(b)
	var back := UiKit.button(tr("UI_BACK"), 640.0)
	back.pressed.connect(show_main)
	col.add_child(back)
	items.append(back)
	UiKit.link_focus(items)


func _read(id: String) -> void:
	lore_read_requested.emit(id)
	var col := _new_page()
	col.add_child(UiKit.heading(tr(LoreDb.title_key(id)), 40))
	col.add_child(UiKit.rule())
	var body := UiKit.label(tr(LoreDb.body_key(id)), 26, UiKit.COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	body.custom_minimum_size = Vector2(1100, 0)
	col.add_child(body)
	var back := UiKit.button(tr("UI_BACK"), 520.0)
	back.name = "LoreBack"
	back.pressed.connect(show_lore)
	col.add_child(back)
	UiKit.link_focus([back] as Array[Control])


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		leave_requested.emit()
		get_viewport().set_input_as_handled()


func _new_page() -> VBoxContainer:
	if _page != null:
		_page.queue_free()
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(holder)
	_page = holder
	return UiKit.centre_column(holder)
