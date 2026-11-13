extends TestCase
## Story 014: the save-slot state round-trips and defaults safely.


func _filled() -> GameState:
	var gs := GameState.new_game("story")
	gs.essence = 420
	gs.add_item("lesser_soul_shard", 3)
	gs.add_item("crude_stone", 7)
	gs.soul_core.append("core_hp_1")
	gs.unlock_vessel("caelan")
	gs.unlock_vessel("nyra")
	gs.affinity_xp["caelan"] = 155.5
	gs.affinity_bonus["nyra"] = 1
	gs.rested_altar = {"room": "z1_04", "altar": "altar_z1_a"}
	gs.lit_altars.append("altar_z1_a")
	gs.checkpoint = {"room": "z1_04", "x": 6.5, "y": 1.0}
	gs.resume = {"room": "z1_05", "x": 12.0, "y": 3.0}
	gs.killed_elites.append("z1_12:0")
	gs.killed_commons.append("z1_03:1")
	gs.cleared_arenas.append("z1_12")
	gs.opened_gates.append("z1_08:ward")
	gs.taken_pickups.append("z1_06:0")
	gs.lore_found.append("parchment_01")
	gs.lore_read.append("parchment_01")
	gs.echo = {"room": "z1_05", "x": 9.0, "y": 0.0, "essence": 80}
	gs.visited_rooms.append("z1_01")
	gs.set_flag("possessed_caelan")
	gs.elite_pity = 4
	gs.play_time_s = 1234.5
	gs.deaths = 2
	gs.current_room = "z1_05"
	return gs


func test_round_trip_keeps_every_field() -> void:
	var gs := _filled()
	var back := GameState.from_dict(gs.to_dict())
	assert_eq(back.to_dict(), gs.to_dict())


func test_round_trip_survives_json_text() -> void:
	var gs := _filled()
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	var back := GameState.from_dict(parsed)
	assert_eq(back.item_count("lesser_soul_shard"), 3)
	assert_eq(back.loadout, gs.loadout)
	assert_almost(back.affinity_xp["caelan"], 155.5)
	assert_eq(back.affinity_bonus["nyra"], 1)
	assert_eq(int(back.echo["essence"]), 80)
	assert_true(back.flag("possessed_caelan"))


func test_missing_and_bad_keys_fall_back_to_defaults() -> void:
	var back := GameState.from_dict({"essence": -5, "inventory": {"x": 0, "y": 2}, "loadout": "oops"})
	assert_eq(back.essence, 0, "Essence never negative")
	assert_eq(back.item_count("x"), 0, "zero counts dropped")
	assert_eq(back.item_count("y"), 2)
	assert_eq(back.loadout.size(), 0, "a non-array becomes empty")
	assert_eq(back.difficulty, "normal")
	assert_eq(str(back.checkpoint["room"]), GameState.START_ROOM, "a save always has somewhere to load")


func test_new_game_starts_as_the_wisp() -> void:
	var gs := GameState.new_game()
	assert_eq(gs.loadout.size(), 0, "no Vessel yet")
	assert_eq(gs.current_room, GameState.START_ROOM)


func test_spend_item_refuses_when_short() -> void:
	var gs := GameState.new()
	gs.add_item("lesser_soul_shard", 1)
	assert_false(gs.spend_item("lesser_soul_shard", 2))
	assert_eq(gs.item_count("lesser_soul_shard"), 1, "nothing taken")
	assert_true(gs.spend_item("lesser_soul_shard", 1))
	assert_false(gs.inventory.has("lesser_soul_shard"), "empty entries removed")


func test_unlock_vessel_equips_until_the_loadout_is_full() -> void:
	var gs := GameState.new()
	for id: String in ["caelan", "nyra", "seris", "darius"]:
		gs.unlock_vessel(id)
	assert_eq(gs.unlocked_vessels.size(), 4)
	assert_eq(gs.loadout, ["caelan", "nyra", "seris"] as Array[String], "3 slots")


func test_rest_brings_commons_back_not_elites() -> void:
	var gs := _filled()
	gs.reset_commons()
	assert_false(gs.is_spawn_dead("z1_03:1", false))
	assert_true(gs.is_spawn_dead("z1_12:0", true))
