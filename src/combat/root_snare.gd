class_name RootSnare
extends RefCounted
## Calcified Husk root-snare on the player (addendum "Root Snare"). The player is rooted for
## `duration_s` seconds and cannot move, jump or dodge. Tapping attack, jump or dodge
## `taps_to_break` times breaks free early; a Shadowstep breaks it at once. Pure: tick it from
## `_physics_process`, test it without a scene.
##
##     var snare := RootSnare.from_data(data)
##     snare.apply()
##     snare.tick(delta)
##     if snare.tap(): pass  # broke free

## Seconds the player stays rooted.
var duration_s: float = 2.5
## Number of action taps needed to break free early.
var taps_to_break: int = 6
## Seconds remaining; 0.0 when not snared.
var left: float = 0.0
## Taps counted toward breaking free since the snare was applied.
var taps: int = 0


## Built from data with keys `duration_s` and `taps_to_break` (defaults 2.5 and 6).
static func from_data(d: Dictionary) -> RootSnare:
	var snare := RootSnare.new()
	snare.duration_s = float(d.get("duration_s", 2.5))
	snare.taps_to_break = int(d.get("taps_to_break", 6))
	return snare


## Start or restart the snare: full duration, no taps counted.
func apply() -> void:
	left = duration_s
	taps = 0


## True while the player is rooted.
func is_active() -> bool:
	return left > 0.0


## Advance the timer. At 0 the snare ends and the tap count resets.
func tick(delta: float) -> void:
	if left <= 0.0:
		return
	left = maxf(left - delta, 0.0)
	if left <= 0.0:
		taps = 0


## Count one action tap. Returns true when the tap count reaches `taps_to_break` and the
## snare breaks; false otherwise (and when not active).
func tap() -> bool:
	if not is_active():
		return false
	taps += 1
	if taps >= taps_to_break:
		left = 0.0
		taps = 0
		return true
	return false


## End the snare at once (Shadowstep).
func break_now() -> void:
	left = 0.0
	taps = 0


## Taps still needed to break free; 0 when not active.
func taps_left() -> int:
	return maxi(taps_to_break - taps, 0) if is_active() else 0
