extends TestCase
## Story 017: resting at a Soul Altar heals, lights it, makes it the respawn point, saves, and
## brings back ordinary enemies but never killed elites.

const DIR := "user://test_altar"

var game: Node


func before_each() -> void:
	_clear()
	game = load("res://src/game/game.tscn").instantiate()
	game.set("save_dir", DIR)
	game.set("enable_bridge", false)
	add_node(game)
	await wait_frames(1)
	var gs := GameState.new_game("normal")
	gs.unlock_vessel("caelan")
	gs.checkpoint = {"room": "z1_04", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(2)


func after_each() -> void:
	tree.paused = false
	_clear()


func _clear() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func _altar() -> Altar:
	var rooms: RoomManager = game.get("rooms")
	for c in rooms.features_root.get_children():
		if c is Altar:
			return c as Altar
	return null


func test_altar_room_builds_an_unlit_altar() -> void:
	var a := _altar()
	assert_not_null(a)
	assert_eq(a.altar_id, "altar_z1_a")
	assert_false(a.lit)
	assert_eq(a.verb_key, "UI_KINDLE")


func test_rest_heals_lights_saves_and_sets_the_respawn_point() -> void:
	var player: Player = game.get("player")
	var state: GameState = game.get("state")
	player.health.damage(200.0)
	player.flask_charges = 0
	game.call("rest_at_altar", _altar())
	assert_almost(player.health.current, player.health.max_value, 0.01)
	assert_eq(player.flask_charges, player.flask_max())
	assert_true(state.lit_altars.has("altar_z1_a"))
	assert_eq(str(state.rested_altar["altar"]), "altar_z1_a")
	assert_eq(str(state.checkpoint["room"]), "z1_04")
	var saved := (game.get("saves") as SaveSystem).load_slot(0)
	assert_true(saved.lit_altars.has("altar_z1_a"), "rest saves")
	assert_not_null(game.get("altar_menu"), "menu opens")
	assert_true(tree.paused)
	game.call("close_altar_menu")
	assert_false(tree.paused)


func test_rest_brings_back_commons_not_killed_elites() -> void:
	var state: GameState = game.get("state")
	var rooms: RoomManager = game.get("rooms")
	state.killed_commons.append("z1_03:0")
	state.killed_commons.append("z1_03:1")
	state.killed_elites.append("z1_12:0")
	game.call("rest_at_altar", _altar())
	game.call("close_altar_menu")
	rooms.enter("z1_03")
	await wait_frames(1)
	# Story 054: the base room's two Crawlers (its upper level has enemies of its own).
	var base_ids := WorldData.room("z1_03").spawns.filter(func(s: Dictionary) -> bool: return not s["upper"]).map(
		func(s: Dictionary) -> String: return str(s["spawn_id"]))
	assert_eq(rooms.enemies().filter(func(e: EnemyBase) -> bool: return base_ids.has(e.spawn_id)).size(), 2,
		"both Crawlers are back")
	rooms.enter("z1_12")
	await wait_frames(1)
	assert_eq(rooms.enemies().size(), 0, "the Warden stays dead")


func test_loadout_and_memory_lore_requests() -> void:
	var state: GameState = game.get("state")
	var player: Player = game.get("player")
	state.unlock_vessel("nyra")
	game.call("apply_loadout", ["nyra", "caelan"] as Array[String])
	assert_eq(state.loadout, ["nyra", "caelan"] as Array[String])
	assert_eq(player.loadout.slots[0].id, "nyra")
	game.call("apply_loadout", ["darius"] as Array[String])
	assert_eq(state.loadout, ["nyra", "caelan"] as Array[String], "locked Vessels are refused")
	state.lore_found.append("memory_caelan")
	game.call("read_lore", "memory_caelan")
	game.call("read_lore", "memory_caelan")
	assert_eq(int(state.affinity_bonus.get("caelan", 0)), 1, "a memory grants +1 once")
