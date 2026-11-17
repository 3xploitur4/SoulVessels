class_name DariusKit
extends VesselKit
## Darius, the surface soldier (addendum "Ability mapping"): a 3-hit hammer combo with hyper-armor,
## Crushing Blow (shatters shields and armor, 150 posture, 7 s; breaks cracked masonry),
## Groundbreaker (5 m seismic slam, 9 s; breaks masonry), a shoulder-charge dodge with knockback,
## Unbreakable and Last Survivor (+1 % damage per 2 % HP missing, max +50 %). Resonance: Meteor
## Drop. Sync Guard: survives a lethal blow at 1 HP with 3 s of Last Survivor at maximum. Ultimate:
## Worldbreaker Override, a charged strike that breaks the posture of every enemy on screen. His
## AoE (`heavy_aoe`) kills Echo Crawlers outright. Numbers in data/balance/vessels/darius.json.

## Seconds left of Last Survivor held at its maximum (after his Sync Guard).
var last_survivor_left: float = 0.0


## Damage multiplier at health `ratio`: +per_step for every `step` of health missing, up to +cap.
static func last_survivor(ratio: float, per_step: float, step: float, cap: float) -> float:
	var missing := clampf(1.0 - ratio, 0.0, 1.0)
	return 1.0 + minf(missing / maxf(step, 0.0001) * per_step, cap)


func damage_dealt_multiplier(player: Player) -> float:
	var pas: Dictionary = data.get("passive", {})
	if last_survivor_left > 0.0:
		return 1.0 + float(pas.get("cap", 0.5))
	return last_survivor(player.health.ratio(), float(pas.get("per_step", 0.01)), float(pas.get("step", 0.02)),
		float(pas.get("cap", 0.5)))


## Every hammer swing has hyper-armor (Unbreakable).
func primary_action(player: Player, index: int) -> PlayerAction:
	var a := super(player, index)
	if a != null:
		a.hyper_armor = bool(data.get("primary", {}).get("hyper_armor", true))
	return a


## The shoulder charge: a short rush that knocks enemies in its path back.
func dodge_action(player: Player) -> PlayerAction:
	var d: Dictionary = data.get("dodge", {})
	var slot := player.loadout.active()
	if not slot.stamina.can_spend():
		return null
	slot.stamina.spend(float(d.get("stamina_cost", 20.0)))
	var dur := Balance.combat_f("dodge.roll_s")
	var a := PlayerAction.new("shoulder_charge", dur)
	a.set_iframes(0.0, float(d.get("iframe_s", 0.15)))
	a.hyper_armor = true
	a.set_velocity(float(d.get("distance_m", 3.2)) / (dur * 0.8), 0.0, dur * 0.8)
	a.cancel_after = dur * 0.8
	a.cancel_into = PackedStringArray(["attack"])
	a.data["kind"] = "shoulder_charge"
	var p := player.make_packet(float(d.get("motion", 0.5)), float(d.get("posture", 8.0)))
	p.knockback = float(d.get("knockback_m", 2.5))
	p.tags["ability"] = "shoulder_charge"
	a.add_hit(ActionHit.new(0.02, dur * 0.8, Vector2(0.6, 1.0), Vector2(1.2, 1.8), p))
	return a


## Crushing Blow as an action (tests read its packet).
func crushing_blow_action(player: Player) -> PlayerAction:
	var a1: Dictionary = data.get("ability_1", {})
	var windup := float(a1.get("windup_s", 0.42))
	var a := PlayerAction.new("crushing_blow", windup + 0.45)
	a.hyper_armor = true
	a.steer = 0.0
	var p := player.make_packet(float(a1.get("motion", 2.2)), float(a1.get("posture", 60.0)))
	p.heavy = true
	p.breaks_shield = bool(a1.get("breaks_shield", true))
	p.tags["breaks_masonry"] = bool(a1.get("breaks_masonry", true))
	p.tags["ability"] = "crushing_blow"
	var reach := float(a1.get("range_m", 2.6))
	a.add_hit(ActionHit.new(windup, windup + 0.14, Vector2(reach * 0.5 + 0.2, 1.0), Vector2(reach, 1.9), p))
	a.on_tick = func(_pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.elapsed >= windup and not act.data.get("shook", false):
			act.data["shook"] = true
			GameEvents.camera_shake_requested.emit(0.4)
			Sfx.play("guard_break")
	return a


func ability_1_released(player: Player, _held_s: float) -> void:
	var a1: Dictionary = data.get("ability_1", {})
	var slot := player.loadout.active()
	var key := str(a1.get("id", "crushing_blow"))
	if not slot.cooldown_ready(key) or not slot.stamina.can_spend():
		return
	slot.stamina.spend(float(a1.get("stamina_cost", 15.0)))
	slot.start_cooldown(key, float(a1.get("cooldown_s", 7.0)))
	player.start_action(crushing_blow_action(player))


## Groundbreaker: a 5 m seismic slam around him.
func ability_2(player: Player) -> void:
	var a2: Dictionary = data.get("ability_2", {})
	var slot := player.loadout.active()
	var key := str(a2.get("id", "groundbreaker"))
	if not slot.cooldown_ready(key) or not slot.stamina.can_spend():
		return
	slot.stamina.spend(float(a2.get("stamina_cost", 20.0)))
	slot.start_cooldown(key, float(a2.get("cooldown_s", 9.0)))
	var windup := float(a2.get("windup_s", 0.35))
	var a := PlayerAction.new(key, windup + 0.4)
	a.hyper_armor = true
	a.steer = 0.0
	a.data["fired"] = false
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["fired"] or act.elapsed < windup:
			return
		act.data["fired"] = true
		_slam(pl, float(a2.get("radius_m", 5.0)), float(a2.get("motion", 1.6)), float(a2.get("posture", 24.0)),
			key, bool(a2.get("heavy_aoe", true)), bool(a2.get("breaks_masonry", true)))
	player.start_action(a)


## Meteor Drop: he lands like a falling star; 3 m AoE. Echo: an Unraveled enemy's armor shatters.
func resonance_action(player: Player) -> PlayerAction:
	var r: Dictionary = data.get("resonance", {})
	var windup := float(r.get("windup_s", 0.3))
	var a := PlayerAction.new("meteor_drop", windup + 0.35)
	a.set_iframes(0.0, windup + 0.1)
	a.hyper_armor = true
	a.data["fired"] = false
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["fired"] or act.elapsed < windup:
			return
		act.data["fired"] = true
		_slam(pl, float(r.get("radius_m", 3.0)), float(r.get("motion", 1.5)), float(r.get("posture", 36.0)),
			"meteor_drop", bool(r.get("heavy_aoe", true)), false, true)
	a.cancel_after = windup + 0.2
	a.cancel_into = PackedStringArray(["attack", "dodge", "ability"])
	return a


## The Sync Guard: he will not fall. One HP left and Last Survivor at its maximum for a while.
func sync_guard(player: Player, _p: DamagePacket) -> bool:
	player.health.current = 1.0
	GameEvents.player_hp_changed.emit(player.health.current, player.health.max_value)
	last_survivor_left = float(data.get("sync_guard", {}).get("last_survivor_s", 3.0))
	return true


## Worldbreaker Override: a long charge, then one blow that breaks every guard on screen.
func ultimate_action(player: Player) -> PlayerAction:
	var u: Dictionary = data.get("ultimate", {})
	var charge := float(u.get("charge_s", 1.2))
	var a := PlayerAction.new("worldbreaker_override", charge + 0.6)
	a.hyper_armor = true
	a.set_iframes(0.0, charge + 0.6)
	a.steer = 0.0
	a.data["fired"] = false
	a.on_start = func(pl: Player, _act: PlayerAction) -> void:
		GameEvents.ultimate_fx_requested.emit("final_stand", pl.global_position, 2.0)
		Sfx.play("ultimate")
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["fired"] or act.elapsed < charge:
			return
		act.data["fired"] = true
		worldbreaker_strike(pl)
	return a


## The Worldbreaker blow itself: damage and a full posture break on every enemy in range.
func worldbreaker_strike(player: Player) -> void:
	var u: Dictionary = data.get("ultimate", {})
	var targets: Array[Node3D] = []
	var centre := Vector2(player.global_position.x, player.global_position.y + 0.9)
	player.world.query_radius(centre, float(u.get("radius_m", 14.0)), CombatWorld.TEAM_ENEMY, targets)
	for t in targets:
		var p := player.make_packet(float(u.get("motion", 3.0)), 0.0)
		p.aoe = true
		p.tags["ability"] = "worldbreaker_override"
		if bool(u.get("heavy_aoe", true)):
			p.tags["heavy_aoe"] = true
		p.source_x = player.global_position.x
		p.result = t.call("receive_hit", p)
		player.report_hit(t, p)
		var post: Variant = t.get("posture")
		if bool(u.get("break_all_posture", true)) and post is Posture and t.has_method("is_alive") and t.call("is_alive"):
			(post as Posture).add((post as Posture).max_value)
			if t.has_method("_enter_stagger"):
				t.call("_enter_stagger")
	GameEvents.ultimate_fx_requested.emit("final_stand", player.global_position, float(u.get("radius_m", 14.0)))
	GameEvents.camera_shake_requested.emit(1.0)
	Sfx.play("posture_break")


func tick(delta: float) -> void:
	last_survivor_left = maxf(last_survivor_left - delta, 0.0)


func ability_cooldown_keys() -> PackedStringArray:
	return PackedStringArray(["crushing_blow", "groundbreaker"])


func _slam(player: Player, radius: float, motion: float, posture: float, ability: String, heavy: bool,
		masonry: bool, echo_shatter: bool = false) -> void:
	var targets: Array[Node3D] = []
	var centre := Vector2(player.global_position.x, player.global_position.y + 0.5)
	player.world.query_radius(centre, radius, CombatWorld.TEAM_ENEMY, targets)
	for t in targets:
		var p := player.make_packet(motion, posture)
		p.aoe = true
		p.heavy = true
		p.source_x = player.global_position.x
		p.tags["ability"] = ability
		if heavy:
			p.tags["heavy_aoe"] = true
		if masonry:
			p.tags["breaks_masonry"] = true
		var st: Variant = t.get("status")
		if echo_shatter and st is StatusEffects and (st as StatusEffects).has_status("unraveled"):
			p.breaks_shield = true
			p.tags["ignore_def"] = true
		p.result = t.call("receive_hit", p)
		player.report_hit(t, p)
	GameEvents.slam_landed.emit(Rect2(centre.x - radius, centre.y - 1.0, radius * 2.0, 2.5),
		{"breaks_masonry": masonry, "ability": ability})
	GameEvents.ultimate_fx_requested.emit("final_stand", player.global_position, radius)
	GameEvents.camera_shake_requested.emit(0.5)
	Sfx.play("shockwave")
