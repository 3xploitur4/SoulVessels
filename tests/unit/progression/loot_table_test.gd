extends TestCase
## Story 019: drop chances, rarity odds, pools and pity.

const COMMON_ENEMY := {"tier": "common", "drops": {"common": {"crude_stone": 2, "lesser_soul_shard": 1}}}
const ELITE_ENEMY := {"tier": "elite", "drops": {"rare": {"polished_basalt_core": 1}, "epic": {"weapon_schematic": 1}}}


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func test_normal_enemy_rates_match_the_addendum() -> void:
	var loot := LootTable.from_data()
	var rng := _rng(42)
	var n := 10000
	var drops := 0
	var by: Dictionary = {"common": 0, "rare": 0, "epic": 0}
	for i in range(n):
		var d := loot.roll(COMMON_ENEMY, "zone1", rng, null)
		if not d.is_empty():
			drops += 1
			by[str(d[0]["rarity"])] += 1
	assert_almost(float(drops) / n, 0.35, 0.015, "35 % drop chance")
	assert_almost(float(by["common"]) / drops, 0.70, 0.015)
	assert_almost(float(by["rare"]) / drops, 0.25, 0.015)
	assert_almost(float(by["epic"]) / drops, 0.05, 0.015)


func test_elite_always_drops_with_elite_odds() -> void:
	var loot := LootTable.from_data()
	var rng := _rng(7)
	var by: Dictionary = {"common": 0, "rare": 0, "epic": 0}
	for i in range(10000):
		var d := loot.roll(ELITE_ENEMY, "zone1", rng, null)
		if i < 3:
			assert_eq(d.size(), 1, "an elite always drops")
		by[str(d[0]["rarity"])] += 1
	assert_almost(float(by["common"]) / 10000.0, 0.20, 0.015)
	assert_almost(float(by["rare"]) / 10000.0, 0.65, 0.015)
	assert_almost(float(by["epic"]) / 10000.0, 0.15, 0.015)


func test_own_pool_wins_and_zone_pool_fills_gaps() -> void:
	var loot := LootTable.from_data()
	var rng := _rng(3)
	for i in range(200):
		var item := loot.pick(COMMON_ENEMY, "zone1", "common", rng)
		assert_true(item in ["crude_stone", "lesser_soul_shard"], "own common pool: %s" % item)
	var rare := loot.pick(COMMON_ENEMY, "zone2", "rare", rng)
	assert_true(rare in ["luminous_root_resin", "standard_soul_shard", "echoing_relic"], "zone 2 rare pool: %s" % rare)


func test_own_pool_weights_are_respected() -> void:
	var loot := LootTable.from_data()
	var rng := _rng(11)
	var stone := 0
	for i in range(6000):
		if loot.pick(COMMON_ENEMY, "zone1", "common", rng) == "crude_stone":
			stone += 1
	assert_almost(stone / 6000.0, 2.0 / 3.0, 0.02, "crude stone weight 2 of 3")


func test_pity_guarantees_an_epic_on_the_sixteenth_elite_kill() -> void:
	var cfg: Dictionary = LootTable.from_data().config.duplicate(true)
	cfg["rarity_odds"]["elite"] = {"common": 0.5, "rare": 0.5, "epic": 0.0}
	var loot := LootTable.new(cfg)
	var rng := _rng(5)
	var gs := GameState.new()
	for i in range(15):
		var d := loot.roll(ELITE_ENEMY, "zone1", rng, gs)
		assert_ne(str(d[0]["rarity"]), "epic", "kill %d" % (i + 1))
	assert_eq(gs.elite_pity, 15)
	var last := loot.roll(ELITE_ENEMY, "zone1", rng, gs)
	assert_eq(str(last[0]["rarity"]), "epic", "16th kill")
	assert_eq(str(last[0]["item"]), "weapon_schematic")
	assert_eq(gs.elite_pity, 0, "pity resets")


func test_every_pool_item_exists() -> void:
	var loot := LootTable.from_data()
	for zone: String in (loot.config["zone_pools"] as Dictionary).keys():
		for rarity: String in (loot.config["zone_pools"][zone] as Dictionary).keys():
			for item: String in (loot.config["zone_pools"][zone][rarity] as Dictionary).keys():
				assert_true(ItemDb.exists(item), "%s/%s: %s" % [zone, rarity, item])
				assert_eq(ItemDb.rarity(item), rarity, "%s is %s in items.json" % [item, ItemDb.rarity(item)])
	for eid in Balance.enemy_ids():
		var d: Variant = Balance.enemy(eid).get("drops", {})
		assert_true(d is Dictionary, "%s drops is a rarity table" % eid)
		for rarity: String in (d as Dictionary).keys():
			for item: String in ((d as Dictionary)[rarity] as Dictionary).keys():
				assert_true(ItemDb.exists(item), "%s drops unknown %s" % [eid, item])
