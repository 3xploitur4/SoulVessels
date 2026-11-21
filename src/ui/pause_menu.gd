class_name PauseMenu
extends CanvasLayer
## Pause (story 016): Resume, Map, Inventory, Lore, Settings (story 059: volumes and this game's
## difficulty), Quit to title. Pauses the tree while open; reads the game state to show it and never
## changes it (`ui-code` rule): Resume, Quit and a new difficulty are requests the game scene
## carries out.
##
##     var pm := PauseMenu.new()
##     pm.state = game_state
##     pm.resume_requested.connect(...)
##     add_child(pm)

signal resume_requested
signal quit_requested
signal difficulty_requested(difficulty: String)

var state: GameState
## Where the player stands in the current room (story 054: the map marks it).
var player_pos: Vector2 = Vector2(-1.0, -1.0)
## May this game's difficulty be set to Abyssal (Chapter I finished once)?
var abyssal_unlocked: bool = false

var _root: Control
var _content: Control
var _tabs: Array[Control] = []


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.theme = UiKit.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0.02, 0.72)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 80
	row.offset_top = 80
	row.offset_right = -80
	row.offset_bottom = -80
	row.add_theme_constant_override("separation", 40)
	_root.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(380, 0)
	row.add_child(left)
	var title := UiKit.heading(tr("UI_PAUSE"), 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	left.add_child(title)
	var pages := [["UI_RESUME", "resume"], ["UI_MAP", "map"], ["UI_INVENTORY", "inventory"],
		["UI_LORE", "lore"], ["UI_SETTINGS", "settings"], ["UI_QUIT_TO_TITLE", "quit"]]
	for p: Array in pages:
		var b := UiKit.button(tr(str(p[0])), 360.0)
		b.name = "Tab_" + str(p[1])
		b.pressed.connect(_on_tab.bind(str(p[1])))
		b.focus_entered.connect(_on_focus.bind(str(p[1])))
		left.add_child(b)
		_tabs.append(b)
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(panel)
	_content = MarginContainer.new()
	panel.add_child(_content)
	UiKit.link_focus(_tabs)
	_show_map()


func _on_focus(page: String) -> void:
	match page:
		"map":
			_show_map()
		"inventory":
			_show_inventory()
		"lore":
			_show_lore()
		"settings":
			_show_settings()


func _on_tab(page: String) -> void:
	match page:
		"resume":
			resume_requested.emit()
		"quit":
			quit_requested.emit()
		"settings":
			_show_settings()
			# Pressing the tab (or a gamepad's confirm) steps into the page.
			_settings_panel().focus_first()
		"inventory":
			_show_inventory()
			var inv := _content.get_node_or_null("Inventory") as InventoryView
			if inv != null:
				inv.focus_first()
		_:
			_on_focus(page)


func _unhandled_input(event: InputEvent) -> void:
	# Back inside the settings page returns to its tab; anywhere else it closes the menu.
	var focus := _root.get_viewport().gui_get_focus_owner()
	if event.is_action_pressed("ui_cancel") and focus != null and _content.is_ancestor_of(focus):
		var page := "Tab_inventory" if _content.get_node_or_null("Inventory") != null else "Tab_settings"
		(_root.find_child(page, true, false) as Control).grab_focus()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		resume_requested.emit()
		get_viewport().set_input_as_handled()


func _clear() -> void:
	for c in _content.get_children():
		c.queue_free()


func _show_map() -> void:
	_clear()
	var m := MapView.new()
	m.name = "Map"
	m.zone = WorldData.zone_of(state.current_room) if state != null else "zone1"
	if state != null:
		m.visited = state.visited_rooms
		m.current = state.current_room
		m.lit_altars = state.lit_altars
		m.echo_room = str(state.echo.get("room", ""))
		m.flags = state.flags
	m.player_pos = player_pos
	m.custom_minimum_size = Vector2(1180, 640)
	_content.add_child(m)


func _show_inventory() -> void:
	_clear()
	# Story 060: icon tiles with counts, the selected item large beside them.
	var v := InventoryView.new()
	v.name = "Inventory"
	v.state = state
	_content.add_child(v)


func _show_lore() -> void:
	_clear()
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(900, 560)
	_content.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	if state == null or state.lore_found.is_empty():
		v.add_child(UiKit.label(tr("UI_LORE_EMPTY"), 26, UiKit.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT))
		return
	for id in state.lore_found:
		v.add_child(UiKit.label(tr(LoreDb.title_key(id)), 28, UiKit.COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
		v.add_child(UiKit.label(tr(LoreDb.body_key(id)), 22, UiKit.COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT))


func _show_settings() -> void:
	if _settings_panel() != null:
		return
	_clear()
	var p := SettingsPanel.new()
	p.name = "Settings"
	p.difficulty = state.difficulty if state != null else "normal"
	p.abyssal_unlocked = abyssal_unlocked
	p.difficulty_requested.connect(func(d: String) -> void: difficulty_requested.emit(d))
	_content.add_child(p)


## The settings page when it is showing (null otherwise).
func _settings_panel() -> SettingsPanel:
	for c in _content.get_children():
		if c is SettingsPanel and not c.is_queued_for_deletion():
			return c as SettingsPanel
	return null
