extends TestCase
## Story 018: dying drops a Soul Echo, the player wakes at the rested altar, and touching the
## echo returns the Essence.

const DIR := "user://test_death"

var game: Node


func before_each() -> void:
	_clear()
	Balance.set_value("combat.death.respawn_delay_s", 0.05)
	game = load("res://src/game/game.tscn").instantiate()
	game.set("save_dir", DIR)
	game.set("enable_bridge", false)
	add_node(game)
	await wait_frames(1)
	var gs := GameState.new_game("normal")
	gs.unlock_vessel("caelan")
	gs.rested_altar = {"room": "z1_04", "altar": "altar_z1_a"}
	gs.checkpoint = {"room": "z1_05", "x": 20.0, "y": 2.0}
	gs.essence = 100
	game.call("begin_run", 0, gs)
	await wait_frames(3)


func after_each() -> void:
	Balance.set_value("combat.death.respawn_delay_s", 2.5)
	tree.paused = false
	_clear()


func _clear() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func _wait_until(cond: Callable, max_frames: int) -> bool:
	for i in range(max_frames):
		if cond.call():
			return true
		await wait_frames(1)
	return cond.call()


func test_death_leaves_an_echo_and_wakes_at_the_altar() -> void:
	var player: Player = game.get("player")
	var rooms: RoomManager = game.get("rooms")
	var state: GameState = game.get("state")
	player.kill()
	var back := await _wait_until(func() -> bool: return rooms.data.id == "z1_04" and player.is_alive(), 240)
	assert_true(back, "woke at the rested altar")
	assert_eq(state.essence, 0)
	assert_eq(int(state.echo.get("essence", 0)), 100)
	assert_eq(str(state.echo.get("room", "")), "z1_05")
	assert_almost(player.health.current, player.health.max_value, 0.01)


func test_touching_the_echo_returns_the_essence() -> void:
	var player: Player = game.get("player")
	var rooms: RoomManager = game.get("rooms")
	var state: GameState = game.get("state")
	player.kill()
	await _wait_until(func() -> bool: return rooms.data.id == "z1_04" and player.is_alive(), 240)
	await wait_frames(30)
	rooms.enter("z1_05", "", Vector2(30.0, 2.0))
	await wait_frames(2)
	assert_not_null(rooms.features_root.get_node_or_null("SoulEcho"), "the echo waits in z1_05")
	player.teleport(float(state.echo["x"]), float(state.echo["y"]))
	await wait_frames(3)
	assert_eq(state.essence, 100)
	assert_true(state.echo.is_empty())
