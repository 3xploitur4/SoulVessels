extends TestCase
## Story 054: spikes cost a share of max HP and put the player back on the last safe ground.

const DIR := "user://test_spikes"

var game: Node


func before_each() -> void:
	game = load("res://src/game/game.tscn").instantiate()
	game.set("save_dir", DIR)
	game.set("enable_bridge", false)
	add_node(game)
	await wait_frames(1)


func after_each() -> void:
	tree.paused = false
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func test_spikes_hurt_and_return_the_player_to_safe_ground() -> void:
	var gs := GameState.new_game("normal")
	gs.unlock_vessel("caelan")
	gs.checkpoint = {"room": "z1_01", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(3)
	var grid: Array = ["########################"]
	for i in range(8):
		grid.append("#......................#")
	grid.append("#..............^^^^....#")
	grid.append("########################")
	grid.append("########################")
	var rooms: RoomManager = game.get("rooms")
	rooms.enter_data(RoomData.parse("t_spikes", "zone1", {"grid": grid}), "", Vector2(4.0, 2.05))
	var player: Player = game.get("player")
	await wait_frames(20)
	var safe := rooms.last_safe
	assert_almost(safe.x, 4.0, 0.5, "standing on rock is safe ground")
	var hp := player.health.current
	player.teleport(16.0, 2.05)
	await wait_frames(6)
	assert_lt(player.health.current, hp, "the spikes hurt")
	assert_almost(player.global_position.x, safe.x, 0.6, "back on the safe ground")
