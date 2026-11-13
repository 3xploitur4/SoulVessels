class_name Health
extends RefCounted
## A hit-point pool. The player's soul HP is one shared Health (the Intruder dies, not the
## Vessel); every enemy has its own.
##
##     var hp := Health.new(300.0)
##     var taken := hp.damage(42.0)

signal changed(current: float, maximum: float)
signal died

var max_value: float = 100.0
var current: float = 100.0


func _init(maximum: float = 100.0) -> void:
	max_value = maximum
	current = maximum


## Subtract `amount` (never below 0). Returns the HP actually removed. Emits `died` once.
func damage(amount: float) -> float:
	if current <= 0.0 or amount <= 0.0:
		return 0.0
	var before := current
	current = maxf(current - amount, 0.0)
	changed.emit(current, max_value)
	if current <= 0.0:
		died.emit()
	return before - current


func heal(amount: float) -> void:
	if current <= 0.0:
		return
	current = minf(current + amount, max_value)
	changed.emit(current, max_value)


## Back to full, alive again (sandbox respawn, altar rest).
func reset(maximum: float = -1.0) -> void:
	if maximum > 0.0:
		max_value = maximum
	current = max_value
	changed.emit(current, max_value)


func is_dead() -> bool:
	return current <= 0.0


func ratio() -> float:
	return current / max_value if max_value > 0.0 else 0.0
