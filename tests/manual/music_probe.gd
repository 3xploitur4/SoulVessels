extends Node
## Manual audio probe (story 012): plays zone 1, stays in explore, then asks for elite at 1 s.
## The director must hold the change until the 4-bar boundary at 13.714 s, and the added stems
## must become audible there. Record with Movie Maker and analyse the audio with
## tools/audio/analyse_probe.py:
##   godot --path . --write-movie <out>.avi --quit-after 1260 res://tests/manual/music_probe.tscn

var _t: float = 0.0
var _asked: bool = false


func _ready() -> void:
	MusicDirector.start_zone("zone1")
	MusicDirector.set_vessel("caelan")
	MusicDirector.force_state("explore")
	print("PROBE start")


func _process(delta: float) -> void:
	_t += delta
	# `-- --control` keeps explore all the way: the same audio without the change, for comparison.
	if not _asked and _t >= 1.0 and not OS.get_cmdline_user_args().has("--control"):
		_asked = true
		MusicDirector.force_state("elite")
		print("PROBE asked elite at song %.3f, pending at %.3f" % [MusicDirector.song_time(), MusicDirector.pending_at])
	if MusicDirector.history.size() > 0 and MusicDirector.history[-1]["state"] == "elite" and not has_meta("logged"):
		set_meta("logged", true)
		print("PROBE elite applied at song %.3f" % float(MusicDirector.history[-1]["at"]))
