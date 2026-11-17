extends TestCase
## Story 019: placed pickups are taken once and remembered; lore items become lore entries;
## enemy drops home in on the player.

const DIR := "user://test_loot"

var game: Node


func before_each() -> void:
	game = load("res://src/game/game.tscn").instantiate()
	game.set("save_dir", DIR)
	game.set("enable_bridge", false)
	add_node(game)
	await wait_frames(1)
	var gs := GameState.new_game("normal")
	gs.unlock_vessel("caelan")
	gs.checkpoint = {"room": "z1_05", "x": 20.0, "y": 2.0}
	game.call("begin_run", 0, gs)
	await wait_frames(2)


func after_each() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func _pickups() -> Array[Pickup]:
	var out: Array[Pickup] = []
	var rooms: RoomManager = game.get("rooms")
	for root: Node in [rooms.features_root, rooms.transient_root]:
		for c in root.get_children():
			if c is Pickup and not c.is_queued_for_deletion():
				out.append(c as Pickup)
	return out


func test_placed_pickup_is_taken_once_and_remembered() -> void:
	var state: GameState = game.get("state")
	var rooms: RoomManager = game.get("rooms")
	var player: Player = game.get("player")
	var p := _pickups()
	assert_eq(p.size(), 1, "the veil pocket shard")
	player.teleport(p[0].global_position.x, p[0].global_position.y)
	# Pickups move on render frames, the test waits on physics frames: allow up to 1 s.
	for i in range(60):
		await wait_frames(1)
		if state.item_count("lesser_soul_shard") > 0:
			break
	assert_eq(state.item_count("lesser_soul_shard"), 1)
	assert_true(state.taken_pickups.has("z1_05:0"))
	rooms.enter("z1_05", "0")
	await wait_frames(1)
	assert_eq(_pickups().size(), 0, "never comes back")


func test_parchment_becomes_the_next_lore_entry() -> void:
	var state: GameState = game.get("state")
	game.call("collect_item", "faded_parchment", 1)
	game.call("collect_item", "faded_parchment", 1)
	assert_eq(state.lore_found, ["parchment_01", "parchment_02"] as Array[String])
	assert_eq(state.item_count("faded_parchment"), 0, "lore items are not inventory")


func test_lore_overflow_pays_essence() -> void:
	var state: GameState = game.get("state")
	for e in LoreDb.of_kind("relic"):
		state.lore_found.append(str(e["id"]))
	game.call("collect_item", "echoing_relic", 1)
	assert_eq(state.essence, 60)


func test_enemy_drop_homes_in_and_is_collected() -> void:
	var state: GameState = game.get("state")
	var loot: LootTable = game.get("loot")
	loot.config["drop_chance"]["common"] = 1.0
	var rooms: RoomManager = game.get("rooms")
	var player: Player = game.get("player")
	var e := rooms.enemies()[0]
	player.teleport(e.global_position.x - 6.0, 2.0)
	GameEvents.enemy_died.emit(e)
	assert_eq(state.essence, 12)
	var before := state.inventory.size() + state.lore_found.size()
	for i in range(240):
		await wait_frames(1)
		if state.inventory.size() + state.lore_found.size() > before:
			break
	assert_gt(float(state.inventory.size() + state.lore_found.size()), float(before), "the drop reached the player 6 m away")
	loot.config["drop_chance"]["common"] = 0.35
