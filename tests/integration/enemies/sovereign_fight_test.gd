extends TestCase
## Story 034 (integration): the Weeping Sovereign in a stand-in throne hall (the real one is built
## in story 038). The arena locks when the fight starts and the HUD shows her bars; damage takes
## her through all three phases and phase 2 raises the water; her defeat opens the bars, drops
## the Sovereign's Crown Fragment, gives Caelan +1 Affinity with his goodbye line, and is saved,
## so she is not there on return. Dying first restarts her at phase 1 with full health.

const DIR := "user://test_sovereign"

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


func _hall() -> RoomData:
	var grid: Array = []
	grid.append("##################################")
	for i in range(8):
		grid.append("L................................L")
	grid.append("L......................B.........L")
	grid.append("##################################")
	grid.append("##################################")
	var d := {"theme": "cavern", "boss": "weeping_sovereign",
		"arena": {"id": "t_throne", "trigger_x": [6.0, 28.0]},
		"water": [{"id": "arena", "x": [1, 33], "level": 2.3, "floor": 1.95}],
		"grid": grid}
	return RoomData.parse("t_throne", "zone3", d)


func _start() -> void:
	var gs := GameState.new_game("normal")
	for v: String in ["caelan", "nyra", "seris"]:
		gs.unlock_vessel(v)
		gs.set_flag("possessed_" + v)
	gs.loadout.assign(["caelan", "nyra", "seris"])
	gs.checkpoint = {"room": "z1_01", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(3)
	var rooms := game.get("rooms") as RoomManager
	rooms.enter_data(_hall(), "", Vector2(10.0, 2.05))
	await wait_frames(30)


func _boss() -> WeepingSovereign:
	for n in (game.get("rooms") as RoomManager).enemies_root.get_children():
		if n is WeepingSovereign:
			return n
	return null


func _strike(b: Boss, amount: float) -> void:
	var p := DamagePacket.new()
	p.atk = amount
	p.crit_chance = 0.0
	p.source_x = b.global_position.x - 2.0
	b.receive_hit(p)


func test_the_fight_runs_through_three_phases_and_is_won() -> void:
	await _start()
	var b := _boss()
	assert_not_null(b, "she is in her hall")
	b.boundary_source = func(_a: float) -> float: return -1.0
	await wait_frames(30)
	var rooms := game.get("rooms") as RoomManager
	assert_true(rooms.builder.gate_active("lock"), "the bars shut when the fight starts")
	assert_eq((game.get("hud") as Hud).boss, b, "the HUD shows her bars")
	var water := rooms.water("arena")
	var level0 := water.level
	b.health.current = b.health.max_value * 0.61
	_strike(b, 300.0)
	assert_eq(b.phase, 1)
	await wait_frames(200)
	assert_almost(water.level, level0 + 1.5, 0.05, "phase 2 raised the water")
	b.health.current = b.health.max_value * 0.26
	_strike(b, 300.0)
	assert_eq(b.phase, 2)
	await wait_frames(100)
	var state: GameState = game.get("state")
	var bonus0 := int(state.affinity_bonus.get("caelan", 0))
	b.health.current = 1.0
	_strike(b, 300.0)
	await wait_frames(40)
	assert_false(rooms.builder.gate_active("lock"), "the bars open")
	assert_true(state.flag("boss_weeping_sovereign"))
	assert_eq(int(state.affinity_bonus.get("caelan", 0)), bonus0 + 1, "Caelan's goodbye: +1 Affinity")
	assert_true(str((game.get("prompts") as Prompts).subtitle_text()).length() > 0, "his line plays")
	# Story 056: boss drops land beside the player, so it may already be in the bag.
	var crown := state.item_count("sovereigns_crown_fragment") > 0
	for n in rooms.transient_root.get_children():
		if n is Pickup and (n as Pickup).item == "sovereigns_crown_fragment":
			crown = true
	assert_true(crown, "the Crown Fragment dropped")
	assert_true((game.get("saves") as SaveSystem).load_slot(0).flag("boss_weeping_sovereign"), "saved")
	rooms.enter_data(_hall(), "", Vector2(10.0, 2.05))
	await wait_frames(5)
	assert_null(_boss(), "she stays dead")


func test_dying_restarts_her_at_phase_one() -> void:
	await _start()
	var b := _boss()
	b.boundary_source = func(_a: float) -> float: return -1.0
	await wait_frames(30)
	b.health.current = b.health.max_value * 0.5
	_strike(b, 100.0)
	assert_eq(b.phase, 1)
	var rooms := game.get("rooms") as RoomManager
	rooms.enter_data(_hall(), "", Vector2(10.0, 2.05))
	await wait_frames(5)
	var again := _boss()
	assert_not_null(again)
	assert_eq(again.phase, 0)
	assert_almost(again.health.current, again.health.max_value)
