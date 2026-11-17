class_name ErasedEcho
extends EnemyBase
## An erased echo of a Vessel (story 047; Narrative 6): in Ilyr's awakening the Intruder fights pale,
## glitching versions of Caelan, Nyra, Seris and Darius, each using its Vessel's painting, rig and
## a sketch of its moves (data/balance/enemies/echo_<vessel>.json). Melee echoes close in and strike;
## a "caster" echo (Seris) keeps its distance and throws Arcane-style orbs. A "dash" attack lunges.
## The look flickers like a bad memory (the sprite's ghost value and a jitter).

var _glitch_t: float = 0.0


func _init() -> void:
	enemy_id = ""


func _hurt_size() -> Vector2:
	return Vector2(0.9, 1.85)


func _physics_process(delta: float) -> void:
	super(delta)
	_glitch_t += delta
	if visual is EnemySpriteVisual and is_alive():
		var body := (visual as EnemySpriteVisual).body
		# A memory coming apart: mostly solid, now and then a stutter.
		var stutter := 1.0 if fmod(_glitch_t * 3.7, 1.0) < 0.08 else 0.0
		body.ghost = 0.35 + 0.45 * stutter
		visual.position.x = 0.12 * stutter * signf(sin(_glitch_t * 97.0))


func _begin_attack() -> void:
	super()
	if bool(current_attack.get("dash", false)):
		velocity.x = float(facing) * float(current_attack.get("dash_mps", 12.0))
	if int(current_attack.get("orbs", 0)) > 0:
		_cast_orbs()


func _attack_tick(player: Node3D, delta: float) -> void:
	if bool(current_attack.get("dash", false)):
		velocity.x = float(facing) * float(current_attack.get("dash_mps", 12.0))
		return
	super(player, delta)


func _make_attack_hit(attack: Dictionary) -> ActionHit:
	if int(attack.get("orbs", 0)) > 0:
		return null
	if bool(attack.get("dash", false)):
		return ActionHit.new(0.0, float(attack.get("active_s", 0.3)) + 0.01, Vector2(0.5, 0.0),
			Vector2(1.2, 1.8), _make_packet(attack))
	return super(attack)


func _cast_orbs() -> void:
	var player := _target()
	var n := int(current_attack.get("orbs", 3))
	var speed := float(current_attack.get("orb_speed_mps", 11.0))
	var origin := Vector2(global_position.x + 0.6 * facing, global_position.y + 1.2)
	var aim := Vector2(float(facing), 0.0)
	if player != null:
		aim = (Vector2(player.global_position.x, player.global_position.y + 1.0) - origin).normalized()
	for i in range(n):
		var t := 0.0 if n <= 1 else float(i) / float(n - 1) - 0.5
		var v := aim.rotated(t * deg_to_rad(float(current_attack.get("orb_spread_deg", 10.0)))) * speed
		var proj := Projectile.spawn(get_parent(), world, _make_packet(current_attack), origin, v, Vector2(0.4, 0.4),
			VfxShapes.bolt(Color(0.75, 0.85, 1.0), 0.16, 1.2))
		proj.target_team = CombatWorld.TEAM_PLAYER
		proj.pierce = false
		proj.max_distance = float(current_attack.get("range_m", 12.0)) + 2.0
		proj.lifetime = proj.max_distance / speed + 0.1
	Sfx.play("bolt")
