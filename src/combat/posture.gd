class_name Posture
extends RefCounted
## Posture bar (addendum "Posture"). Fills from hits and parries; a full bar staggers for
## `stagger_s` (2.5 s for enemies, a 1 s guard break for the player) and resets. Drains
## `drain_per_s` after `drain_delay_s` without a hit. While staggered the owner is open to a
## Riposte (2x), which ends the stagger early via `end_stagger()`.
##
##     var p := Posture.for_enemy(220.0)
##     if p.add(35.0): _enter_stagger()

signal broken
signal changed(value: float, maximum: float)

var max_value: float = 100.0
var value: float = 0.0
var drain_per_s: float = 10.0
var drain_delay_s: float = 2.0
var stagger_s: float = 2.5

var _since_hit: float = 999.0
var _stagger_left: float = 0.0


## An enemy bar of `max_value`, timings from combat.json `posture.*`.
static func for_enemy(max_posture: float) -> Posture:
	var p := Posture.new()
	p.max_value = max_posture
	p.drain_per_s = Balance.combat_f("posture.drain_per_s")
	p.drain_delay_s = Balance.combat_f("posture.drain_delay_s")
	p.stagger_s = Balance.combat_f("posture.stagger_s")
	return p


## The player's hidden bar: 100, full = 1 s guard break.
static func for_player() -> Posture:
	var p := Posture.new()
	p.max_value = Balance.combat_f("posture.player_max")
	p.drain_per_s = Balance.combat_f("posture.drain_per_s")
	p.drain_delay_s = Balance.combat_f("posture.drain_delay_s")
	p.stagger_s = Balance.combat_f("posture.player_guard_break_s")
	return p


## Add posture damage. Returns true on the hit that fills the bar (stagger starts, bar resets).
## Hits on an already staggered owner add nothing.
func add(amount: float) -> bool:
	if _stagger_left > 0.0 or amount <= 0.0:
		return false
	_since_hit = 0.0
	value = minf(value + amount, max_value)
	changed.emit(value, max_value)
	if value >= max_value:
		value = 0.0
		_stagger_left = stagger_s
		broken.emit()
		changed.emit(value, max_value)
		return true
	return false


func is_staggered() -> bool:
	return _stagger_left > 0.0


func stagger_left() -> float:
	return _stagger_left


## End the stagger now (after a Riposte lands).
func end_stagger() -> void:
	_stagger_left = 0.0


func ratio() -> float:
	return value / max_value if max_value > 0.0 else 0.0


func tick(delta: float) -> void:
	if _stagger_left > 0.0:
		_stagger_left = maxf(_stagger_left - delta, 0.0)
		return
	_since_hit += delta
	var drain_time := minf(delta, _since_hit - drain_delay_s)
	if drain_time > 0.0 and value > 0.0:
		value = maxf(value - drain_per_s * drain_time, 0.0)
		changed.emit(value, max_value)
