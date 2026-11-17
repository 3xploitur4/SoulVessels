class_name SyncPassives
extends RefCounted
## Sync passives (story 037): each Vessel has one slot and three passives to choose from, paid
## with Greater Soul Shards. A bought passive stays owned; the slot can be switched between owned
## passives at an altar for free. While slotted, its patch is applied to the Vessel's data.
## Pure: it reads and writes a `GameState`.
##
##     var passives := SyncPassives.from_data()
##     if passives.can_buy(state, "caelan", "kings_mercy"): passives.buy(state, "caelan", "kings_mercy")

const PATH := "res://data/progression/sync_passives.json"

## The item id passives are paid in ("greater_soul_shard").
var shard_item: String = ""
## The price of every passive, in `shard_item`.
var cost: int = 1
## Vessel id -> the passive options: [{"id", "name_key", "patch"}, ...] in file order.
var vessels: Dictionary[String, Array] = {}


## Load the rules from `res://data/progression/sync_passives.json`.
static func from_data() -> SyncPassives:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_error("SyncPassives: %s does not parse" % PATH)
		return SyncPassives.new()
	return SyncPassives.from_dict(parsed)


## Build from parsed JSON (or a matching Dictionary). Missing keys get defaults.
static func from_dict(d: Dictionary) -> SyncPassives:
	var s := SyncPassives.new()
	s.shard_item = str(d.get("shard_item", ""))
	s.cost = int(d.get("cost", 1))
	var table: Variant = d.get("vessels", {})
	if table is Dictionary:
		for k: Variant in (table as Dictionary).keys():
			var list: Variant = (table as Dictionary)[k]
			if list is Array:
				var entries: Array = []
				for entry: Variant in list:
					if entry is Dictionary:
						entries.append(entry)
				s.vessels[str(k)] = entries
	return s


## The vessel's passive options, in file order.
func options(vessel: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry: Variant in vessels.get(vessel, []):
		if entry is Dictionary:
			out.append(entry)
	return out


## The passive's data row (empty when the vessel or the id is unknown).
func _entry(vessel: String, id: String) -> Dictionary:
	for entry: Variant in vessels.get(vessel, []):
		if entry is Dictionary and str(entry.get("id", "")) == id:
			return entry
	return {}


## Is the passive bought (and therefore free to equip)?
func owned(state: GameState, vessel: String, id: String) -> bool:
	return state.owned_passives.has("%s:%s" % [vessel, id])


## Can the passive be bought right now? Needs it not owned, known, and enough shards held.
func can_buy(state: GameState, vessel: String, id: String) -> bool:
	return not owned(state, vessel, id) and not _entry(vessel, id).is_empty() \
			and state.item_count(shard_item) >= cost


## Spend the shards, mark the passive owned and slot it when the vessel's slot is still empty.
## False (nothing changes) when it cannot be bought.
func buy(state: GameState, vessel: String, id: String) -> bool:
	if not can_buy(state, vessel, id):
		return false
	state.spend_item(shard_item, cost)
	GameState.add_unique(state.owned_passives, "%s:%s" % [vessel, id])
	if slotted(state, vessel).is_empty():
		state.sync_passive[vessel] = id
	return true


## Put an owned passive into the vessel's slot, replacing whatever was slotted. Free; false (and
## no change) when the passive is not owned or unknown.
func equip(state: GameState, vessel: String, id: String) -> bool:
	if not owned(state, vessel, id) or _entry(vessel, id).is_empty():
		return false
	state.sync_passive[vessel] = id
	return true


## The passive id currently in the vessel's slot (empty when none).
func slotted(state: GameState, vessel: String) -> String:
	return str(state.sync_passive.get(vessel, ""))


## A deep copy of the vessel data with the slotted passive's patch applied, or the data unchanged
## when the slot is empty (or its id is unknown).
func patched(data: Dictionary, state: GameState, vessel: String) -> Dictionary:
	var id := slotted(state, vessel)
	if id.is_empty():
		return data
	var entry := _entry(vessel, id)
	if entry.is_empty():
		return data
	return DataPatch.apply(data, entry.get("patch", {}))
