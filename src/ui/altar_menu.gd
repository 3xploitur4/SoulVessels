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

var state: GameState
var altar_name: String = ""

var _root: Control
var _page: Control
var _working: Array[String] = []


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
	var heading := UiKit.label(altar_name, 52, UiKit.COL_GOLD)
	heading.custom_minimum_size.x = 1100.0
	col.add_child(heading)
	col.add_child(UiKit.label(tr("ALTAR_RESTED"), 26, UiKit.COL_DIM))
	var items: Array[Control] = []
	var pages := [["ALTAR_LOADOUT", "Loadout", show_loadout], ["ALTAR_SOUL_CORE", "SoulCore", show_core],
		["ALTAR_LORE", "Lore", show_lore], ["ALTAR_LEAVE", "Leave", func() -> void: leave_requested.emit()]]
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
	col.add_child(UiKit.label(tr("ALTAR_LOADOUT"), 44))
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


# --- Soul Core (story 020 fills the page) -----------------------------------------------------

func show_core() -> void:
	var col := _new_page()
	col.add_child(UiKit.label(tr("ALTAR_SOUL_CORE"), 44))
	var back := UiKit.button(tr("UI_BACK"), 520.0)
	back.pressed.connect(show_main)
	col.add_child(back)
	UiKit.link_focus([back] as Array[Control])


# --- Lore -----------------------------------------------------------------------------------

func show_lore() -> void:
	var col := _new_page()
	col.add_child(UiKit.label(tr("ALTAR_LORE"), 44))
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
	col.add_child(UiKit.label(tr(LoreDb.title_key(id)), 40, UiKit.COL_GOLD))
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
