class_name SettingsPanel
extends VBoxContainer
## The settings page (story 059, decision D-070), on the title screen and in the pause menu:
## four volume sliders (the whole game, music, sound effects, ambience) that apply as they move
## and are saved at once (`GameSettings`), each with its percentage and a sample sound so the level
## can be heard; and, in a game, the difficulty of that game (Story, Normal, Abyssal once Chapter I
## is done). The difficulty belongs to the save, so the panel only asks for it
## (`difficulty_requested`); the game changes it. Works with a mouse, a keyboard or a gamepad:
## up and down move between rows, left and right move a slider.
##
##     var p := SettingsPanel.new()
##     p.difficulty = state.difficulty          # "" on the title screen: no difficulty row
##     p.abyssal_unlocked = saves.chapter_complete()
##     p.difficulty_requested.connect(game.set_difficulty)
##     add_child(p)

signal difficulty_requested(difficulty: String)

const ROWS := [["master", "SET_MASTER"], ["music", "SET_MUSIC"], ["effects", "SET_EFFECTS"], ["ambience", "SET_AMBIENCE"]]
## A sample per slider so the new level can be heard ("" = the music itself is the sample).
const SAMPLES := {"master": "slash", "music": "", "effects": "hit", "ambience": "amb_drip"}
const DIFFICULTIES: Array[String] = ["story", "normal", "abyssal"]

## The game's difficulty ("" hides the difficulty row: no game is running).
var difficulty: String = ""
var abyssal_unlocked: bool = false

var sliders: Dictionary[String, HSlider] = {}
var spoken_button: Button
var difficulty_buttons: Dictionary[String, Button] = {}
var _values: Dictionary[String, Label] = {}
var _desc: Label
var _sample_left: float = 0.0
var _pending_sample: String = ""


func _ready() -> void:
	add_theme_constant_override("separation", 18)
	add_child(UiKit.label(tr("UI_SETTINGS"), 36, UiKit.COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	for row: Array in ROWS:
		_slider_row(str(row[0]), tr(str(row[1])))
	# Story 060: spoken voices in conversations.
	var voices := HBoxContainer.new()
	add_child(voices)
	var vl := UiKit.label(tr("SET_SPOKEN"), 28, UiKit.COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	vl.custom_minimum_size.x = 300.0
	vl.autowrap_mode = TextServer.AUTOWRAP_OFF
	voices.add_child(vl)
	spoken_button = UiKit.button(tr("UI_ON") if GameSettings.spoken else tr("UI_OFF"), 160.0)
	spoken_button.name = "Spoken"
	spoken_button.pressed.connect(_toggle_spoken)
	voices.add_child(spoken_button)
	var vh := UiKit.label(tr("SET_SPOKEN_HINT"), 20, UiKit.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	vh.custom_minimum_size.x = 760.0
	add_child(vh)
	if difficulty != "":
		add_child(_spacer(10))
		add_child(UiKit.label(tr("SET_DIFFICULTY"), 30, UiKit.COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
		var line := HBoxContainer.new()
		add_child(line)
		for d in DIFFICULTIES:
			var b := UiKit.button(tr("DIFFICULTY_" + d.to_upper()), 220.0)
			b.name = "Difficulty_" + d
			b.toggle_mode = true
			b.disabled = d == "abyssal" and not abyssal_unlocked
			b.pressed.connect(_on_difficulty.bind(d))
			line.add_child(b)
			difficulty_buttons[d] = b
		_desc = UiKit.label("", 22, UiKit.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
		_desc.custom_minimum_size.x = 760.0
		add_child(_desc)
		_show_difficulty(difficulty)
	else:
		var hint := UiKit.label(tr("SET_DIFFICULTY_HINT"), 22, UiKit.COL_DIM, HORIZONTAL_ALIGNMENT_LEFT)
		hint.custom_minimum_size.x = 760.0
		add_child(hint)
	_link_focus()


## Put the focus on the first slider (a gamepad entering the page).
func focus_first() -> void:
	sliders["master"].grab_focus()


func _process(delta: float) -> void:
	# A sample plays a moment after the slider stops, not on every step of a drag.
	if _sample_left > 0.0:
		_sample_left -= delta
		if _sample_left <= 0.0 and _pending_sample != "":
			if _pending_sample.begins_with("amb_"):
				var p := AudioStreamPlayer.new()
				p.bus = "Ambience"
				p.stream = load("res://assets/audio/ambience/%s.wav" % _pending_sample) as AudioStream
				add_child(p)
				p.play()
				p.finished.connect(p.queue_free)
			else:
				Sfx.play(_pending_sample)
			_pending_sample = ""


func _slider_row(key: String, text: String) -> void:
	var line := HBoxContainer.new()
	add_child(line)
	var name_label := UiKit.label(text, 28, UiKit.COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.custom_minimum_size.x = 300.0
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(name_label)
	var s := HSlider.new()
	s.name = "Volume_" + key
	s.min_value = 0.0
	s.max_value = 100.0
	s.step = 5.0
	s.value = round(GameSettings.volume(key) * 100.0)
	s.custom_minimum_size = Vector2(380.0, 48.0)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_ALL
	s.value_changed.connect(_on_volume.bind(key))
	line.add_child(s)
	var value := UiKit.label("%d %%" % int(s.value), 28, UiKit.COL_ACCENT, HORIZONTAL_ALIGNMENT_RIGHT)
	value.custom_minimum_size.x = 110.0
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	line.add_child(value)
	sliders[key] = s
	_values[key] = value


func _on_volume(v: float, key: String) -> void:
	GameSettings.set_volume(key, v / 100.0)
	_values[key].text = "%d %%" % int(v)
	if str(SAMPLES[key]) != "":
		_pending_sample = str(SAMPLES[key])
		_sample_left = 0.25


func _toggle_spoken() -> void:
	GameSettings.set_spoken(not GameSettings.spoken)
	spoken_button.text = tr("UI_ON") if GameSettings.spoken else tr("UI_OFF")


func _on_difficulty(d: String) -> void:
	if d == difficulty:
		_show_difficulty(d)
		return
	difficulty = d
	_show_difficulty(d)
	difficulty_requested.emit(d)


func _show_difficulty(d: String) -> void:
	for k: String in difficulty_buttons.keys():
		difficulty_buttons[k].set_pressed_no_signal(k == d)
	if _desc != null:
		var key := "DIFFICULTY_%s_DESC" % d.to_upper()
		_desc.text = "%s: %s" % [tr("DIFFICULTY_" + d.to_upper()), tr(key)]


## Up and down walk the rows, left and right stay inside a slider or the difficulty line.
func _link_focus() -> void:
	var rows: Array[Control] = []
	for row: Array in ROWS:
		rows.append(sliders[str(row[0])])
	var diff: Array[Control] = []
	for d in DIFFICULTIES:
		if difficulty_buttons.has(d) and not difficulty_buttons[d].disabled:
			diff.append(difficulty_buttons[d])
	rows.append(spoken_button)
	for i in range(rows.size()):
		var c := rows[i]
		var up: Control = rows[i - 1] if i > 0 else c
		var down: Control = rows[i + 1] if i < rows.size() - 1 else (diff[0] if not diff.is_empty() else c)
		c.focus_neighbor_top = c.get_path_to(up)
		c.focus_neighbor_bottom = c.get_path_to(down)
	for i in range(diff.size()):
		var b := diff[i]
		b.focus_neighbor_top = b.get_path_to(rows[rows.size() - 1])
		b.focus_neighbor_bottom = b.get_path_to(b)
		b.focus_neighbor_left = b.get_path_to(diff[i - 1] if i > 0 else b)
		b.focus_neighbor_right = b.get_path_to(diff[i + 1] if i < diff.size() - 1 else b)


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c
