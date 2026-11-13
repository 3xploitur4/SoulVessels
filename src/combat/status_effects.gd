class_name StatusEffects
extends RefCounted
## Element build-up meters and the statuses they trigger (addendum "Elements and status
## effects"). Each element fills a meter; a full meter starts its status for the data's duration
## and empties. Meters decay when not fed. M1 sources are Physical only, but the whole table runs
## so Seris, Darius and coatings plug in without code.
##
##     var s := StatusEffects.new()
##     if s.add_buildup("frost", 60.0): print("frozen")
##     s.has_status("frozen")

signal status_started(status: String)
signal status_ended(status: String)

## Element -> status name.
const STATUS_OF := {
	"frost": "frozen",
	"venom": "poisoned",
	"aether": "unraveled",
	"ember": "burning",
	"stagger": "staggered_buildup",
}

var meters: Dictionary[String, float] = {}
var active: Dictionary[String, float] = {}

var _config: Dictionary = {}


func _init(config: Dictionary = {}) -> void:
	_config = config


## Build `StatusEffects` with combat.json `status`.
static func from_balance() -> StatusEffects:
	var cfg: Variant = Balance.combat("status")
	return StatusEffects.new(cfg if cfg is Dictionary else {})


## Feed `amount` into `element`'s meter. Returns true when it triggers the status.
func add_buildup(element: String, amount: float) -> bool:
	if not STATUS_OF.has(element) or amount <= 0.0:
		return false
	var status: String = STATUS_OF[element]
	if active.has(status):
		return false
	var threshold := _num(element, "threshold", 100.0)
	var v: float = meters.get(element, 0.0) + amount
	if v >= threshold:
		meters[element] = 0.0
		active[status] = _duration(element)
		status_started.emit(status)
		return true
	meters[element] = v
	return false


## Start a status directly (Echo Bonus spread, debug).
func apply(status: String, duration: float) -> void:
	active[status] = duration
	status_started.emit(status)


func has_status(status: String) -> bool:
	return active.has(status)


## Frost below the threshold is Chill: a partial slow.
func is_chilled() -> bool:
	return meters.get("frost", 0.0) > 0.0 or active.has("frozen")


func clear() -> void:
	meters.clear()
	active.clear()


## Per-second damage from active damage-over-time statuses, given the owner's max HP.
func dot_per_s(max_hp: float) -> float:
	var total := 0.0
	if active.has("poisoned"):
		total += max_hp * _num("venom", "pct_max_hp_per_s", 0.02)
	if active.has("burning"):
		total += _num("ember", "damage_per_s", 15.0)
	return total


## Multiplier on damage taken (Frozen +25 %).
func damage_taken_multiplier() -> float:
	return _num("frost", "frozen_damage_taken", 1.25) if active.has("frozen") else 1.0


## Multiplier on DEF (Unraveled -20 %).
func def_multiplier() -> float:
	return 1.0 - _num("aether", "def_reduction", 0.2) if active.has("unraveled") else 1.0


## Multiplier on move speed (Chill -30 %, Frozen 0).
func move_multiplier() -> float:
	if active.has("frozen"):
		return 0.0
	if is_chilled():
		return 1.0 - _num("frost", "slow", 0.3)
	return 1.0


func tick(delta: float) -> void:
	for status: String in active.keys():
		active[status] = active[status] - delta
		if active[status] <= 0.0:
			active.erase(status)
			status_ended.emit(status)
	for element: String in meters.keys():
		var decay := _num(element, "decay_per_s", 20.0)
		meters[element] = maxf(meters[element] - decay * delta, 0.0)
		if meters[element] <= 0.0:
			meters.erase(element)


func _duration(element: String) -> float:
	match element:
		"frost":
			return _num(element, "freeze_s", 2.0)
		_:
			return _num(element, "duration_s", 4.0)


func _num(element: String, key: String, fallback: float) -> float:
	var block: Variant = _config.get(element, {})
	if block is Dictionary and (block as Dictionary).has(key):
		return float((block as Dictionary)[key])
	return fallback
