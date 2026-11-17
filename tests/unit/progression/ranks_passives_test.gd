extends TestCase
## Story 037: ability ranks and Sync passives — costs, buying, patching and save round trips.

const VESSEL := "caelan"


func test_data_patch_set_mul_add_and_input_untouched() -> void:
	var data := {
		"ability_1": {"counterstrike": {"posture": 10.0, "motion": 2.0}},
		"ultimate": {},
	}
	var patch := {
		"set": {"ability_1.counterstrike.posture": 5, "ability_2.knives": 7},
		"mul": {"ability_1.counterstrike.motion": 2.0, "ability_1.missing.path": 3.0},
		"add": {"ultimate.duration_s": 2.0, "ability_1.counterstrike.posture": 1.0},
	}
	var out := DataPatch.apply(data, patch)
	assert_eq(float(out["ability_1"]["counterstrike"]["posture"]), 6.0, "set 5 then add 1")
	assert_eq(int(out["ability_2"]["knives"]), 7, "set creates missing dictionaries")
	assert_eq(float(out["ability_1"]["counterstrike"]["motion"]), 4.0)
	assert_false(out["ability_1"].has("missing"), "mul leaves a missing path untouched")
	assert_eq(float(out["ultimate"]["duration_s"]), 2.0, "add treats missing as 0")
	assert_eq(float(data["ability_1"]["counterstrike"]["posture"]), 10.0, "input untouched")
	assert_eq(float(data["ability_1"]["counterstrike"]["motion"]), 2.0, "input untouched")
	assert_false(data.has("ability_2"), "input untouched")
	assert_false(data["ultimate"].has("duration_s"), "input untouched")


func test_rank_defaults_to_one() -> void:
	var ranks := AbilityRanks.from_data()
	var gs := GameState.new_game("normal")
	assert_eq(ranks.rank(gs, VESSEL, "kings_judgment"), 1)
	assert_eq(ranks.rank(gs, "nobody", "kings_judgment"), 1)


func test_costs_are_two_then_three_then_zero() -> void:
	var ranks := AbilityRanks.from_data()
	var gs := GameState.new_game("normal")
	assert_eq(ranks.cost(gs, VESSEL, "kings_judgment"), 2, "rank 1 -> 2")
	gs.ability_ranks[VESSEL] = {"kings_judgment": 2}
	assert_eq(ranks.cost(gs, VESSEL, "kings_judgment"), 3, "rank 2 -> 3")
	gs.ability_ranks[VESSEL] = {"kings_judgment": 3}
	assert_eq(ranks.cost(gs, VESSEL, "kings_judgment"), 0, "rank 3 is the top")
	assert_eq(ranks.cost(gs, VESSEL, "not_an_ability"), 0)


func test_buying_without_shards_fails_and_changes_nothing() -> void:
	var ranks := AbilityRanks.from_data()
	var gs := GameState.new_game("normal")
	assert_false(ranks.can_buy(gs, VESSEL, "kings_judgment"))
	assert_false(ranks.buy(gs, VESSEL, "kings_judgment"))
	assert_eq(ranks.rank(gs, VESSEL, "kings_judgment"), 1)
	assert_eq(gs.item_count(ranks.shard_item), 0)


func test_buying_spends_shards_and_raises_the_rank() -> void:
	var ranks := AbilityRanks.from_data()
	var gs := GameState.new_game("normal")
	gs.add_item("standard_soul_shard", 5)
	assert_true(ranks.can_buy(gs, VESSEL, "kings_judgment"))
	assert_true(ranks.buy(gs, VESSEL, "kings_judgment"))
	assert_eq(ranks.rank(gs, VESSEL, "kings_judgment"), 2)
	assert_eq(gs.item_count("standard_soul_shard"), 3)
	assert_true(ranks.buy(gs, VESSEL, "kings_judgment"))
	assert_eq(ranks.rank(gs, VESSEL, "kings_judgment"), 3)
	assert_eq(gs.item_count("standard_soul_shard"), 0)
	assert_false(ranks.buy(gs, VESSEL, "kings_judgment"), "rank 3 is the top")
	assert_eq(ranks.rank(gs, VESSEL, "kings_judgment"), 3)
	assert_eq(gs.item_count("standard_soul_shard"), 0)


func test_patched_at_rank_two_multiplies_the_power_path() -> void:
	var ranks := AbilityRanks.from_data()
	var gs := GameState.new_game("normal")
	gs.ability_ranks[VESSEL] = {"kings_judgment": 2}
	var base := Balance.vessel(VESSEL)
	var out := ranks.patched(base, gs, VESSEL)
	assert_almost(float(out["ability_2"]["motion"]), 1.8 * 1.2, 0.001)
	assert_almost(float(out["ability_2"]["range_m"]), 8.0, 0.001, "range grows only at rank 3")
	assert_almost(float(base["ability_2"]["motion"]), 1.8, 0.001, "the input is untouched")


func test_patched_at_rank_three_also_applies_the_rank3_patch() -> void:
	var ranks := AbilityRanks.from_data()
	var gs := GameState.new_game("normal")
	gs.ability_ranks[VESSEL] = {"kings_judgment": 3}
	var out := ranks.patched(Balance.vessel(VESSEL), gs, VESSEL)
	assert_almost(float(out["ability_2"]["motion"]), 1.8 * 1.2, 0.001, "power still applies")
	assert_almost(float(out["ability_2"]["range_m"]), 8.0 * 1.5, 0.001)


func test_passive_costs_a_greater_shard_buying_slots_it() -> void:
	var passives := SyncPassives.from_data()
	var gs := GameState.new_game("normal")
	assert_eq(passives.cost, 1)
	assert_eq(passives.shard_item, "greater_soul_shard")
	assert_false(passives.can_buy(gs, VESSEL, "kings_mercy"), "no shards held")
	gs.add_item("greater_soul_shard", 1)
	assert_true(passives.can_buy(gs, VESSEL, "kings_mercy"))
	assert_true(passives.buy(gs, VESSEL, "kings_mercy"))
	assert_eq(gs.item_count("greater_soul_shard"), 0)
	assert_true(passives.owned(gs, VESSEL, "kings_mercy"))
	assert_eq(passives.slotted(gs, VESSEL), "kings_mercy", "the empty slot took it")


func test_one_slot_per_vessel_and_replacing_needs_an_owned_passive() -> void:
	var passives := SyncPassives.from_data()
	var gs := GameState.new_game("normal")
	gs.add_item("greater_soul_shard", 3)
	assert_true(passives.buy(gs, VESSEL, "kings_mercy"))
	assert_true(passives.buy(gs, VESSEL, "unbowed"), "buying marks it owned even with a full slot")
	assert_true(passives.owned(gs, VESSEL, "unbowed"))
	assert_eq(passives.slotted(gs, VESSEL), "kings_mercy", "a full slot keeps the first passive")
	assert_false(passives.equip(gs, "nyra", "kings_mercy"), "another vessel's passive")
	assert_false(passives.equip(gs, VESSEL, "oath_unbroken"), "not owned")
	assert_eq(passives.slotted(gs, VESSEL), "kings_mercy", "failed equip changes nothing")
	assert_true(passives.equip(gs, VESSEL, "unbowed"))
	assert_eq(passives.slotted(gs, VESSEL), "unbowed", "the second owned passive replaces the first")


func test_patched_with_kings_mercy_sets_the_heal_fraction() -> void:
	var passives := SyncPassives.from_data()
	var gs := GameState.new_game("normal")
	assert_eq(passives.patched(Balance.vessel(VESSEL), gs, VESSEL), Balance.vessel(VESSEL),
			"empty slot: data unchanged")
	gs.add_item("greater_soul_shard", 1)
	assert_true(passives.buy(gs, VESSEL, "kings_mercy"))
	var out := passives.patched(Balance.vessel(VESSEL), gs, VESSEL)
	assert_almost(float(out["sync_guard"]["heal_fraction"]), 0.2, 0.001)


func test_progression_survives_a_save_round_trip() -> void:
	var gs := GameState.new_game("normal")
	gs.ability_ranks[VESSEL] = {"kings_judgment": 3}
	gs.owned_passives.append("%s:kings_mercy" % VESSEL)
	gs.sync_passive[VESSEL] = "kings_mercy"
	var restored := GameState.from_dict(gs.to_dict())
	assert_eq(int(restored.ability_ranks[VESSEL]["kings_judgment"]), 3)
	assert_true(restored.owned_passives.has("%s:kings_mercy" % VESSEL))
	assert_eq(str(restored.sync_passive.get(VESSEL, "")), "kings_mercy")
