class_name Reforge
extends RefCounted
## Weapon reforging (addendum "Progression, upgrades and loot"): a Vessel weapon goes +0 to +5
## at Soul Altars, paid with Soul Essence plus materials where any single listed option is enough.
## +8% ATK per level; +3 adds a coating slot. Pure: it reads and writes a `GameState`.
##
##     var reforge := Reforge.from_data()
##     if reforge.can_reforge(state, "caelan"): reforge.reforge(state, "caelan")

const PATH := "res://data/progression/reforge.json"

## ATK added per reforge level (fraction of base attack).
var atk_per_level: float = 0.08
## The reforge level that adds a coating slot.
var coating_slot_level: int = 3
## Highest reforge level.
var max_level: int = 5
## Target level -> {"level", "essence", "materials"}; `materials` is an array of
## option dictionaries (item id -> count) where paying any one option is enough.
var levels: Array[Dictionary] = []
## Output item id -> input dictionary (item id -> count).
var craft_recipes: Dictionary[String, Dictionary] = {}


## Load the rules from `res://data/progression/reforge.json`.
static func from_data() -> Reforge:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not parsed is Dictionary:
		push_error("Reforge: %s does not parse" % PATH)
		return Reforge.new()
	return Reforge.from_dict(parsed)


## Build from parsed JSON (or a matching Dictionary). Missing keys get defaults.
static func from_dict(d: Dictionary) -> Reforge:
	var r := Reforge.new()
	r.atk_per_level = float(d.get("atk_per_level", 0.08))
	r.coating_slot_level = int(d.get("coating_slot_level", 3))
	r.max_level = int(d.get("max_level", 5))
	for entry: Variant in d.get("levels", []):
		if entry is Dictionary:
			r.levels.append(entry)
	var recipes: Variant = d.get("craft", {})
	if recipes is Dictionary:
		for k: Variant in (recipes as Dictionary).keys():
			var recipe: Variant = (recipes as Dictionary)[k]
			if recipe is Dictionary:
				r.craft_recipes[str(k)] = recipe
	return r


## The vessel's current reforge level (0 when it has never been reforged).
func level(state: GameState, vessel: String) -> int:
	return state.weapon_levels.get(vessel, 0)


## What the next reforge level costs: {"level": n, "essence": E, "materials": [options]}.
## Empty at (or past) `max_level`.
func next_cost(state: GameState, vessel: String) -> Dictionary:
	var lvl := level(state, vessel)
	if lvl >= max_level:
		return {}
	for entry: Dictionary in levels:
		if int(entry.get("level", 0)) == lvl + 1:
			return {
				"level": lvl + 1,
				"essence": int(entry.get("essence", 0)),
				"materials": entry.get("materials", []),
			}
	return {}


## Index of the first material option `state` can pay (essence included), or -1.
func affordable_option(state: GameState, vessel: String) -> int:
	var cost := next_cost(state, vessel)
	if cost.is_empty() or state.essence < int(cost.get("essence", 0)):
		return -1
	var options: Array = cost.get("materials", [])
	for i in options.size():
		if _can_pay(state, options[i]):
			return i
	return -1


## Can the vessel reach its next reforge level right now?
func can_reforge(state: GameState, vessel: String) -> bool:
	return affordable_option(state, vessel) >= 0


## Spend the essence and the first affordable option's items, raise the level by one.
## False (nothing changes) when the vessel is at max level or the cost cannot be paid.
func reforge(state: GameState, vessel: String) -> bool:
	var cost := next_cost(state, vessel)
	if cost.is_empty():
		return false
	if state.essence < int(cost.get("essence", 0)):
		return false
	var options: Array = cost.get("materials", [])
	var option: Dictionary = {}
	for candidate: Variant in options:
		if _can_pay(state, candidate):
			option = candidate
			break
	if option.is_empty():
		return false
	state.essence -= int(cost["essence"])
	for item: Variant in option.keys():
		state.spend_item(str(item), int(option[item]))
	state.weapon_levels[vessel] = level(state, vessel) + 1
	return true


## ATK multiplier of a weapon at reforge level `lvl`.
func atk_multiplier(lvl: int) -> float:
	return 1.0 + atk_per_level * float(lvl)


## Does a weapon at reforge level `lvl` have a coating slot?
func has_coating_slot(lvl: int) -> bool:
	return lvl >= coating_slot_level


## Can `state` pay the inputs to craft one of `item`?
func can_craft(state: GameState, item: String) -> bool:
	return not craft_recipes.get(item, {}).is_empty() and _can_pay(state, craft_recipes[item])


## Spend the inputs and add one crafted `item`. False (nothing changes) when it cannot be paid.
func craft(state: GameState, item: String) -> bool:
	if not can_craft(state, item):
		return false
	var inputs: Dictionary = craft_recipes[item]
	for id: Variant in inputs.keys():
		state.spend_item(str(id), int(inputs[id]))
	state.add_item(item, 1)
	return true


func _can_pay(state: GameState, option: Variant) -> bool:
	if not option is Dictionary:
		return false
	for id: Variant in (option as Dictionary).keys():
		if state.item_count(str(id)) < int((option as Dictionary)[id]):
			return false
	return true
