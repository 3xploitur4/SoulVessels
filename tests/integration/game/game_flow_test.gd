extends TestCase
## Story 016: title -> new game -> suspend-save -> quit to title -> continue at the same spot.

const DIR := "user://test_game_flow"

var game: Node


func before_each() -> void:
	_clear()
	game = load("res://src/game/game.tscn").instantiate()
	game.set("save_dir", DIR)
	game.set("enable_bridge", false)
	add_node(game)
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


func test_boots_to_the_title_with_three_empty_slots() -> void:
	assert_not_null(game.get("title"))
	assert_null(game.get("player"))
	var saves: SaveSystem = game.get("saves")
	for i in range(3):
		assert_false(saves.exists(i))


func test_new_game_starts_the_wisp_in_room_one_and_saves() -> void:
	game.call("start_new", 1, "story")
	await wait_frames(2)
	var player: Player = game.get("player")
	assert_not_null(player)
	assert_true(player.is_wisp(), "no Vessel before Caelan")
	assert_eq((game.get("rooms") as RoomManager).data.id, "z1_01")
	assert_true((game.get("saves") as SaveSystem).exists(1))
	assert_eq((game.get("state") as GameState).difficulty, "story")


func test_suspend_save_resumes_at_the_same_spot_once() -> void:
	game.call("start_new", 0, "normal")
	await wait_frames(2)
	var player: Player = game.get("player")
	player.teleport(6.5, 2.0)
	game.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	var saved := (game.get("saves") as SaveSystem).load_slot(0)
	assert_eq(str(saved.resume.get("room", "")), "z1_01")
	assert_almost(float(saved.resume.get("x", 0.0)), 6.5, 0.05)
	game.call("show_title")
	await wait_frames(2)
	assert_null(game.get("player"))
	game.call("continue_game", 0)
	await wait_frames(2)
	player = game.get("player")
	assert_almost(player.global_position.x, 6.5, 0.1, "continued where the app was backgrounded")
	assert_true((game.get("state") as GameState).resume.is_empty(), "the resume point is used once")


func test_pause_stops_the_tree_and_resume_restarts_it() -> void:
	game.call("start_new", 0, "normal")
	await wait_frames(1)
	game.call("open_pause")
	assert_true(tree.paused)
	game.call("close_pause")
	assert_false(tree.paused)


func test_showing_the_title_twice_keeps_one_title() -> void:
	game.call("show_title")
	game.call("show_title")
	await wait_frames(2)
	var count := 0
	for c in game.get_children():
		if c is TitleScreen and not c.is_queued_for_deletion():
			count += 1
	assert_eq(count, 1)
