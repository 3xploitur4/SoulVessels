class_name EnemyBase
extends CharacterBody3D
## Shared enemy body and state machine (story 010). States: idle -> approach -> telegraph ->
## attack -> recover, plus hurt (flinch), knockdown, staggered (posture broken, open to a Riposte)
## and dead. Each attack in the data has a kind (parryable / unblockable / magic) and the standard
## telegraph plays before it with the enemy's own tell. Subclasses pick attacks and run the
## special ones (lunge, beam, charge).
##
## Inject before add_child:
##     var e := EchoCrawler.new()
##     e.world = combat_world
##     e.rng_seed = 17
##     arena.add_child(e)
##     e.global_position = Vector3(8, 0, 0)

const STATE_IDLE := "idle"
const STATE_APPROACH := "approach"
const STATE_TELEGRAPH := "telegraph"
const STATE_ATTACK := "attack"
const STATE_RECOVER := "recover"
const STATE_HURT := "hurt"
const STATE_KNOCKDOWN := "knockdown"
const STATE_STAGGERED := "staggered"
const STATE_DEAD := "dead"
const FLINCH_S := 0.22
const DISSOLVE_S := 0.4

## Data id in data/balance/enemies/.
var enemy_id: String = ""
## Stable id of the room spawn that made this enemy ("room:index"), "" outside rooms.
var spawn_id: String = ""
var data: Dictionary = {}
var world: CombatWorld
var rng_seed: int = 1
var team: int = CombatWorld.TEAM_ENEMY
var facing: int = -1
var tier: String = "common"
var health: Health
var posture: Posture
var status: StatusEffects
var state: String = STATE_IDLE
var state_time: float = 0.0
var aggro: bool = false
var current_attack: Dictionary = {}
## Difficulty multiplier on this enemy's damage.
var damage_scale: float = 1.0
## Turn delay: seconds the enemy keeps its facing after the player crosses behind it.
var turn_delay_s: float = 0.0

var visual: EnemyVisual
var telegraph: Telegraph
var rng := RandomNumberGenerator.new()

var _cooldowns: Dictionary[String, float] = {}
var _attack_hit: ActionHit
var _gravity: float = 30.0
var _turn_timer: float = 0.0
var _flinch_left: float = 0.0
var _dead_left: float = 0.0
var _preferred_range: float = 2.0
var _scratch: Array[Node3D] = []
var _buff_left: float = 0.0
var _buff_mult: float = 1.0
var _buff_fx: Node3D


func _ready() -> void:
	if data.is_empty():
		data = Balance.enemy(enemy_id)
	rng.seed = rng_seed
	tier = str(data.get("tier", "common"))
	collision_layer = 1 << 2
	# World, one-way platforms, veil curtains and the room's enemy-only side walls.
	collision_mask = 1 | (1 << 8) | (1 << 9) | (1 << 10)
	axis_lock_linear_z = true
	health = Health.new(float(data.get("hp", 100.0)))
	posture = Posture.for_enemy(float(data.get("posture", 50.0)))
	status = StatusEffects.from_balance()
	_gravity = float(Balance.combat_f("movement.gravity"))
	_preferred_range = float(data.get("preferred_range_m", 2.0)) + rng.randf_range(-0.4, 0.9)
	var shape := CollisionShape3D.new()
	shape.shape = _collision_shape()
	shape.position.y = _hurt_size().y * 0.5
	add_child(shape)
	visual = EnemyVisual.build(data)
	add_child(visual)
	telegraph = Telegraph.new()
	telegraph.height = _hurt_size().y + 0.7
	add_child(telegraph)
	if world != null:
		world.register(self)


func _exit_tree() -> void:
	if world != null:
		world.unregister(self)
	if aggro:
		GameEvents.enemy_aggro_changed.emit(self, false)


# --- Combatant interface -------------------------------------------------------------------

func hurt_rect() -> Rect2:
	var size := _hurt_size()
	return Rect2(global_position.x - size.x * 0.5, global_position.y + _hurt_offset_y(), size.x, size.y)


func is_alive() -> bool:
	return state != STATE_DEAD and not health.is_dead()


func is_staggered() -> bool:
	return posture.is_staggered()


## Resolve a player hit: backstab, crit, element, AoE, shield, Riposte, Echo Bonus, posture.
func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	if not is_alive():
		return DamagePacket.Result.IGNORED
	_set_aggro(true)
	var attacker := p.attacker as Node3D
	var hidden_backstab := attacker != null and is_instance_valid(attacker) and bool(attacker.get("next_hit_backstab"))
	var backstab := p.force_backstab or hidden_backstab or CombatMath.is_backstab(p.source_x, global_position.x, facing)
	var echo: Dictionary = p.tags.get("echo", {})
	var echo_on := _echo_applies(echo)
	var crit := p.force_crit or (echo_on and bool(echo.get("guaranteed_crit", false))) or CombatMath.roll_crit(p.crit_chance, rng)
	var riposte := p.is_primary and posture.is_staggered() and _riposte_allowed()
	var element_mult := CombatMath.element_multiplier(p.element, data.get("weaknesses", []), data.get("resists", []),
		Balance.combat_f("damage.weakness_multiplier"), Balance.combat_f("damage.resist_multiplier"))
	var def := float(data.get("def", 0.0)) * status.def_multiplier() * buff_multiplier()
	if bool(p.tags.get("ignore_def", false)):
		def = 0.0
	var dmg := CombatMath.damage(p.atk, p.motion, def, p.crit_multiplier if crit else 1.0, element_mult,
		p.backstab_multiplier if backstab else 1.0)
	if p.aoe:
		dmg *= float(data.get("aoe_multiplier", 1.0))
	dmg *= status.damage_taken_multiplier()
	# Darius's AoE kills Echo Crawlers outright (addendum "Resolved contradictions"; story 041).
	if p.aoe and bool(p.tags.get("heavy_aoe", false)) and bool(data.get("dies_to_heavy_aoe", false)):
		dmg = maxf(dmg, health.current)
	var posture_amt := p.posture
	if echo_on:
		posture_amt *= float(echo.get("posture_multiplier", 1.0))
	if riposte:
		dmg *= Balance.combat_f("posture.riposte_multiplier")
		posture.end_stagger()
		posture_amt = 0.0
	var result := DamagePacket.Result.HIT
	var shielded := _shield_blocks(p, backstab)
	if shielded:
		var frac := _shield_fraction()
		dmg = CombatMath.shielded_damage(dmg, true, true, frac)
		posture_amt *= 1.0 - frac * 0.5
		result = DamagePacket.Result.SHIELDED
	p.dealt = health.damage(dmg)
	p.was_crit = crit
	p.was_backstab = backstab
	p.was_riposte = riposte
	if p.element_buildup > 0.0:
		status.add_buildup(p.element, p.element_buildup)
	GameEvents.hit_fx_requested.emit(global_position + Vector3(0.0, _hurt_size().y * 0.6, 0.5),
		p.dealt, crit or riposte, shielded)
	if health.is_dead():
		_die()
		return DamagePacket.Result.KILLED
	if posture.add(posture_amt):
		_enter_stagger()
	elif p.tags.has("knockdown_s"):
		_enter_state(STATE_KNOCKDOWN)
		_flinch_left = float(p.tags["knockdown_s"])
		telegraph.hide_cue()
		visual.tell(0.0)
	elif not shielded and _can_flinch():
		_flinch(p)
	visual.flash(Color(1.0, 0.95, 0.9) if not shielded else Color(0.85, 0.65, 0.3), 0.08)
	return result


## A perfect parry by the player: posture damage, attack cancelled, a long recovery.
func on_parried(_by: Node3D, posture_damage: float) -> void:
	_end_attack()
	if posture.add(posture_damage):
		_enter_stagger()
	else:
		_enter_state(STATE_RECOVER)
		state_time = -0.5


## Open the guard for `seconds` (Counterstrike). Shield-bearers lower their shield.
func open_guard(_seconds: float) -> void:
	pass


## A reflected magic attack (Watcher beam parried by Caelan). Default: own ATK as damage.
func receive_reflect(p: DamagePacket) -> void:
	if not is_alive():
		return
	var dmg := CombatMath.damage(float(data.get("atk", 10.0)), 1.0, float(data.get("def", 0.0)))
	health.damage(dmg)
	GameEvents.hit_fx_requested.emit(global_position + Vector3(0.0, _hurt_size().y * 0.6, 0.5), dmg, true, false)
	if p.attacker != null and p.attacker.has_method("report_hit"):
		var r := p.duplicate_packet()
		r.result = DamagePacket.Result.KILLED if health.is_dead() else DamagePacket.Result.HIT
		r.dealt = dmg
		p.attacker.call("report_hit", self, r)
	if health.is_dead():
		_die()
		return
	_end_attack()
	if posture.add(25.0):
		_enter_stagger()
	else:
		_enter_state(STATE_HURT)
		_flinch_left = 0.6


## Bridge/HUD snapshot.
func snapshot() -> Dictionary:
	return {
		"id": enemy_id,
		"x": snappedf(global_position.x, 0.01),
		"y": snappedf(global_position.y, 0.01),
		"hp": snappedf(health.current, 0.1),
		"hp_max": health.max_value,
		"posture": snappedf(posture.value, 0.1),
		"posture_max": posture.max_value,
		"state": state,
		"state_time": snappedf(state_time, 0.001),
		"facing": facing,
		"staggered": posture.is_staggered(),
		"attack": str(current_attack.get("id", "")),
		"tier": tier,
		"buffed": buff_multiplier() > 1.0,
		"frozen": status.has_status("frozen"),
	}


# --- Frame loop -----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	state_time += delta
	posture.tick(delta)
	status.tick(delta)
	for key: String in _cooldowns.keys():
		_cooldowns[key] = maxf(_cooldowns[key] - delta, 0.0)
	_tick_buff(delta)
	if state == STATE_DEAD:
		_dead_left -= delta
		visual.dissolve(1.0 - clampf(_dead_left / DISSOLVE_S, 0.0, 1.0))
		if _dead_left <= 0.0:
			queue_free()
		return
	var dot := status.dot_per_s(health.max_value)
	if dot > 0.0:
		health.damage(dot * delta)
		if health.is_dead():
			_die()
			return
	if posture.is_staggered():
		if state != STATE_STAGGERED:
			_enter_stagger()
	elif state == STATE_STAGGERED:
		_enter_state(STATE_APPROACH)
	if status.has_status("frozen") and state != STATE_STAGGERED:
		_frozen_tick(delta)
		return
	var player := _target()
	match state:
		STATE_IDLE:
			_idle_tick(player, delta)
		STATE_APPROACH:
			_approach_tick(player, delta)
		STATE_TELEGRAPH:
			_halt(delta)
			var tel := float(current_attack.get("telegraph_s", 0.6))
			visual.tell(state_time / maxf(tel, 0.01))
			_telegraph_tick(player, delta)
			if state_time >= tel:
				_begin_attack()
		STATE_ATTACK:
			_attack_tick(player, delta)
			if _attack_hit != null and state == STATE_ATTACK:
				var origin := Vector2(global_position.x, global_position.y)
				_attack_hit.sweep(world, origin, facing, CombatWorld.TEAM_PLAYER, _on_attack_landed)
			if state == STATE_ATTACK and state_time >= float(current_attack.get("active_s", 0.2)):
				_end_attack()
				_enter_state(STATE_RECOVER)
		STATE_RECOVER:
			_halt(delta)
			if state_time >= float(current_attack.get("recover_s", 0.6)):
				_enter_state(STATE_APPROACH)
		STATE_HURT, STATE_KNOCKDOWN:
			_halt(delta * 0.5)
			_flinch_left -= delta
			if _flinch_left <= 0.0:
				_enter_state(STATE_APPROACH)
		STATE_STAGGERED:
			_halt(delta)
	_apply_gravity(delta)
	move_and_slide()
	if global_position.z != 0.0:
		global_position.z = 0.0
	visual.animate(state, facing, absf(velocity.x), delta)


# --- Buffs and Freeze (story 033) -----------------------------------------------------------

## An ally's aura (the Choir Prelate): ATK and DEF times mult for the given seconds, refreshed while in range.
func apply_buff(mult: float, seconds: float) -> void:
	_buff_mult = mult
	_buff_left = maxf(_buff_left, seconds)


## The ATK and DEF multiplier from a buff now (1.0 when none).
func buff_multiplier() -> float:
	return _buff_mult if _buff_left > 0.0 else 1.0


func _tick_buff(delta: float) -> void:
	_buff_left = maxf(_buff_left - delta, 0.0)
	var on := _buff_left > 0.0 and is_alive()
	if on and _buff_fx == null:
		_buff_fx = VfxShapes.ring(Color(1.0, 0.82, 0.38), _hurt_size().x * 0.75)
		add_child(_buff_fx)
		_buff_fx.position.y = 0.06
	if _buff_fx != null:
		_buff_fx.visible = on


## Frozen (Frost build-up full): it cannot move or act until the ice breaks.
func _frozen_tick(delta: float) -> void:
	if state == STATE_TELEGRAPH or state == STATE_ATTACK:
		_end_attack()
		_enter_state(STATE_RECOVER)
	velocity.x = 0.0
	_apply_gravity(delta)
	move_and_slide()
	if global_position.z != 0.0:
		global_position.z = 0.0
	visual.flash(Color(0.7, 0.92, 1.0), 0.05)
	visual.animate(STATE_STAGGERED, facing, 0.0, delta)


# --- Overridable behaviour ------------------------------------------------------------------

## Hurt rect size (w, h) in metres.
func _hurt_size() -> Vector2:
	return Vector2(1.0, 1.0)


## Rect bottom relative to the body origin (hovering enemies raise it).
func _hurt_offset_y() -> float:
	return 0.0


func _collision_shape() -> Shape3D:
	var b := BoxShape3D.new()
	var s := _hurt_size()
	b.size = Vector3(s.x * 0.8, s.y, 0.8)
	return b


## Pick an attack for the current distance, or {} to keep approaching.
func _choose_attack(distance: float) -> Dictionary:
	for a: Dictionary in data.get("attacks", []):
		if distance <= float(a.get("range_m", 2.0)) and _cooldowns.get(str(a.get("id", "")), 0.0) <= 0.0:
			return a
	return {}


## Called every frame of the telegraph (aim, face, charge).
func _telegraph_tick(_player: Node3D, _delta: float) -> void:
	pass


## Called every frame of the attack's active window (lunge, beam).
func _attack_tick(_player: Node3D, delta: float) -> void:
	_halt(delta)


## The melee hit rect for an attack, or null for attacks that hit their own way (beam).
func _make_attack_hit(attack: Dictionary) -> ActionHit:
	var reach := float(attack.get("range_m", 2.0))
	return ActionHit.new(0.0, float(attack.get("active_s", 0.2)) + 0.01,
		Vector2(reach * 0.5 + 0.2, 0.9), Vector2(reach, 1.6), _make_packet(attack))


## May a primary hit on a staggered enemy be a Riposte (2x, ends the stagger)? Bosses say no:
## their break is a timed vulnerable window instead.
func _riposte_allowed() -> bool:
	return true


func _can_flinch() -> bool:
	return tier == "common" and state != STATE_ATTACK


func _shield_blocks(_p: DamagePacket, _backstab: bool) -> bool:
	return false


func _shield_fraction() -> float:
	return 0.0


func _move_speed() -> float:
	return float(data.get("move_speed", 3.0)) * status.move_multiplier()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = maxf(velocity.y - _gravity * delta, -30.0)
	elif velocity.y < 0.0:
		velocity.y = 0.0


# --- Shared helpers -------------------------------------------------------------------------

func _target() -> Node3D:
	if world == null or world.player == null or not is_instance_valid(world.player):
		return null
	var pl := world.player
	if not bool(pl.call("is_alive")):
		return null
	return pl


func _player_hidden(player: Node3D) -> bool:
	return player != null and player.has_method("is_hidden") and bool(player.call("is_hidden"))


func _idle_tick(player: Node3D, delta: float) -> void:
	_halt(delta)
	if player == null or _player_hidden(player):
		return
	if absf(player.global_position.x - global_position.x) <= float(data.get("aggro_range_m", 10.0)) \
			and absf(player.global_position.y - global_position.y) <= 6.0:
		_set_aggro(true)
		_enter_state(STATE_APPROACH)


func _approach_tick(player: Node3D, delta: float) -> void:
	if player == null or _player_hidden(player):
		_halt(delta)
		if player == null or state_time > 2.0:
			_set_aggro(false)
			_enter_state(STATE_IDLE)
		return
	var dx := player.global_position.x - global_position.x
	if absf(dx) > float(data.get("leash_range_m", 25.0)):
		_set_aggro(false)
		_enter_state(STATE_IDLE)
		return
	_face_toward(dx, delta)
	var attack := _choose_attack(absf(dx))
	if not attack.is_empty() and int(signf(dx)) == facing:
		_begin_telegraph(attack)
		return
	var gap := absf(dx) - _preferred_range
	var dir := signf(dx) if gap > 0.0 else -signf(dx) * 0.5
	if absf(gap) < 0.3:
		dir = 0.0
	velocity.x = move_toward(velocity.x, dir * _move_speed(), 30.0 * delta)


func _face_toward(dx: float, delta: float) -> void:
	var want := 1 if dx > 0.0 else -1
	if want == facing:
		_turn_timer = 0.0
		return
	_turn_timer += delta
	if _turn_timer >= turn_delay_s:
		facing = want
		_turn_timer = 0.0


func _begin_telegraph(attack: Dictionary) -> void:
	current_attack = attack
	_enter_state(STATE_TELEGRAPH)
	telegraph.show_cue(str(attack.get("kind", "parryable")), float(attack.get("telegraph_s", 0.6)))
	visual.flash(Color(str(Balance.combat("telegraph.%s.color" % str(attack.get("kind", "parryable"))))),
		Balance.combat_f("telegraph.flash_duration_s"))


func _begin_attack() -> void:
	_enter_state(STATE_ATTACK)
	visual.tell(0.0)
	telegraph.hide_cue()
	_attack_hit = _make_attack_hit(current_attack)
	_cooldowns[str(current_attack.get("id", ""))] = float(current_attack.get("cooldown_s", 1.5))


func _end_attack() -> void:
	_attack_hit = null
	telegraph.hide_cue()
	visual.tell(0.0)


func _make_packet(attack: Dictionary) -> DamagePacket:
	var p := DamagePacket.new()
	p.attacker = self
	p.team = team
	p.atk = float(data.get("atk", 10.0)) * damage_scale * buff_multiplier()
	p.motion = float(attack.get("motion", 1.0))
	p.posture = float(attack.get("posture", 10.0))
	p.kind = str(attack.get("kind", DamagePacket.KIND_PARRYABLE))
	p.knockback = float(attack.get("knockback_m", 2.5))
	p.heavy = bool(attack.get("heavy", false))
	p.can_reflect = bool(attack.get("parry_reflects", false))
	p.source_x = global_position.x
	p.tags["attack"] = str(attack.get("id", ""))
	return p


func _on_attack_landed(_target_node: Node3D, _p: DamagePacket) -> void:
	pass


func _enter_state(new_state: String) -> void:
	state = new_state
	state_time = 0.0


func _enter_stagger() -> void:
	_end_attack()
	_enter_state(STATE_STAGGERED)
	Sfx.play("posture_break")
	GameEvents.camera_shake_requested.emit(0.3)


func _flinch(p: DamagePacket) -> void:
	_end_attack()
	_enter_state(STATE_HURT)
	_flinch_left = FLINCH_S
	var away := signf(global_position.x - p.source_x)
	velocity.x = away * maxf(p.knockback, 1.5)


func _halt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 40.0 * delta)


func _set_aggro(on: bool) -> void:
	if aggro == on:
		return
	aggro = on
	GameEvents.enemy_aggro_changed.emit(self, on)


func _die() -> void:
	_end_attack()
	_enter_state(STATE_DEAD)
	_dead_left = DISSOLVE_S
	velocity = Vector3.ZERO
	collision_layer = 0
	_set_aggro(false)
	Sfx.play("enemy_death")
	GameEvents.enemy_died.emit(self)


func _echo_applies(echo: Dictionary) -> bool:
	match str(echo.get("against", "")):
		"frozen":
			return status.has_status("frozen")
		"staggered":
			return posture.is_staggered()
		"poisoned":
			return status.has_status("poisoned")
		"unraveled":
			return status.has_status("unraveled")
	return false
