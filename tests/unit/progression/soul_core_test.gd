extends TestCase
## Story 020: the Soul Core tree rules and its summed modifiers.


func _state(shards: int) -> GameState:
	var gs := GameState.new_game()
	gs.add_item("lesser_soul_shard", shards)
	return gs


func test_tree_has_twenty_nodes_one_shard_each() -> void:
	var core := SoulCore.from_data()
	assert_eq(core.order.size(), 20, "addendum: 20 nodes")
	for id in core.order:
		assert_eq(core.cost(id), 1, id)
		for req: Variant in core.nodes[id].get("requires", []):
			assert_true(core.nodes.has(str(req)), "%s requires unknown %s" % [id, req])


func test_root_is_buyable_and_children_are_locked() -> void:
	var core := SoulCore.from_data()
	var gs := _state(1)
	assert_eq(core.status(gs, "core_heart"), "buyable")
	assert_eq(core.status(gs, "vitality_1"), "locked")


func test_buy_spends_a_shard_and_unlocks_the_next_node() -> void:
	var core := SoulCore.from_data()
	var gs := _state(2)
	assert_true(core.buy(gs, "core_heart"))
	assert_eq(gs.item_count("lesser_soul_shard"), 1)
	assert_eq(core.status(gs, "core_heart"), "owned")
	assert_eq(core.status(gs, "vitality_1"), "buyable")
	assert_false(core.buy(gs, "core_heart"), "cannot buy twice")


func test_no_shard_is_reported_and_refused() -> void:
	var core := SoulCore.from_data()
	var gs := _state(0)
	assert_eq(core.status(gs, "core_heart"), "no_shard")
	assert_false(core.buy(gs, "core_heart"))
	assert_true(gs.soul_core.is_empty())


func test_node_with_two_requirements_needs_both() -> void:
	var core := SoulCore.from_data()
	var gs := _state(10)
	for id: String in ["core_heart", "vessel_1", "mercy_1"]:
		assert_true(core.buy(gs, id), id)
	assert_eq(core.status(gs, "mercy_2"), "locked", "needs vessel_2 as well")
	core.buy(gs, "vessel_2")
	assert_eq(core.status(gs, "mercy_2"), "buyable")


func test_modifiers_sum_the_addendum_values() -> void:
	var core := SoulCore.from_data()
	var owned: Array[String] = ["core_heart", "vitality_1", "endurance_1", "endurance_2", "resonance_1", "vessel_1"]
	var mods := core.modifiers(owned)
	assert_almost(float(mods["max_hp"]), 30.0, 0.001, "+15 HP per node")
	assert_almost(float(mods["stamina_regen"]), 0.10, 0.001, "+5 % per node")
	assert_almost(float(mods["gauge_cap"]), 10.0, 0.001)
	assert_almost(float(mods["flask_charges"]), 1.0, 0.001)


func test_all_flask_nodes_reach_six_charges() -> void:
	var core := SoulCore.from_data()
	var mods := core.modifiers(core.order)
	assert_almost(float(mods["flask_charges"]) + Balance.combat_f("flask.charges"), 6.0, 0.001, "3 base, up to 6")
