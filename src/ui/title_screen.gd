class_name TitleScreen
extends CanvasLayer
## Title screen (story 016): the game's name, three save-slot cards, and per-slot pages: New Game
## with a difficulty choice for an empty slot; Continue or Delete (with a confirm) for a used one.
## Display only: it emits requests and the game scene acts on them (`ui-code` rule).
##
##     var t := TitleScreen.new()
##     t.summaries = [saves.summary(0), saves.summary(1), saves.summary(2)]
##     t.new_game_requested.connect(...)
##     add_child(t)

signal new_game_requested(slot: int, difficulty: String)
signal continue_requested(slot: int)
signal delete_requested(slot: int)

## One `SaveSystem.summary` per slot.
var summaries: Array[Dictionary] = []

var _root: Control
var _page: Control


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.theme = UiKit.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.02, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(shade)
	show_slots()


## Replace the slot summaries (after a delete) and show the slot list again.
func refresh(new_summaries: Array[Dictionary]) -> void:
	summaries = new_summaries
	show_slots()


func show_slots() -> void:
	var col := _new_page()
	col.add_child(UiKit.label(tr("TITLE_GAME"), 96, UiKit.COL_TEXT))
	col.add_child(UiKit.label(tr("TITLE_SUBTITLE"), 30, UiKit.COL_DIM))
	col.add_child(_spacer(24))
	var buttons: Array[Control] = []
	for i in range(3):
		var b := UiKit.button(_slot_text(i), 760.0)
		b.custom_minimum_size.y = 96.0
		b.name = "Slot%d" % i
		b.pressed.connect(_on_slot.bind(i))
		col.add_child(b)
		buttons.append(b)
	UiKit.link_focus(buttons)


func _slot_text(i: int) -> String:
	var s: Dictionary = summaries[i] if i < summaries.size() else {"exists": false}
	if not bool(s.get("exists", false)):
		return tr("TITLE_SLOT_EMPTY") % (i + 1)
	var room := WorldData.room(str(s.get("room", "")))
	var place := tr(room.name_key) if room != null else "?"
	return tr("TITLE_SLOT_USED") % [i + 1, place, UiKit.format_time(float(s.get("play_time_s", 0.0))),
		int(s.get("essence", 0)), tr("DIFFICULTY_" + str(s.get("difficulty", "normal")).to_upper())]


func _on_slot(i: int) -> void:
	var s: Dictionary = summaries[i] if i < summaries.size() else {}
	if bool(s.get("exists", false)):
		_show_used(i)
	else:
		_show_difficulty(i)


func _show_difficulty(i: int) -> void:
	var col := _new_page()
	col.add_child(UiKit.label(tr("TITLE_CHOOSE_DIFFICULTY"), 44))
	var buttons: Array[Control] = []
	for d: String in ["story", "normal"]:
		var b := UiKit.button(tr("DIFFICULTY_" + d.to_upper()), 560.0)
		b.name = "Difficulty_" + d
		b.pressed.connect(func() -> void: new_game_requested.emit(i, d))
		col.add_child(b)
		col.add_child(UiKit.label(tr("DIFFICULTY_%s_DESC" % d.to_upper()), 22, UiKit.COL_DIM))
		buttons.append(b)
	var abyssal := UiKit.button(tr("DIFFICULTY_ABYSSAL"), 560.0)
	abyssal.disabled = true
	col.add_child(abyssal)
	col.add_child(UiKit.label(tr("DIFFICULTY_ABYSSAL_LOCKED"), 22, UiKit.COL_DIM))
	var back := UiKit.button(tr("UI_BACK"), 560.0)
	back.pressed.connect(show_slots)
	col.add_child(back)
	buttons.append(back)
	UiKit.link_focus(buttons)


func _show_used(i: int) -> void:
	var col := _new_page()
	col.add_child(UiKit.label(_slot_text(i), 30))
	var cont := UiKit.button(tr("TITLE_CONTINUE"), 560.0)
	cont.name = "Continue"
	cont.pressed.connect(func() -> void: continue_requested.emit(i))
	var del := UiKit.button(tr("TITLE_DELETE"), 560.0)
	del.name = "Delete"
	del.pressed.connect(_confirm_delete.bind(i))
	var back := UiKit.button(tr("UI_BACK"), 560.0)
	back.pressed.connect(show_slots)
	for b: Button in [cont, del, back]:
		col.add_child(b)
	UiKit.link_focus([cont, del, back] as Array[Control])


func _confirm_delete(i: int) -> void:
	var col := _new_page()
	col.add_child(UiKit.label(tr("TITLE_DELETE_CONFIRM") % (i + 1), 34))
	var no := UiKit.button(tr("UI_NO"), 420.0)
	no.pressed.connect(_show_used.bind(i))
	var yes := UiKit.button(tr("UI_YES_DELETE"), 420.0)
	yes.name = "ConfirmDelete"
	yes.pressed.connect(func() -> void: delete_requested.emit(i))
	col.add_child(no)
	col.add_child(yes)
	UiKit.link_focus([no, yes] as Array[Control])


func _new_page() -> VBoxContainer:
	if _page != null:
		_page.queue_free()
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(holder)
	_page = holder
	return UiKit.centre_column(holder)


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## Android back / Esc on a sub-page returns to the slot list.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		show_slots()
		get_viewport().set_input_as_handled()
