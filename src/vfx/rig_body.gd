class_name RigBody
extends SpriteBody
## A painted character cut into parts and moved by bones (story 029, decision D-034): the
## concept painting is split by `tools/art/cut_rig.gd` into pieces (head, arms, sword, legs,
## cape...), and each piece hangs from its parent at a joint. Animation clips in
## `data/art/rigs/<id>.json` turn the joints; the body blends from one clip to the next.
##
## Everything `SpriteBody` does still works (lean, crouch, roll, flash, dissolve, stealth,
## afterimages, dust, tell glow), so the visuals that pose a `SpriteBody` pose this the same
## way and add `play(clip, progress)` on top.
##
##     var body := SpriteBody.create("caelan")     # a RigBody when a rig exists
##     (body as RigBody).play("attack_0", 0.3)
##     body.tick(delta)

## How fast joints blend toward a new clip (per second); higher is snappier.
const BLEND_RATE := 18.0
## Depth step between parts so the draw order holds (metres toward the camera).
const PART_Z := 0.004
## Landing and turning squash spring (see `kick`).
const KICK_SPEED := 26.0
const KICK_STIFFNESS := 260.0
const KICK_DAMPING := 18.0
## Shader values copied from the hidden whole-body material to every part each frame.
const SHARED := ["flash", "flash_color", "dissolve", "ghost", "glow", "tint"]

var rig: Dictionary = {}
var clips: Dictionary = {}
## Name of the clip playing and, for one-shot clips, how far through it is (0..1).
var clip: String = "idle"
var clip_t: float = 0.0

var _bones: Dictionary[String, Node3D] = {}
## Part id -> its pivot in painting pixels (for `part_point`).
var _pivots: Dictionary[String, Vector2] = {}
var _lean_bone: String = ""
var _lean_scale: float = 1.0
var _angle: Dictionary[String, float] = {}
var _mats: Array[ShaderMaterial] = []
var _root: Node3D
var _loop_t: float = 0.0
var _px: float = 0.0
var _squash: float = 0.0
## A short squash on top of the clip's (landing, turning round), decaying on its own.
var _kick: float = 0.0
var _kick_vel: float = 0.0
var _facing_sign: float = 0.0
## Bone -> the clip channel it follows, and a scale on that channel (see `alias` in the data).
var _channel: Dictionary[String, String] = {}
var _channel_scale: Dictionary[String, float] = {}
## Squash amounts per event from the rig data ("land", "turn").
var _kicks: Dictionary = {}
## Secondary motion (capes, tails): bone -> settings from the rig data, and spring state.
var _secondary: Dictionary = {}
var _sec_angle: Dictionary[String, float] = {}
var _sec_vel: Dictionary[String, float] = {}
var _last_pos: Vector3 = Vector3.INF


## True when `id` has a cut rig and clips (its own, or the one named by `rig` in sprites.json).
static func has_rig(id: String) -> bool:
	var r := rig_id(id)
	return FileAccess.file_exists("res://assets/art/rigs/%s/rig.json" % r) \
		and FileAccess.file_exists("res://data/art/rigs/%s.json" % r)


## The rig a sprite uses: its own id unless its sprites.json entry borrows another painting's
## rig (the Fungal Stalker uses the Calcified Husk's).
static func rig_id(id: String) -> String:
	return str(SpriteArt.spec(id).get("rig", id))


## A rig's data with borrowed clips merged in: `clips_from` names another rig whose clips this
## one starts from; its own `clips` replace any of the same name.
static func load_def(id: String) -> Dictionary:
	var def: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/art/rigs/%s.json" % id))
	var merged: Dictionary = {}
	var base := str(def.get("clips_from", ""))
	if base != "" and base != id:
		merged = (load_def(base).get("clips", {}) as Dictionary).duplicate(true)
	merged.merge(def.get("clips", {}), true)
	def["clips"] = merged
	return def


## Play `name` (a clip in the rig's data). For one-shot clips `progress` is how far through it
## is; looping clips ignore it and run on their own clock.
func play(name: String, progress: float = 0.0) -> void:
	if not clips.has(name):
		name = "idle"
	if name != clip:
		_loop_t = 0.0
	clip = name
	clip_t = clampf(progress, 0.0, 1.0)


## The pose of clip `name` at `t` (0..1): joint name -> degrees, plus "root_y" in metres.
func sample(name: String, t: float) -> Dictionary:
	var c: Dictionary = clips.get(name, {})
	var keys: Array = c.get("keys", [])
	var out: Dictionary = {}
	if keys.is_empty():
		return out
	var prev: Array = keys[0]
	var next: Array = keys[keys.size() - 1]
	for i in range(keys.size() - 1):
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if t >= float(a[0]) and t <= float(b[0]):
			prev = a
			next = b
			break
	var span := maxf(float(next[0]) - float(prev[0]), 0.0001)
	var k := ease_key(clampf((t - float(prev[0])) / span, 0.0, 1.0), str(next[2]) if next.size() > 2 else "")
	var pa: Dictionary = prev[1]
	var pb: Dictionary = next[1]
	for j: String in pa.keys():
		out[j] = lerpf(float(pa[j]), float(pb.get(j, 0.0)), k)
	for j: String in pb.keys():
		if not out.has(j):
			out[j] = lerpf(0.0, float(pb[j]), k)
	return out


## Easing into a key: "in" accelerates into it (a strike landing), "out" decelerates into it (a
## wind-up settling, an overshoot), "linear" is even; anything else eases both ends.
static func ease_key(k: float, mode: String) -> float:
	match mode:
		"in":
			return k * k * k
		"out":
			return 1.0 - pow(1.0 - k, 3.0)
		"linear":
			return k
	return smoothstep(0.0, 1.0, k)


## Jump straight to clip `name` at `t` with no blending (previews, tests).
func pose_now(name: String, t: float) -> void:
	play(name, t)
	_loop_t = t
	var pose := sample(name, t)
	for j: String in _bones.keys():
		_angle[j] = _pose_angle(pose, j)
		_bones[j].rotation.z = deg_to_rad(_angle[j])
	_root.position.y = float(pose.get("root_y", 0.0))
	_squash = float(pose.get("squash", 0.0))
	_apply_squash()


## Current angle of joint `bone` in degrees (for tests and debugging).
## The node of part `name` (null when the rig has none); things that ride a part follow it (story 045).
func bone(name: String) -> Node3D:
	return _bones.get(name, null)


## Where the painting's pixel `px` lies in part `name`'s own space (a point that rides the part,
## like the Leviathan's eyes; story 045). Zero when the part is unknown.
func part_point(name: String, px: Vector2) -> Vector3:
	if not _pivots.has(name):
		return Vector3.ZERO
	var pv := _pivots[name]
	return Vector3((px.x - pv.x) * _px, (pv.y - px.y) * _px, 0.3)


func joint_deg(bone: String) -> float:
	return _angle.get(bone, 0.0)


func _build(id: String) -> void:
	super._build(id)
	# The whole painting stays as the afterimage source but is not drawn.
	_mesh.visible = false
	var rid := rig_id(id)
	rig = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/rigs/%s/rig.json" % rid))
	var def := load_def(rid)
	clips = def.get("clips", {})
	# A part may follow another clip channel, scaled: {"foot_l": ["leg_l_thigh", 0.3]} or
	# {"dagger": "sword"}, so a rig can borrow clips made for different part names.
	var alias: Dictionary = def.get("alias", {})
	for b: String in alias.keys():
		var a: Variant = alias[b]
		if a is Array:
			_channel[b] = str(a[0])
			_channel_scale[b] = float(a[1])
		else:
			_channel[b] = str(a)
	var size: Array = rig["image_size"]
	var img_w := float(size[0])
	var img_h := float(size[1])
	_px = height_m / img_h
	_root = Node3D.new()
	_root.name = "Rig"
	_root.scale.x = float(spec.get("faces", 1))
	_pivot.add_child(_root)
	var parts: Array = rig["parts"]
	var by_id: Dictionary = {}
	for p: Dictionary in parts:
		by_id[str(p["id"])] = p
	# Bones first, parents before children (the list itself is in draw order, not tree order).
	var placed := 0
	while placed < parts.size():
		var before := placed
		for p: Dictionary in parts:
			var pid := str(p["id"])
			var parent_id := str(p["parent"])
			if _bones.has(pid) or (parent_id != "" and not _bones.has(parent_id)):
				continue
			var pv: Array = p["pivot"]
			var parent: Node3D = _root
			var origin := Vector2(img_w * 0.5, img_h * 0.5)
			if parent_id != "":
				parent = _bones[parent_id]
				var ppv: Array = (by_id[parent_id] as Dictionary)["pivot"]
				origin = Vector2(float(ppv[0]), float(ppv[1]))
			var bone := Node3D.new()
			bone.name = pid
			bone.position = Vector3((float(pv[0]) - origin.x) * _px, (origin.y - float(pv[1])) * _px, 0.0)
			parent.add_child(bone)
			_bones[pid] = bone
			_pivots[pid] = Vector2(float(pv[0]), float(pv[1]))
			_angle[pid] = 0.0
			placed += 1
		if placed == before:
			push_error("RigBody: %s has a part whose parent is missing" % id)
			break
	# Then the pictures, each a hair nearer the camera than the one before it in the list.
	for i in range(parts.size()):
		var p: Dictionary = parts[i]
		var pid := str(p["id"])
		if str(p["file"]) == "" or not _bones.has(pid):
			continue
		var pv: Array = p["pivot"]
		var off: Array = p["offset"]
		var sz: Array = p["size"]
		var q := QuadMesh.new()
		q.size = Vector2(float(sz[0]) * _px, float(sz[1]) * _px)
		var m := MeshInstance3D.new()
		m.name = "Pic"
		m.mesh = q
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var cx := float(off[0]) + float(sz[0]) * 0.5
		var cy := float(off[1]) + float(sz[1]) * 0.5
		m.position = Vector3((cx - float(pv[0])) * _px, (float(pv[1]) - cy) * _px, PART_Z * (i + 1))
		var mat := ShaderMaterial.new()
		mat.shader = SpriteArt.shader()
		mat.set_shader_parameter("tex", TexBank.get_tex(str(p["file"])))
		mat.set_shader_parameter("height_m", height_m)
		mat.set_shader_parameter("emission_amount", float(spec.get("emission", SpriteArt.num("emission", 0.62))))
		mat.set_shader_parameter("step_amount", 0.0)
		mat.set_shader_parameter("lean", 0.0)
		mat.set_shader_parameter("wind", 0.0)
		if spec.has("tint"):
			mat.set_shader_parameter("tint", Color(str(spec["tint"])))
		m.material_override = mat
		_bones[pid].add_child(m)
		_mats.append(mat)
	_lean_bone = str(def.get("lean_bone", ""))
	_lean_scale = float(def.get("lean_scale", 1.0))
	_secondary = def.get("secondary", {})
	_kicks = def.get("kicks", {})
	for j: String in _secondary.keys():
		_sec_angle[j] = 0.0
		_sec_vel[j] = 0.0


func tick(delta: float) -> void:
	super.tick(delta)
	var c: Dictionary = clips.get(clip, {})
	var t := clip_t
	if bool(c.get("loop", false)):
		var rate := 1.0 / maxf(float(c.get("length_s", 1.0)), 0.05)
		if c.has("stride_scaled"):
			rate *= maxf(stride, 0.4)
		_loop_t = fmod(_loop_t + delta * rate, 1.0)
		t = _loop_t
	# Facing left turns the visual half a circle, which would reverse the parts' depth order;
	# mirror the depth back so the front-most part stays nearest the camera.
	_root.scale.z = -1.0 if _pivot.global_basis.z.z < 0.0 else 1.0
	var pose := sample(clip, t)
	# Attacks blend fast so the snap of the blow survives; idle poses drift in softly.
	var k := minf(delta * float(c.get("blend", BLEND_RATE)), 1.0)
	_tick_secondary(delta)
	for j: String in _bones.keys():
		_angle[j] = lerpf(_angle[j], _pose_angle(pose, j), k)
		_bones[j].rotation.z = deg_to_rad(_angle[j] + _sec_angle.get(j, 0.0))
	# The body's lean (metres at the head, forward positive) tips the lean bone forward.
	if _lean_bone != "" and _bones.has(_lean_bone):
		_bones[_lean_bone].rotation.z -= atan(_cur["lean"] * _lean_scale / maxf(height_m * 0.5, 0.1))
	_root.position.y = lerpf(_root.position.y, float(pose.get("root_y", 0.0)), k)
	_squash = lerpf(_squash, float(pose.get("squash", 0.0)), k)
	_tick_kick(delta)
	_apply_squash()
	for name: String in SHARED:
		var v: Variant = _mat.get_shader_parameter(name)
		if v == null:
			continue
		for m in _mats:
			m.set_shader_parameter(name, v)


## "squash" in a pose: positive crouches the whole body down and wide (coiling), negative
## stretches it tall and thin (a lunge). Scaled about the feet.
func _apply_squash() -> void:
	var f := float(spec.get("faces", 1))
	var sq := _squash + _kick
	_root.scale.x = f * (1.0 + sq * 0.5)
	_root.scale.y = 1.0 - sq


## Parts that react to movement on their own (a cape): each is a spring pulled toward an angle
## set by how fast the body moves forward and falls, so it trails, lifts and settles late.
## Settings per bone in the rig data: drag (degrees per m/s forward), fall (degrees per m/s
## falling), min/max (degrees), stiffness and damping of the spring.
func _tick_secondary(delta: float) -> void:
	if _secondary.is_empty() or delta <= 0.0:
		return
	var pos := global_position
	var vel := Vector3.ZERO
	if _last_pos != Vector3.INF:
		vel = (pos - _last_pos) / delta
	_last_pos = pos
	# Teleports and room changes are not movement.
	if vel.length() > 30.0:
		vel = Vector3.ZERO
	var forward := vel.x * signf(_pivot.global_basis.x.x)
	for j: String in _secondary.keys():
		var s: Dictionary = _secondary[j]
		var target := -forward * float(s.get("drag", 3.0)) + minf(vel.y, 0.0) * float(s.get("fall", 3.0))
		target = clampf(target, float(s.get("min", -35.0)), float(s.get("max", 10.0)))
		var acc := (target - _sec_angle[j]) * float(s.get("stiffness", 120.0)) - _sec_vel[j] * float(s.get("damping", 12.0))
		_sec_vel[j] += acc * delta
		_sec_angle[j] += _sec_vel[j] * delta


## The landing or turning squash now (for tests).
func kick_amount() -> float:
	return _kick


## Extra angle a secondary bone carries now (for tests).
func secondary_deg(bone: String) -> float:
	return _sec_angle.get(bone, 0.0)


## Squash the body down for a moment, springing back with a little rebound (landings).
func kick(amount: float) -> void:
	_kick_vel += amount * KICK_SPEED


## Landing dust also squashes the body.
func puff() -> void:
	super.puff()
	kick(float(_kicks.get("land", 0.0)))


func _tick_kick(delta: float) -> void:
	if delta <= 0.0:
		return
	# Turning round squashes a little too, so the flip does not read as a snap.
	var f := signf(_pivot.global_basis.x.x)
	if _facing_sign != 0.0 and f != _facing_sign:
		kick(float(_kicks.get("turn", 0.0)))
	_facing_sign = f
	# A stiff, lightly damped spring: down fast, a small bounce, settled in about 0.3 s.
	var acc := -_kick * KICK_STIFFNESS - _kick_vel * KICK_DAMPING
	_kick_vel += acc * delta
	_kick += _kick_vel * delta


## The angle bone `j` takes from `pose`: its own channel, unless it follows another.
func _pose_angle(pose: Dictionary, j: String) -> float:
	if pose.has(j) and not _channel.has(j):
		return float(pose[j])
	return float(pose.get(_channel.get(j, j), 0.0)) * _channel_scale.get(j, 1.0)
