class_name FungalStalker
extends EnemyBase
## Fungal Stalker (addendum enemy table, new): a ceiling ambusher for the vertical rooms. It
## hangs upside down from the ceiling until the player passes beneath within `drop_trigger_m`,
## shudders for 0.6 s with the crimson X, and drops hard: an unblockable body slam on the way
## down. On the ground it fights with a parryable slash. Weak to Ember.
##
##     var s := FungalStalker.new()
##     s.set_ceiling(14.0)   # RoomManager passes the ceiling height from the grid ("t")

## Fall speed of the drop, m/s.
const DROP_SPEED := 22.0
## While it hangs, its warning cue shows this far below it, so the cue is on screen even when
## the stalker itself sits above the frame.
const HANG_CUE_DROP_M := 4.5

## True while hanging from the ceiling.
var hanging: bool = true

var _ceiling_y: float = NAN
var _placed: bool = false
var _dropping: bool = false


func _init() -> void:
	enemy_id = "fungal_stalker"


func _hurt_size() -> Vector2:
	return Vector2(1.0, 1.7)


## The underside of the rock it hangs from (room metres).
func set_ceiling(y: float) -> void:
	_ceiling_y = y


func _physics_process(delta: float) -> void:
	if hanging and not _placed and not is_nan(_ceiling_y):
		_placed = true
		global_position.y = _ceiling_y - _hurt_size().y - 0.05
		visual.rotation.z = PI
		visual.position.y = _hurt_size().y
		telegraph.position.y = -HANG_CUE_DROP_M
		reset_physics_interpolation()
	super(delta)
	if _dropping and is_on_floor():
		_land()


func _apply_gravity(delta: float) -> void:
	if hanging and not _dropping:
		velocity.y = 0.0
		return
	super(delta)


func _idle_tick(player: Node3D, delta: float) -> void:
	if not hanging:
		super(player, delta)
		return
	_halt(delta)
	if player == null or _player_hidden(player):
		return
	var below := player.global_position.y < global_position.y - 0.5
	if below and absf(player.global_position.x - global_position.x) <= float(data.get("drop_trigger_m", 2.0)):
		_set_aggro(true)
		var drop := _attack("drop_slam")
		if not drop.is_empty():
			_begin_telegraph(drop)


func _choose_attack(distance: float) -> Dictionary:
	if hanging:
		return {}
	for a: Dictionary in data.get("attacks", []):
		if bool(a.get("from_ceiling", false)):
			continue
		if distance <= float(a.get("range_m", 2.0)) and _cooldowns.get(str(a.get("id", "")), 0.0) <= 0.0:
			return a
	return {}


func _attack(id: String) -> Dictionary:
	for a: Dictionary in data.get("attacks", []):
		if str(a.get("id", "")) == id:
			return a
	return {}


func _begin_attack() -> void:
	super()
	if bool(current_attack.get("from_ceiling", false)):
		_dropping = true
		velocity.y = -DROP_SPEED
		telegraph.position.y = _hurt_size().y + 0.7
		visual.rotation.z = 0.0
		visual.position.y = 0.0


func _attack_tick(_player: Node3D, delta: float) -> void:
	if _dropping:
		velocity.x = 0.0
		velocity.y = -DROP_SPEED
		# Stay in the attack until the ground is reached.
		state_time = minf(state_time, float(current_attack.get("active_s", 0.6)) - delta * 2.0)
		return
	_halt(delta)


func _make_attack_hit(attack: Dictionary) -> ActionHit:
	if bool(attack.get("from_ceiling", false)):
		# The whole falling body hits.
		return ActionHit.new(0.0, 99.0, Vector2(0.0, 0.0), Vector2(1.3, 1.8), _make_packet(attack))
	return super(attack)


func _land() -> void:
	_dropping = false
	hanging = false
	_end_attack()
	_enter_state(STATE_RECOVER)
	Sfx.play("guard_break")
	GameEvents.camera_shake_requested.emit(0.35)
	if visual is EnemySpriteVisual:
		(visual as EnemySpriteVisual).body.puff()


func _can_flinch() -> bool:
	return not hanging and super()
