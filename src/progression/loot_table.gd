class_name LootTable
extends RefCounted
## Rolls what an enemy drops (story 019, addendum "Progression, upgrades and loot"): a drop
## chance by tier (normal 35 %, elite 100 %), a rarity by tier (normal 70/25/5, elite 20/65/15),
## then an item weighted from the enemy's own pool for that rarity, or the zone pool when the
## enemy lists none. Pity: after 15 elite kills without an Epic the next elite kill drops one.
## Pure and seeded; config is injected so tests can bend the odds.
##
##     var loot := LootTable.from_data()
##     var drops := loot.roll(enemy.data, "zone1", rng, state)   # [{"item": id, "count": n}]

const PATH := "res://data/progression/loot.json"
const RARITIES: Array[String] = ["common", "rare", "epic"]

var config: Dictionary = {}


func _init(cfg: Dictionary = {}) -> void:
	config = cfg


static func from_data() -> LootTable:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_error("LootTable: %s does not parse" % PATH)
		return LootTable.new({})
	return LootTable.new(parsed)


## A number from loot.json (top level).
func num(key: String, fallback: float) -> float:
	return float(config.get(key, fallback))


## Roll one enemy's drops. Updates `state.elite_pity` for elites.
func roll(enemy: Dictionary, zone: String, rng: RandomNumberGenerator, state: GameState) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if str(enemy.get("tier", "")) == "boss":
		# Bosses always drop their full list (addendum loot table).
		var drops: Dictionary = enemy.get("drops", {})
		for rarity: String in ["common", "rare", "epic", "legendary"]:
			var table: Dictionary = drops.get(rarity, {})
			for item: String in table.keys():
				out.append({"item": item, "count": int(table[item]), "rarity": rarity})
		return out
	var tier := "elite" if str(enemy.get("tier", "common")) == "elite" else "common"
	var chance := float((config.get("drop_chance", {}) as Dictionary).get(tier, 0.0))
	if rng.randf() >= chance:
		return out
	var rarity := roll_rarity(tier, rng)
	if tier == "elite" and state != null:
		if state.elite_pity >= int(num("pity_elite_kills", 15)):
			rarity = "epic"
		state.elite_pity = 0 if rarity == "epic" else state.elite_pity + 1
	var item := pick(enemy, zone, rarity, rng)
	if item != "":
		out.append({"item": item, "count": 1, "rarity": rarity})
	return out


## "common" / "rare" / "epic" for a drop from `tier`.
func roll_rarity(tier: String, rng: RandomNumberGenerator) -> String:
	var odds: Dictionary = (config.get("rarity_odds", {}) as Dictionary).get(tier, {})
	var r := rng.randf()
	var acc := 0.0
	for rarity in RARITIES:
		acc += float(odds.get(rarity, 0.0))
		if r < acc:
			return rarity
	return "common"


## A weighted item of `rarity`: the enemy's own pool, else the zone's.
func pick(enemy: Dictionary, zone: String, rarity: String, rng: RandomNumberGenerator) -> String:
	var own: Dictionary = (enemy.get("drops", {}) as Dictionary).get(rarity, {}) if enemy.get("drops") is Dictionary else {}
	var pool := own
	if pool.is_empty():
		pool = ((config.get("zone_pools", {}) as Dictionary).get(zone, {}) as Dictionary).get(rarity, {})
	var total := 0.0
	for k: Variant in pool.keys():
		total += float(pool[k])
	if total <= 0.0:
		return ""
	var r := rng.randf() * total
	for k: Variant in pool.keys():
		r -= float(pool[k])
		if r < 0.0:
			return str(k)
	return str(pool.keys()[pool.size() - 1])
