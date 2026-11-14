extends TestCase
## Story 018: Soul Essence on death, the Soul Echo and its recovery.


func _state(essence: int) -> GameState:
	var gs := GameState.new_game()
	gs.essence = essence
	gs.add_item("lesser_soul_shard", 2)
	gs.affinity_xp["caelan"] = 40.0
	return gs


func test_first_death_leaves_an_echo_with_all_essence() -> void:
	var gs := _state(120)
	var r := DeathRules.on_death(gs, "z1_05", Vector2(12, 2), true)
	assert_eq(gs.essence, 0)
	assert_eq(int(gs.echo["essence"]), 120)
	assert_eq(str(gs.echo["room"]), "z1_05")
	assert_eq(int(r["lost"]), 0)
	assert_eq(gs.deaths, 1)


func test_second_death_before_recovery_loses_the_old_echo() -> void:
	var gs := _state(120)
	DeathRules.on_death(gs, "z1_05", Vector2(12, 2), true)
	gs.essence = 30
	var r := DeathRules.on_death(gs, "z1_07", Vector2(4, 2), true)
	assert_eq(int(r["lost"]), 120, "the first echo is gone")
	assert_eq(int(gs.echo["essence"]), 30, "only what was carried this time")
	assert_eq(str(gs.echo["room"]), "z1_07")


func test_story_difficulty_merges_echoes_instead() -> void:
	var gs := _state(120)
	DeathRules.on_death(gs, "z1_05", Vector2(12, 2), false)
	gs.essence = 30
	var r := DeathRules.on_death(gs, "z1_07", Vector2(4, 2), false)
	assert_eq(int(r["lost"]), 0)
	assert_eq(int(gs.echo["essence"]), 150, "never lost: merged into the new echo")


func test_recovery_returns_the_essence_once() -> void:
	var gs := _state(80)
	DeathRules.on_death(gs, "z1_05", Vector2(12, 2), true)
	gs.essence = 5
	assert_eq(DeathRules.recover(gs), 80)
	assert_eq(gs.essence, 85)
	assert_true(gs.echo.is_empty())
	assert_eq(DeathRules.recover(gs), 0, "nothing left to recover")


func test_zero_essence_makes_no_echo_and_keeps_items() -> void:
	var gs := _state(0)
	DeathRules.on_death(gs, "z1_05", Vector2(12, 2), true)
	assert_true(gs.echo.is_empty())
	assert_eq(gs.item_count("lesser_soul_shard"), 2, "shards never lost")
	assert_almost(gs.affinity_xp["caelan"], 40.0, 0.001, "Affinity never lost")


func test_death_brings_back_ordinary_enemies() -> void:
	var gs := _state(10)
	gs.killed_commons.append("z1_03:0")
	gs.killed_elites.append("z1_12:0")
	DeathRules.on_death(gs, "z1_05", Vector2(12, 2), true)
	assert_true(gs.killed_commons.is_empty())
	assert_true(gs.killed_elites.has("z1_12:0"))


func test_respawn_point_prefers_the_rested_altar() -> void:
	var gs := _state(0)
	assert_eq(str(DeathRules.respawn_point(gs)["room"]), GameState.START_ROOM)
	gs.rested_altar = {"room": "z1_04", "altar": "altar_z1_a"}
	gs.checkpoint = {"room": "z1_04", "x": 12.7, "y": 2.0}
	var p := DeathRules.respawn_point(gs)
	assert_eq(str(p["room"]), "z1_04")
	assert_almost(float(p["x"]), 12.7, 0.001)
	gs.checkpoint = {"room": "z2_01", "x": 2.0, "y": 2.0}
	assert_eq(str(DeathRules.respawn_point(gs)["room"]), "z1_04", "a zone-entry checkpoint is not a respawn point")
