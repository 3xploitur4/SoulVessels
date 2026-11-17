extends TestCase
## Story 038: Zone 3, the Sunken Palace. The flooded stair from Zone 2 leads in; Seris is broken
## out of her crystal in room 4 and joins the loadout; the Hall of Murals door is a rune sequence;
## the throne hall holds the Weeping Sovereign behind arena bars, in water; the zone has 18 rooms,
## 2 altars and 6 rune puzzles, and its way to Zone 4 is sealed.

const DIR := "user://test_zone3"

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


func _start(room: String, vessels: Array[String] = ["caelan", "nyra"], at: Vector2 = Vector2(-1.0, -1.0)) -> void:
	var gs := GameState.new_game("normal")
	for v in vessels:
		gs.unlock_vessel(v)
		gs.set_flag("possessed_" + v if v == "caelan" else "freed_" + v)
	gs.checkpoint = {"room": room, "x": at.x, "y": at.y}
	game.call("begin_run", 0, gs)
	await wait_frames(3)


func _features() -> Node:
	return (game.get("rooms") as RoomManager).features_root


func test_the_zone_has_eighteen_rooms_two_altars_and_six_rune_doors() -> void:
	var ids := WorldData.room_ids("zone3")
	assert_eq(ids.size(), 18)
	var altars := 0
	var puzzles := 0
	for id in ids:
		var r := WorldData.room(id)
		if r.raw.has("altar"):
			altars += 1
		if r.raw.has("runes"):
			puzzles += 1
	assert_eq(altars, 2)
	assert_eq(puzzles, 6)


func test_the_flooded_stair_leads_down_into_the_palace() -> void:
	var z2 := WorldData.room("z2_16")
	assert_true(z2.exits.has("2"))
	assert_eq(str(z2.exits["2"].get("to", "")), "z3_01")


func test_seris_is_broken_out_of_her_crystal_and_joins() -> void:
	await _start("z3_04")
	var c := _features().get_node_or_null("Crystal_seris") as RootPrison
	assert_not_null(c, "Seris sleeps in crystal in room 4")
	assert_eq(c.look, "crystal")
	var player: Player = game.get("player")
	var hits := int(Balance.combat("root_prison").get("hits", 3))
	for i in range(hits):
		var p := DamagePacket.new()
		p.team = CombatWorld.TEAM_PLAYER
		p.atk = 10.0
		c.receive_hit(p)
	assert_true(c.can_interact(player))
	game.call("free_vessel", "seris", c)
	await wait_frames(3)
	var state: GameState = game.get("state")
	assert_true(state.unlocked_vessels.has("seris"))
	assert_true(state.flag("freed_seris"))
	assert_true(player.loadout.index_of("seris") >= 0, "she joins the loadout")


func test_the_hall_of_murals_door_is_a_sequence_with_a_mural() -> void:
	await _start("z3_05", ["caelan", "nyra", "seris"])
	var p := _features().get_node_or_null("RunePuzzle") as RunePuzzle
	assert_not_null(p)
	assert_eq(p.sequence.kind, "sequence")
	assert_eq(p.positions.size(), 3)
	assert_true((game.get("rooms") as RoomManager).builder.gate_active("rune"))


func test_the_throne_hall_holds_the_sovereign_in_water() -> void:
	await _start("z3_17", ["caelan", "nyra", "seris"])
	var rooms := game.get("rooms") as RoomManager
	var boss: WeepingSovereign = null
	for n in rooms.enemies_root.get_children():
		if n is WeepingSovereign:
			boss = n
	assert_not_null(boss)
	assert_not_null(rooms.water("arena"))
	assert_not_null(_features().get_node_or_null("Arena"))


func test_the_way_to_zone_four_is_sealed() -> void:
	var r := WorldData.room("z3_18")
	assert_true(r.gate_rects.has("masonry"))
	assert_eq(r.exits.size(), 1, "only the way back")
