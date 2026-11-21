class_name IlyrAwakening
extends Node
## Ilyr's awakening (story 047; Narrative 6): the end of Chapter I. In this room the Intruder is
## Ilyr alone (the real loadout is set aside, not changed in the save), and the erased echoes of
## the other four Vessels come one after another. When the last falls Ilyr speaks ("You've worn
## this face before."), the screen fades to black, Chapter I is marked complete (Abyssal unlocks for
## new games), the save is written with the real loadout, and the chapter-end screen shows.
##
## Room JSON: "awakening": {"echoes": ["echo_caelan", ...], "spawn_x": 20}

var game: Node
var manager: RoomManager
var echoes: Array[String] = []
var spawn_x: float = 20.0
var index: int = -1

var _current: EnemyBase
var _done: bool = false
var _gap_left: float = 0.0
var _saved_vessels: Array[String] = []


## Build the awakening for a room that has one. Registered as a room feature.
static func build_for(g: Node, m: RoomManager, room: RoomData) -> void:
	var def: Variant = room.raw.get("awakening")
	if not def is Dictionary:
		return
	var a := IlyrAwakening.new()
	a.name = "Awakening"
	a.game = g
	a.manager = m
	for e: Variant in (def as Dictionary).get("echoes", []):
		a.echoes.append(str(e))
	a.spawn_x = float((def as Dictionary).get("spawn_x", 20.0))
	m.features_root.add_child(a)


func _ready() -> void:
	var player: Player = game.get("player")
	_saved_vessels = player.vessel_ids.duplicate()
	player.equip(["ilyr"] as Array[String], {"ilyr": 0})
	GameEvents.vessel_swapped.emit("ilyr", 0)
	# Story 060: meeting Ilyr is a conversation (its first line is his waking line).
	if game.has_method("meet"):
		game.call("meet", "awakened:ilyr")
	else:
		var prompts: Prompts = game.get("prompts")
		if prompts != null:
			prompts.subtitle(tr("VESSEL_ILYR"), tr("ILYR_WAKES"), Color(0.92, 0.88, 0.7))
	if MusicDirector.has_zone("finale_short"):
		MusicDirector.start_zone("finale_short")
	_gap_left = 1.5


func _exit_tree() -> void:
	# Leaving before the end (death): the Vessels come back.
	if not _done and game != null and is_instance_valid(game):
		var player: Player = game.get("player")
		if player != null and is_instance_valid(player) and not _saved_vessels.is_empty():
			player.equip(_saved_vessels, game.call("affinity_levels"))


func _physics_process(delta: float) -> void:
	if _done:
		return
	if _current != null and is_instance_valid(_current) and _current.is_alive():
		return
	_gap_left -= delta
	if _gap_left > 0.0:
		return
	index += 1
	if index >= echoes.size():
		_finish()
		return
	_current = manager.spawn(echoes[index], spawn_x, 2.05)
	_gap_left = 1.2
	GameEvents.ultimate_fx_requested.emit("cataclysm_fused", Vector3(spawn_x, 2.0, 0.0), 2.0)
	Sfx.play("vanish")


func _finish() -> void:
	_done = true
	var prompts: Prompts = game.get("prompts")
	if prompts != null:
		prompts.subtitle(tr("VESSEL_ILYR"), tr("ILYR_FACE"), Color(0.92, 0.88, 0.7))
	var state: GameState = game.get("state")
	var saves: SaveSystem = game.get("saves")
	if state != null:
		state.set_flag("chapter1_complete")
	if saves != null:
		saves.mark_chapter_complete()
	var player: Player = game.get("player")
	player.input_enabled = false
	await get_tree().create_timer(3.0, true, false, true).timeout
	if not is_instance_valid(game):
		return
	var fader: Node = game.get("fader")
	if fader != null and fader.has_method("fade_to"):
		await fader.call("fade_to", 1.0, 1.5)
	player.equip(_saved_vessels, game.call("affinity_levels"))
	game.call("save_now")
	game.call("show_chapter_end")
	# The chapter-end screen is black itself; lift the fade so its words show.
	if fader != null and fader.has_method("fade_to"):
		fader.call("fade_to", 0.0, 0.8)
