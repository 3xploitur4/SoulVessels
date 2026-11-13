class_name BrandedWarden
extends EnemyBase
## Branded Warden (addendum enemy table, elite): 2.6 m iron guard. The tower shield blocks 80 %
## of frontal damage until it is lowered (a Caelan perfect parry opens a 2 s guard break, decision
## D-008) or broken (Crushing Blow). Hits from behind ignore it, and it turns slowly, so Nyra can
## flank. Gold halberd thrust (parryable) up close; crimson shield charge (unblockable) at range.

var shield_up: bool = true
var shield_broken: bool = false
var _guard_open_left: float = 0.0


func _init() -> void:
	enemy_id = "branded_warden"
	turn_delay_s = 0.6


func _ready() -> void:
	super()
	tier = "elite"


func _hurt_size() -> Vector2:
	return Vector2(1.3, 2.6)


func _physics_process(delta: float) -> void:
	if _guard_open_left > 0.0:
		_guard_open_left -= delta
		if _guard_open_left <= 0.0 and not shield_broken:
			shield_up = true
	super(delta)
	if visual != null and visual.shield != null:
		var lowered := not shield_up
		visual.shield.rotation.z = lerpf(visual.shield.rotation.z, -1.2 if lowered else 0.0, minf(delta * 10.0, 1.0))
		visual.shield.position.y = lerpf(visual.shield.position.y, 0.9 if lowered else 1.55, minf(delta * 10.0, 1.0))
	if visual != null and visual.weapon != null:
		var target_rot := 0.0
		if state == STATE_TELEGRAPH and str(current_attack.get("id", "")) == "halberd_thrust":
			target_rot = 0.9
		elif state == STATE_ATTACK and str(current_attack.get("id", "")) == "halberd_thrust":
			target_rot = -1.4
		visual.weapon.rotation.z = lerpf(visual.weapon.rotation.z, target_rot, minf(delta * 14.0, 1.0))


func open_guard(seconds: float) -> void:
	shield_up = false
	_guard_open_left = maxf(_guard_open_left, seconds)
	_end_attack()
	_enter_state(STATE_HURT)
	_flinch_left = seconds
	Sfx.play("guard_break")


## Crushing Blow and similar: the shield is gone for the fight.
func break_shield() -> void:
	shield_broken = true
	shield_up = false


func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	if p.breaks_shield and not shield_broken:
		break_shield()
	return super(p)


func snapshot() -> Dictionary:
	var s := super()
	s["shield_up"] = shield_up
	s["shield_broken"] = shield_broken
	return s


func _shield_blocks(p: DamagePacket, backstab: bool) -> bool:
	if not shield_up or shield_broken or backstab:
		return false
	var arc := float(data.get("shield", {}).get("frontal_arc_deg", 120.0))
	return CombatMath.hits_frontal_arc(p.source_x, global_position.x, facing, arc)


func _shield_fraction() -> float:
	return float(data.get("shield", {}).get("block_fraction", 0.8))


func _choose_attack(distance: float) -> Dictionary:
	if not shield_up and not shield_broken:
		return {}
	for a: Dictionary in data.get("attacks", []):
		var id := str(a.get("id", ""))
		if _cooldowns.get(id, 0.0) > 0.0:
			continue
		if id == "shield_charge" and distance >= float(a.get("min_range_m", 3.5)) and distance <= float(a.get("range_m", 6.0)) + 1.0:
			return a
		if id == "halberd_thrust" and distance <= float(a.get("range_m", 3.5)):
			return a
	return {}


func _attack_tick(_player: Node3D, delta: float) -> void:
	if str(current_attack.get("id", "")) == "shield_charge":
		var dist := float(current_attack.get("charge_distance_m", 6.0))
		var active := maxf(float(current_attack.get("active_s", 0.4)), 0.01)
		velocity.x = float(facing) * dist / active
	else:
		_halt(delta)


func _make_attack_hit(attack: Dictionary) -> ActionHit:
	if str(attack.get("id", "")) == "shield_charge":
		return ActionHit.new(0.0, float(attack.get("active_s", 0.4)) + 0.01, Vector2(1.0, 1.2),
			Vector2(1.4, 2.2), _make_packet(attack))
	return super(attack)
