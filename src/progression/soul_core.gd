class_name SoulCore
extends RefCounted
## The Soul Core tree (story 020, addendum "Progression"): 20 shared nodes bought at Soul Altars
## with Lesser Soul Shards, one shard each. A node needs every node in its `requires` list first.
## Pure: it reads and writes a `GameState`; the player applies the summed modifiers.
##
##     var core := SoulCore.from_data()
##     if core.can_buy(state, "vitality_1"): core.buy(state, "vitality_1")
##     player.apply_bonuses(core.modifiers(state.soul_core))

const PATH := "res://data/progression/soul_core.json"

## Node id -> {"id", "effect", "pos", "requires", "cost"}.
var nodes: Dictionary[String, Dictionary] = {}
## Node ids in file order.
var order: Array[String] = []
## The item a node costs.
var shard_item: String = "lesser_soul_shard"


static func from_data() -> SoulCore:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_error("SoulCore: %s does not parse" % PATH)
		return SoulCore.new()
	return SoulCore.from_dict(parsed)


static func from_dict(d: Dictionary) -> SoulCore:
	var c := SoulCore.new()
	c.shard_item = str(d.get("shard_item", "lesser_soul_shard"))
	for n: Variant in d.get("nodes", []):
		if n is Dictionary:
			var id := str((n as Dictionary).get("id", ""))
			c.nodes[id] = n
			c.order.append(id)
	return c


func cost(id: String) -> int:
	return int(nodes.get(id, {}).get("cost", 1))


## "owned", "buyable", "no_shard" (unlocked but too few shards), "locked" (a requirement is
## missing) or "unknown".
func status(state: GameState, id: String) -> String:
	if not nodes.has(id):
		return "unknown"
	if state.soul_core.has(id):
		return "owned"
	for req: Variant in nodes[id].get("requires", []):
		if not state.soul_core.has(str(req)):
			return "locked"
	return "buyable" if state.item_count(shard_item) >= cost(id) else "no_shard"


func can_buy(state: GameState, id: String) -> bool:
	return status(state, id) == "buyable"


## Spend the shards and own the node. False (nothing changes) when it cannot be bought.
func buy(state: GameState, id: String) -> bool:
	if not can_buy(state, id):
		return false
	state.spend_item(shard_item, cost(id))
	state.soul_core.append(id)
	return true


## Sum of the effects of every owned node: {"max_hp": 45, "stamina_regen": 0.1, ...}.
func modifiers(owned: Array[String]) -> Dictionary:
	var out := {}
	for id in owned:
		var effect: Dictionary = nodes.get(id, {}).get("effect", {})
		for k: Variant in effect.keys():
			out[str(k)] = float(out.get(str(k), 0.0)) + float(effect[k])
	return out
