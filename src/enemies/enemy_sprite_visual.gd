class_name EnemySpriteVisual
extends EnemyVisual
## An enemy drawn from its concept painting (story 027, decision D-032): a `SpriteBody` posed by
## the enemy's state, with the enemy's own tell as a glow on the painting (the Crawler's spine
## sacs, the Watcher's eye, the Warden's brand) and a soul-burn dissolve on death. Same interface
## as the placeholder `EnemyVisual`.
##
##     var vis := EnemyVisual.build(Balance.enemy("echo_crawler"))   # picks this when art exists

var body: SpriteBody

var _h: float = 1.0
var _z: float = 0.0
var _t: float = 0.0


static func build_sprite(enemy_data: Dictionary) -> EnemySpriteVisual:
	var v := EnemySpriteVisual.new()
	var id := str(enemy_data.get("id", ""))
	var sil: Dictionary = enemy_data.get("silhouette", {})
	v.kind = str(sil.get("kind", "arachnid"))
	v.name = "Visual_%s" % id
	v.body = SpriteBody.create(id)
	v.add_child(v.body)
	v._h = v.body.height_m
	v.body.trail_color = Color(str((v.body.spec.get("tell", {}) as Dictionary).get("color", "#ff5040")))
	# Enemies sit a little behind the player's plane, each at its own depth, so overlapping
	# sprites never fight over the same pixels.
	v._z = -0.06 - 0.02 * float(randi() % 8)
	# Handles the subclasses move (the Warden's shield and halberd); the painting has them
	# painted in, so these carry the state only.
	v.shield = Node3D.new()
	v.add_child(v.shield)
	v.weapon = Node3D.new()
	v.add_child(v.weapon)
	if v.kind == "sphere":
		v._build_lines(Color(str(sil.get("accent_color", "#39d7ff"))))
	return v


func tell(strength: float) -> void:
	body.tell = clampf(strength, 0.0, 1.0)


func flash(color: Color, seconds: float) -> void:
	body.flash(color, maxf(seconds, 0.1))


func animate(state: String, facing: int, speed: float, delta: float) -> void:
	_t += delta
	rotation.y = 0.0 if facing > 0 else PI
	body.position.z = _z * float(facing)
	var b := body
	b.lean = 0.0
	b.stride = 0.0
	b.crouch = 0.0
	b.roll = 0.0
	b.forward = 0.0
	b.lift = 0.0
	# A fast attack (the Crawler lunge, the Warden charge) leaves afterimages in its tell colour.
	b.trailing = state == "attack" and speed > 4.0
	match state:
		"approach":
			if speed > 0.2:
				b.stride = 1.0
				b.lean = 0.05 * _h
		"telegraph":
			b.lean = -0.1 * _h
			b.crouch = 0.45
			b.forward = sin(_t * 46.0) * 0.025
		"attack":
			b.lean = 0.2 * _h
			b.forward = 0.3
			b.stride = 1.0 if speed > 1.0 else 0.0
		"recover":
			b.crouch = 0.25
		"hurt":
			b.lean = -0.14 * _h
		"knockdown":
			b.roll = -1.25
			b.lift = 0.15
		"staggered":
			b.lean = -0.16 * _h + sin(_t * 5.0) * 0.03
			b.crouch = 0.5
	# The Warden's lowered shield (guard open after a parry): he reels.
	if shield != null and shield.rotation.z < -0.4:
		b.lean = -0.18 * _h
		b.crouch = 0.4
	b.tick(delta)


func dissolve(progress: float) -> void:
	body.set_dissolve(progress)
	body.lift = -0.15 * progress
