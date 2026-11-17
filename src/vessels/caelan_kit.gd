class_name CaelanKit
extends VesselKit
## Caelan, the Knight (addendum "Ability mapping"): 4-hit longsword combo, Royal Guard (hold to
## block, perfect block = Counterstrike), King's Judgment (8 m ground shockwave, 6 s), Iron Resolve
## (-15 % damage, -30 % while blocking). Resonance: Oathbreaker Lunge. Sync Guard: intercepts a
## lethal blow. Ultimate: Final Stand. Every number is in data/balance/vessels/caelan.json.


func ability_1_pressed(player: Player) -> void:
	player.begin_block()


func ability_1_released(player: Player, _held_s: float) -> void:
	player.end_block()


## King's Judgment: a wave that runs 8 m along the floor and hits everything in its path.
func ability_2(player: Player) -> void:
	var a2: Dictionary = data.get("ability_2", {})
	var slot := player.loadout.active()
	var key := str(a2.get("id", "kings_judgment"))
	if not slot.cooldown_ready(key) or not slot.stamina.can_spend():
		return
	slot.stamina.spend(float(a2.get("stamina_cost", 15.0)))
	slot.start_cooldown(key, float(a2.get("cooldown_s", 6.0)))
	var windup := float(a2.get("windup_s", 0.3))
	var a := PlayerAction.new(key, windup + 0.35)
	a.data["fired"] = false
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["fired"] or act.elapsed < windup:
			return
		act.data["fired"] = true
		var p := pl.make_packet(float(a2.get("motion", 1.8)), float(a2.get("posture", 40.0)))
		p.aoe = true
		p.tags["ability"] = key
		var speed := float(a2.get("travel_speed_mps", 16.0))
		var origin := Vector2(pl.global_position.x + 0.8 * pl.facing, pl.global_position.y + 0.6)
		pl.spawn_projectile(p, origin, Vector2(speed * pl.facing, 0.0), Vector2(1.2, 1.3),
			float(a2.get("range_m", 8.0)), VfxShapes.shockwave(Color(0.55, 0.75, 1.0)))
		GameEvents.camera_shake_requested.emit(0.25)
		Sfx.play("shockwave")
	player.start_action(a)


## Counterstrike: an automatic riposte slash after a perfect parry; the parried attacker's guard
## opens for `guard_break_s` (a Branded Warden lowers its shield).
func on_perfect_parry(player: Player, attacker: Node3D, _p: DamagePacket) -> void:
	var cs: Dictionary = data.get("ability_1", {}).get("counterstrike", {})
	if attacker != null and is_instance_valid(attacker) and attacker.has_method("open_guard"):
		attacker.call("open_guard", float(cs.get("guard_break_s", 2.0)))
	_sworn_shield(player, attacker, _p)
	var a := PlayerAction.new("counterstrike", 0.38)
	var p := player.make_packet(float(cs.get("motion", 1.5)), float(cs.get("posture", 35.0)))
	p.is_primary = true
	p.tags["ability"] = "counterstrike"
	var reach := float(cs.get("range_m", 2.4))
	a.add_hit(ActionHit.new(0.06, 0.18, Vector2(reach * 0.5 + 0.1, 1.0), Vector2(reach, 1.8), p))
	a.cancel_after = 0.2
	a.cancel_into = PackedStringArray(["attack", "dodge", "ability"])
	player.start_action(a)


func damage_taken_multiplier(_player: Player, blocking: bool) -> float:
	var passive: Dictionary = data.get("passive", {})
	if blocking:
		return float(passive.get("blocking_damage_taken_multiplier", 0.7))
	return float(passive.get("damage_taken_multiplier", 0.85))


## Oathbreaker Lunge: a shield-bash dash, heavy posture damage. Echo: 3x posture vs Frozen.
func resonance_action(player: Player) -> PlayerAction:
	var r: Dictionary = data.get("resonance", {})
	var dash_s := float(r.get("dash_s", 0.18))
	var a := PlayerAction.new("oathbreaker_lunge", dash_s + 0.22)
	a.set_velocity(float(r.get("dash_m", 4.0)) / dash_s, 0.0, dash_s)
	a.set_iframes(0.0, dash_s)
	a.gravity_scale = 0.0
	a.velocity_y = 0.0
	var p := player.make_packet(float(r.get("motion", 1.2)), 0.0)
	p.posture = float(r.get("posture", 60.0))
	p.is_resonance = true
	p.knockback = 3.0
	p.tags["echo"] = r.get("echo", {})
	p.tags["ability"] = "oathbreaker_lunge"
	a.add_hit(ActionHit.new(0.0, dash_s + 0.05, Vector2(0.9, 1.0), Vector2(1.4, 1.8), p))
	a.cancel_after = dash_s + 0.1
	a.cancel_into = PackedStringArray(["attack", "dodge", "ability"])
	return a


## Sync Guard: Caelan steps in and takes the lethal blow on the shield.
func sync_guard(player: Player, _p: DamagePacket) -> bool:
	var a := PlayerAction.new("sync_guard", 0.5)
	a.blocking = true
	a.set_iframes(0.0, 0.5)
	player.start_action(a)
	return true


## Final Stand: 6 m AoE knockdown, then 50 % damage reduction for the duration.
func ultimate_action(player: Player) -> PlayerAction:
	var u: Dictionary = data.get("ultimate", {})
	var a := PlayerAction.new("final_stand", 1.2)
	a.hyper_armor = true
	a.set_iframes(0.0, 1.2)
	a.data["slammed"] = false
	a.on_start = func(pl: Player, _act: PlayerAction) -> void:
		pl.damage_reduction = float(u.get("damage_reduction", 0.5))
		pl.damage_reduction_left = float(u.get("duration_s", 4.0))
		GameEvents.ultimate_fx_requested.emit("final_stand", pl.global_position, float(u.get("radius_m", 6.0)))
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["slammed"] or act.elapsed < 0.45:
			return
		act.data["slammed"] = true
		var targets: Array[Node3D] = []
		var centre := Vector2(pl.global_position.x, pl.global_position.y + 0.9)
		pl.world.query_radius(centre, float(u.get("radius_m", 6.0)), CombatWorld.TEAM_ENEMY, targets)
		for t in targets:
			var p := pl.make_packet(float(u.get("motion", 2.0)), float(u.get("posture", 80.0)))
			p.aoe = true
			p.knockback = 6.0
			p.source_x = pl.global_position.x
			p.tags["knockdown_s"] = float(u.get("knockdown_s", 1.5))
			p.tags["ability"] = "final_stand"
			p.result = t.call("receive_hit", p)
			pl.report_hit(t, p)
		GameEvents.camera_shake_requested.emit(0.8)
		Sfx.play("ultimate")
	return a


func ability_cooldown_keys() -> PackedStringArray:
	return PackedStringArray(["royal_guard", "kings_judgment"])


## Sworn Shield (story 050, Affinity 5): a perfect parry sends a magic attack back at its caster
## (one that is not already reflected, like the Watcher's beam), at its own strength.
func _sworn_shield(player: Player, attacker: Node3D, p: DamagePacket) -> void:
	if p == null or not bool(data.get("signature", {}).get("reflect_magic", false)):
		return
	if p.kind != DamagePacket.KIND_MAGIC or p.can_reflect:
		return
	if attacker == null or not is_instance_valid(attacker) or not attacker.has_method("receive_hit"):
		return
	var back := player.make_packet(p.motion, 20.0)
	back.kind = DamagePacket.KIND_MAGIC
	back.atk = p.atk
	back.element = p.element
	back.element_buildup = p.element_buildup
	back.tags["ability"] = "sworn_shield"
	attacker.call("receive_hit", back)
	GameEvents.hit_fx_requested.emit(attacker.global_position + Vector3(0.0, 1.0, 0.3), 0.0, true, false)
