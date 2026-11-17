extends TestCase
## Story 037 (integration): bought ability ranks and a slotted Sync passive reach the Vessel in
## play (its kit reads the patched numbers), survive a reload, and King's Mercy heals on a Sync Guard.

const DIR := "user://test_ranks"

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


func _start(gs: GameState = null) -> void:
	if gs == null:
		gs = GameState.new_game("normal")
		gs.unlock_vessel("caelan")
		gs.set_flag("possessed_caelan")
		gs.loadout.assign(["caelan"])
		gs.add_item("standard_soul_shard", 5)
		gs.add_item("greater_soul_shard", 1)
	gs.checkpoint = {"room": "z1_01", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(3)


func _caelan_data() -> Dictionary:
	return (game.get("player") as Player).loadout.slots[0].data


func test_rank_three_kings_judgment_reaches_the_kit() -> void:
	await _start()
	var base := float(Balance.vessel("caelan")["ability_2"]["range_m"])
	game.call("buy_rank", "caelan", "kings_judgment")
	game.call("buy_rank", "caelan", "kings_judgment")
	var d := _caelan_data()
	assert_almost(float(d["ability_2"]["range_m"]), base * 1.5, 0.01, "rank 3 modifier")
	assert_almost(float(d["ability_2"]["motion"]), float(Balance.vessel("caelan")["ability_2"]["motion"]) * 1.2, 0.01,
		"rank 2 power")
	var state: GameState = game.get("state")
	assert_eq(state.item_count("standard_soul_shard"), 0, "2 + 3 shards")


func test_ranks_and_passive_survive_a_reload() -> void:
	await _start()
	game.call("buy_rank", "caelan", "final_stand")
	game.call("choose_passive", "caelan", "kings_mercy")
	var loaded := (game.get("saves") as SaveSystem).load_slot(0)
	game.queue_free()
	await wait_frames(2)
	game = load("res://src/game/game.tscn").instantiate()
	game.set("save_dir", DIR)
	game.set("enable_bridge", false)
	add_node(game)
	await wait_frames(1)
	await _start(loaded)
	var d := _caelan_data()
	assert_almost(float(d["ultimate"]["motion"]), float(Balance.vessel("caelan")["ultimate"]["motion"]) * 1.2, 0.01)
	assert_almost(float(d["sync_guard"].get("heal_fraction", 0.0)), 0.2, 0.001)


func test_kings_mercy_heals_on_a_sync_guard() -> void:
	await _start()
	game.call("choose_passive", "caelan", "kings_mercy")
	var player: Player = game.get("player")
	player.set_affinity("caelan", 3)
	player.gauge.add(300.0)
	player.health.current = 10.0
	var p := DamagePacket.new()
	p.atk = 500.0
	p.source_x = player.global_position.x + 1.0
	player.receive_hit(p)
	assert_gt(player.health.current, 10.0 + player.max_hp() * 0.15, "the lethal blow was blocked and she healed")
