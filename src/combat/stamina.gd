class_name Stamina
extends RefCounted
## Per-Vessel stamina (addendum "Stamina"). 100 max, regen 40/s after 0.6 s without spending,
## Exhausted (no dodge) for 1.5 s on reaching 0. Inactive Vessels regen at 2x (the caller passes
## the multiplier). Pure: tick it from `_physics_process`, test it without a scene.
##
##     var s := Stamina.from_balance()
##     if s.can_spend(): s.spend(20.0)
##     s.tick(delta)

signal exhausted
signal changed(value: float, maximum: float)

var max_value: float = 100.0
var value: float = 100.0
var regen_per_s: float = 40.0
var regen_delay_s: float = 0.6
var exhausted_s: float = 1.5

var _since_spend: float = 999.0
var _exhausted_left: float = 0.0


## Built from combat.json `stamina.*`.
static func from_balance() -> Stamina:
	var s := Stamina.new()
	s.max_value = Balance.combat_f("stamina.max")
	s.value = s.max_value
	s.regen_per_s = Balance.combat_f("stamina.regen_per_s")
	s.regen_delay_s = Balance.combat_f("stamina.regen_delay_s")
	s.exhausted_s = Balance.combat_f("stamina.exhausted_s")
	return s


## Souls rule: any action is allowed while stamina is above 0 and the Vessel is not Exhausted.
func can_spend() -> bool:
	return value > 0.0 and _exhausted_left <= 0.0


## Spend `cost`. Returns false (and spends nothing) when `can_spend()` is false. Reaching 0
## starts Exhausted.
func spend(cost: float) -> bool:
	if not can_spend():
		return false
	if cost <= 0.0:
		return true
	value = maxf(value - cost, 0.0)
	_since_spend = 0.0
	if value <= 0.0:
		_exhausted_left = exhausted_s
		exhausted.emit()
	changed.emit(value, max_value)
	return true


## Take stamina without the can-spend gate (blocking a hit drains even an empty bar).
## Returns true when the bar ran dry (guard break for a block).
func drain(cost: float) -> bool:
	var dry := value - cost < 0.0
	value = maxf(value - cost, 0.0)
	_since_spend = 0.0
	if value <= 0.0 and _exhausted_left <= 0.0:
		_exhausted_left = exhausted_s
		exhausted.emit()
	changed.emit(value, max_value)
	return dry


## Instant gain (perfect parry +15). Clears Exhausted when it lifts the bar off 0.
func restore(amount: float) -> void:
	value = minf(value + amount, max_value)
	if value > 0.0:
		_exhausted_left = 0.0
	changed.emit(value, max_value)


func is_exhausted() -> bool:
	return _exhausted_left > 0.0


func ratio() -> float:
	return value / max_value if max_value > 0.0 else 0.0


## Advance regen and the Exhausted timer. `multiplier` is 2.0 for an inactive Vessel.
func tick(delta: float, multiplier: float = 1.0) -> void:
	if _exhausted_left > 0.0:
		_exhausted_left = maxf(_exhausted_left - delta, 0.0)
	_since_spend += delta
	# Only the part of this tick that lies past the delay regenerates.
	var regen_time := minf(delta, _since_spend - regen_delay_s)
	if regen_time > 0.0 and value < max_value:
		value = minf(value + regen_per_s * multiplier * regen_time, max_value)
		changed.emit(value, max_value)
