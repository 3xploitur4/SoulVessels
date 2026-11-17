extends TestCase
## Story 024: the wisp takes Caelan's body in the Knight's Vigil (and cannot leave before), the
## Warden's hall locks while the fight runs and opens for good when it falls, and tutorials and
## the Sovereign's lines fire once per save.

const DIR := "user://test_zone1"

var game: Node


func before_each() -> void:
	game = load("res://src/game/game.tscn").instantiate()
	game.set("save_dir", DIR)
	game.set("enable_bridge", false)
	add_node(game)
	await wait_frames(1)


func after_each() -> void:
	for a in ["move_left", "move_right"]:
		Input.action_release(a)
	tree.paused = false
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func _start(room: String, vessels: Array[String] = [], at: Vector2 = Vector2(-1.0, -1.0)) -> void:
	var gs := GameState.new_game("normal")
	for v in vessels:
		gs.unlock_vessel(v)
		gs.set_flag("possessed_" + v)
	gs.checkpoint = {"room": room, "x": at.x, "y": at.y}
	game.call("begin_run", 0, gs)
	await wait_frames(3)


func _features() -> Node:
	return (game.get("rooms") as RoomManager).features_root


func test_the_wisp_finds_caelans_body_and_takes_it() -> void:
	await _start("z1_02")
	var player: Player = game.get("player")
	assert_true(player.is_wisp(), "a new run starts as the wisp")
	var body := _features().get_node_or_null("Body_caelan") as PossessionBody
	assert_true(body != null, "the body lies in the Knight's Vigil")
	assert_true(body.can_interact(player))
	game.call("possess", "caelan", body)
	await wait_frames(2)
	var state: GameState = game.get("state")
	assert_false(player.is_wisp(), "now Caelan")
	assert_eq(player.loadout.active().id, "caelan")
	assert_true(state.flag("possessed_caelan"))
	assert_true(state.unlocked_vessels.has("caelan"))
	assert_true((game.get("saves") as SaveSystem).load_slot(0).flag("possessed_caelan"), "saved")


func test_a_taken_body_is_not_there_on_return() -> void:
	await _start("z1_02", ["caelan"])
	assert_true(_features().get_node_or_null("Body_caelan") == null)


func test_the_wisp_cannot_leave_the_vigil_before_possessing() -> void:
	await _start("z1_02")
	var rooms := game.get("rooms") as RoomManager
	var player: Player = game.get("player")
	player.teleport(21.5, 2.05)
	Input.action_press("move_right")
	await wait_frames(60)
	Input.action_release("move_right")
	await wait_frames(20)
	assert_eq(rooms.data.id, "z1_02", "still in the Vigil")
	assert_true(str((game.get("prompts") as Prompts).tutorial_text()).length() > 0, "told why")


func test_after_possessing_the_exit_opens() -> void:
	await _start("z1_02", ["caelan"])
	var rooms := game.get("rooms") as RoomManager
	var player: Player = game.get("player")
	player.teleport(21.5, 2.05)
	Input.action_press("move_right")
	for i in range(120):
		await wait_frames(1)
		if rooms.data.id != "z1_02":
			break
	Input.action_release("move_right")
	assert_eq(rooms.data.id, "z1_03")


func test_the_warden_hall_locks_during_the_fight_and_opens_after() -> void:
	# Arrive by the west door, as in play (the trigger span starts at x 8).
	await _start("z1_12", ["caelan"], Vector2(2.0, 2.0))
	var rooms := game.get("rooms") as RoomManager
	var player: Player = game.get("player")
	assert_false(rooms.builder.gate_active("lock"), "bars open before the fight")
	player.teleport(12.0, 2.05)
	await wait_frames(3)
	assert_true(rooms.builder.gate_active("lock"), "bars shut once the player walks in")
	var arena := _features().get_node("Arena") as Arena
	assert_true(arena.running)
	rooms.kill_all()
	await wait_frames(3)
	assert_false(rooms.builder.gate_bodies.has("lock"), "bars gone when the Warden falls")
	assert_true((game.get("state") as GameState).cleared_arenas.has("z1_12_warden"))


func test_a_cleared_hall_stays_open() -> void:
	var gs := GameState.new_game("normal")
	gs.unlock_vessel("caelan")
	gs.cleared_arenas.append("z1_12_warden")
	gs.checkpoint = {"room": "z1_12", "x": -1.0, "y": -1.0}
	game.call("begin_run", 0, gs)
	await wait_frames(3)
	assert_false((game.get("rooms") as RoomManager).builder.gate_bodies.has("lock"))


func test_a_tutorial_fires_once_per_save() -> void:
	await _start("z1_03", ["caelan"])
	var state: GameState = game.get("state")
	var prompts := game.get("prompts") as Prompts
	await wait_frames(2)
	assert_true(state.flag("story_TUT_ATTACK"), "attack tutorial shown on entry")
	assert_true(prompts.tutorial_text().length() > 0)
	prompts.clear()
	(game.get("rooms") as RoomManager).enter("z1_03")
	await wait_frames(3)
	assert_eq(prompts.tutorial_text(), "", "not shown again")


func test_the_wisp_does_not_get_the_attack_tutorial() -> void:
	await _start("z1_03")
	await wait_frames(2)
	assert_false((game.get("state") as GameState).flag("story_TUT_ATTACK"))
