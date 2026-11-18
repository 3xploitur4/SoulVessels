extends Node
## Autoload `Sfx`: one-shot sound effects by name from `res://assets/audio/sfx/<name>.wav`
## (synthesised placeholders until real audio lands, decision D-006). A small pool of players
## on the "SFX" bus; telegraph cues go to the "Telegraph" bus, which ducks the music.
## A missing file is reported once and then ignored, so code can name sounds before they exist.
##
##     Sfx.play("parry")
##     Sfx.play("telegraph_chime")

const ROOT := "res://assets/audio/sfx/"
const POOL_SIZE := 10
const TELEGRAPH_PREFIX := "telegraph_"

var _streams: Dictionary[String, AudioStream] = {}
var _missing: Dictionary[String, bool] = {}
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
## Global SFX volume (accessibility / settings).
var volume_db: float = 0.0
## Count of plays per name, for tests and the debug HUD.
var play_counts: Dictionary[String, int] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(p)
		_pool.append(p)


## Play `sound_name` once. `pitch` varies it slightly for repeats; `gain_db` sets it quieter or
## louder than the rest (footsteps sit under everything).
func play(sound_name: String, pitch: float = 1.0, gain_db: float = 0.0) -> void:
	play_counts[sound_name] = play_counts.get(sound_name, 0) + 1
	var stream := _stream(sound_name)
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	var bus := "Telegraph" if sound_name.begins_with(TELEGRAPH_PREFIX) else "SFX"
	p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else "Master"
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db + gain_db
	p.play()


func _stream(sound_name: String) -> AudioStream:
	if _streams.has(sound_name):
		return _streams[sound_name]
	if _missing.has(sound_name):
		return null
	var path := ROOT + sound_name + ".wav"
	if not ResourceLoader.exists(path):
		_missing[sound_name] = true
		return null
	var s := load(path) as AudioStream
	_streams[sound_name] = s
	return s
