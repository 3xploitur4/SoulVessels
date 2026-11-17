class_name Boss
extends EnemyBase
## Base for every boss (story 034; addendum boss table and "Phase changes"). Adds to EnemyBase:
## - Phases from data: `phases` [{"at": 1.0}, {"at": 0.6, ...}, {"at": 0.25, ...}] by health
##   fraction. Crossing one starts a 1.5 s invulnerable change, stretched by up to 1 s to land on
##   the next 4-bar musical boundary, and emits `phase_changed` and GameEvents.boss_phase_changed.
## - A full posture break: `vulnerable_s` (4 s) open at 2x damage; no Riposte ends it early.
## - Attacks pick by phase (`phases` list on each attack) and by style: "melee" (the base reach
##   hit), "dash" (charges forward while active), "wave" (a ground wave toward the player), "orbs"
##   (magic orbs fanned at the player) or "rain" (orbs falling on the player's position).
##   Attacks may carry an `element` and `buildup` (Ember burns the player).
## - A phase may raise the arena's water: `water_rise_m` over `water_rise_s`.
## - No flinch. Tier "boss": it stays dead (like an elite) and drops its whole list.
##
##     var b := WeepingSovereign.new()
##     b.boundary_source = MusicDirector.seconds_to_boundary

## Emitted when the phase changes (0-based).
signal phase_changed(phase: int)

## Current phase, 0-based.
var phase: int = 0
## Returns the seconds from now to the first music boundary at least `after` s away (-1: none).
var boundary_source: Callable

var _thresholds: Array[float] = []
var _transition_left: float = 0.0
var _started: bool = false


## Phase index for a health `fraction` given the descending phase start fractions after phase 0.
static func phase_for_fraction(fraction: float, thresholds: Array[float]) -> int:
	var p := 0
	for i in range(thresholds.size()):
		if fraction <= thresholds[i] + 0.00001:
			p = i + 1
	return p


## Length of a phase change: `base`, stretched to the boundary `to_boundary` seconds away when
## that is no more than `max_shift` later; never shorter than `base`. -1 means no music.
static func transition_length(base: float, to_boundary: float, max_shift: float) -> float:
	if to_boundary < 0.0:
		return base
	return clampf(to_boundary, base, base + max_shift)


func _ready() -> void:
	super._ready()
	for ph: Dictionary in (data.get("phases", []) as Array).slice(1):
		_thresholds.append(float(ph.get("at", 0.0)))
	posture.stagger_s = float(data.get("vulnerable_s", 4.0))
	if not boundary_source.is_valid():
		boundary_source = func(after: float) -> float: return MusicDirector.seconds_to_boundary(after)


func in_transition() -> bool:
	return _transition_left > 0.0


func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	if not is_alive():
		return DamagePacket.Result.IGNORED
	if in_transition():
		GameEvents.hit_fx_requested.emit(global_position + Vector3(0.0, _hurt_size().y * 0.6, 0.5), 0.0, false, true)
		return DamagePacket.Result.IGNORED
	if posture.is_staggered():
		p.motion *= float(data.get("vulnerable_damage_mult", 2.0))
	var r := super(p)
	_check_phase()
	return r


func _riposte_allowed() -> bool:
	return false


func _can_flinch() -> bool:
	return false


func _set_aggro(on: bool) -> void:
	super(on)
	if on and not _started:
		_started = true
		GameEvents.boss_started.emit(self)


func _check_phase() -> void:
	if not is_alive():
		return
	var want := phase_for_fraction(health.ratio(), _thresholds)
	if want <= phase:
		return
	phase = want
	var base := float(data.get("transition_s", 1.5))
	var to_b := float(boundary_source.call(base)) if boundary_source.is_valid() else -1.0
	_transition_left = transition_length(base, to_b, float(data.get("transition_max_shift_s", 1.0)))
	_end_attack()
	_enter_state(STATE_RECOVER)
	posture.end_stagger()
	visual.flash(Color(1.0, 1.0, 1.0), 0.4)
	GameEvents.camera_shake_requested.emit(0.5)
	Sfx.play("posture_break")
	var ph: Dictionary = (data.get("phases", []) as Array)[phase]
	if float(ph.get("water_rise_m", 0.0)) != 0.0:
		var w := _arena_water()
		if w != null:
			w.rise_to(w.level + float(ph.get("water_rise_m", 0.0)), float(ph.get("water_rise_s", 2.0)))
	if ph.has("tilt"):
		# The arena tilts (the Guardian's elevator, story 044): every slide zone and the camera.
		for n in get_tree().get_nodes_in_group(SlideZone.GROUP):
			(n as SlideZone).tilt_to(float(ph["tilt"]), float(ph.get("tilt_s", 1.5)))
		GameEvents.camera_roll_requested.emit(float(ph["tilt"]) * 0.5, float(ph.get("tilt_s", 1.5)))
	if ph.has("tint") and visual is EnemySpriteVisual:
		# The phase shows on her: phase 3 of the Sovereign burns warm (story 039).
		(visual as EnemySpriteVisual).body.set_tint(Color(str(ph["tint"])))
	phase_changed.emit(phase)
	GameEvents.boss_phase_changed.emit(self, phase)


func _arena_water() -> Water:
	if not is_inside_tree():
		return null
	var best: Water = null
	for n in get_tree().get_nodes_in_group(Water.GROUP):
		var w := n as Water
		if global_position.x >= w.x_range.x - 2.0 and global_position.x <= w.x_range.y + 2.0:
			best = w
	return best


func _physics_process(delta: float) -> void:
	if _transition_left > 0.0:
		_transition_left = maxf(_transition_left - delta, 0.0)
		state_time = 0.0
		velocity.x = 0.0
		visual.animate(STATE_STAGGERED, facing, 0.0, delta)
		_apply_gravity(delta)
		move_and_slide()
		return
	super(delta)


func _die() -> void:
	super()
	GameEvents.boss_defeated.emit(self)


# --- Attacks ---------------------------------------------------------------------------------

func _choose_attack(distance: float) -> Dictionary:
	var options: Array[Dictionary] = []
	for a: Dictionary in data.get("attacks", []):
		var phases: Array = a.get("phases", [0, 1, 2])
		if not (phases.has(phase) or phases.has(float(phase))):
			continue
		if distance > float(a.get("range_m", 2.0)) or _cooldowns.get(str(a.get("id", "")), 0.0) > 0.0:
			continue
		options.append(a)
	if options.is_empty() or _cooldowns.get("_any", 0.0) > 0.0:
		return {}
	return options[rng.randi_range(0, options.size() - 1)]


## The attack with its timings divided by this phase's `speed` (the Guardian's phase 3 is x1.4).
func scaled_attack(attack: Dictionary) -> Dictionary:
	var ph: Dictionary = (data.get("phases", [{}]) as Array)[phase]
	var speed := float(ph.get("speed", 1.0))
	if speed == 1.0:
		return attack
	var a := attack.duplicate()
	for k: String in ["telegraph_s", "active_s", "recover_s", "cooldown_s"]:
		if a.has(k):
			a[k] = float(a[k]) / speed
	return a


func _begin_telegraph(attack: Dictionary) -> void:
	super(scaled_attack(attack))


func _begin_attack() -> void:
	super()
	_cooldowns["_any"] = float(data.get("attack_gap_s", 0.6))
	var style := str(current_attack.get("style", "melee"))
	match style:
		"wave":
			_fire_wave()
		"shockwave":
			# Radial: a wave each way.
			_fire_wave()
			facing = -facing
			_fire_wave()
			facing = -facing
		"beam":
			_fire_beam()
		"orbs":
			_fire_orbs(false)
		"rain":
			_fire_orbs(true)


func _attack_tick(player: Node3D, delta: float) -> void:
	if str(current_attack.get("style", "")) == "dash":
		velocity.x = float(facing) * float(current_attack.get("dash_mps", 14.0))
		return
	super(player, delta)


func _make_attack_hit(attack: Dictionary) -> ActionHit:
	match str(attack.get("style", "melee")):
		"wave", "orbs", "rain", "shockwave", "beam":
			return null
		"dash":
			return ActionHit.new(0.0, float(attack.get("active_s", 0.4)) + 0.01, Vector2(0.6, 0.0),
				Vector2(_hurt_size().x + 0.6, _hurt_size().y), _make_packet(attack))
	return super(attack)


func _make_packet(attack: Dictionary) -> DamagePacket:
	var p := super(attack)
	p.element = str(attack.get("element", "physical"))
	p.element_buildup = float(attack.get("buildup", 0.0))
	return p


func _fire_wave() -> void:
	var speed := float(current_attack.get("speed_mps", 10.0))
	var origin := Vector2(global_position.x + 1.0 * facing, global_position.y + 0.6)
	var proj := Projectile.spawn(get_parent(), world, _make_packet(current_attack), origin,
		Vector2(speed * facing, 0.0), Vector2(1.0, 1.2), VfxShapes.shockwave(_attack_color()))
	proj.target_team = CombatWorld.TEAM_PLAYER
	proj.max_distance = float(current_attack.get("range_m", 14.0))
	proj.lifetime = proj.max_distance / speed + 0.1
	GameEvents.camera_shake_requested.emit(0.3)
	Sfx.play("shockwave")


func _fire_orbs(rain: bool) -> void:
	var player := _target()
	var n := int(current_attack.get("orbs", 3))
	var speed := float(current_attack.get("orb_speed_mps", 9.0))
	var px := player.global_position.x if player != null else global_position.x + 4.0 * facing
	var py := player.global_position.y if player != null else global_position.y
	for i in range(n):
		var t := 0.0 if n <= 1 else float(i) / float(n - 1) - 0.5
		var origin: Vector2
		var v: Vector2
		if rain:
			origin = Vector2(px + t * float(current_attack.get("rain_spread_m", 5.0)), py + 7.0)
			v = Vector2(0.0, -speed)
		else:
			origin = Vector2(global_position.x + 0.8 * facing, global_position.y + _hurt_size().y * 0.7)
			var aim := (Vector2(px, py + 1.0) - origin).normalized()
			v = aim.rotated(t * deg_to_rad(float(current_attack.get("orb_spread_deg", 18.0)))) * speed
		var proj := Projectile.spawn(get_parent(), world, _make_packet(current_attack), origin, v, Vector2(0.5, 0.5),
			VfxShapes.bolt(_attack_color(), 0.24, 1.3))
		proj.target_team = CombatWorld.TEAM_PLAYER
		proj.pierce = false
		proj.max_distance = 18.0
		proj.lifetime = 18.0 / speed + 0.2
	Sfx.play("telegraph_harmonic")


func _attack_color() -> Color:
	if str(current_attack.get("element", "")) == "ember":
		return Color(1.0, 0.45, 0.15)
	if str(current_attack.get("kind", "")) == "magic":
		return Color(0.55, 0.75, 1.0)
	return Color(0.9, 0.85, 0.7)


## A fast, thin magic beam from the chest toward the player (the Guardian's chest laser).
func _fire_beam() -> void:
	var speed := float(current_attack.get("speed_mps", 24.0))
	var y := global_position.y + float(current_attack.get("height_m", 2.6))
	var player := _target()
	var dy := 0.0
	if player != null:
		dy = clampf((player.global_position.y + 1.0) - y, -3.0, 3.0)
	var origin := Vector2(global_position.x + 1.2 * facing, y)
	var v := Vector2(speed * facing, dy / maxf(absf(float(current_attack.get("range_m", 14.0))) / speed, 0.1))
	var proj := Projectile.spawn(get_parent(), world, _make_packet(current_attack), origin, v, Vector2(2.4, 0.45),
		VfxShapes.knife(Color(1.0, 0.45, 0.2)))
	proj.target_team = CombatWorld.TEAM_PLAYER
	proj.max_distance = float(current_attack.get("range_m", 14.0))
	proj.lifetime = proj.max_distance / speed + 0.1
	Sfx.play("beam")
