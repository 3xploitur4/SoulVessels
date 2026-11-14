extends TestCase
## Story 020: Affinity levels from XP and memory bonuses.


func test_xp_thresholds_map_to_levels() -> void:
	var t: Array = Affinity.config()["level_xp"]
	assert_eq(Affinity.xp_level(0.0), 0)
	assert_eq(Affinity.xp_level(float(t[1]) - 0.1), 0)
	assert_eq(Affinity.xp_level(float(t[1])), 1)
	assert_eq(Affinity.xp_level(float(t[3])), 3)
	assert_eq(Affinity.xp_level(999999.0), 5, "capped at 5")


func test_kill_xp_raises_the_level_and_reports_it() -> void:
	var gs := GameState.new_game()
	var kills := int(ceil(float(Affinity.config()["level_xp"][1]) / Affinity.xp_for("kill")))
	var gained := -1
	for i in range(kills):
		var r := Affinity.add_xp(gs, "caelan", "kill")
		if r != -1:
			gained = r
	assert_eq(gained, 1)
	assert_eq(Affinity.level(gs, "caelan"), 1)
	assert_eq(Affinity.level(gs, "nyra"), 0, "per Vessel")


func test_memory_bonus_adds_a_level_and_caps_at_five() -> void:
	var gs := GameState.new_game()
	gs.affinity_xp["nyra"] = float(Affinity.config()["level_xp"][2])
	gs.affinity_bonus["nyra"] = 1
	assert_eq(Affinity.level(gs, "nyra"), 3)
	gs.affinity_bonus["nyra"] = 9
	assert_eq(Affinity.level(gs, "nyra"), 5)


func test_combat_time_gives_xp_by_the_second() -> void:
	var gs := GameState.new_game()
	Affinity.add_xp(gs, "caelan", "combat_s", 10.0)
	assert_almost(float(gs.affinity_xp["caelan"]), 10.0 * Affinity.xp_for("combat_s"), 0.001)


func test_the_wisp_earns_nothing() -> void:
	var gs := GameState.new_game()
	assert_eq(Affinity.add_xp(gs, "wisp", "kill"), -1)
	assert_true(gs.affinity_xp.is_empty())
