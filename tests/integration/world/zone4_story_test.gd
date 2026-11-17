extends TestCase
## Story 049: Zone 4, the Sealed Rift and the Starless Shore. 14 rooms, 1 altar and a checkpoint
## before each boss; Darius is dug out of the rubble in room 3 and joins; dark rooms, sliding
## floors, masonry, Crawler swarms of 8 and Wardens; the Guardian's lift and the Leviathan's shore;
## the rift its fall opens leads into Ilyr's awakening.

const DIR := "user://test_zone4"
const ALL: Array[String] = ["caelan", "nyra", "seris", "darius"]

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


func _start(room: String, vessels: Array[String] = ALL, at: Vector2 = Vector2(-1.0, -1.0)) -> GameState:
	var gs := GameState.new_game("normal")
	for v in vessels:
		gs.unlock_vessel(v)
		gs.set_flag("possessed_" + v if v == "caelan" else "freed_" + v)
	gs.checkpoint = {"room": room, "x": at.x, "y": at.y}
	game.call("begin_run", 0, gs)
	await wait_frames(3)
	return game.get("state")


func _rooms() -> RoomManager:
	return game.get("rooms") as RoomManager


func _count(code_id: String) -> Dictionary:
	var per_room := {}
	for id in WorldData.room_ids("zone4"):
		var n := 0
		for s: Dictionary in WorldData.room(id).spawns:
			if str(s["id"]) == code_id:
				n += 1
		if n > 0:
			per_room[id] = n
	return per_room


func test_fourteen_rooms_one_altar_two_checkpoints() -> void:
	var ids := WorldData.room_ids("zone4")
	assert_eq(ids.size(), 14)
	var altars := 0
	var checkpoints: Array[String] = []
	for id in ids:
		var r := WorldData.room(id)
		if r.markers.has("altar"):
			altars += 1
		if bool(r.raw.get("checkpoint", false)):
			checkpoints.append(id)
	assert_eq(altars, 1)
	assert_eq(checkpoints, ["z4_09", "z4_12"] as Array[String])
	# Each checkpoint room leads straight into its boss.
	assert_eq(str(WorldData.room("z4_09").exits["1"]["to"]), "z4_10")
	assert_eq(str(WorldData.room("z4_12").exits["1"]["to"]), "z4_13")


func test_the_zone_has_its_mechanics() -> void:
	var dark := 0
	var slides := 0
	var masonry := 0
	for id in WorldData.room_ids("zone4"):
		var r := WorldData.room(id)
		dark += 1 if r.dark else 0
		slides += 1 if not r.slides.is_empty() else 0
		masonry += 1 if r.gate_rects.has("masonry") else 0
	assert_true(dark >= 3, "dark rooms")
	assert_true(slides >= 3, "sliding floors")
	assert_true(masonry >= 3, "masonry walls")
	var swarms := _count("echo_crawler")
	assert_true(swarms.size() >= 3, "three swarms")
	for id: String in swarms:
		assert_eq(swarms[id], 8, id + ": Crawlers come in eights")
	assert_true(_count("branded_warden").size() >= 3, "Wardens")


func test_the_breach_leads_down_from_the_palace() -> void:
	assert_eq(str(WorldData.room("z4_01").exits["0"]["to"]), "z3_18")
	assert_eq(WorldData.zone_of("z4_01"), "zone4")


func test_darius_is_dug_out_of_the_rubble_and_joins() -> void:
	var state := await _start("z4_03", ["caelan", "nyra", "seris"] as Array[String])
	var r := _rooms().features_root.get_node_or_null("Rubble_darius") as RootPrison
	assert_not_null(r, "Darius lies under the rubble in room 3")
	assert_eq(r.look, "rubble")
	var player: Player = game.get("player")
	assert_false(r.can_interact(player))
	while r.is_alive():
		var p := DamagePacket.new()
		p.team = CombatWorld.TEAM_PLAYER
		p.atk = 10.0
		r.receive_hit(p)
	assert_true(r.can_interact(player))
	game.call("free_vessel", "darius", r)
	await wait_frames(3)
	assert_true(state.unlocked_vessels.has("darius"))
	assert_true(player.loadout.index_of("darius") >= 0, "he joins the loadout")
	assert_true(_rooms().builder.gate_active("masonry"), "the way on is masonry he must break")


func test_a_checkpoint_before_the_boss_is_where_death_returns() -> void:
	var state := await _start("z4_04")
	state.rested_altar = {"room": "z4_04", "altar": "altar_z4_a"}
	_rooms().enter("z4_09", "0")
	await wait_frames(3)
	var back := DeathRules.respawn_point(state)
	assert_eq(str(back["room"]), "z4_09", "not the altar")
	assert_true(float(back["x"]) > 0.0)


func test_the_guardian_waits_on_the_lift() -> void:
	await _start("z4_10")
	var boss: GuardianBelow = null
	for n in _rooms().enemies_root.get_children():
		if n is GuardianBelow:
			boss = n
	assert_not_null(boss)
	assert_not_null(_rooms().features_root.get_node_or_null("Arena"))
	assert_eq(get_tree_nodes_in_group("slide_zone").size(), 1, "the lift floor can tilt")


func test_the_shore_has_its_own_music() -> void:
	await _start("z4_11")
	assert_eq(MusicDirector.zone, "zone4_shore")
	assert_not_null(_rooms().darkness)


func test_the_rift_opens_when_the_leviathan_falls_and_leads_to_the_awakening() -> void:
	var state := await _start("z4_13")
	var rift := _rooms().features_root.get_node_or_null("Rift") as RiftPortal
	assert_not_null(rift)
	var player: Player = game.get("player")
	assert_false(rift.can_interact(player), "sealed while the Leviathan lives")
	assert_false(rift.visible)
	state.set_flag("rift_open")
	await wait_frames(2)
	assert_true(rift.visible, "the tear shows once open")
	assert_true(rift.can_interact(player))
	await rift.manager.travel("z4_14", "", rift.arrive)
	assert_eq(_rooms().data.id, "z4_14")
	assert_not_null(_rooms().features_root.get_node_or_null("Awakening"))


func get_tree_nodes_in_group(g: String) -> Array[Node]:
	return tree.get_nodes_in_group(g)
