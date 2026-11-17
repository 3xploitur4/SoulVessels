extends TestCase
## Story 036 (integration): reforging at an altar raises the Vessel's ATK at once, survives a
## save and reload, and the altar's Reforge page lists the weapon with its cost.

const DIR := "user://test_reforge"

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


func _start() -> GameState:
	var gs := GameState.new_game("normal")
	gs.unlock_vessel("caelan")
	gs.set_flag("possessed_caelan")
	gs.loadout.assign(["caelan"])
	gs.essence = 1000
	gs.add_item("crude_stone", 3)
	gs.checkpoint = {"room": "z1_01", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(3)
	return game.get("state")


func test_a_reforge_raises_atk_now_and_after_a_reload() -> void:
	var state := await _start()
	var player: Player = game.get("player")
	var atk0 := player.stat("atk")
	game.call("reforge_weapon", "caelan")
	assert_eq(int(state.weapon_levels.get("caelan", 0)), 1)
	assert_eq(state.essence, 700)
	assert_eq(state.item_count("crude_stone"), 0)
	assert_almost(player.stat("atk"), atk0 * 1.08, 0.01)
	var loaded := (game.get("saves") as SaveSystem).load_slot(0)
	assert_eq(int(loaded.weapon_levels.get("caelan", 0)), 1, "saved")


func test_the_reforge_page_lists_the_weapon_and_disables_what_cannot_be_paid() -> void:
	await _start()
	var menu := AltarMenu.new()
	menu.state = game.get("state")
	menu.reforge = game.get("reforge")
	add_node(menu)
	menu.show_reforge()
	await wait_frames(2)
	var b := menu.find_child("Reforge_caelan", true, false) as Button
	assert_not_null(b)
	assert_false(b.disabled, "3 stones and 1000 Essence pay for +1")
	var craft := menu.find_child("Craft_censer_core", true, false) as Button
	assert_true(craft.disabled, "no shards")
