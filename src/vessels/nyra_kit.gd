class_name NyraKit
extends VesselKit
## Nyra, the Wanderer (addendum "Ability mapping"): 6-hit dagger flurry, Shadowstep (6 m teleport
## dash, 3 s; hold for Vanishing Act, 2 s stealth, 12 s), Phantom Blades (5 knives, 5 s), Backstab
## 2.5x, 20 % crit. Resonance: Severing Arrival. Sync Guard: auto-evade an unblockable hit with a
## shadow counter. Ultimate: Dance of Shadows. Numbers in data/balance/vessels/nyra.json.

var _hold_fired: bool = false


func ability_1_pressed(_player: Player) -> void:
	_hold_fired = false


## Holding past `hold_s` turns Shadowstep into Vanishing Act.
func ability_1_held(player: Player, held_s: float) -> void:
	var a1: Dictionary = data.get("ability_1", {})
	if _hold_fired or held_s < float(a1.get("hold_s", 0.35)):
		return
	_hold_fired = true
	var va: Dictionary = a1.get("hold_ability", {})
	var slot := player.loadout.active()
	var key := str(va.get("id", "vanishing_act"))
	if not slot.cooldown_ready(key):
		return
	slot.start_cooldown(key, float(va.get("cooldown_s", 12.0)))
	player.stealth_left = float(va.get("duration_s", 2.0))
	player.next_hit_backstab = bool(va.get("next_hit_is_backstab", true))
	GameEvents.stealth_changed.emit(true)
	Sfx.play("vanish")


## A tap: Shadowstep, a 6 m teleport dash through enemies with i-frames.
func ability_1_released(player: Player, held_s: float) -> void:
	var a1: Dictionary = data.get("ability_1", {})
	if _hold_fired or held_s >= float(a1.get("hold_s", 0.35)):
		return
	var slot := player.loadout.active()
	var key := str(a1.get("id", "shadowstep"))
	if not slot.cooldown_ready(key):
		return
	slot.start_cooldown(key, float(a1.get("cooldown_s", 3.0)))
	var dash_s := float(a1.get("dash_s", 0.12))
	var a := PlayerAction.new(key, dash_s + 0.08)
	a.set_velocity(float(a1.get("distance_m", 6.0)) / dash_s, 0.0, dash_s)
	a.set_iframes(0.0, dash_s + 0.08)
	a.velocity_y = 0.0
	a.gravity_scale = 0.0
	a.cancel_after = dash_s
	a.cancel_into = PackedStringArray(["attack", "dodge", "ability"])
	player.start_action(a)
	Sfx.play("shadowstep")


## Phantom Blades: five spectral knives fanned forward.
func ability_2(player: Player) -> void:
	var a2: Dictionary = data.get("ability_2", {})
	var slot := player.loadout.active()
	var key := str(a2.get("id", "phantom_blades"))
	if not slot.cooldown_ready(key):
		return
	slot.start_cooldown(key, float(a2.get("cooldown_s", 5.0)))
	var a := PlayerAction.new(key, 0.3)
	a.steer = 0.3
	a.on_start = func(pl: Player, _act: PlayerAction) -> void:
		var count := int(a2.get("knives", 5))
		var spread := deg_to_rad(float(a2.get("spread_deg", 30.0)))
		var speed := float(a2.get("speed_mps", 22.0))
		for i in range(count):
			var t := 0.0 if count <= 1 else float(i) / float(count - 1) - 0.5
			var angle := t * spread
			var vel := Vector2(cos(angle) * speed * pl.facing, sin(angle) * speed)
			var p := pl.make_packet(float(a2.get("motion", 0.7)), float(a2.get("posture", 6.0)))
			p.tags["ability"] = key
			var origin := Vector2(pl.global_position.x + 0.5 * pl.facing, pl.global_position.y + 1.2)
			pl.spawn_projectile(p, origin, vel, Vector2(0.5, 0.35), float(a2.get("range_m", 10.0)),
				VfxShapes.knife(Color(0.7, 0.55, 1.0)))
		Sfx.play("knives")
	player.start_action(a)


## Severing Arrival: appear behind the nearest enemy within range and strike its back.
## Echo: a guaranteed crit against a Staggered target.
func resonance_action(player: Player) -> PlayerAction:
	var r: Dictionary = data.get("resonance", {})
	var a := PlayerAction.new("severing_arrival", 0.34)
	a.set_iframes(0.0, 0.2)
	a.gravity_scale = 0.3
	a.on_start = func(pl: Player, _act: PlayerAction) -> void:
		var centre := Vector2(pl.global_position.x, pl.global_position.y + 0.9)
		var target := pl.world.nearest(centre, CombatWorld.TEAM_ENEMY, float(r.get("target_range_m", 8.0)))
		if target == null:
			return
		var t_facing: int = int(target.get("facing")) if target.get("facing") != null else 1
		var behind_x := target.global_position.x - float(t_facing) * float(r.get("behind_offset_m", 1.2))
		pl.teleport(behind_x, maxf(target.global_position.y, 0.0))
		pl.set_facing(t_facing)
		Sfx.play("shadowstep")
	var p := player.make_packet(float(r.get("motion", 1.4)), float(r.get("posture", 20.0)))
	p.is_resonance = true
	p.force_backstab = bool(r.get("guaranteed_backstab", true))
	p.tags["echo"] = r.get("echo", {})
	p.tags["ability"] = "severing_arrival"
	a.add_hit(ActionHit.new(0.05, 0.16, Vector2(1.0, 1.0), Vector2(1.8, 1.8), p))
	a.cancel_after = 0.18
	a.cancel_into = PackedStringArray(["attack", "dodge", "ability"])
	return a


## Sync Guard: slip behind the attacker and counter with a shadow strike.
func sync_guard(player: Player, p: DamagePacket) -> bool:
	var sg: Dictionary = data.get("sync_guard", {})
	var attacker := p.attacker as Node3D
	if attacker != null and is_instance_valid(attacker):
		var t_facing: int = int(attacker.get("facing")) if attacker.get("facing") != null else 1
		player.teleport(attacker.global_position.x - float(t_facing) * 1.3, maxf(attacker.global_position.y, 0.0))
		player.set_facing(t_facing)
	var a := PlayerAction.new("shadow_counter", 0.35)
	a.set_iframes(0.0, 0.35)
	var counter := player.make_packet(float(sg.get("counter_motion", 1.2)), 15.0)
	counter.force_backstab = true
	counter.tags["ability"] = "shadow_counter"
	a.add_hit(ActionHit.new(0.08, 0.2, Vector2(1.0, 1.0), Vector2(1.8, 1.8), counter))
	player.start_action(a)
	return true


## Dance of Shadows: 12 auto-targeted slashes over 3 s, flickering between enemies in range.
func ultimate_action(player: Player) -> PlayerAction:
	var u: Dictionary = data.get("ultimate", {})
	var slashes := int(u.get("slashes", 12))
	var duration := float(u.get("duration_s", 3.0))
	var a := PlayerAction.new("dance_of_shadows", duration)
	a.hyper_armor = true
	a.set_iframes(0.0, duration)
	a.gravity_scale = 0.0
	a.velocity_y = 0.0
	a.data["done"] = 0
	a.on_start = func(pl: Player, _act: PlayerAction) -> void:
		GameEvents.ultimate_fx_requested.emit("dance_of_shadows", pl.global_position,
			float(u.get("target_range_m", 8.0)))
		Sfx.play("ultimate")
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		var due := mini(int(floorf(act.elapsed / (duration / float(slashes)))) + 1, slashes)
		while int(act.data["done"]) < due:
			act.data["done"] = int(act.data["done"]) + 1
			var targets: Array[Node3D] = []
			var centre := Vector2(pl.global_position.x, pl.global_position.y + 0.9)
			pl.world.query_radius(centre, float(u.get("target_range_m", 8.0)), CombatWorld.TEAM_ENEMY, targets)
			if targets.is_empty():
				continue
			var t: Node3D = targets[int(act.data["done"]) % targets.size()]
			var side := 1.0 if int(act.data["done"]) % 2 == 0 else -1.0
			pl.teleport(t.global_position.x - side * 1.1, maxf(t.global_position.y, 0.0))
			pl.set_facing(int(side))
			var p := pl.make_packet(float(u.get("motion", 0.8)), float(u.get("posture", 8.0)))
			p.source_x = pl.global_position.x
			p.tags["ability"] = "dance_of_shadows"
			p.result = t.call("receive_hit", p)
			pl.report_hit(t, p)
			GameEvents.ultimate_fx_requested.emit("slash", t.global_position, 1.0)
	return a


## Shadowstep breaks a root-snare at once (addendum "Resolved contradictions").
func breaks_snare_on(action_name: String) -> bool:
	return action_name == "ability_1"


func ability_cooldown_keys() -> PackedStringArray:
	return PackedStringArray(["shadowstep", "phantom_blades"])
