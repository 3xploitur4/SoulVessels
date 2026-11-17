extends Node
## Autoload `MusicDirector` (story 012): the adaptive 5-layer score. One zone track is a set of
## shared intensity stems (Bed, Pulse, Combat, Elite) plus one lead stem per Vessel, all looping
## inside a single `AudioStreamSynchronized` so they never drift. Intensity changes wait for the
## next 4-bar boundary; swapping Vessel crossfades the lead stems over one beat.
##
## States: explore -> alert (an enemy has aggro) -> combat (first damage either way) -> elite
## (an elite with aggro within 15 m); back to explore 6 s after the last aggro ends.
##
##     MusicDirector.start_zone("zone1")
##     MusicDirector.set_vessel("nyra")
##     MusicDirector.force_state("combat")   # tests and the bridge
##
## Config: data/audio/music.json. Beat maths is static and unit-tested.

const STATES := ["explore", "alert", "combat", "elite"]

## The node whose position decides "elite within range" (the sandbox sets the player).
var listener: Node3D
## Current intensity state.
var state: String = "explore"
## State waiting for the next boundary ("" when none).
var pending_state: String = ""
## Song time (seconds since start) when the pending state applies.
var pending_at: float = -1.0
var vessel: String = ""
var bpm: float = 70.0
var beats_per_bar: int = 4
var zone: String = ""
## Log of applied state changes: [{state, at}] (tests, debug).
var history: Array[Dictionary] = []

var _cfg: Dictionary = {}
var _zone_cfg: Dictionary = {}
var _player: AudioStreamPlayer
var _sync: AudioStreamSynchronized
## Stem name -> sync index.
var _index: Dictionary[String, int] = {}
var _current_db: Dictionary[String, float] = {}
var _target_db: Dictionary[String, float] = {}
var _rate_db: Dictionary[String, float] = {}
var _song_time: float = 0.0
var _last_usec: int = 0
var _aggro: Dictionary[int, Node] = {}
var _damage_seen: bool = false
var _calm_left: float = 0.0
var _forced: String = ""
var _duck_left: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cfg = _load_json("res://data/audio/music.json")
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	add_child(_player)
	GameEvents.enemy_aggro_changed.connect(_on_aggro)
	GameEvents.player_hp_changed.connect(func(_c: float, _m: float) -> void: _damage_seen = true)
	GameEvents.hit_fx_requested.connect(func(_w: Vector3, _a: float, _c: bool, _b: bool) -> void: _damage_seen = true)
	GameEvents.vessel_swapped.connect(func(id: String, _s: int) -> void: set_vessel(id))
	GameEvents.telegraph_fired.connect(func(_k: String, _s: Node) -> void: _duck_left = _num("telegraph_duck_s", 0.15))


## True when music.json has a track for `zone_id`.
func has_zone(zone_id: String) -> bool:
	return (_cfg.get("zones", {}) as Dictionary).has(zone_id)


## Load a zone's stems and start playing in `explore`.
func start_zone(zone_id: String) -> void:
	var zones: Dictionary = _cfg.get("zones", {})
	if not zones.has(zone_id):
		push_error("MusicDirector: unknown zone %s" % zone_id)
		return
	zone = zone_id
	_zone_cfg = zones[zone_id]
	bpm = float(_zone_cfg.get("bpm", 70.0))
	beats_per_bar = int(_zone_cfg.get("beats_per_bar", 4))
	_sync = AudioStreamSynchronized.new()
	_index.clear()
	_current_db.clear()
	_target_db.clear()
	_rate_db.clear()
	var folder := str(_zone_cfg.get("folder", ""))
	var names: Array[String] = []
	var stems: Dictionary = _zone_cfg.get("stems", {})
	var leads: Dictionary = _zone_cfg.get("leads", {})
	for n: String in stems.keys():
		names.append(n)
	for n: String in leads.keys():
		names.append("lead_" + n)
	_sync.stream_count = names.size()
	for i in range(names.size()):
		var n := names[i]
		var spec: Dictionary = stems.get(n, leads.get(n.trim_prefix("lead_"), {}))
		var stream := _load_stem(folder + str(spec.get("file", n + ".wav")))
		_sync.set_sync_stream(i, stream)
		_index[n] = i
		_current_db[n] = silent_db()
		_target_db[n] = silent_db()
		_rate_db[n] = 60.0
		_sync.set_sync_stream_volume(i, silent_db())
	_player.stream = _sync
	_song_time = 0.0
	_last_usec = Time.get_ticks_usec()
	history.clear()
	state = "explore"
	pending_state = ""
	_apply_state_targets(state, 0.5)
	if vessel != "":
		set_vessel(vessel)
	_player.play()


## Crossfade the lead stems to `vessel_id` over one beat (immediately, not on a boundary).
func set_vessel(vessel_id: String) -> void:
	vessel = vessel_id
	var leads: Dictionary = _zone_cfg.get("leads", {})
	var fade_s := beat_length(bpm) * _num("lead_crossfade_beats", 1.0)
	for n: String in leads.keys():
		var key := "lead_" + n
		var on_db := float((leads[n] as Dictionary).get("db", -6.0))
		_set_target(key, on_db if n == vessel_id else silent_db(), fade_s)


## Pin a state (tests, bridge); "" returns control to the automatic rules.
func force_state(s: String) -> void:
	_forced = s
	if s != "":
		request_state(s)


## Ask for `s`; it applies on the next 4-bar boundary.
func request_state(s: String) -> void:
	if s == state and pending_state == "":
		return
	if s == pending_state:
		return
	pending_state = s
	pending_at = next_boundary_time(_song_time, bpm, beats_per_bar, int(_num("boundary_bars", 4.0)))


func song_time() -> float:
	return _song_time


func silent_db() -> float:
	return _num("silent_db", -60.0)


## Current volume of a stem in dB (tests, debug HUD).
func stem_db(stem: String) -> float:
	return _current_db.get(stem, silent_db())


## Does the current track have a stem called `stem`?
func has_stem(stem: String) -> bool:
	return _index.has(stem)


func is_playing() -> bool:
	return _player != null and _player.playing


## Seconds of one loop of the zone track (bars x beats x beat length).
func loop_length() -> float:
	return beat_length(bpm) * float(beats_per_bar) * float(_zone_cfg.get("bars", 8))


## Where the audio server says playback is, compensated for mix latency (0 when not mixing).
func playback_position() -> float:
	if _player == null or not _player.playing:
		return 0.0
	return _player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()


## Difference between the director's clock (mod one loop) and the audio playback position, in
## seconds. Near 0 means intensity changes land where the music actually is.
func clock_drift() -> float:
	var pos := playback_position()
	if pos <= 0.0:
		return 0.0
	var l := loop_length()
	var d := fposmod(_song_time, l) - fposmod(pos, l)
	if d > l * 0.5:
		d -= l
	elif d < -l * 0.5:
		d += l
	return d


## Seconds per beat.
static func beat_length(tempo_bpm: float) -> float:
	return 60.0 / maxf(tempo_bpm, 1.0)


## The first time >= `now` that falls on a `bars`-bar boundary. A time already on a boundary
## (within 1 ms) is returned as is.
static func next_boundary_time(now: float, tempo_bpm: float, beats_bar: int, bars: int) -> float:
	var span := beat_length(tempo_bpm) * float(beats_bar) * float(maxi(bars, 1))
	var k := ceilf((now - 0.001) / span)
	return maxf(k, 0.0) * span


## Seconds from now to the first 4-bar boundary at least `after` seconds away; -1 with no music
## (a boss phase change lands on it, story 034).
func seconds_to_boundary(after: float) -> float:
	if not is_playing():
		return -1.0
	var now := song_time()
	return next_boundary_time(now + after, bpm, beats_per_bar, int(_num("boundary_bars", 4))) - now


func _process(_delta: float) -> void:
	# Real time, not game time: hitstop slows Engine.time_scale but the music keeps going.
	var now := Time.get_ticks_usec()
	var dt := float(now - _last_usec) / 1_000_000.0
	_last_usec = now
	if _player == null or _sync == null:
		return
	_advance_clock(dt)
	_update_rules(dt)
	if pending_state != "" and _song_time >= pending_at:
		_apply_state(pending_state)
	for n: String in _current_db.keys():
		var cur := _current_db[n]
		var tgt := _target_db[n]
		if cur != tgt:
			cur = move_toward(cur, tgt, _rate_db[n] * dt)
			_current_db[n] = cur
			_sync.set_sync_stream_volume(_index[n], cur)
	if _duck_left > 0.0:
		_duck_left -= dt
		_player.volume_db = _num("telegraph_duck_db", -3.0)
	else:
		_player.volume_db = 0.0


## The audio playback position is the authority (it is what the player hears, and Movie Maker
## renders audio in game time); real time only fills in when nothing is mixing (headless runs).
## Loops are counted so song time keeps growing across the 8-bar wrap.
func _advance_clock(dt: float) -> void:
	var pos := playback_position()
	if pos <= 0.0:
		_song_time += dt
		return
	var l := loop_length()
	var in_loop := fposmod(pos, l)
	var loops := floorf(_song_time / l)
	var candidate := loops * l + in_loop
	# Wrapped past the loop end since the last frame.
	if candidate < _song_time - l * 0.5:
		candidate += l
	# Never run backwards on mix jitter; small steps back are held.
	_song_time = maxf(_song_time, candidate)


func _update_rules(dt: float) -> void:
	if _forced != "":
		return
	var any_aggro := false
	var elite_near := false
	var range_m := _num("elite_range_m", 15.0)
	for id: int in _aggro.keys():
		var e := _aggro[id]
		if not is_instance_valid(e):
			_aggro.erase(id)
			continue
		any_aggro = true
		if str(e.get("tier")) == "elite" and listener != null and is_instance_valid(listener):
			if (e as Node3D).global_position.distance_to(listener.global_position) <= range_m:
				elite_near = true
	var want := state
	if any_aggro:
		_calm_left = _num("calm_down_s", 6.0)
		if elite_near and _damage_seen:
			want = "elite"
		elif _damage_seen:
			want = "combat"
		else:
			want = "alert"
	else:
		_calm_left -= dt
		if _calm_left <= 0.0:
			want = "explore"
			_damage_seen = false
	if want != state or (pending_state != "" and want != pending_state):
		request_state(want)


func _apply_state(s: String) -> void:
	state = s
	pending_state = ""
	history.append({"state": s, "at": snappedf(_song_time, 0.001)})
	_apply_state_targets(s, beat_length(bpm) * _num("intensity_fade_beats", 2.0))
	GameEvents.music_state_changed.emit(s)


func _apply_state_targets(s: String, fade_s: float) -> void:
	var stems: Dictionary = _zone_cfg.get("stems", {})
	for n: String in stems.keys():
		var spec: Dictionary = stems[n]
		var on: bool = (spec.get("states", []) as Array).has(s)
		_set_target(n, float(spec.get("db", 0.0)) if on else silent_db(), fade_s)


func _set_target(stem: String, db: float, fade_s: float) -> void:
	if not _target_db.has(stem):
		return
	_target_db[stem] = db
	var span := absf(db - _current_db[stem])
	_rate_db[stem] = span / maxf(fade_s, 0.01) if span > 0.0 else 60.0


func _on_aggro(enemy: Node, on: bool) -> void:
	if on:
		_aggro[enemy.get_instance_id()] = enemy
	else:
		_aggro.erase(enemy.get_instance_id())


func _load_stem(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("MusicDirector: missing stem %s (run tools/audio/synth_stems.py)" % path)
		return AudioStreamWAV.new()
	var s := load(path) as AudioStream
	if s is AudioStreamWAV:
		var w := s as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = int(roundf(w.get_length() * float(w.mix_rate)))
	return s


func _num(key: String, fallback: float) -> float:
	return float(_cfg.get(key, fallback))


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("MusicDirector: %s not found" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
