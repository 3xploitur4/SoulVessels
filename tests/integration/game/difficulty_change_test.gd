extends TestCase
## Story 059 (D-070): changing a game's difficulty from the pause menu changes the save, the
## player and the enemies already in the room, and Abyssal stays locked until Chapter I is done.

const DIR := "user://test_difficulty"

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
	gs.checkpoint = {"room": "z1_02", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(3)


func after_each() -> void:
	tree.paused = false
	_clear()


func _clear() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func test_story_takes_effect_at_once_and_is_saved() -> void:
	var rooms: RoomManager = game.get("rooms")
	var e := rooms.spawn("echo_crawler", 10.0, 2.0)
	assert_almost(e.damage_scale, 1.0, 0.001, "spawned on Normal")
	game.call("set_difficulty", "story")
	var state: GameState = game.get("state")
	var player: Player = game.get("player")
	assert_eq(state.difficulty, "story")
	assert_eq(player.difficulty, "story")
	assert_almost(e.damage_scale, float(Balance.combat("difficulty.story.enemy_damage")), 0.001, "the enemy already here")
	var saves: SaveSystem = game.get("saves")
	assert_eq(str(saves.summary(0).get("difficulty", "")), "story", "saved")


func test_abyssal_stays_locked_before_chapter_one_is_done() -> void:
	game.call("set_difficulty", "abyssal")
	var state: GameState = game.get("state")
	assert_eq(state.difficulty, "normal")


func test_the_pause_menu_has_a_settings_page_with_this_games_difficulty() -> void:
	game.call("open_pause")
	await wait_frames(2)
	var pm: PauseMenu = game.get("pause_menu")
	assert_true(pm != null, "paused")
	var tab := pm.find_child("Tab_settings", true, false) as Button
	assert_true(tab != null, "a Settings tab")
	tab.pressed.emit()
	await wait_frames(1)
	var panel := pm.find_child("Settings", true, false) as SettingsPanel
	assert_true(panel != null, "the settings page")
	assert_true(panel.difficulty_buttons["normal"].button_pressed)
	panel.difficulty_buttons["story"].pressed.emit()
	var state: GameState = game.get("state")
	assert_eq(state.difficulty, "story", "the page's choice reaches the game")
	game.call("close_pause")
