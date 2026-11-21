class_name Ambience
extends Node
## Exploration ambience (story 055, decision D-065): a loop under each room theme (wind and
## rumble in the cavern, glints in the forest, lapping water in the palace, embers in the rift,
## waves on the shore) and one-shots now and then (a distant bell, chains, drips, falling stones,
## a far choir, a wooden creak), picked by weight, near or far. Changing theme crossfades. Plays
## on its own Ambience bus under the music. Settings in data/audio/ambience.json.
##
##     var amb := Ambience.new()
##     add_child(amb)
##     amb.set_theme("cavern")

const PATH := "res://data/audio/ambience.json"

## The theme now playing ("" = silent).
var theme: String = ""
## One-shots played so far, by name (tests, debug).
var played: Dictionary[String, int] = {}

var _cfg: Dictionary = {}
var _beds: Array[AudioStreamPlayer] = []
var _active: int = 0
var _shot: AudioStreamPlayer
var _next_s: float = 0.0
var _rng := RandomNumberGenerator.new()
var _fade_left: float = 0.0


func _ready() -> void:
	if FileAccess.file_exists(PATH):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if d is Dictionary:
			_cfg = d
	# Story 059: its own bus, so the settings can set ambience apart from the effects.
	GameSettings.ensure_bus("Ambience")
	var bus := "Ambience"
	for i in range(2):
		var p := AudioStreamPlayer.new()
		p.bus = bus
		p.volume_db = -80.0
		add_child(p)
		_beds.append(p)
	_shot = AudioStreamPlayer.new()
	_shot.bus = bus
	add_child(_shot)
	_rng.randomize()


## Settings of `theme_id` ({} when it has no ambience).
func theme_cfg(theme_id: String) -> Dictionary:
	return (_cfg.get("themes", {}) as Dictionary).get(theme_id, {})


## Crossfade to `theme_id`'s loop and one-shots (no change when it is already playing).
func set_theme(theme_id: String) -> void:
	if theme_id == theme:
		return
	theme = theme_id
	var t := theme_cfg(theme_id)
	_active = 1 - _active
	var p := _beds[_active]
	p.stream = _looping(str(t.get("bed", "")))
	p.volume_db = -80.0
	if p.stream != null:
		p.play()
	_fade_left = float(_cfg.get("fade_s", 2.0))
	_next_s = _pick_gap(t)


## Pick the next one-shot of `theme_id` by weight ("" when it has none).
func pick_oneshot(theme_id: String, roll: float) -> String:
	var shots: Dictionary = theme_cfg(theme_id).get("oneshots", {})
	var total := 0.0
	for k: String in shots.keys():
		total += float(shots[k])
	var r := roll * total
	for k: String in shots.keys():
		r -= float(shots[k])
		if r <= 0.0:
			return k
	return ""


func _process(delta: float) -> void:
	var t := theme_cfg(theme)
	var fade := maxf(float(_cfg.get("fade_s", 2.0)), 0.01)
	if _fade_left > 0.0:
		_fade_left = maxf(_fade_left - delta, 0.0)
	var k := 1.0 - _fade_left / fade
	var bed_db := float(t.get("bed_db", -16.0))
	_beds[_active].volume_db = lerpf(-60.0, bed_db, k) if _beds[_active].stream != null else -80.0
	_beds[1 - _active].volume_db = lerpf(_beds[1 - _active].volume_db, -80.0, minf(delta * 2.0, 1.0))
	if _fade_left <= 0.0 and _beds[1 - _active].playing and _beds[1 - _active].volume_db < -70.0:
		_beds[1 - _active].stop()
	if t.is_empty():
		return
	_next_s -= delta
	if _next_s <= 0.0:
		_next_s = _pick_gap(t)
		var name := pick_oneshot(theme, _rng.randf())
		var s := _stream(name)
		if s != null:
			_shot.stream = s
			_shot.volume_db = float(t.get("oneshot_db", -13.0)) - _rng.randf() * float(_cfg.get("oneshot_spread_db", 8.0))
			_shot.pitch_scale = _rng.randf_range(0.9, 1.08)
			_shot.play()
			played[name] = played.get(name, 0) + 1


func _pick_gap(t: Dictionary) -> float:
	var every: Array = t.get("every_s", [5.0, 12.0])
	return _rng.randf_range(float(every[0]), float(every[1]))


func _stream(name: String) -> AudioStream:
	var path := "%s%s.wav" % [str(_cfg.get("folder", "res://assets/audio/ambience/")), name]
	if name == "" or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream


## The loop for `name`, set to repeat over its whole length.
func _looping(name: String) -> AudioStream:
	var s := _stream(name)
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(w.get_length() * float(w.mix_rate))
	return s
