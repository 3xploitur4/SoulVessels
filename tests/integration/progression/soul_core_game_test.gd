extends TestCase
## Story 020: buying Soul Core nodes changes the player; Affinity levels unlock in play.

const DIR := "user://test_core"

var game: Node


func before_each() -> void:
	game = load("res://src/game/game.tscn").instantiate()
	game.set("save_dir", DIR)
	game.set("enable_bridge", false)
	add_node(game)
	await wait_frames(1)
	var gs := GameState.new_game("normal")
	gs.unlock_vessel("caelan")
	gs.checkpoint = {"room": "z1_04", "x": -1.0, "y": -1.0}
	gs.add_item("lesser_soul_shard", 4)
	game.call("begin_run", 0, gs)
	await wait_frames(2)


func after_each() -> void:
	tree.paused = false
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func test_buying_hp_nodes_raises_max_hp_and_heals_the_gain() -> void:
	var player: Player = game.get("player")
	var state: GameState = game.get("state")
	var base := player.health.max_value
	game.call("buy_core", "core_heart")
	game.call("buy_core", "vitality_1")
	assert_almost(player.health.max_value, base + 30.0, 0.01)
	assert_almost(player.health.current, base + 30.0, 0.01)
	assert_eq(state.item_count("lesser_soul_shard"), 2)
	var saved := (game.get("saves") as SaveSystem).load_slot(0)
	assert_true(saved.soul_core.has("vitality_1"), "a purchase saves")


func test_locked_node_is_refused() -> void:
	var player: Player = game.get("player")
	var state: GameState = game.get("state")
	var base := player.health.max_value
	game.call("buy_core", "vitality_3")
	assert_almost(player.health.max_value, base, 0.01)
	assert_eq(state.item_count("lesser_soul_shard"), 4)


func test_flask_gauge_and_stamina_nodes_apply() -> void:
	var player: Player = game.get("player")
	for id: String in ["core_heart", "vessel_1", "resonance_1", "endurance_1"]:
		game.call("buy_core", id)
	assert_eq(player.flask_max(), 4)
	assert_eq(player.flask_charges, 4, "the new charge arrives full")
	assert_almost(player.gauge.max_value, Balance.combat_f("soul_gauge.max") + 10.0, 0.01)
	assert_almost(player.loadout.active().stamina.regen_per_s, Balance.combat_f("stamina.regen_per_s") * 1.05, 0.01)


func test_bonuses_survive_a_reload() -> void:
	game.call("buy_core", "core_heart")
	game.call("show_title")
	await wait_frames(2)
	game.call("continue_game", 0)
	await wait_frames(2)
	var player: Player = game.get("player")
	assert_almost(player.health.max_value, Balance.combat_f("soul_hp_base") + 120.0 + 15.0, 0.01)


func test_affinity_levels_unlock_sync_guard_and_the_memory() -> void:
	var player: Player = game.get("player")
	var state: GameState = game.get("state")
	assert_eq(player.loadout.active().affinity, 0)
	var need: float = float(Affinity.config()["level_xp"][2])
	game.call("_award_xp", "kill", need / Affinity.xp_for("kill"))
	assert_eq(player.loadout.active().affinity, 2, "Sync Guard level")
	assert_true(state.lore_found.has("memory_caelan"), "the memory became lore at level 1+")
	game.call("read_lore", "memory_caelan")
	assert_eq(player.loadout.active().affinity, 3, "reading the memory adds a level")
