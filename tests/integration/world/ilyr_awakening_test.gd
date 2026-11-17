extends TestCase
## Story 047 (integration): Ilyr's awakening. In the awakening room the player is Ilyr alone; the
## four erased echoes come one after another; when the last falls, Ilyr speaks, the chapter-end
## screen shows, Chapter I is marked complete (Abyssal unlocks for new games), and the save keeps
## the real loadout.

const DIR := "user://test_awakening"

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


func _room() -> RoomData:
	var grid: Array = []
	grid.append("##############################")
	for i in range(9):
		grid.append("#............................#")
	grid.append("#............................#")
	grid.append("##############################")
	grid.append("##############################")
	return RoomData.parse("t_wake", "zone4", {"grid": grid,
		"awakening": {"echoes": ["echo_caelan", "echo_nyra", "echo_seris", "echo_darius"], "spawn_x": 20.0}})


func _start() -> void:
	var gs := GameState.new_game("normal")
	for v: String in ["caelan", "nyra", "seris", "darius"]:
		gs.unlock_vessel(v)
	gs.loadout.assign(["caelan", "darius", "seris"])
	gs.checkpoint = {"room": "z1_01", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(3)
	(game.get("rooms") as RoomManager).enter_data(_room(), "", Vector2(6.0, 2.05))
	await wait_frames(20)


func _echo() -> EnemyBase:
	for n in (game.get("rooms") as RoomManager).enemies_root.get_children():
		if n is ErasedEcho and (n as EnemyBase).is_alive():
			return n
	return null


func test_the_awakening_runs_to_the_chapter_end() -> void:
	await _start()
	var player: Player = game.get("player")
	assert_eq(player.vessel_ids, ["ilyr"] as Array[String], "the Intruder is Ilyr alone")
	var order: Array[String] = []
	for i in range(4):
		var e := _echo()
		for f in range(120):
			if e != null:
				break
			await wait_frames(1)
			e = _echo()
		assert_not_null(e, "echo %d appears" % (i + 1))
		order.append(e.enemy_id)
		e.health.current = 1.0
		var p := DamagePacket.new()
		p.atk = 100.0
		p.crit_chance = 0.0
		e.receive_hit(p)
		await wait_frames(40)
	assert_eq(order, ["echo_caelan", "echo_nyra", "echo_seris", "echo_darius"] as Array[String])
	await wait_frames(420)
	var state: GameState = game.get("state")
	assert_true(state.flag("chapter1_complete"))
	assert_true(game.get("chapter_end") != null, "the chapter-end screen shows")
	assert_true((game.get("saves") as SaveSystem).chapter_complete(), "Abyssal unlocks for new games")
	var loaded := (game.get("saves") as SaveSystem).load_slot(0)
	assert_eq(loaded.loadout, ["caelan", "darius", "seris"] as Array[String], "the real loadout is kept")


func test_the_title_offers_abyssal_only_after_chapter_one() -> void:
	var saves: SaveSystem = game.get("saves")
	var t := TitleScreen.new()
	t.abyssal_unlocked = saves.chapter_complete()
	add_node(t)
	t.call("_show_difficulty", 1)
	await wait_frames(2)
	assert_true((t.find_child("Difficulty_abyssal", true, false) as Button).disabled, "locked on a fresh profile")
	t.queue_free()
	saves.mark_chapter_complete()
	var t2 := TitleScreen.new()
	t2.abyssal_unlocked = saves.chapter_complete()
	add_node(t2)
	t2.call("_show_difficulty", 1)
	await wait_frames(2)
	assert_false((t2.find_child("Difficulty_abyssal", true, false) as Button).disabled, "open after Chapter I")
