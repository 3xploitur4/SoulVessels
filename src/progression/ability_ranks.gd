class_name AbilityRanks
extends RefCounted
## Vessel ability ranks (story 037): every ability starts at rank 1; rank 2 and 3 are bought at
## Soul Altars with Standard Soul Shards. Rank 2 multiplies the ability's power paths by
## `power_mult`; rank 3 also applies its `rank3` patch to the Vessel's data. Pure: it reads and
## writes a `GameState`.
##
##     var ranks := AbilityRanks.from_data()
##     if ranks.can_buy(state, "caelan", "kings_judgment"): ranks.buy(state, "caelan", "kings_judgment")

const PATH := "res://data/progression/ability_ranks.json"
## Highest rank an ability can reach.
const MAX_RANK := 3

## The item id ranks are paid in ("standard_soul_shard").
var shard_item: String = ""
## Rank -> cost in `shard_item` ({"2": 2, "3": 3} in the file).
var rank_costs: Dictionary = {}
## Multiplier applied to an ability's `power` paths from rank 2.
var power_mult: float = 1.0
## Vessel id -> ability id -> {"name_key", "power": [paths], "rank3": patch, "rank3_key"}.
var vessels: Dictionary[String, Dictionary] = {}


## Load the rules from `res://data/progression/ability_ranks.json`.
static func from_data() -> AbilityRanks:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_error("AbilityRanks: %s does not parse" % PATH)
		return AbilityRanks.new()
	return AbilityRanks.from_dict(parsed)


## Build from parsed JSON (or a matching Dictionary). Missing keys get defaults.
static func from_dict(d: Dictionary) -> AbilityRanks:
	var r := AbilityRanks.new()
	r.shard_item = str(d.get("shard_item", ""))
	var costs: Variant = d.get("rank_costs", {})
	if costs is Dictionary:
		for k: Variant in (costs as Dictionary).keys():
			r.rank_costs[int(k)] = int((costs as Dictionary)[k])
	r.power_mult = float(d.get("power_mult", 1.0))
	var table: Variant = d.get("vessels", {})
	if table is Dictionary:
		for k: Variant in (table as Dictionary).keys():
			var inner: Variant = (table as Dictionary)[k]
			if inner is Dictionary:
				r.vessels[str(k)] = inner
	return r


## The vessel's ability ids, in file order.
func abilities(vessel: String) -> Array[String]:
	var out: Array[String] = []
	for k: Variant in vessels.get(vessel, {}).keys():
		out.append(str(k))
	return out


## The ability's current rank (1 when the vessel never raised it, or the ability is unknown).
func rank(state: GameState, vessel: String, ability: String) -> int:
	return int(state.ability_ranks.get(vessel, {}).get(ability, 1))


## The cost in shards of the NEXT rank. 0 at rank 3 or for an unknown ability.
func cost(state: GameState, vessel: String, ability: String) -> int:
	var r := rank(state, vessel, ability)
	if r >= MAX_RANK or not vessels.get(vessel, {}).has(ability):
		return 0
	return int(rank_costs.get(r + 1, 0))


## Can the vessel buy the next rank right now? Needs the ability known, rank below 3 and enough
## shards held.
func can_buy(state: GameState, vessel: String, ability: String) -> bool:
	var price := cost(state, vessel, ability)
	return price > 0 and state.item_count(shard_item) >= price


## Spend the shards and raise the rank by one. False (nothing changes) when it cannot be bought.
func buy(state: GameState, vessel: String, ability: String) -> bool:
	if not can_buy(state, vessel, ability):
		return false
	state.spend_item(shard_item, cost(state, vessel, ability))
	var ranks: Dictionary = state.ability_ranks.get(vessel, {})
	ranks[ability] = rank(state, vessel, ability) + 1
	state.ability_ranks[vessel] = ranks
	return true


## A deep copy of the vessel data with every bought rank applied: for rank 2 or 3 each path in the
## ability's `power` list is multiplied by `power_mult`, and at rank 3 its `rank3` patch is applied
## too. Unchanged abilities pass through untouched.
func patched(data: Dictionary, state: GameState, vessel: String) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var table: Dictionary = vessels.get(vessel, {})
	var ranks: Dictionary = state.ability_ranks.get(vessel, {})
	for ability: Variant in table.keys():
		var r := int(ranks.get(str(ability), 1))
		if r < 2:
			continue
		var info: Dictionary = table[ability]
		var power: Variant = info.get("power", [])
		if power is Array and not (power as Array).is_empty():
			var mul := {}
			for path: Variant in power:
				mul[str(path)] = power_mult
			out = DataPatch.apply(out, {"mul": mul})
		if r >= MAX_RANK:
			var rank3: Variant = info.get("rank3", {})
			if rank3 is Dictionary and not (rank3 as Dictionary).is_empty():
				out = DataPatch.apply(out, rank3)
	return out
