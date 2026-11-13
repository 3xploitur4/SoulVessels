class_name SubterraneanWatcher
extends EnemyBase
## Subterranean Watcher (addendum enemy table): a porcelain sphere hovering 4 m up. 1.2 s cyan
## eye charge with the violet diamond cue, then a 1.5 s sweeping beam that ticks every 0.25 s.
## A Caelan perfect parry reflects the beam back (its own ATK). Aether grounds it for 4 s.

var _aim_angle: float = 0.0
var _beam_angle: float = 0.0
var _tick_left: float = 0.0
var _grounded_left: float = 0.0
var _hover_y: float = 4.0
var _beam_range: float = 12.0
var _bob: float = 0.0


func _init() -> void:
	enemy_id = "subterranean_watcher"


func _ready() -> void:
	super()
	_hover_y = float(data.get("hover_height_m", 4.0))
	visual.position.y = 0.0
	# Hovering high: put the cue just above the sphere so it stays inside the frame.
	telegraph.position.y = _hurt_size().y * 0.5 + 0.55


func _hurt_size() -> Vector2:
	var r := float(data.get("silhouette", {}).get("radius_m", 0.6))
	return Vector2(r * 2.2, r * 2.2)


func _hurt_offset_y() -> float:
	return -_hurt_size().y * 0.5


func _collision_shape() -> Shape3D:
	var s := SphereShape3D.new()
	s.radius = _hurt_size().x * 0.4
	return s


## Ground the Watcher for `seconds` (Aether hits; Seris arrives in M3).
func ground(seconds: float) -> void:
	_grounded_left = seconds
	_end_attack()
	_enter_state(STATE_HURT)
	_flinch_left = seconds


func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	var r := super(p)
	if p.element == "aether" and is_alive():
		ground(float(data.get("grounded_s_on_aether", 4.0)))
	return r


func _choose_attack(distance: float) -> Dictionary:
	var player := _target()
	if player == null:
		return {}
	var dy := absf(player.global_position.y + 0.9 - global_position.y)
	return super(Vector2(distance, dy).length())


func _apply_gravity(delta: float) -> void:
	_bob += delta
	if _grounded_left > 0.0:
		_grounded_left -= delta
		super(delta)
		return
	var floor_y := 0.0
	var target_y := floor_y + _hover_y + sin(_bob * 1.6) * 0.25
	velocity.y = (target_y - global_position.y) * 4.0


func _telegraph_tick(player: Node3D, _delta: float) -> void:
	if player == null:
		return
	var to := Vector2(player.global_position.x - global_position.x, player.global_position.y + 0.9 - global_position.y)
	# Aim tracks during the first two thirds of the charge, then locks: the dodge window.
	if state_time < float(current_attack.get("telegraph_s", 1.2)) * 0.66:
		_aim_angle = to.angle()
		facing = 1 if to.x >= 0.0 else -1
	_show_line(visual.aim_line, _aim_angle, true)


func _begin_attack() -> void:
	super()
	_attack_hit = null
	var sweep := deg_to_rad(float(current_attack.get("beam_sweep_deg", 40.0)))
	_beam_angle = _aim_angle - sweep * 0.5 * float(facing)
	_beam_range = float(current_attack.get("range_m", 12.0))
	_tick_left = 0.0
	visual.aim_line.visible = false
	Sfx.play("beam")


func _attack_tick(_player: Node3D, delta: float) -> void:
	_halt(delta)
	var active := maxf(float(current_attack.get("active_s", 1.5)), 0.01)
	var sweep := deg_to_rad(float(current_attack.get("beam_sweep_deg", 40.0)))
	_beam_angle = _aim_angle + (state_time / active - 0.5) * sweep * float(facing)
	_show_line(visual.beam, _beam_angle, true)
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = float(current_attack.get("tick_s", 0.25))
	var a := Vector2(global_position.x, global_position.y)
	var b := a + Vector2.from_angle(_beam_angle) * _beam_range
	_scratch.clear()
	world.members_of(CombatWorld.TEAM_PLAYER, _scratch)
	for t in _scratch:
		if CombatWorld.segment_hits_rect(a, b, t.call("hurt_rect")):
			var p := _make_packet(current_attack)
			p.source_x = global_position.x
			p.result = t.call("receive_hit", p)
			if p.result == DamagePacket.Result.REFLECTED:
				return


func _end_attack() -> void:
	super()
	if visual != null:
		visual.beam.visible = false
		visual.aim_line.visible = false


func _show_line(line: MeshInstance3D, angle: float, on: bool) -> void:
	line.visible = on
	if not on:
		return
	var length := _beam_range
	# The visual is a child of the rotated visual root; undo its facing flip.
	var local_angle := angle if facing > 0 else PI - angle
	line.scale = Vector3(length, 1.0, 1.0)
	line.rotation = Vector3(0.0, 0.0, local_angle)
	line.position = Vector3(cos(local_angle), sin(local_angle), 0.0) * length * 0.5
