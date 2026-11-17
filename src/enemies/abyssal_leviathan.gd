class_name AbyssalLeviathan
extends Boss
## The Abyssal Leviathan (addendum boss table; bible boss 3; Narrative 5): the Foundation's jailer
## on the Starless Shore. 12,000 HP, phases at 65 % and 30 %.
## - Twelve eyes (`LeviathanEye`), 300 HP each, hit separately; damage to an eye also wounds the
##   Leviathan. Every 3 eyes destroyed stagger it for 5 s (open at 2x). Body hits deal damage but
##   build no posture: the eyes are how it breaks.
## - Phase 1: tail-whips and lunge bites as it rises from black water.
## - Phase 2: the arena goes dark (a Darkness overlay) with only its eyes lit; it strikes from
##   behind the player ("blindside"), cue still shown.
## - Phase 3: the dark lifts; dimensional rifts fire beams from above and it roars (shockwaves).
## - It dives and surfaces elsewhere along its 40 m shore every `resurface_s`.
## Its fall drops the Pure Soul Matrix, the Abyssal Scale and the Primeval Truth, ends Darius's
## distrust, unlocks Overdrive and tears the rift open. Numbers in abyssal_leviathan.json.

var eyes: Array[LeviathanEye] = []
## The dark of phase 2 (null before it).
var darkness: Darkness

var _destroyed: int = 0
var _home_x: float = 0.0
var _surface_t: float = 0.0


func _init() -> void:
	enemy_id = "abyssal_leviathan"
	turn_delay_s = 0.4


## Where a blindside strike lands: `gap` metres behind a player at `px` facing `pfacing`.
static func blindside_x(px: float, pfacing: int, gap: float) -> float:
	return px - float(pfacing) * gap


func _ready() -> void:
	super._ready()
	_home_x = global_position.x
	var bones: Array = data.get("eye_bones", [])
	for i in range((data.get("eyes", []) as Array).size()):
		var xy: Array = data["eyes"][i]
		var e := LeviathanEye.new()
		e.leviathan = self
		e.offset = Vector2(float(xy[0]), float(xy[1]))
		e.bone_name = str(bones[i]) if i < bones.size() else "head"
		var pxs: Array = data.get("eye_px", [])
		if i < pxs.size():
			e.paint_px = Vector2(float(pxs[i][0]), float(pxs[i][1]))
		e.hp = float(data.get("eye_hp", 300.0))
		add_child(e)
		eyes.append(e)


func _hurt_size() -> Vector2:
	return Vector2(4.0, 3.4)


func eyes_left() -> int:
	var n := 0
	for e in eyes:
		if e.hp > 0.0:
			n += 1
	return n


## Body hits: damage only.
func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	p.posture = 0.0
	return super(p)


## An eye took `p`: the eye loses HP, the Leviathan a share; a third eye gone opens it.
func eye_hit(eye: LeviathanEye, p: DamagePacket) -> DamagePacket.Result:
	if not is_alive() or eye.hp <= 0.0 or in_transition():
		return DamagePacket.Result.IGNORED
	var dmg := CombatMath.damage(p.atk, p.motion, 0.0, p.crit_multiplier if CombatMath.roll_crit(p.crit_chance, rng) else 1.0)
	eye.hp = maxf(eye.hp - dmg, 0.0)
	health.damage(dmg * float(data.get("eye_damage_share", 1.0)))
	GameEvents.hit_fx_requested.emit(eye.global_position, dmg, false, false)
	if eye.hp <= 0.0:
		_destroyed += 1
		eye.burst()
		if _destroyed % int(data.get("eyes_per_stagger", 3)) == 0:
			posture.add(posture.max_value)
			_enter_stagger()
	if health.is_dead():
		_die()
		return DamagePacket.Result.KILLED
	_check_phase()
	return DamagePacket.Result.KILLED if eye.hp <= 0.0 else DamagePacket.Result.HIT


func _check_phase() -> void:
	var before := phase
	super()
	if phase == before:
		return
	var ph: Dictionary = (data.get("phases", []) as Array)[phase]
	if bool(ph.get("dark", false)):
		_bring_dark()
	elif darkness != null:
		darkness.fade(0.0, 1.0)


func _bring_dark() -> void:
	if darkness == null:
		darkness = Darkness.new()
		darkness.name = "LeviathanDark"
		darkness.player = world.player as Player if world != null else null
		darkness.glow_points = _eye_glow
		darkness.amount = 0.0
		get_parent().add_child(darkness)
	darkness.fade(1.0, 1.0)


## Lit points for the dark: every live eye.
func _eye_glow() -> Dictionary:
	var out := {}
	for e in eyes:
		if e.hp > 0.0:
			out[e.global_position] = float(data.get("eye_glow_m", 0.9))
	return out


func _die() -> void:
	super()
	if darkness != null:
		darkness.fade(0.0, 1.5)


func _physics_process(delta: float) -> void:
	super(delta)
	if not is_alive() or in_transition():
		return
	_surface_t += delta
	if _surface_t >= float(data.get("resurface_s", 14.0)) and (state == STATE_APPROACH or state == STATE_IDLE):
		_surface_t = 0.0
		_resurface()


## Dive and come up near the player, inside its stretch of shore.
func _resurface() -> void:
	var player := _target()
	if player == null:
		return
	var half := float(data.get("shore_half_m", 18.0))
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var x := clampf(player.global_position.x + side * float(data.get("resurface_gap_m", 6.0)), _home_x - half, _home_x + half)
	GameEvents.ultimate_fx_requested.emit("splash", global_position + Vector3(0.0, 1.0, 0.0), 2.0)
	global_position.x = x
	reset_physics_interpolation()
	GameEvents.ultimate_fx_requested.emit("splash", global_position + Vector3(0.0, 1.0, 0.0), 2.0)
	Sfx.play("splash")


func _begin_telegraph(attack: Dictionary) -> void:
	if str(attack.get("style", "")) == "blindside":
		var player := _target()
		if player != null:
			var pf := int(player.get("facing")) if player.get("facing") != null else 1
			global_position.x = blindside_x(player.global_position.x, pf, float(attack.get("gap_m", 3.0)))
			facing = 1 if player.global_position.x > global_position.x else -1
			reset_physics_interpolation()
			Sfx.play("splash")
	super(attack)


func _make_attack_hit(attack: Dictionary) -> ActionHit:
	if str(attack.get("style", "")) == "blindside":
		# It may pick a blindside from anywhere (range_m); the bite itself reaches reach_m.
		var reach := float(attack.get("reach_m", 3.0))
		return ActionHit.new(0.0, float(attack.get("active_s", 0.2)) + 0.01,
			Vector2(reach * 0.5 + 0.2, 0.9), Vector2(reach, 1.8), _make_packet(attack))
	return super(attack)


func _riposte_allowed() -> bool:
	return false
