class_name IlyrKit
extends VesselKit
## Ilyr (addendum "Ability mapping"; Narrative 6), playable in Chapter I only in the 90-second
## awakening: a 4-hit dimensional blade (Aether), Fracture (a spatial tear that cuts for 3 s, 6 s),
## Distortion (pulls the nearest enemy in front to his blade, 8 s), Null Space (a blink that erases
## enemy projectiles on its path), and Echo (every 5th hit repeats at 70 %). Ultimate: Absolute
## Rupture, an implosion pulling every enemy near together. Numbers in data/balance/vessels/ilyr.json.

var _hits: int = 0


## Is the `count`-th landed attack an Echo (every `every`)?
static func echo_due(count: int, every: int) -> bool:
	return every > 0 and count > 0 and count % every == 0


## Echo: count landed primary hits; every 5th repeats on the same target at 70 %.
func on_primary_landed(player: Player, target: Node3D, p: DamagePacket) -> void:
	var pas: Dictionary = data.get("passive", {})
	_hits += 1
	if not echo_due(_hits, int(pas.get("every", 5))) or target == null or not is_instance_valid(target):
		return
	var e := p.duplicate_packet()
	e.motion = p.motion * float(pas.get("repeat_motion", 0.7))
	e.is_primary = false
	e.tags["ability"] = "echo"
	e.result = target.call("receive_hit", e)
	GameEvents.ultimate_fx_requested.emit("slash", target.global_position, 1.0)
	Sfx.play("swap")


## Fracture: a tear in the air ahead that cuts whatever stands in it, every half second for 3 s.
func ability_1_released(player: Player, _held_s: float) -> void:
	var a1: Dictionary = data.get("ability_1", {})
	var slot := player.loadout.active()
	var key := str(a1.get("id", "fracture"))
	if not slot.cooldown_ready(key) or not slot.stamina.can_spend():
		return
	slot.stamina.spend(float(a1.get("stamina_cost", 10.0)))
	slot.start_cooldown(key, float(a1.get("cooldown_s", 6.0)))
	var size: Array = a1.get("size_m", [2.0, 2.2])
	var cx := player.global_position.x + float(a1.get("range_m", 4.0)) * 0.5 * player.facing + 0.6 * player.facing
	var rect := Rect2(cx - float(size[0]) * 0.5, player.global_position.y, float(size[0]), float(size[1]))
	var tear := FractureTear.new()
	tear.player = player
	tear.rect = rect
	tear.duration = float(a1.get("duration_s", 3.0))
	tear.tick_s = float(a1.get("tick_s", 0.5))
	tear.motion = float(a1.get("motion", 0.35))
	tear.posture = float(a1.get("posture", 4.0))
	player.fx_parent.add_child(tear)
	Sfx.play("vanish")


## Distortion: the nearest enemy in front is pulled to his blade.
func ability_2(player: Player) -> void:
	var a2: Dictionary = data.get("ability_2", {})
	var slot := player.loadout.active()
	var key := str(a2.get("id", "distortion"))
	if not slot.cooldown_ready(key):
		return
	var range := float(a2.get("range_m", 8.0))
	var best: Node3D = null
	var best_d := range
	var foes: Array[Node3D] = []
	player.world.members_of(CombatWorld.TEAM_ENEMY, foes)
	for f in foes:
		var dx := (f.global_position.x - player.global_position.x) * float(player.facing)
		if dx > 0.0 and dx < best_d and absf(f.global_position.y - player.global_position.y) < 3.0 and f is EnemyBase:
			best = f
			best_d = dx
	if best == null:
		return
	slot.start_cooldown(key, float(a2.get("cooldown_s", 8.0)))
	best.global_position.x = player.global_position.x + float(a2.get("pull_to_m", 1.4)) * player.facing
	best.reset_physics_interpolation()
	var p := player.make_packet(float(a2.get("motion", 0.6)), float(a2.get("posture", 25.0)))
	p.tags["ability"] = key
	p.source_x = player.global_position.x
	p.result = best.call("receive_hit", p)
	player.report_hit(best, p)
	GameEvents.ultimate_fx_requested.emit("slash", best.global_position, 1.0)
	Sfx.play("shadowstep")


## Null Space: the blink dodge, erasing enemy projectiles along its path.
func dodge_action(player: Player) -> PlayerAction:
	var a := super(player)
	if a == null:
		return null
	var d: Dictionary = data.get("dodge", {})
	var from := Vector2(player.global_position.x, player.global_position.y + 1.0)
	var to := from + Vector2(float(d.get("distance_m", 5.0)) * player.facing, 0.0)
	a.on_start = func(pl: Player, _act: PlayerAction) -> void:
		erase_projectiles(pl, from, to)
	return a


## Remove every enemy projectile within the erase radius of the segment `from`-`to`.
func erase_projectiles(player: Player, from: Vector2, to: Vector2) -> void:
	var r := float(data.get("dodge", {}).get("erase_radius_m", 1.6))
	for n in player.get_tree().get_nodes_in_group(Projectile.ENEMY_GROUP):
		var proj := n as Node3D
		if proj == null or proj.is_queued_for_deletion():
			continue
		var p := Vector2(proj.global_position.x, proj.global_position.y)
		var seg := to - from
		var t := clampf((p - from).dot(seg) / maxf(seg.length_squared(), 0.0001), 0.0, 1.0)
		if (from + seg * t).distance_to(p) <= r:
			proj.queue_free()
			GameEvents.hit_fx_requested.emit(proj.global_position, 0.0, false, true)


## Dislocation: swap places with the nearest enemy and cut it.
func resonance_action(player: Player) -> PlayerAction:
	var r: Dictionary = data.get("resonance", {})
	var a := PlayerAction.new("dislocation", 0.3)
	a.set_iframes(0.0, 0.25)
	a.on_start = func(pl: Player, _act: PlayerAction) -> void:
		var t := pl.world.nearest(Vector2(pl.global_position.x, pl.global_position.y + 0.9), CombatWorld.TEAM_ENEMY,
			float(r.get("range_m", 8.0)))
		if t == null:
			return
		var here := pl.global_position.x
		pl.teleport(t.global_position.x, maxf(t.global_position.y, 0.0))
		t.global_position.x = here
		var p := pl.make_packet(float(r.get("motion", 0.8)), float(r.get("posture", 20.0)))
		p.tags["ability"] = "dislocation"
		p.result = t.call("receive_hit", p)
		pl.report_hit(t, p)
		Sfx.play("shadowstep")
	return a


## Absolute Rupture: every enemy near is pulled into one point and torn.
func ultimate_action(player: Player) -> PlayerAction:
	var u: Dictionary = data.get("ultimate", {})
	var a := PlayerAction.new("absolute_rupture", float(u.get("duration_s", 2.0)))
	a.hyper_armor = true
	a.set_iframes(0.0, float(u.get("duration_s", 2.0)))
	a.data["fired"] = false
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["fired"] or act.elapsed < 0.6:
			return
		act.data["fired"] = true
		var targets: Array[Node3D] = []
		var c := Vector2(pl.global_position.x + 2.5 * pl.facing, pl.global_position.y + 0.9)
		pl.world.query_radius(c, float(u.get("pull_radius_m", 8.0)), CombatWorld.TEAM_ENEMY, targets)
		for t in targets:
			t.global_position.x = c.x
			var p := pl.make_packet(float(u.get("motion", 2.5)), float(u.get("posture", 60.0)))
			p.aoe = true
			p.tags["ability"] = "absolute_rupture"
			p.result = t.call("receive_hit", p)
			pl.report_hit(t, p)
		GameEvents.ultimate_fx_requested.emit("cataclysm_fused", Vector3(c.x, pl.global_position.y, 0.0),
			float(u.get("pull_radius_m", 8.0)))
		GameEvents.camera_shake_requested.emit(0.8)
		Sfx.play("ultimate")
	return a


func ability_cooldown_keys() -> PackedStringArray:
	return PackedStringArray(["fracture", "distortion"])
