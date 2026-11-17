class_name ChoirPrelate
extends EnemyBase
## Choir Prelate (addendum enemy table, elite, Zone 3): a floating cleric who keeps its distance and
## fires volleys of magic orbs (violet diamond cue). Its golden aura gives every ally within
## `aura_radius_m` +30 % ATK and DEF; Unravel (an Aether status) strips the aura while it lasts.
## When the player comes within `teleport_trigger_m` it vanishes and reappears `teleport_step_m`
## away on the far side. Drops the Tarnished Censer Shard. Numbers in choir_prelate.json.
##
##     var p := ChoirPrelate.new()   # or EnemyFactory.create("choir_prelate")

var _aura_t: float = 0.0
var _tp_cooldown: float = 0.0
var _tp_left: float = -1.0
var _tp_to: float = 0.0
var _aura_ring: MeshInstance3D
var _ally_scratch: Array[Node3D] = []


func _init() -> void:
	enemy_id = "choir_prelate"


func _ready() -> void:
	super._ready()
	# The aura's reach, drawn as a thin ellipse flattened onto the walkway (8 m each way along x).
	_aura_ring = VfxShapes.ring(Color(1.0, 0.84, 0.42, 0.45), float(data.get("aura_radius_m", 8.0)))
	add_child(_aura_ring)
	_aura_ring.position = Vector3(0.0, 0.04 - float(data.get("hover_height_m", 0.0)), 0.0)


func _hurt_size() -> Vector2:
	return Vector2(1.1, 2.2)


## True while its aura is up (alive and not Unraveled).
func aura_active() -> bool:
	return is_alive() and not status.has_status("unraveled")


## Would it teleport away from a player `distance` metres off?
func wants_teleport(distance: float) -> bool:
	return _tp_cooldown <= 0.0 and _tp_left < 0.0 and distance <= float(data.get("teleport_trigger_m", 3.0))


## Where to reappear: `step` metres from `from_x`, on the side away from the player.
static func teleport_x(from_x: float, player_x: float, step: float) -> float:
	return from_x - step if player_x >= from_x else from_x + step


func _start_teleport_cooldown() -> void:
	_tp_cooldown = float(data.get("teleport_cooldown_s", 4.0))


func _physics_process(delta: float) -> void:
	_tp_cooldown = maxf(_tp_cooldown - delta, 0.0)
	_tick_aura(delta)
	if _tp_left >= 0.0 and is_alive():
		_tick_teleport(delta)
		return
	super(delta)


func _apply_gravity(_delta: float) -> void:
	# It floats: no fall, it rides the height it spawned at.
	velocity.y = 0.0


func _tick_aura(delta: float) -> void:
	_aura_ring.visible = aura_active()
	if _aura_ring.visible:
		var pulse := 1.0 + 0.04 * sin(state_time * 4.0)
		_aura_ring.scale = Vector3(pulse, 1.0, 0.1 * pulse)
	if not aura_active() or world == null:
		return
	_aura_t -= delta
	if _aura_t > 0.0:
		return
	_aura_t = float(data.get("aura_tick_s", 0.25))
	_ally_scratch.clear()
	world.query_radius(Vector2(global_position.x, global_position.y + 1.0), float(data.get("aura_radius_m", 8.0)),
		CombatWorld.TEAM_ENEMY, _ally_scratch)
	for ally in _ally_scratch:
		if ally != self and ally is EnemyBase:
			(ally as EnemyBase).apply_buff(float(data.get("aura_multiplier", 1.3)), float(data.get("aura_hold_s", 0.6)))


func _approach_tick(player: Node3D, delta: float) -> void:
	if player != null and not _player_hidden(player):
		var dist := absf(player.global_position.x - global_position.x)
		if wants_teleport(dist):
			_begin_teleport(player.global_position.x)
			return
	super(player, delta)


func _begin_teleport(player_x: float) -> void:
	_end_attack()
	_tp_left = float(data.get("teleport_s", 0.35))
	_tp_to = teleport_x(global_position.x, player_x, float(data.get("teleport_step_m", 7.0)))
	if not _clear_at(_tp_to):
		# Blocked that way: try the other side of the player instead.
		_tp_to = teleport_x(global_position.x, 2.0 * global_position.x - player_x, float(data.get("teleport_step_m", 7.0)))
	_start_teleport_cooldown()
	visual.flash(Color(1.0, 0.86, 0.45), 0.2)
	Sfx.play("vanish")


func _tick_teleport(delta: float) -> void:
	velocity = Vector3.ZERO
	_tp_left -= delta
	visual.visible = int(_tp_left * 30.0) % 2 == 0
	if _tp_left <= 0.0:
		_tp_left = -1.0
		visual.visible = true
		if _clear_at(_tp_to):
			global_position.x = _tp_to
			reset_physics_interpolation()
		visual.flash(Color(1.0, 0.86, 0.45), 0.2)
		_enter_state(STATE_APPROACH)
	visual.animate(STATE_IDLE, facing, 0.0, delta)


## Is the spot `x` at its own height free of rock?
func _clear_at(x: float) -> bool:
	if not is_inside_tree():
		return true
	var space := get_world_3d().direct_space_state
	var q := PhysicsPointQueryParameters3D.new()
	q.position = Vector3(x, global_position.y + 1.0, 0.0)
	q.collision_mask = 1
	return space.intersect_point(q, 1).is_empty()


## The volley: `orbs` magic orbs fanned toward the player.
func _begin_attack() -> void:
	super()
	var player := _target()
	var n := int(current_attack.get("orbs", 3))
	var speed := float(current_attack.get("orb_speed_mps", 9.0))
	var spread := deg_to_rad(float(current_attack.get("orb_spread_deg", 16.0)))
	var origin := Vector2(global_position.x + 0.6 * facing, global_position.y + 1.6)
	var aim := Vector2(float(facing), 0.0)
	if player != null:
		aim = (Vector2(player.global_position.x, player.global_position.y + 1.0) - origin).normalized()
	for i in range(n):
		var t := 0.0 if n <= 1 else float(i) / float(n - 1) - 0.5
		var v := aim.rotated(t * spread) * speed
		var proj := Projectile.spawn(get_parent(), world, _make_packet(current_attack), origin, v, Vector2(0.45, 0.45),
			VfxShapes.bolt(Color(0.62, 0.38, 1.0), 0.22, 1.3))
		proj.target_team = CombatWorld.TEAM_PLAYER
		proj.pierce = false
		proj.max_distance = float(current_attack.get("range_m", 14.0)) + 2.0
		proj.lifetime = proj.max_distance / speed + 0.1
	Sfx.play("telegraph_harmonic")


func _make_attack_hit(_attack: Dictionary) -> ActionHit:
	# The orbs do the hitting.
	return null
