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
var _h: float = 1.9
var _was_air: bool = false
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
	if state != _last_state:
		_last_state = state
		_struck = false
	var b := body
	b.lean = 0.0
	b.stride = 0.0
	b.crouch = 0.0
	b.stretch = 0.0
	b.roll = 0.0
	b.lift = 0.0
	b.forward = 0.0
	var guard := 0.0
	var air := state == "jump" or state == "fall" or state == "air_dash"
	b.set_grounded(not air)
	if _was_air and not air and state != "dead":
		b.puff()
	_was_air = air
	b.trailing = state in ["dodge", "air_dash", "shadowstep", "oathbreaker_lunge", "severing_arrival", "shadow_counter",
		"dance_of_shadows"]
	if state == "run":
		b.stride = clampf(speed, 0.4, 1.3)
		b.lean = 0.07 * _h
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
	elif state.begins_with("primary"):
		var idx := int(state.get_slice("_", 1))
		if progress < STRIKE_AT:
			b.lean = -0.07 * _h
			b.crouch = 0.35
		else:
			var out := clampf((progress - STRIKE_AT) / 0.25, 0.0, 1.0)
			b.lean = 0.16 * _h * (1.0 - out * 0.5)
			b.forward = 0.28 * (1.0 - out)
			if not _struck:
				_struck = true
				_strike(idx)
	elif state in ["counterstrike", "oathbreaker_lunge", "severing_arrival", "shadow_counter", "kings_judgment",
			"phantom_blades"]:
		b.lean = 0.2 * _h
		b.forward = 0.2
		if progress >= 0.2 and not _struck:
			_struck = true
			_arc.play(_slash_color, _reach * 1.25, 95.0, -55.0, 0.2)
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
		var t := clampf(progress / 0.75, 0.0, 1.0)
		b.roll = -TAU * t
		b.crouch = 0.6
		b.lift = 0.15 * sin(t * PI)
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
	if b is RigBody:
		(b as RigBody).play(clip_for_rig(state, (b as RigBody).clips), progress)
	_guard_mat.albedo_color.a = lerpf(_guard_mat.albedo_color.a, 0.75 * guard, minf(delta * 20.0, 1.0))
	_guard.visible = _guard_mat.albedo_color.a > 0.02
	b.tick(delta)
	_tick_orbit(delta)


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
	return _clip_for(state)


## The rig clip (story 029) for a player state.
static func _clip_for(state: String) -> String:
	if state.begins_with("primary"):
		return "attack_%d" % (int(state.get_slice("_", 1)) % 4)
	match state:
		"run", "jump", "fall", "wall_slide", "block", "dodge", "hurt", "rooted", "dead":
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


## The weapon arc for combo hit `idx`: swings alternate down and up; the last is the widest.
func _strike(idx: int) -> void:
	if _dagger_user:
		var up := idx % 2 == 0
		_arc.play(_slash_color, _reach * (1.3 if idx >= 5 else 0.95), 55.0 if up else -55.0, -35.0 if up else 35.0, 0.11)
		return
	match idx % 4:
		0:
			_arc.play(_slash_color, _reach, 80.0, -40.0, 0.15)
		1:
			_arc.play(_slash_color, _reach, -60.0, 45.0, 0.15)
		2:
			_arc.play(_slash_color, _reach * 1.1, 95.0, -55.0, 0.17)
		_:
			_arc.play(_slash_color, _reach * 1.35, 120.0, -70.0, 0.22)


func set_hidden_look(hidden_on: bool) -> void:
	body.ghost = 1.0 if hidden_on else 0.0


## Soul core brightness (1 = idle, about 2.5 with a full gauge): a little extra self-light.
func set_glow(energy: float) -> void:
	body.glow = clampf((energy - 1.0) * 0.12, 0.0, 0.3)
