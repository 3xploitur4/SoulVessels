extends TestCase
## Story 044 (integration): the Guardian Below on a stand-in elevator (Zone 4's real one comes in
## story 049). The arena locks; hits on its fists walk it through three phases; phase 2 tilts the
## elevator and rolls boulders; its defeat opens the bars, drops the Heart of the Guardian, sets the
## Greatsword unlock, and is saved.

const DIR := "user://test_guardian"

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
	grid.append("##########################")
	for i in range(9):
		grid.append("L........................L")
	grid.append("L.................B......L")
	grid.append("##########################")
	grid.append("##########################")
	return RoomData.parse("t_lift", "zone4", {"boss": "guardian_below",
		"arena": {"id": "t_lift_arena", "trigger_x": [3.0, 23.0]},
		"slides": [{"x": [1, 25], "y": [2, 4], "angle": 0}], "grid": grid})


func _start() -> void:
	var gs := GameState.new_game("normal")
	for v: String in ["caelan", "darius"]:
		gs.unlock_vessel(v)
	gs.loadout.assign(["darius", "caelan"])
	gs.checkpoint = {"room": "z1_01", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(3)
	(game.get("rooms") as RoomManager).enter_data(_hall(), "", Vector2(6.0, 2.05))
	await wait_frames(30)


func _boss() -> GuardianBelow:
	for n in (game.get("rooms") as RoomManager).enemies_root.get_children():
		if n is GuardianBelow:
			return n
	return null


func _fist(g: GuardianBelow, amount: float) -> void:
	var p := DamagePacket.new()
	p.atk = amount
	p.crit_chance = 0.0
	p.source_x = g.global_position.x - 2.0
	g.zone_hit(p, "fist")


func test_three_phases_the_tilt_and_the_win() -> void:
	await _start()
	var g := _boss()
	assert_not_null(g)
	g.boundary_source = func(_a: float) -> float: return -1.0
	var rooms := game.get("rooms") as RoomManager
	assert_true(rooms.builder.gate_active("lock"), "the elevator's bars shut")
	g.health.current = g.health.max_value * 0.64
	_fist(g, 100.0)
	assert_eq(g.phase, 1)
	await wait_frames(150)
	var zone: SlideZone = null
	for n in rooms.features_root.get_children():
		if n is SlideZone:
			zone = n
	assert_almost(zone.angle, 15.0, 0.1, "the elevator tilts")
	g.health.current = g.health.max_value * 0.29
	_fist(g, 100.0)
	assert_eq(g.phase, 2)
	assert_true(g.core_open())
	await wait_frames(100)
	g.health.current = 1.0
	_fist(g, 500.0)
	await wait_frames(40)
	var state: GameState = game.get("state")
	assert_true(state.flag("boss_guardian_below"))
	assert_true(state.flag("unlock_greatsword"), "Caelan's Greatsword is unlocked")
	assert_false(rooms.builder.gate_active("lock"), "the bars open")
	var heart := false
	for n in rooms.transient_root.get_children():
		if n is Pickup and (n as Pickup).item == "heart_of_the_guardian":
			heart = true
	assert_true(heart, "the Heart of the Guardian dropped")
	assert_true((game.get("saves") as SaveSystem).load_slot(0).flag("boss_guardian_below"), "saved")
