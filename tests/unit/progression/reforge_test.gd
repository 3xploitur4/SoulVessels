extends TestCase
## Story 036: the weapon reforge rules — costs, either-or materials and crafting.

const VESSEL := "caelan"


func _reforge() -> Reforge:
	return Reforge.from_data()


func test_data_essence_costs_match_the_addendum() -> void:
	var reforge := _reforge()
	var expected := {1: 300, 2: 700, 3: 1500, 4: 3000, 5: 6000}
	assert_eq(reforge.levels.size(), 5, "one row per level 1..5")
	for entry: Dictionary in reforge.levels:
		var lvl := int(entry["level"])
		assert_eq(int(entry["essence"]), expected[lvl], "level %d essence" % lvl)


func test_level_three_is_paid_with_either_material() -> void:
	var reforge := _reforge()
	var gs := GameState.new_game("normal")
	gs.weapon_levels[VESSEL] = 2
	gs.essence = 1500
	gs.add_item("luminous_root_resin", 2)
	assert_eq(reforge.affordable_option(gs, VESSEL), 1, "resin option, no basalt held")
	assert_true(reforge.can_reforge(gs, VESSEL))
	assert_true(reforge.reforge(gs, VESSEL))
	assert_eq(reforge.level(gs, VESSEL), 3)
	assert_eq(gs.item_count("luminous_root_resin"), 0)


func test_reforge_with_too_little_essence_changes_nothing() -> void:
	var reforge := _reforge()
	var gs := GameState.new_game("normal")
	gs.essence = 299
	gs.add_item("crude_stone", 3)
	assert_false(reforge.can_reforge(gs, VESSEL))
	assert_false(reforge.reforge(gs, VESSEL))
	assert_eq(gs.essence, 299)
	assert_eq(gs.item_count("crude_stone"), 3)
	assert_eq(reforge.level(gs, VESSEL), 0)


func test_successful_reforge_spends_exactly_the_cost() -> void:
	var reforge := _reforge()
	var gs := GameState.new_game("normal")
	gs.essence = 1000
	gs.add_item("crude_stone", 3)
	assert_true(reforge.reforge(gs, VESSEL))
	assert_eq(gs.essence, 700)
	assert_eq(gs.item_count("crude_stone"), 0)
	assert_eq(reforge.level(gs, VESSEL), 1)


func test_atk_multiplier_is_eight_percent_per_level() -> void:
	assert_almost(_reforge().atk_multiplier(3), 1.24, 0.001)


func test_coating_slot_only_from_plus_three() -> void:
	var reforge := _reforge()
	assert_false(reforge.has_coating_slot(2))
	assert_true(reforge.has_coating_slot(3))
	assert_true(reforge.has_coating_slot(5))


func test_no_reforge_past_plus_five() -> void:
	var reforge := _reforge()
	var gs := GameState.new_game("normal")
	gs.essence = 9999
	gs.add_item("sovereigns_crown_fragment", 1)
	gs.weapon_levels[VESSEL] = 5
	assert_true(reforge.next_cost(gs, VESSEL).is_empty())
	assert_eq(reforge.affordable_option(gs, VESSEL), -1)
	assert_false(reforge.can_reforge(gs, VESSEL))
	assert_false(reforge.reforge(gs, VESSEL))
	assert_eq(reforge.level(gs, VESSEL), 5)
	assert_eq(gs.essence, 9999)


func test_censer_core_craft_takes_three_shards() -> void:
	var reforge := _reforge()
	var gs := GameState.new_game("normal")
	gs.add_item("tarnished_censer_shard", 3)
	assert_true(reforge.can_craft(gs, "censer_core"))
	assert_true(reforge.craft(gs, "censer_core"))
	assert_eq(gs.item_count("tarnished_censer_shard"), 0)
	assert_eq(gs.item_count("censer_core"), 1)
	gs.add_item("tarnished_censer_shard", 2)
	assert_false(reforge.craft(gs, "censer_core"), "needs a third shard")


func test_weapon_levels_survive_a_save_round_trip() -> void:
	var gs := GameState.new_game("normal")
	gs.weapon_levels[VESSEL] = 3
	var restored := GameState.from_dict(gs.to_dict())
	assert_eq(restored.weapon_levels.get(VESSEL, -1), 3)
