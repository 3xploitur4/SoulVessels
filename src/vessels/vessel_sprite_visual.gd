class_name VesselSpriteVisual
extends VesselVisual
## A Vessel drawn from its concept painting (story 027, decision D-032): a `SpriteBody` posed by
## state (run, jump, attacks, block, dodge, hurt) plus a weapon arc of light on every strike and a
## guard glow while blocking. Same interface as the placeholder `VesselVisual`, so the player
## never knows which one it holds.
##
##     var vis := VesselVisual.build(Balance.vessel("caelan"))   # picks this when art exists

## When in an action the weapon arc fires (share of the action's length).
const STRIKE_AT := 0.28
## Depth offset toward the camera so the player draws in front of enemies on the same plane.
const Z_FRONT := 0.14

var body: SpriteBody

var _arc: SlashArc
var _guard: MeshInstance3D
var _guard_mat: StandardMaterial3D
var _last_state: String = ""
var _struck: bool = false
var _slash_color: Color = Color.WHITE
var _reach: float = 2.0
var _dagger_user: bool = false
## Story 055: a caster's primary is a bolt with its own sound, not a blade.
var _blade: bool = true
var _h: float = 1.9
var _was_air: bool = false
## Story 054 (D-062): ground dust. Time in the air (a longer fall lands harder), time to the next
## footstep puff and wall scrape, and last frame's facing (a turn while running skids).
var _air_t: float = 0.0
var _step_left: float = 0.0
var _scrape_left: float = 0.0
var _last_facing: int = 0
var _last_progress: float = 0.0
## Story 054 (D-063): weight. Seconds left of the crouch after a landing and of the lean back
## against the old momentum after a turn, and how deep that landing was.
var _land_left: float = 0.0
var _land_depth: float = 0.0
var _turn_left: float = 0.0
## Seconds to the next puff of dust under a dodge step.
var _skid_left: float = 0.0
const LAND_HOLD_S := 0.14
const TURN_LEAN_S := 0.12
## Story 055: footsteps sit well under the rest of the mix.
const STEP_DB := -9.0
## Moves that slam the ground: a burst of dust and grit when they land.
const SLAMS := ["crushing_blow", "groundbreaker", "meteor_drop", "worldbreaker_override"]
## Story 053: shards orbiting a point on a part (Seris's Floating Focus); see `weapon.look.orbit`.
var _orbit: Array[MeshInstance3D] = []
var _orbit_part: String = ""
var _orbit_px: Vector2 = Vector2.ZERO
var _orbit_t: float = 0.0


static func build_sprite(vessel_data: Dictionary) -> VesselSpriteVisual:
	var v := VesselSpriteVisual.new()
	var id := str(vessel_data.get("id", ""))
	v.name = "Vessel_%s" % id
	v.body = SpriteBody.create(id)
	v.add_child(v.body)
	v._h = v.body.height_m
	var slash: Dictionary = v.body.spec.get("slash", {})
	v._slash_color = Color(str(slash.get("color", "#ffffff")))
	v.body.trail_color = v._slash_color
	v._reach = float(slash.get("reach_m", 2.0))
	v._dagger_user = (vessel_data.get("primary", {}).get("hits", []) as Array).size() >= 6
	v._blade = str((vessel_data.get("primary", {}) as Dictionary).get("kind", "")) != "bolt"
	v._arc = SlashArc.new()
	v._arc.position = Vector3(0.25, v._h * 0.55, 0.3)
	v.add_child(v._arc)
	# Guard glow: a tall soft bar of gold light in front of the body while blocking.
	v._guard = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.9, v._h * 1.05)
	v._guard.mesh = q
	v._guard_mat = StandardMaterial3D.new()
	v._guard_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	v._guard_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	v._guard_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	v._guard_mat.albedo_texture = SpriteArt.blob()
	v._guard_mat.albedo_color = Color(1.0, 0.82, 0.4, 0.0)
	v._guard_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	v._guard.material_override = v._guard_mat
	v._guard.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	v._guard.position = Vector3(0.55, v._h * 0.5, 0.25)
	v.add_child(v._guard)
	# Story 053: a second weapon's look (weapons.json "weapon.look").
	var look: Dictionary = (vessel_data.get("weapon", {}) as Dictionary).get("look", {})
	if not look.is_empty() and v.body is RigBody:
		(v.body as RigBody).apply_look(look)
		if look.has("slash"):
			v._slash_color = Color(str(look["slash"]))
			v.body.trail_color = v._slash_color
		var orbit: Dictionary = look.get("orbit", {})
		if not orbit.is_empty():
			v._build_orbit(orbit)
	return v


func _build_orbit(orbit: Dictionary) -> void:
	_orbit_part = str(orbit.get("part", ""))
	var px: Array = orbit.get("px", [0, 0])
	_orbit_px = Vector2(float(px[0]), float(px[1]))
	var c := Color(str(orbit.get("color", "#a8e6ff")))
	for i in range(int(orbit.get("count", 4))):
		# A thin crystal shard with a soft glow around it.
		var m := MeshInstance3D.new()
		var p := PrismMesh.new()
		p.size = Vector3(0.05, 0.18, 0.03)
		m.mesh = p
		m.material_override = ArenaMaterials.flat(c.lerp(Color.WHITE, 0.3), 1.6, true)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var halo := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.32, 0.32)
		halo.mesh = q
		var hm := StandardMaterial3D.new()
		hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hm.albedo_texture = SpriteArt.blob()
		hm.albedo_color = Color(c.r, c.g, c.b, 0.55)
		halo.material_override = hm
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.add_child(halo)
		add_child(m)
		_orbit.append(m)


## Shards circle the hand point, riding the arm as it moves.
func _tick_orbit(delta: float) -> void:
	if _orbit.is_empty() or not body is RigBody:
		return
	_orbit_t += delta
	var b: Node3D = (body as RigBody).bone(_orbit_part)
	if b == null:
		return
	var centre: Vector3 = b.to_global((body as RigBody).part_point(_orbit_part, _orbit_px))
	for i in range(_orbit.size()):
		var a := _orbit_t * 2.4 + TAU * float(i) / float(_orbit.size())
		_orbit[i].global_position = centre + Vector3(cos(a) * 0.22, sin(a) * 0.12 + 0.05, sin(a) * 0.15)
		_orbit[i].rotation.z = a


func pose(state: String, progress: float, facing: int, speed: float, delta: float) -> void:
	rotation.y = 0.0 if facing > 0 else PI
	# Rotating the visual flips its local z, so keep the sprite on the camera side by hand.
	body.position.z = Z_FRONT * float(facing)
	_arc.position.z = 0.3 * float(facing)
	_guard.position.z = 0.25 * float(facing)
	var prev := _last_state
	# A move started again under the same name (spamming the rising cut) is a new swing too: its
	# progress jumps back to the start (story 060).
	var restarted := state == _last_state and progress + 0.25 < _last_progress
	if state != _last_state or restarted:
		_last_state = state
		_struck = false
	_last_progress = progress
	var b := body
	b.lean = 0.0
	b.stride = 0.0
	b.crouch = 0.0
	b.stretch = 0.0
	b.roll = 0.0
	b.lift = 0.0
	b.forward = 0.0
	var guard := 0.0
	var air := _airborne(state)
	_ground_dust(state, prev, air, facing, speed, delta)
	_was_air = air
	b.trailing = state in ["dodge", "air_dash", "shadowstep", "oathbreaker_lunge", "severing_arrival", "shadow_counter",
		"dance_of_shadows", "slash_dash"]
	if state == "run":
		b.stride = clampf(speed, 0.4, 1.3)
		b.lean = 0.07 * _h
	elif state == "walk":
		# Story 060: the slow walk.
		b.stride = clampf(speed * 2.0, 0.4, 0.9)
		b.lean = 0.02 * _h
	elif state == "crouch" or state == "crouch_walk":
		b.stride = clampf(speed * 3.0, 0.5, 1.0) if state == "crouch_walk" else 0.0
	elif state == "jump":
		b.stretch = -0.25
		b.lean = 0.04 * _h
	elif state == "rooted":
		# Caught in the roots: hunched, shaking against them.
		b.crouch = 0.55
		b.lean = sin(Time.get_ticks_msec() * 0.03) * 0.03 * _h
		b.glow = 0.0
	elif state == "wall_slide":
		# Braced against the wall: leaning back into it, knees bent.
		b.lean = -0.06 * _h
		b.crouch = 0.35
	elif state == "fall":
		b.crouch = -0.3
		b.lean = -0.03 * _h
	elif state.begins_with("primary") or state.begins_with("slash_"):
		var idx := int(state.get_slice("_", 1)) if state.begins_with("primary") else -1
		var move := state.substr(6) if idx < 0 else ""
		if progress < STRIKE_AT:
			b.lean = -0.07 * _h
			b.crouch = 0.35 if not move.begins_with("air") else 0.05
		else:
			var out := clampf((progress - STRIKE_AT) / 0.25, 0.0, 1.0)
			b.lean = 0.16 * _h * (1.0 - out * 0.5)
			b.forward = 0.28 * (1.0 - out)
			if move == "dash":
				b.forward = 0.45 * (1.0 - out)
				b.stretch = 0.4 * (1.0 - out)
			elif move == "up":
				b.lean = -0.04 * _h
				b.lift = 0.12 * (1.0 - out)
			if not _struck:
				_struck = true
				_strike(idx, move)
		# The finisher spins: the body turns away and back while the wide arc goes round.
		# (Drawn frames carry their own turn, story 058.)
		var drawn := b is RigBody and (b as RigBody).has_frames(clip_for_rig(state, (b as RigBody).clips))
		if _is_spin(idx) and not drawn and progress > STRIKE_AT + 0.02 and progress < STRIKE_AT + 0.16:
			rotation.y += PI
			body.position.z = -body.position.z
	elif state in ["counterstrike", "oathbreaker_lunge", "severing_arrival", "shadow_counter", "kings_judgment",
			"phantom_blades"]:
		b.lean = 0.2 * _h
		b.forward = 0.2
		if progress >= 0.2 and not _struck:
			_struck = true
			_arc.play(_slash_color, _reach * 1.25, 95.0, -55.0, 0.2)
			Sfx.play("slash_heavy", randf_range(0.9, 1.0))
	elif state == "final_stand" or state == "ultimate" or state == "dance_of_shadows":
		b.crouch = -0.25
		b.lean = 0.05 * _h
		if state == "dance_of_shadows" and fmod(progress * 12.0, 1.0) < 0.3 and progress < 0.98:
			_arc.play(_slash_color, _reach, 80.0 * (1.0 if int(progress * 12.0) % 2 == 0 else -1.0), 0.0, 0.1)
	elif state == "block" or state == "sync_guard":
		b.crouch = 0.4
		b.lean = -0.03 * _h
		guard = 1.0
	elif state == "dodge":
		# Story 055 (D-066): a fast low step, after Blasphemous, not a roll. The body drops into a
		# sliding lunge (the rig's "dodge" clip) and leans into the move; dust skids under it.
		var t := clampf(progress, 0.0, 1.0)
		b.lean = 0.1 * _h * sin(minf(t * 1.6, 1.0) * PI * 0.5) * (1.0 - t * 0.6)
		b.stretch = 0.35 * (1.0 - absf(t - 0.25) * 2.0) if t < 0.75 else 0.0
		_skid_left -= get_process_delta_time()
		if _skid_left <= 0.0 and t < 0.7 and not _was_air:
			_skid_left = 0.06
			DustFx.spawn(self, "step", global_position, -float(facing), 0.8)
	elif state == "air_dash" or state == "shadowstep":
		b.stretch = 1.0
		b.lean = 0.2 * _h
	elif state == "hurt" or state == "guard_break":
		b.lean = -0.14 * _h
		b.crouch = 0.3
		if not _struck:
			_struck = true
			b.flash(Color(1.0, 0.35, 0.3), 0.22)
	elif state == "flask":
		b.lean = -0.04 * _h
		if not _struck:
			_struck = true
			b.flash(Color(0.5, 0.95, 1.0), 0.6)
	elif state in SLAMS and progress >= 0.4 and not _struck:
		_struck = true
		DustFx.spawn(self, "slam", global_position, float(facing), 1.2)
	# Weight: a landing is taken in the knees for a beat; a turn leans back against the momentum.
	if _land_left > 0.0:
		_land_left = maxf(_land_left - delta, 0.0)
		if state in ["idle", "run"]:
			b.crouch = maxf(b.crouch, _land_depth * _land_left / LAND_HOLD_S)
	if _turn_left > 0.0:
		_turn_left = maxf(_turn_left - delta, 0.0)
		if state == "run":
			b.lean = -0.06 * _h * _turn_left / TURN_LEAN_S
	if b is RigBody:
		(b as RigBody).play(clip_for_rig(state, (b as RigBody).clips), progress)
	_guard_mat.albedo_color.a = lerpf(_guard_mat.albedo_color.a, 0.75 * guard, minf(delta * 20.0, 1.0))
	_guard.visible = _guard_mat.albedo_color.a > 0.02
	b.tick(delta)
	_tick_orbit(delta)


## Dust off the ground (story 054): a landing (harder after a longer fall), a take-off, a push off
## the wall, footsteps while running, a skid on a turn or a dodge, and grit scraped off a wall.
func _ground_dust(state: String, prev: String, air: bool, facing: int, speed: float, delta: float) -> void:
	var feet := global_position
	var f := float(facing)
	if _was_air and not air and state not in ["dead", "swim", "wall_slide"]:
		var hard := clampf(0.7 + _air_t * 0.6, 0.7, 1.6)
		body.puff(hard)
		Sfx.play("land", randf_range(0.92, 1.05), linear_to_db(clampf(hard / 1.3, 0.45, 1.0)))
		_land_left = LAND_HOLD_S
		_land_depth = clampf(0.25 + (hard - 0.7) * 0.45, 0.25, 0.65)
	_air_t = _air_t + delta if air else 0.0
	if state != prev:
		match state:
			"jump":
				if prev == "wall_slide":
					DustFx.spawn(self, "wall", feet + Vector3(-f * 0.4, 0.4, 0.0), -f, 1.4)
				elif not _was_air:
					DustFx.spawn(self, "jump", feet)
					if body is RigBody:
						(body as RigBody).push_off()
			"dodge":
				Sfx.play("dodge", randf_range(0.95, 1.08))
				if not _was_air:
					DustFx.spawn(self, "skid", feet, -f)
	if state == "run" or state == "walk" or state == "crouch_walk":
		var soft := state != "run"
		if not soft and _last_facing != 0 and facing != _last_facing:
			# Turning: the dust carries on the old way and the body leans back against it.
			DustFx.spawn(self, "skid", feet, -f, 0.8)
			_turn_left = TURN_LEAN_S
		_step_left -= delta
		if _step_left <= 0.0:
			# A walk steps slower and softer than a run.
			_step_left = DustFx.step_interval(speed) * (2.0 if soft else 1.0)
			DustFx.spawn(self, "step", feet - Vector3(f * 0.2, 0.0, 0.0), -f, 0.6 if soft else 1.0)
			Sfx.play("step", randf_range(0.85, 1.15), STEP_DB - (5.0 if soft else 0.0))
	else:
		_step_left = 0.06
	if state == "wall_slide":
		_scrape_left -= delta
		if _scrape_left <= 0.0:
			_scrape_left = 0.12
			DustFx.spawn(self, "wall", feet + Vector3(f * 0.35, 0.5, 0.0), -f)
	else:
		_scrape_left = 0.0
	_last_facing = facing


## Is the body off the ground? Asked of the player's body when there is one (an attack in the
## air is not a landing, story 057); else read from the state.
func _airborne(state: String) -> bool:
	var p := get_parent()
	if p is CharacterBody3D and p.is_inside_tree():
		return not (p as CharacterBody3D).is_on_floor() and state != "swim" and state != "dead"
	return state == "jump" or state == "fall" or state == "air_dash" or state.begins_with("slash_air")


## The clip for `state` on a rig that has `clips`: a Vessel's own clip when it has one (Seris
## casts her bolts with "bolt", plants Frost Binding with "frost", swims with "swim"; story 039),
## else the shared clip from `_clip_for`.
static func clip_for_rig(state: String, clips: Dictionary) -> String:
	# Story 051: a Vessel's own clip named after the action (Darius's "crushing_blow", Ilyr's
	# "fracture", a hammer's "primary_2") comes first.
	if clips.has(state):
		return state
	var own := ""
	if state.begins_with("primary"):
		own = "bolt"
	match state:
		"frost_binding":
			own = "frost"
		"aether_burst", "cataclysm_fused":
			own = "cast"
		"swim":
			own = "swim"
	if own != "" and clips.has(own):
		return own
	if state == "swim":
		return "fall"
	# Story 060: a rig without the walk or crouch clips borrows the nearest it has.
	if state == "walk" and not clips.has("walk"):
		return "run"
	if state == "crouch_walk" and not clips.has("crouch_walk"):
		return "crouch" if clips.has("crouch") else "idle"
	return _clip_for(state)


## The rig clip (story 029) for a player state.
static func _clip_for(state: String) -> String:
	if state.begins_with("primary"):
		return "attack_%d" % (int(state.get_slice("_", 1)) % 4)
	# Story 057: the combo moves.
	if state.begins_with("slash_air"):
		return "attack_air_%d" % (int(state.get_slice("_", 2)) % 2)
	if state == "slash_dash" or state == "slash_up":
		return "attack_" + state.substr(6)
	match state:
		"run", "jump", "fall", "wall_slide", "block", "dodge", "hurt", "rooted", "dead", "walk", "crouch", "crouch_walk":
			return state
		"sync_guard":
			return "block"
		"guard_break":
			return "hurt"
		"air_dash", "shadowstep", "shoulder_charge":
			return "dash"
		"crushing_blow", "groundbreaker", "meteor_drop":
			return "lunge"
		"worldbreaker_override":
			return "cast"
		"counterstrike", "oathbreaker_lunge", "severing_arrival", "shadow_counter", "kings_judgment", "phantom_blades":
			return "lunge"
		"final_stand", "ultimate", "dance_of_shadows":
			return "cast"
	return "idle"


## The swing for combo hit `idx` (or combo move `move`: "air_0", "air_1", "dash", "up"), story
## 057 (D-068): horizontal cuts drawn as flat arcs passing in front of the body, a backhand going
## the other way, a rising diagonal, and a spinning finisher whose arc goes all the way round. On
## the ground the front foot scuffs dust forward; the finisher throws grit.
func _strike(idx: int, move: String = "") -> void:
	var last := _is_spin(idx)
	if _blade:
		Sfx.play("slash_heavy" if last or move == "dash" else "slash", randf_range(0.92, 1.08) * (1.15 if _dagger_user else 1.0))
	if not _was_air:
		var fwd := 1.0 if rotation.y == 0.0 else -1.0
		DustFx.spawn(self, "slam" if last else ("skid" if move == "dash" else "scuff"),
			global_position + Vector3(fwd * 0.35, 0.0, 0.0), fwd if move != "dash" else -fwd, 0.7 if last else 1.0)
	_arc.position.y = _h * (0.8 if move == "up" else 0.55)
	var a: Array = swing(idx, move, _dagger_user)
	_arc.play(_slash_color, _reach * float(a[0]), float(a[1]), float(a[2]), float(a[3]), float(a[4]), float(a[5]))


## The arc of a swing: [reach share, from degrees, to degrees, seconds, flatness, tilt degrees].
static func swing(idx: int, move: String, daggers: bool) -> Array:
	match move:
		"air_0":
			return [1.0, 160.0, -30.0, 0.15, 0.32, -10.0]
		"air_1":
			return [1.1, 200.0, -60.0, 0.17, 0.42, -22.0]
		"dash":
			return [1.3, 130.0, -10.0, 0.16, 0.18, -3.0]
		"up":
			return [1.0, -70.0, 140.0, 0.17, 1.0, 0.0]
	if daggers:
		if idx >= 5:
			return [1.3, 200.0, -200.0, 0.24, 0.28, 0.0]
		return [0.95, 150.0, -20.0, 0.11, 0.3, -6.0] if idx % 2 == 0 else [0.95, -20.0, 150.0, 0.11, 0.3, 8.0]
	match idx % 4:
		0:
			return [1.0, 165.0, -25.0, 0.15, 0.3, -4.0]
		1:
			return [1.0, -15.0, 170.0, 0.15, 0.3, 6.0]
		2:
			return [1.1, -150.0, 70.0, 0.17, 0.55, 30.0]
	return [1.35, 200.0, -200.0, 0.26, 0.28, 0.0]


## Is combo hit `idx` the spinning finisher?
func _is_spin(idx: int) -> bool:
	if idx < 0:
		return false
	return idx >= 5 if _dagger_user else idx % 4 == 3


func set_hidden_look(hidden_on: bool) -> void:
	body.ghost = 1.0 if hidden_on else 0.0


## Soul core brightness (1 = idle, about 2.5 with a full gauge): a little extra self-light.
func set_glow(energy: float) -> void:
	body.glow = clampf((energy - 1.0) * 0.12, 0.0, 0.3)
