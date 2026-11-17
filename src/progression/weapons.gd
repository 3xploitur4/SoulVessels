class_name Weapons
extends RefCounted
## Second weapons and Affinity 5 signature passives (story 050, decision D-056). Each Vessel has
## one second weapon, unlocked by a save flag or by holding an item once, and switched at an altar.
## While it is in hand its patch is applied to the Vessel's data (as ability ranks and Sync passives
## are, story 037); the signature passive's patch applies from Affinity 5. Pure: reads and writes a
## `GameState`.
##
##     var w := Weapons.from_data()
##     if w.unlocked(state, "caelan"): w.equip(state, "caelan", "greatsword")
##     data = w.patched(data, state, "caelan", affinity_level)

const PATH := "res://data/progression/weapons.json"

## Vessel id -> {"id", "name_key", "desc_key", "unlock": {"flag"|"item"}, "patch"}.
var vessels: Dictionary[String, Dictionary] = {}
## Vessel id -> {"id", "name_key", "level", "patch"}.
var signatures: Dictionary[String, Dictionary] = {}


## Load the rules from `res://data/progression/weapons.json`.
static func from_data() -> Weapons:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_error("Weapons: %s does not parse" % PATH)
		return Weapons.new()
	return Weapons.from_dict(parsed)


## Build from parsed JSON (or a matching Dictionary).
static func from_dict(d: Dictionary) -> Weapons:
	var w := Weapons.new()
	for key: String in ["vessels", "signatures"]:
		var table: Variant = d.get(key, {})
		if not table is Dictionary:
			continue
		for k: Variant in (table as Dictionary).keys():
			var e: Variant = (table as Dictionary)[k]
			if e is Dictionary:
				if key == "vessels":
					w.vessels[str(k)] = e
				else:
					w.signatures[str(k)] = e
	return w


## The Vessel's second weapon row (empty when it has none).
func second(vessel: String) -> Dictionary:
	return vessels.get(vessel, {})


## Is the Vessel's second weapon unlocked? A flag source, an item held now, or an earlier unlock.
func unlocked(state: GameState, vessel: String) -> bool:
	var e := second(vessel)
	if e.is_empty():
		return false
	if state.flag("weapon_" + str(e.get("id", ""))):
		return true
	var src: Dictionary = e.get("unlock", {})
	if src.has("flag"):
		return state.flag(str(src["flag"]))
	if src.has("item"):
		return state.item_count(str(src["item"])) > 0
	return false


## Remember every unlock met now (an item may be spent later). Returns the newly unlocked ids.
func refresh(state: GameState) -> Array[String]:
	var out: Array[String] = []
	for v: String in vessels:
		var id := str(vessels[v].get("id", ""))
		if not state.flag("weapon_" + id) and unlocked(state, v):
			state.set_flag("weapon_" + id)
			out.append(id)
	return out


## The weapon in hand: the second weapon's id, or "" for the first.
func equipped(state: GameState, vessel: String) -> String:
	return str(state.weapons.get(vessel, ""))


## Take up `id` ("" = the first weapon). False (nothing changes) for a locked or unknown weapon.
func equip(state: GameState, vessel: String, id: String) -> bool:
	if id == "":
		state.weapons.erase(vessel)
		return true
	if str(second(vessel).get("id", "")) != id or not unlocked(state, vessel):
		return false
	state.set_flag("weapon_" + id)
	state.weapons[vessel] = id
	return true


## Is the Vessel's signature passive active at `affinity`?
func signature_active(vessel: String, affinity: int) -> bool:
	var s: Dictionary = signatures.get(vessel, {})
	return not s.is_empty() and affinity >= int(s.get("level", 5))


## `data` with the weapon in hand and the signature passive (from its level) applied.
func patched(data: Dictionary, state: GameState, vessel: String, affinity: int) -> Dictionary:
	var out := data
	var e := second(vessel)
	if not e.is_empty() and equipped(state, vessel) == str(e.get("id", "")):
		out = DataPatch.apply(out, e.get("patch", {}))
	if signature_active(vessel, affinity):
		out = DataPatch.apply(out, (signatures[vessel] as Dictionary).get("patch", {}))
	return out
