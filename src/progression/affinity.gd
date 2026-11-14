class_name Affinity
extends RefCounted
## Affinity, the trust between the Intruder and a Vessel, 0 to 5 (story 020, addendum
## "Affinity"). XP comes from time active in combat, kills, perfect parries and dodges; each
## Vessel memory read at an altar adds a whole level on top. Level 1 unlocks the memory, 2 the
## Sync Guard, 3 the Sync Ultimate and +5 % stats. Pure: numbers from
## `data/progression/affinity.json`, state in `GameState`.
##
##     var before := Affinity.level(state, "caelan")
##     Affinity.add_xp(state, "caelan", "kill")
##     if Affinity.level(state, "caelan") > before: ...

const PATH := "res://data/progression/affinity.json"

static var _cfg: Dictionary = {}


static func config() -> Dictionary:
	if _cfg.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_cfg = parsed
		else:
			push_error("Affinity: %s does not parse" % PATH)
			_cfg = {"level_xp": [0], "max_level": 5, "xp": {}}
	return _cfg


static func max_level() -> int:
	return int(config().get("max_level", 5))


## The level `xp` alone reaches (before memory bonuses).
static func xp_level(xp: float) -> int:
	var thresholds: Array = config().get("level_xp", [0])
	var lvl := 0
	for i in range(thresholds.size()):
		if xp >= float(thresholds[i]):
			lvl = i
	return mini(lvl, max_level())


## The Affinity level of a Vessel: XP level plus memory bonuses, capped.
static func level(state: GameState, vessel: String) -> int:
	return mini(xp_level(float(state.affinity_xp.get(vessel, 0.0))) + int(state.affinity_bonus.get(vessel, 0)), max_level())


## XP that `source` gives per unit ("combat_s" per second, "kill", "elite_kill",
## "perfect_parry", "perfect_dodge").
static func xp_for(source: String) -> float:
	return float((config().get("xp", {}) as Dictionary).get(source, 0.0))


## Add `amount` units of `source` XP to `vessel`. Returns the level reached, or -1 when the
## level did not change.
static func add_xp(state: GameState, vessel: String, source: String, amount: float = 1.0) -> int:
	if vessel == "" or vessel == "wisp":
		return -1
	var before := level(state, vessel)
	state.affinity_xp[vessel] = float(state.affinity_xp.get(vessel, 0.0)) + xp_for(source) * amount
	var after := level(state, vessel)
	return after if after != before else -1


## XP still missing for the next XP level (0 at the top).
static func xp_to_next(xp: float) -> float:
	var thresholds: Array = config().get("level_xp", [0])
	for t: Variant in thresholds:
		if float(t) > xp:
			return float(t) - xp
	return 0.0


## The level at which the memory of a Vessel becomes lore.
static func memory_level() -> int:
	return int(config().get("memory_level", 1))
