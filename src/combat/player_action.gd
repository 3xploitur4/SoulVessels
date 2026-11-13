class_name PlayerAction
extends RefCounted
## A timed thing the player body does: a combo hit, a dodge, a dash, an ability, a Resonance
## Strike, an Ultimate. Data in, behaviour out: the player ticks it each physics frame and asks
## it what to do (velocity, i-frames, hits, gravity, cancel windows). Special behaviour hangs on
## the `on_start` / `on_tick` / `on_end` callables, so kits stay small.
##
##     var a := PlayerAction.new("roll", 0.45)
##     a.set_iframes(0.05, 0.30)
##     a.set_velocity(6.7, 0.0, 0.45)
##     player.start_action(a)

var id: String = ""
var duration: float = 0.3
var elapsed: float = 0.0
## I-frames window [start, end] in action time; negative start = none.
var iframe_start: float = -1.0
var iframe_end: float = -1.0
## From this time on, attack/dodge/jump input may cancel the action.
var cancel_after: float = INF
## Inputs this action can be cancelled into ("attack", "dodge", "jump", "any").
var cancel_into: PackedStringArray = PackedStringArray(["any"])
## Horizontal speed along facing between vel_start and vel_end; NAN leaves control to physics.
var velocity_x: float = NAN
var vel_start: float = 0.0
var vel_end: float = 0.0
## Vertical velocity forced while active (air-dash holds 0); NAN = gravity rules.
var velocity_y: float = NAN
var gravity_scale: float = 1.0
## Steering allowed during the action (fraction of move speed).
var steer: float = 0.0
## Ignore flinch while active (Darius swings, ultimates).
var hyper_armor: bool = false
## Block stance while active (Royal Guard).
var blocking: bool = false
var hits: Array[ActionHit] = []
var on_start: Callable
var on_tick: Callable
var on_end: Callable
## Free-form state for the callables.
var data: Dictionary = {}

var _started: bool = false
var _ended: bool = false


func _init(action_id: String = "", length: float = 0.3) -> void:
	id = action_id
	duration = length


func set_iframes(from_s: float, to_s: float) -> PlayerAction:
	iframe_start = from_s
	iframe_end = to_s
	return self


func set_velocity(speed: float, from_s: float, to_s: float) -> PlayerAction:
	velocity_x = speed
	vel_start = from_s
	vel_end = to_s
	return self


func add_hit(h: ActionHit) -> PlayerAction:
	hits.append(h)
	return self


func is_invulnerable() -> bool:
	return iframe_start >= 0.0 and elapsed >= iframe_start and elapsed <= iframe_end


## Time since the i-frames began (for the perfect-dodge check); -1 when not in i-frames.
func time_into_iframes() -> float:
	return elapsed - iframe_start if is_invulnerable() else -1.0


func can_cancel_into(input_kind: String) -> bool:
	if elapsed < cancel_after:
		return false
	return cancel_into.has("any") or cancel_into.has(input_kind)


## Horizontal speed this frame along facing, or NAN.
func current_velocity_x() -> float:
	if is_nan(velocity_x):
		return NAN
	return velocity_x if elapsed >= vel_start and elapsed <= vel_end else 0.0


func is_finished() -> bool:
	return elapsed >= duration


## Called by the owner. Returns true while the action keeps running.
func advance(owner: Node, delta: float) -> bool:
	if not _started:
		_started = true
		if on_start.is_valid():
			on_start.call(owner, self)
	elapsed += delta
	if on_tick.is_valid():
		on_tick.call(owner, self, delta)
	return not is_finished()


## Run `on_end` once (finished or interrupted).
func finish(owner: Node, interrupted: bool) -> void:
	if _ended:
		return
	_ended = true
	if on_end.is_valid():
		on_end.call(owner, self, interrupted)
