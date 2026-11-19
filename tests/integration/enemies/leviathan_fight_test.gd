extends TestCase
## Story 045 (integration): the Abyssal Leviathan on a stand-in 40 m shore (Zone 4's real one comes
## in story 049). The arena locks; eyes break it open; phase 2 darkens the shore and phase 3 lifts
## it; its fall drops the Pure Soul Matrix, unlocks Overdrive, opens the rift, ends Darius's
## distrust, and is saved.

const DIR := "user://test_leviathan"

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


func _shore() -> RoomData:
	var grid: Array = []
	grid.append("############################################")
	for i in range(9):
		grid.append("L..........................................L")
	grid.append("L.......................B..................L")
	grid.append("############################################")
	grid.append("############################################")
	return RoomData.parse("t_shore", "zone4", {"boss": "abyssal_leviathan",
		"arena": {"id": "t_shore_arena", "trigger_x": [3.0, 41.0]},
		"water": [{"id": "sea", "x": [28, 43], "level": 2.4, "floor": 1.95}], "grid": grid})


func _boss() -> AbyssalLeviathan:
	for n in (game.get("rooms") as RoomManager).enemies_root.get_children():
		if n is AbyssalLeviathan:
			return n
	return null


func _start() -> void:
	var gs := GameState.new_game("normal")
	for v: String in ["caelan", "darius"]:
		gs.unlock_vessel(v)
	gs.loadout.assign(["darius", "caelan"])
	gs.checkpoint = {"room": "z1_01", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(3)
	(game.get("rooms") as RoomManager).enter_data(_shore(), "", Vector2(8.0, 2.05))
	await wait_frames(30)


func _strike(l: AbyssalLeviathan, amount: float) -> void:
	var p := DamagePacket.new()
	p.atk = amount
	p.crit_chance = 0.0
	p.source_x = l.global_position.x - 2.0
	l.receive_hit(p)


func test_the_shore_fight_from_eyes_to_the_rift() -> void:
	await _start()
	var l := _boss()
	assert_not_null(l)
	l.boundary_source = func(_a: float) -> float: return -1.0
	var rooms := game.get("rooms") as RoomManager
	assert_true(rooms.builder.gate_active("lock"))
	for i in range(3):
		var p := DamagePacket.new()
		p.atk = 320.0
		p.crit_chance = 0.0
		l.eyes[i].receive_hit(p)
	assert_true(l.posture.is_staggered(), "three eyes break it open")
	l.health.current = l.health.max_value * 0.64
	_strike(l, 50.0)
	assert_eq(l.phase, 1)
	await wait_frames(100)
	assert_gt(l.darkness.amount, 0.5, "the shore goes dark")
	l.health.current = l.health.max_value * 0.29
	_strike(l, 50.0)
	assert_eq(l.phase, 2)
	await wait_frames(100)
	assert_lt(l.darkness.amount, 0.5, "the dark lifts in phase 3")
	l.health.current = 1.0
	_strike(l, 500.0)
	await wait_frames(40)
	var state: GameState = game.get("state")
	assert_true(state.flag("boss_abyssal_leviathan"))
	assert_true(state.flag("unlock_overdrive"))
	assert_true(state.flag("rift_open"))
	assert_almost(Affinity.xp_multiplier(state, "darius"), 1.0, 0.001, "Darius trusts you now")
	# Story 056: boss drops land beside the player, so it may already be in the bag.
	var matrix := state.item_count("pure_soul_matrix") > 0
	for n in rooms.transient_root.get_children():
		if n is Pickup and (n as Pickup).item == "pure_soul_matrix":
			matrix = true
	assert_true(matrix, "the Pure Soul Matrix dropped")
	assert_true((game.get("saves") as SaveSystem).load_slot(0).flag("unlock_overdrive"), "saved")
