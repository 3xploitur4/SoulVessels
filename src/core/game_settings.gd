class_name GameSettings
extends RefCounted
## Player settings that belong to the player, not to a save slot (story 059, decision D-070):
## the volume of the whole game, the music, the sound effects and the ambience, each 0..1. Kept in
## `user://settings.json` and applied to the audio buses (Master, Music, SFX with Telegraph, and
## an Ambience bus made here if the layout has none). Difficulty is a save slot's, not a setting
## (see `GameState.difficulty`).
##
##     GameSettings.load_and_apply()
##     GameSettings.set_volume("music", 0.6)    # applies and saves

const PATH := "user://settings.json"
## Setting -> the buses it drives.
const BUSES := {"master": ["Master"], "music": ["Music"], "effects": ["SFX", "Telegraph"], "ambience": ["Ambience"]}
const KEYS: Array[String] = ["master", "music", "effects", "ambience"]

static var volumes: Dictionary = {"master": 1.0, "music": 1.0, "effects": 1.0, "ambience": 1.0}
## Each bus's own level from the bus layout (the Telegraph bus sits 2 dB up), so a setting scales
## it rather than replacing it.
static var _base_db: Dictionary = {}
## Where settings are kept (tests point it elsewhere).
static var path: String = PATH


## Read the settings file (missing or broken: everything at full) and apply it.
static func load_and_apply() -> void:
	volumes = {"master": 1.0, "music": 1.0, "effects": 1.0, "ambience": 1.0}
	if FileAccess.file_exists(path):
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary:
			var v: Dictionary = (d as Dictionary).get("volumes", {})
			for k in KEYS:
				if v.has(k):
					volumes[k] = clampf(float(v[k]), 0.0, 1.0)
	apply()


## Set `key` ("master", "music", "effects", "ambience") to `value` (0..1), apply it and save.
static func set_volume(key: String, value: float) -> void:
	if not volumes.has(key):
		return
	volumes[key] = clampf(value, 0.0, 1.0)
	apply()
	save()


static func volume(key: String) -> float:
	return float(volumes.get(key, 1.0))


## Push every volume to its buses. Zero mutes the bus.
static func apply() -> void:
	ensure_bus("Ambience")
	for key in KEYS:
		for bus_name: String in BUSES[key]:
			var i := AudioServer.get_bus_index(bus_name)
			if i < 0:
				continue
			if not _base_db.has(bus_name):
				_base_db[bus_name] = AudioServer.get_bus_volume_db(i)
			var v := volume(key)
			AudioServer.set_bus_mute(i, v <= 0.001)
			AudioServer.set_bus_volume_db(i, float(_base_db[bus_name]) + bus_db(v))


## Decibels for a 0..1 slider: a curve that sounds even to the ear (half way is about -12 dB).
static func bus_db(v: float) -> float:
	if v <= 0.001:
		return -80.0
	return linear_to_db(v * v)


static func save() -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"volumes": volumes}, "  "))


## Make bus `bus_name` (sending to Master) when the layout has none. Returns its index.
static func ensure_bus(bus_name: String) -> int:
	var i := AudioServer.get_bus_index(bus_name)
	if i >= 0:
		return i
	AudioServer.add_bus()
	i = AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus_name)
	AudioServer.set_bus_send(i, "Master")
	return i
