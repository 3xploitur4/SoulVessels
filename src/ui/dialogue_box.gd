class_name DialogueBox
extends CanvasLayer
## Conversations and spoken lines (story 060, decision D-071). A box at the bottom of the screen
## with the speaker's portrait (cut from their painting; the voice in the walls a pale ghost), a
## name plate in their colour, and the line typing out as they speak. Each speaker has a voice:
## the device reads the line aloud when spoken voices are on (`GameSettings.spoken`), or a murmur
## of syllables plays as the text appears. Three ways in:
##
## - `play(id)`: a conversation (data/narrative/conversations.json) when a new character is met.
##   The game waits: each press of attack, jump, interact or a tap shows the rest of the line or
##   the next one; pause or back skips it. A memory in it is read by the narrating voice.
## - `say(speaker, text, color)`: a line in passing (the voice in the walls, a companion's remark);
##   play goes on and the box fades after the line has been read.
## - `read_lore(id)`: a piece of lore just found, read aloud in passing.
##
## `auto_advance` (headless tests, `--auto-dialogue` playtests) never waits for a press: a
## conversation plays as lines in passing. Display only: the game decides when to call it.
##
##     dialogue.play("nyra")
##     dialogue.say(tr("SPEAKER_VOICE"), tr("SOV_Z1_THIEF"), Color("#b8d4ff"))

signal finished(conversation: String)

const CONV_PATH := "res://data/narrative/conversations.json"
const PORTRAIT_PATH := "res://data/narrative/portraits.json"
## Letters shown per second as a line types out.
const CHARS_PER_S := 40.0
## A murmured syllable every this many letters.
const BLIP_EVERY := 3
## Seconds a line in passing stays after it has typed out (plus a little per letter).
const HOLD_S := 2.0
const HOLD_PER_CHAR_S := 0.035
const FADE_S := 0.35
const PORTRAIT_PX := 168.0
## A line in passing sits in a smaller box at the top of the screen, clear of the player.
const PASSING_PORTRAIT_PX := 92.0
## Lines in passing waiting their turn, at most.
const QUEUE_MAX := 4
## Play resumes this long after a conversation closes, so the press that closed it does not also
## swing or jump.
const RESUME_DELAY_S := 0.12
const FEMALE_HINTS := ["zira", "hazel", "susan", "eva", "aria", "jenny", "female", "samantha", "victoria",
	"karen", "moira", "tessa", "fiona", "catherine", "linda", "heera", "sonia", "libby", "emma", "ava"]

## Never wait for a press (tests and playtests).
var auto_advance: bool = false
## The conversation playing ("" when none).
var playing: String = ""
## The last lines asked for, shown or still waiting, newest last, as "Name: text" (playtests).
var said: Array[String] = []

static var _conversations: Dictionary = {}
static var _portraits: Dictionary = {}

var _root: Control
var _panel: PanelContainer
var _portrait: TextureRect
var _portrait_frame: PanelContainer
var _name: Label
var _text: Label
var _more: Label
var _queue: Array[Dictionary] = []
var _line: Dictionary = {}
var _shown: float = 0.0
var _hold: float = 0.0
var _fade: float = 0.0
var _blocking: bool = false
var _paused_tree: bool = false
var _resuming: bool = false
var _blip_at: int = 0
var _voices: Dictionary = {}
var _time: float = 0.0


# --- Data -------------------------------------------------------------------------------------

static func conversations() -> Dictionary:
	if _conversations.is_empty() and FileAccess.file_exists(CONV_PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONV_PATH))
		_conversations = (d as Dictionary).get("conversations", {}) if d is Dictionary else {}
	return _conversations


static func portraits() -> Dictionary:
	if _portraits.is_empty() and FileAccess.file_exists(PORTRAIT_PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PORTRAIT_PATH))
		_portraits = (d as Dictionary).get("speakers", {}) if d is Dictionary else {}
	return _portraits


## The conversation started by `trigger` ("freed:nyra", "boss:guardian_below"...), or "".
static func conversation_for(trigger: String) -> String:
	var all := conversations()
	for id: String in all.keys():
		if str((all[id] as Dictionary).get("on", "")) == trigger:
			return id
	return ""


## Line keys a conversation says (a room's story line with one of these is not shown again).
static func used_keys() -> Dictionary:
	var out := {}
	var all := conversations()
	for id: String in all.keys():
		for l: Dictionary in (all[id] as Dictionary).get("lines", []):
			if l.has("line"):
				out[str(l["line"])] = true
	return out


## The speaker key whose translated name is `name` ("" when none matches).
static func speaker_key(name: String) -> String:
	var all := portraits()
	for k: String in all.keys():
		if TranslationServer.translate(k) == name:
			return k
	return ""


# --- Showing ----------------------------------------------------------------------------------

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.theme = UiKit.theme()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_panel_input)
	_root.add_child(_panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	_panel.add_child(row)
	_portrait_frame = PanelContainer.new()
	_portrait_frame.custom_minimum_size = Vector2(PORTRAIT_PX + 12, PORTRAIT_PX + 12)
	_portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.custom_minimum_size = Vector2(PORTRAIT_PX, PORTRAIT_PX)
	_portrait_frame.add_child(_portrait)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	_name = UiKit.label("", 30, UiKit.COL_GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	_name.add_theme_font_override("font", UiKit.display_font())
	col.add_child(_name)
	_text = UiKit.label("", 28, UiKit.COL_TEXT, HORIZONTAL_ALIGNMENT_LEFT)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	col.add_child(_text)
	_more = UiKit.label("▼", 24, UiKit.COL_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	col.add_child(_more)
	_root.visible = false
	_layout(false)


## A conversation (play paused) fills the bottom of the screen with a large portrait; a line in
## passing is a compact box at the top centre, between the health bar and the Vessel portraits,
## so the floor the player fights on stays in view.
func _layout(blocking: bool) -> void:
	var px := PORTRAIT_PX if blocking else PASSING_PORTRAIT_PX
	if blocking:
		_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		_panel.offset_left = 120
		_panel.offset_right = -120
		_panel.offset_top = -250
		_panel.offset_bottom = -24
	else:
		_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
		_panel.offset_left = 540
		_panel.offset_right = -540
		_panel.offset_top = 20
		_panel.offset_bottom = 20 + px + 40
	_portrait_frame.custom_minimum_size = Vector2(px + 12, px + 12)
	_portrait.custom_minimum_size = Vector2(px, px)
	_name.add_theme_font_size_override("font_size", 30 if blocking else 24)
	_text.add_theme_font_size_override("font_size", 28 if blocking else 23)


## Play conversation `id`. False when it does not exist.
func play(id: String) -> bool:
	var conv: Dictionary = conversations().get(id, {})
	if conv.is_empty():
		return false
	var lines: Array[Dictionary] = []
	for l: Dictionary in conv.get("lines", []):
		if l.has("lore"):
			lines.append(_lore_line(str(l["lore"])))
		else:
			var key := str(l.get("speaker", ""))
			lines.append({"speaker": key, "name": tr(key), "text": tr(str(l.get("line", "")))})
	playing = id
	for l in lines:
		_note(l)
	if auto_advance:
		# Nobody to press: the lines play in passing, after anything already waiting.
		for l in lines:
			_queue.append(l)
		if _line.is_empty():
			_next()
		return true
	_blocking = true
	_queue = lines
	if _resuming:
		_resuming = false
		_paused_tree = true
	elif not get_tree().paused:
		get_tree().paused = true
		_paused_tree = true
	_next()
	return true


## A line in passing from `speaker` (a display name; its portrait is found by name).
func say(speaker: String, text: String, color: Color = UiKit.COL_TEXT) -> void:
	var line := {"speaker": speaker_key(speaker), "name": speaker, "text": text, "color": color}
	_note(line)
	if _blocking or not _line.is_empty():
		if _queue.size() >= QUEUE_MAX:
			_queue.pop_front()
		_queue.append(line)
		if not _blocking and _shown >= float(_line.get("text", "").length()):
			_hold = minf(_hold, 0.6)
		return
	_queue.append(line)
	_next()


## Read lore entry `id` aloud in passing (its title as the name, its text as the line).
func read_lore(id: String) -> void:
	var line := _lore_line(id)
	_note(line)
	if _blocking or not _line.is_empty():
		_queue.append(line)
		return
	_queue.append(line)
	_next()


## The line showing (for tests and the subtitle API), "" when the box is hidden.
func current_text() -> String:
	return str(_line.get("text", "")) if _root.visible and not _line.is_empty() else ""


## The line showing as "Name: text" (the subtitle API), "" when the box is hidden.
func current_line() -> String:
	var t := current_text()
	if t == "":
		return ""
	var n := str(_line.get("name", ""))
	return "%s: %s" % [n, t] if n != "" else t


## The speaker key of the line showing.
func current_speaker() -> String:
	return str(_line.get("speaker", ""))


func is_open() -> bool:
	return _root.visible


func _note(line: Dictionary) -> void:
	said.append("%s: %s" % [line.get("name", ""), line.get("text", "")])
	if said.size() > 32:
		said.pop_front()


func _lore_line(id: String) -> Dictionary:
	return {"speaker": "SPEAKER_MEMORY", "name": tr(LoreDb.title_key(id)), "text": tr(LoreDb.body_key(id)), "lore": id}


func _next() -> void:
	_stop_voice()
	if _queue.is_empty():
		_line = {}
		_end()
		return
	_line = _queue.pop_front()
	_shown = 0.0
	_blip_at = 0
	_fade = 0.0
	var key := str(_line.get("speaker", ""))
	var spec: Dictionary = portraits().get(key, {})
	_hold = HOLD_S + HOLD_PER_CHAR_S * float(str(_line["text"]).length())
	_name.text = str(_line.get("name", ""))
	var col := Color(str(spec.get("color", ""))) if spec.has("color") else _line.get("color", UiKit.COL_GOLD) as Color
	_name.add_theme_color_override("font_color", col)
	_text.text = str(_line["text"])
	_text.visible_characters = 0
	_layout(_blocking)
	_set_portrait(spec)
	_more.visible = false
	_root.visible = true
	_root.modulate.a = 1.0
	_speak(str(_line["text"]), spec)


func _end() -> void:
	_root.visible = false
	var was := playing
	playing = ""
	if _blocking:
		_blocking = false
		if _paused_tree:
			_paused_tree = false
			_resume_later()
	if was != "":
		finished.emit(was)


func _resume_later() -> void:
	_resuming = true
	await get_tree().create_timer(RESUME_DELAY_S, true, false, true).timeout
	if _resuming:
		_resuming = false
		get_tree().paused = false


func _set_portrait(spec: Dictionary) -> void:
	_portrait_frame.visible = not spec.is_empty()
	if spec.is_empty():
		return
	var sprite := str(spec.get("sprite", ""))
	var tex: Texture2D
	if sprite.begins_with("icon:"):
		tex = TexBank.get_tex("res://assets/art/props/item_%s.png" % sprite.trim_prefix("icon:"))
	else:
		tex = SpriteArt.texture(sprite)
	if tex == null:
		_portrait_frame.visible = false
		return
	var r: Array = spec.get("region", [0.0, 0.0, 1.0, 1.0])
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	atlas.region = Rect2(float(r[0]) * w, float(r[1]) * h, float(r[2]) * w, float(r[3]) * h)
	_portrait.texture = atlas
	_portrait.modulate = Color(0.55, 0.68, 0.95, 0.6) if bool(spec.get("ghost", false)) else Color.WHITE


func _process(delta: float) -> void:
	_time += delta
	if _line.is_empty():
		return
	# A line in passing waits, unseen, while a menu has the game paused.
	if not _blocking and get_tree().paused and not _resuming:
		_root.modulate.a = 0.0
		return
	if not _blocking and _fade == 0.0:
		_root.modulate.a = 1.0
	var text := str(_line["text"])
	if _shown < float(text.length()):
		_shown = minf(_shown + CHARS_PER_S * delta, float(text.length()))
		_text.visible_characters = int(_shown)
		_murmur(text)
		return
	_text.visible_characters = -1
	if _blocking:
		_more.visible = true
		_more.modulate.a = 0.5 + 0.5 * sin(_time * 5.0)
		return
	# A line in passing: wait while it is still being read aloud, then hold, then fade.
	if _speaking():
		return
	if _hold > 0.0:
		_hold -= delta
		return
	_fade += delta
	_root.modulate.a = clampf(1.0 - _fade / FADE_S, 0.0, 1.0)
	if _fade >= FADE_S:
		_next()


func _input(event: InputEvent) -> void:
	if not _blocking or not _root.visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		_queue.clear()
		_next()
		get_viewport().set_input_as_handled()
		return
	for a: String in ["attack", "jump", "interact", "ui_accept"]:
		if event.is_action_pressed(a):
			_advance()
			get_viewport().set_input_as_handled()
			return


func _on_panel_input(event: InputEvent) -> void:
	var tap := (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if tap and _blocking:
		_advance()


## A press: the rest of the line if it is still typing, else the next line.
func _advance() -> void:
	var text := str(_line.get("text", ""))
	if _shown < float(text.length()):
		_shown = float(text.length())
		_text.visible_characters = -1
		return
	_next()


# --- Voices -----------------------------------------------------------------------------------

## A murmured syllable every few letters while the line types out (when not read aloud).
func _murmur(text: String) -> void:
	if _speaking_on():
		return
	var n := int(_shown)
	if n < _blip_at + BLIP_EVERY:
		return
	_blip_at = n
	var c := text.substr(clampi(n - 1, 0, text.length() - 1), 1)
	if c == " " or ".,!?-".contains(c):
		return
	var spec: Dictionary = portraits().get(str(_line.get("speaker", "")), {})
	var voice := str(spec.get("voice", "voice_echo"))
	Sfx.play(voice, float(spec.get("pitch", 1.0)) * randf_range(0.9, 1.12), -8.0)


func _speaking_on() -> bool:
	return GameSettings.spoken and _tts_available()


static func _tts_available() -> bool:
	return DisplayServer.get_name() != "headless" and bool(ProjectSettings.get_setting("audio/general/text_to_speech", false)) \
		and DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)


func _speaking() -> bool:
	return _speaking_on() and DisplayServer.tts_is_speaking()


func _speak(text: String, spec: Dictionary) -> void:
	if not _speaking_on():
		return
	var tts: Dictionary = spec.get("tts", {})
	var voice := _voice_id(bool(tts.get("female", false)))
	if voice == "":
		return
	var vol := int(clampf(GameSettings.volume("master") * GameSettings.volume("effects"), 0.0, 1.0) * 100.0)
	DisplayServer.tts_speak(text, voice, vol, float(tts.get("pitch", 1.0)), float(tts.get("rate", 1.0)), 0, true)


func _stop_voice() -> void:
	if _speaking_on():
		DisplayServer.tts_stop()


## An English system voice, a woman's when `female` and the system has one.
func _voice_id(female: bool) -> String:
	var key := "f" if female else "m"
	if _voices.has(key):
		return _voices[key]
	var english := DisplayServer.tts_get_voices_for_language("en")
	var all := DisplayServer.tts_get_voices()
	var pick := english[0] if not english.is_empty() else ""
	for v: Dictionary in all:
		var id := str(v.get("id", ""))
		if not english.is_empty() and not english.has(id):
			continue
		var name := str(v.get("name", "")).to_lower()
		var is_f := FEMALE_HINTS.any(func(h: String) -> bool: return name.contains(h))
		if is_f == female:
			pick = id
			break
	_voices[key] = pick
	return pick
