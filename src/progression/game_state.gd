class_name GameState
extends RefCounted
## Everything one save slot remembers (story 014). Pure data: no nodes, no file access, so every
## rule that reads or writes it is unit-testable. `SaveSystem` turns it into JSON and back.
##
## Addendum "Death, saving": shards, items and Affinity are never lost; carried Soul Essence is
## (see `DeathRules`).
##
##     var gs := GameState.new_game("normal")
##     gs.add_item("lesser_soul_shard", 2)
##     var copy := GameState.from_dict(gs.to_dict())

## Bumped when the layout changes; `from_dict` upgrades older saves.
const VERSION := 1
## Where a new game starts (the wisp wakes here).
const START_ROOM := "z1_01"

var version: int = VERSION
## Row in combat.json `difficulty` ("story", "normal").
var difficulty: String = "normal"
## Carried Soul Essence (lost into a Soul Echo on death).
var essence: int = 0
## Item id -> count (shards, materials, keys).
var inventory: Dictionary[String, int] = {}
## Bought Soul Core node ids.
var soul_core: Array[String] = []
## Vessels the Intruder has bound (in the order found).
var unlocked_vessels: Array[String] = []
## Equipped Vessels in wheel order; empty means the bare wisp.
var loadout: Array[String] = []
## Vessel id -> Affinity XP.
var affinity_xp: Dictionary[String, float] = {}
## Vessel id -> extra Affinity levels from read Vessel memories.
var affinity_bonus: Dictionary[String, int] = {}
## The altar you respawn at: {"room": id, "altar": id}. Empty before the first rest.
var rested_altar: Dictionary = {}
## Altar ids lit so far (fast travel needs all 7).
var lit_altars: Array[String] = []
## Where Continue puts you: {"room": id, "x": m, "y": m}.
var checkpoint: Dictionary = {}
## Suspend point written when the app is backgrounded: same shape as `checkpoint`. Continue uses
## it once, then clears it.
var resume: Dictionary = {}
## Spawn ids ("room:index") of elites killed for good.
var killed_elites: Array[String] = []
## Spawn ids of ordinary enemies killed since the last rest (they return on rest or death).
var killed_commons: Array[String] = []
## Arena ids (set-pieces, gauntlets) cleared for good.
var cleared_arenas: Array[String] = []
## Gate ids opened for good.
var opened_gates: Array[String] = []
## Placed pickup ids taken (they never come back).
var taken_pickups: Array[String] = []
## Lore entry ids found, in order found.
var lore_found: Array[String] = []
## Lore entry ids read at an altar.
var lore_read: Array[String] = []
## The Soul Echo: {"room": id, "x": m, "y": m, "essence": n}. Empty when none.
var echo: Dictionary = {}
## Room ids entered at least once (the map).
var visited_rooms: Array[String] = []
## Story flags (tutorials seen, bodies possessed, set-pieces started).
var flags: Dictionary = {}
## Elite kills since the last Epic drop (pity rule).
var elite_pity: int = 0
var play_time_s: float = 0.0
var deaths: int = 0
## Room the player is in (for the title-screen card).
var current_room: String = ""


## A fresh run: the wisp at the start room, nothing found yet.
static func new_game(diff: String = "normal") -> GameState:
	var gs := GameState.new()
	gs.difficulty = diff
	gs.current_room = START_ROOM
	gs.checkpoint = {"room": START_ROOM, "x": -1.0, "y": -1.0}
	return gs


# --- Inventory ------------------------------------------------------------------------------

func item_count(id: String) -> int:
	return inventory.get(id, 0)


func add_item(id: String, count: int = 1) -> void:
	if count <= 0:
		return
	inventory[id] = item_count(id) + count


## Take `count`; false (and nothing taken) when short.
func spend_item(id: String, count: int = 1) -> bool:
	if count <= 0:
		return true
	if item_count(id) < count:
		return false
	inventory[id] = item_count(id) - count
	if inventory[id] == 0:
		inventory.erase(id)
	return true


# --- Sets of ids ----------------------------------------------------------------------------

## Append `id` to `list` when absent. Returns true when it was added.
static func add_unique(list: Array[String], id: String) -> bool:
	if list.has(id):
		return false
	list.append(id)
	return true


func flag(key: String) -> bool:
	return bool(flags.get(key, false))


func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value


## Bind a Vessel: unlock it and, when the loadout has room, equip it at the end.
func unlock_vessel(id: String) -> void:
	add_unique(unlocked_vessels, id)
	if loadout.size() < Loadout.MAX_SLOTS and not loadout.has(id):
		loadout.append(id)


## Is the spawn with id `spawn_id` (tier "common" or "elite") currently dead?
func is_spawn_dead(spawn_id: String, elite: bool) -> bool:
	return killed_elites.has(spawn_id) if elite else killed_commons.has(spawn_id)


## Rest rule: ordinary enemies come back, killed elites stay dead.
func reset_commons() -> void:
	killed_commons.clear()


# --- Serialisation --------------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"difficulty": difficulty,
		"essence": essence,
		"inventory": inventory.duplicate(),
		"soul_core": soul_core.duplicate(),
		"unlocked_vessels": unlocked_vessels.duplicate(),
		"loadout": loadout.duplicate(),
		"affinity_xp": affinity_xp.duplicate(),
		"affinity_bonus": affinity_bonus.duplicate(),
		"rested_altar": rested_altar.duplicate(),
		"lit_altars": lit_altars.duplicate(),
		"checkpoint": checkpoint.duplicate(),
		"resume": resume.duplicate(),
		"killed_elites": killed_elites.duplicate(),
		"killed_commons": killed_commons.duplicate(),
		"cleared_arenas": cleared_arenas.duplicate(),
		"opened_gates": opened_gates.duplicate(),
		"taken_pickups": taken_pickups.duplicate(),
		"lore_found": lore_found.duplicate(),
		"lore_read": lore_read.duplicate(),
		"echo": echo.duplicate(),
		"visited_rooms": visited_rooms.duplicate(),
		"flags": flags.duplicate(),
		"elite_pity": elite_pity,
		"play_time_s": play_time_s,
		"deaths": deaths,
		"current_room": current_room,
	}


## Rebuild from `to_dict` output (or parsed JSON). Missing or mistyped keys get defaults.
static func from_dict(d: Dictionary) -> GameState:
	var gs := GameState.new()
	gs.version = int(d.get("version", VERSION))
	gs.difficulty = str(d.get("difficulty", "normal"))
	gs.essence = maxi(int(d.get("essence", 0)), 0)
	var inv: Variant = d.get("inventory", {})
	if inv is Dictionary:
		for k: Variant in (inv as Dictionary).keys():
			var n := int((inv as Dictionary)[k])
			if n > 0:
				gs.inventory[str(k)] = n
	gs.soul_core = _strings(d.get("soul_core"))
	gs.unlocked_vessels = _strings(d.get("unlocked_vessels"))
	gs.loadout = _strings(d.get("loadout"))
	var xp: Variant = d.get("affinity_xp", {})
	if xp is Dictionary:
		for k: Variant in (xp as Dictionary).keys():
			gs.affinity_xp[str(k)] = float((xp as Dictionary)[k])
	var bonus: Variant = d.get("affinity_bonus", {})
	if bonus is Dictionary:
		for k: Variant in (bonus as Dictionary).keys():
			gs.affinity_bonus[str(k)] = int((bonus as Dictionary)[k])
	gs.rested_altar = _dict(d.get("rested_altar"))
	gs.lit_altars = _strings(d.get("lit_altars"))
	gs.checkpoint = _dict(d.get("checkpoint"))
	gs.resume = _dict(d.get("resume"))
	gs.killed_elites = _strings(d.get("killed_elites"))
	gs.killed_commons = _strings(d.get("killed_commons"))
	gs.cleared_arenas = _strings(d.get("cleared_arenas"))
	gs.opened_gates = _strings(d.get("opened_gates"))
	gs.taken_pickups = _strings(d.get("taken_pickups"))
	gs.lore_found = _strings(d.get("lore_found"))
	gs.lore_read = _strings(d.get("lore_read"))
	gs.echo = _dict(d.get("echo"))
	gs.visited_rooms = _strings(d.get("visited_rooms"))
	gs.flags = _dict(d.get("flags"))
	gs.elite_pity = maxi(int(d.get("elite_pity", 0)), 0)
	gs.play_time_s = maxf(float(d.get("play_time_s", 0.0)), 0.0)
	gs.deaths = maxi(int(d.get("deaths", 0)), 0)
	gs.current_room = str(d.get("current_room", ""))
	if gs.checkpoint.is_empty():
		gs.checkpoint = {"room": START_ROOM, "x": -1.0, "y": -1.0}
	return gs


static func _strings(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if v is Array:
		for item: Variant in v:
			out.append(str(item))
	return out


static func _dict(v: Variant) -> Dictionary:
	return (v as Dictionary).duplicate(true) if v is Dictionary else {}
