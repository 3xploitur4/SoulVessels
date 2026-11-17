extends TestCase
## Story 025: Nyra is cut free from the roots in room 8 and joins the loadout; the Husk ambush
## gauntlet locks its hall, sends three waves, then opens for good.

const DIR := "user://test_zone2"

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


func _start(room: String, at: Vector2 = Vector2(-1.0, -1.0), flags: Array[String] = []) -> void:
	var gs := GameState.new_game("normal")
	gs.unlock_vessel("caelan")
	gs.set_flag("possessed_caelan")
	for f in flags:
		gs.set_flag(f)
	gs.checkpoint = {"room": room, "x": at.x, "y": at.y}
	game.call("begin_run", 0, gs)
	await wait_frames(3)


func _features() -> Node:
	return (game.get("rooms") as RoomManager).features_root


func _hit(target: Node3D) -> DamagePacket.Result:
	var p := DamagePacket.new()
	p.team = CombatWorld.TEAM_PLAYER
	p.atk = 10.0
	return (target as RootPrison).receive_hit(p)


func test_the_roots_must_be_cut_before_nyra_can_be_freed() -> void:
	await _start("z2_08")
	var roots := _features().get_node_or_null("Roots_nyra") as RootPrison
	assert_true(roots != null, "Nyra is bound in room 8")
	var player: Player = game.get("player")
	assert_false(roots.can_interact(player), "not while the roots hold")
	var hits := int(Balance.combat("root_prison").get("hits", 3))
	for i in range(hits - 1):
		assert_eq(_hit(roots), DamagePacket.Result.HIT)
	assert_false(roots.can_interact(player), "one root left")
	assert_eq(_hit(roots), DamagePacket.Result.KILLED)
	assert_true(roots.can_interact(player), "free to take")
	assert_eq(_hit(roots), DamagePacket.Result.IGNORED, "nothing left to cut")


func test_the_player_attack_reaches_the_roots() -> void:
	await _start("z2_08")
	var roots := _features().get_node("Roots_nyra") as RootPrison
	var world: CombatWorld = game.get("world")
	var hits: Array[Node3D] = []
	world.query_rect(roots.hurt_rect(), CombatWorld.TEAM_ENEMY, hits)
	assert_true(hits.has(roots), "the roots are a target for player attacks")


func test_freeing_nyra_adds_her_and_keeps_caelan_in_hand() -> void:
	await _start("z2_08")
	var roots := _features().get_node("Roots_nyra") as RootPrison
	for i in range(int(Balance.combat("root_prison").get("hits", 3))):
		_hit(roots)
	game.call("free_vessel", "nyra", roots)
	await wait_frames(2)
	var player: Player = game.get("player")
	var state: GameState = game.get("state")
	assert_eq(player.loadout.active().id, "caelan", "Caelan stays active")
	assert_true(player.loadout.index_of("nyra") >= 0, "Nyra in the loadout")
	assert_true(state.flag("freed_nyra"))
	assert_true((game.get("saves") as SaveSystem).load_slot(0).unlocked_vessels.has("nyra"), "saved")


func test_a_freed_nyra_is_not_bound_again() -> void:
	await _start("z2_08", Vector2(-1.0, -1.0), ["freed_nyra"])
	assert_true(_features().get_node_or_null("Roots_nyra") == null)


func test_the_gauntlet_sends_three_waves_then_opens() -> void:
	await _start("z2_13", Vector2(2.0, 2.0))
	var rooms := game.get("rooms") as RoomManager
	var player: Player = game.get("player")
	var arena := _features().get_node("Arena") as Arena
	assert_eq(rooms.enemies().size(), 2, "only the first wave stands in the hall")
	assert_eq(arena.waves_left(), 2)
	player.teleport(10.0, 2.05)
	await wait_frames(3)
	assert_true(rooms.builder.gate_active("lock"), "exits lock")
	rooms.kill_all()
	await wait_frames(3)
	assert_eq(rooms.enemies().size(), 3, "second wave")
	rooms.kill_all()
	await wait_frames(3)
	assert_eq(rooms.enemies().size(), 3, "third wave")
	assert_true(rooms.builder.gate_active("lock"), "still locked")
	rooms.kill_all()
	await wait_frames(3)
	assert_false(rooms.builder.gate_bodies.has("lock"), "open after the last wave")
	assert_true((game.get("state") as GameState).cleared_arenas.has("z2_13_gauntlet"))


func test_later_waves_come_awake() -> void:
	await _start("z2_13", Vector2(2.0, 2.0))
	var rooms := game.get("rooms") as RoomManager
	(game.get("player") as Player).teleport(10.0, 2.05)
	await wait_frames(3)
	rooms.kill_all()
	await wait_frames(3)
	for e in rooms.enemies():
		assert_false(bool(e.get("dormant")), "%s is awake" % e.name)
