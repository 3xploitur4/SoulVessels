class_name SerisKit
extends VesselKit
## Seris, the court arcanist (addendum "Ability mapping"): Arcane Bolt (3-shot ranged chain, 20 m,
## Aether), Frost Binding (4 m ice field, 60 % Frost build-up, 8 s), Aether Shield (3 s projectile
## barrier, 10 s), Rift Step (5 m blink that breaks a root-snare), passive +10 % spell damage per
## enemy within 10 m (max +30 %). Resonance: Aether Burst. Sync Guard: an automatic shield against
## a big magic hit. Ultimate: Cataclysm Fused. Numbers in data/balance/vessels/seris.json.
##
##     var kit := VesselKit.create("seris", Balance.vessel("seris")) as SerisKit
##     kit.fire_bolt(player, 0)

## Every live Arcane Bolt is in this group, so rune doors and mirror-shields (story 032) find it.
const BOLT_GROUP := &"arcane_bolt"
const BOLT_COLOR := Color(0.55, 0.85, 1.0)
const FROST_COLOR := Color(0.7, 0.92, 1.0)


## Spell-damage multiplier for `enemies` nearby: 1 + per_enemy each, capped at 1 + cap.
static func spell_multiplier(enemies: int, per_enemy: float, cap: float) -> float:
	return 1.0 + minf(float(maxi(enemies, 0)) * per_enemy, cap)


## Living enemies within the passive's range of the player.
func enemies_near(player: Player) -> int:
	var pas: Dictionary = data.get("passive", {})
	var out: Array[Node3D] = []
	var centre := Vector2(player.global_position.x, player.global_position.y + 0.9)
	player.world.query_radius(centre, float(pas.get("range_m", 10.0)), CombatWorld.TEAM_ENEMY, out)
	return out.size()


## A spell packet: magic, the element and build-up given, motion scaled by the passive.
func spell_packet(player: Player, motion: float, posture: float, element: String, buildup: float) -> DamagePacket:
	var pas: Dictionary = data.get("passive", {})
	var mult := spell_multiplier(enemies_near(player), float(pas.get("per_enemy", 0.1)), float(pas.get("cap", 0.3)))
	var p := player.make_packet(motion * mult, posture)
	p.kind = DamagePacket.KIND_MAGIC
	p.element = element
	p.element_buildup = buildup
	return p


## Fire the `index`th Arcane Bolt now and return it.
func fire_bolt(player: Player, index: int) -> Projectile:
	var pr: Dictionary = data.get("primary", {})
	var hits: Array = pr.get("hits", [])
	if hits.is_empty():
		return null
	var h: Dictionary = hits[clampi(index, 0, hits.size() - 1)]
	var p := spell_packet(player, float(h.get("motion", 1.0)), float(h.get("posture", 4.0)),
		str(pr.get("element", "aether")), float(h.get("buildup", 0.0)))
	p.is_primary = true
	p.heavy = bool(h.get("heavy", false))
	p.tags["ability"] = "arcane_bolt"
	var speed := float(pr.get("speed_mps", 24.0))
	var origin := Vector2(player.global_position.x + 0.6 * player.facing, player.global_position.y + 0.95)
	var radius := 0.22 if p.heavy else 0.16
	var proj := player.spawn_projectile(p, origin, Vector2(speed * player.facing, 0.0), Vector2(0.5, 0.9),
		float(pr.get("range_m", 20.0)), VfxShapes.bolt(BOLT_COLOR, radius))
	proj.pierce = false
	proj.add_to_group(BOLT_GROUP)
	Sfx.play("bolt")
	return proj


## The primary is a cast: the bolt leaves at the end of the wind-up.
func primary_action(player: Player, index: int) -> PlayerAction:
	var hits: Array = data.get("primary", {}).get("hits", [])
	if hits.is_empty():
		return null
	var h: Dictionary = hits[clampi(index, 0, hits.size() - 1)]
	var speed := maxf(player.stat("attack_speed"), 0.1)
	var windup := float(h.get("windup_s", 0.16)) / speed
	var active := float(h.get("active_s", 0.06)) / speed
	var recover := float(h.get("recover_s", 0.22)) / speed
	var a := PlayerAction.new("primary_%d" % index, windup + active + recover)
	a.cancel_after = windup + active
	a.cancel_into = PackedStringArray(["attack", "dodge", "jump", "ability"])
	a.gravity_scale = 0.55
	a.steer = 0.4
	a.data["combo_index"] = index
	a.data["windup"] = windup
	a.data["active"] = active
	a.data["fired"] = false
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["fired"] or act.elapsed < windup:
			return
		act.data["fired"] = true
		fire_bolt(pl, index)
	if bool(h.get("heavy", false)):
		a.on_start = func(pl: Player, _act: PlayerAction) -> void:
			var slot := pl.loadout.active()
			if slot.stamina.can_spend():
				slot.stamina.spend(Balance.combat_f("stamina.heavy_cost"))
	return a


## Rift Step is a blink: it breaks a root-snare at once (addendum "Resolved contradictions").
func breaks_snare_on(action_name: String) -> bool:
	return action_name == "dodge" and bool(data.get("dodge", {}).get("breaks_snare", false))


## Frost Binding: a 4 m ice field in front of Seris; Frost build-up on each enemy inside, and a
## frozen surface on any water under it (story 031 listens to `GameEvents.frost_field_cast`).
func ability_1_released(player: Player, _held_s: float) -> void:
	var a1: Dictionary = data.get("ability_1", {})
	var slot := player.loadout.active()
	var key := str(a1.get("id", "frost_binding"))
	if not slot.cooldown_ready(key) or not slot.stamina.can_spend():
		return
	slot.stamina.spend(float(a1.get("stamina_cost", 15.0)))
	slot.start_cooldown(key, float(a1.get("cooldown_s", 8.0)))
	var windup := float(a1.get("windup_s", 0.25))
	var a := PlayerAction.new(key, windup + 0.3)
	a.steer = 0.0
	a.data["fired"] = false
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["fired"] or act.elapsed < windup:
			return
		act.data["fired"] = true
		var w := float(a1.get("width_m", 4.0))
		var h := float(a1.get("height_m", 1.4))
		var near_x := pl.global_position.x + 0.3 * pl.facing
		var left := near_x if pl.facing > 0 else near_x - w
		var rect := Rect2(left, pl.global_position.y - 0.4, w, h)
		var p := spell_packet(pl, float(a1.get("motion", 0.4)), float(a1.get("posture", 5.0)),
			str(a1.get("element", "frost")), float(a1.get("buildup", 60.0)))
		p.aoe = true
		p.tags["ability"] = key
		var field := FrostField.spawn(pl.fx_parent, pl.world, p, rect, float(a1.get("duration_s", 3.0)))
		field.hit_landed.connect(pl.report_hit)
		if bool(a1.get("freezes_water", true)):
			GameEvents.frost_field_cast.emit(rect, float(a1.get("duration_s", 3.0)))
		Sfx.play("frost")
	player.start_action(a)


## Aether Shield: a 3 s barrier that absorbs magic hits and destroys enemy projectiles.
func ability_2(player: Player) -> void:
	var a2: Dictionary = data.get("ability_2", {})
	var slot := player.loadout.active()
	var key := str(a2.get("id", "aether_shield"))
	if not slot.cooldown_ready(key):
		return
	slot.start_cooldown(key, float(a2.get("cooldown_s", 10.0)))
	player.raise_aether_shield(float(a2.get("duration_s", 3.0)), float(a2.get("radius_m", 1.6)))


## Aether Burst: a 3 m radial blast on arrival, knockback and Aether build-up. Echo: against a
## Poisoned enemy, the poison spreads to every enemy hit.
func resonance_action(player: Player) -> PlayerAction:
	var r: Dictionary = data.get("resonance", {})
	var windup := float(r.get("windup_s", 0.12))
	var a := PlayerAction.new("aether_burst", windup + 0.3)
	a.set_iframes(0.0, windup + 0.1)
	a.data["fired"] = false
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["fired"] or act.elapsed < windup:
			return
		act.data["fired"] = true
		var centre := Vector2(pl.global_position.x, pl.global_position.y + 0.9)
		var targets: Array[Node3D] = []
		pl.world.query_radius(centre, float(r.get("radius_m", 3.0)), CombatWorld.TEAM_ENEMY, targets)
		var spread := false
		for t in targets:
			var st: Variant = t.get("status")
			if st is StatusEffects and (st as StatusEffects).has_status("poisoned"):
				spread = true
		for t in targets:
			var p := spell_packet(pl, float(r.get("motion", 1.0)), float(r.get("posture", 20.0)),
				str(r.get("element", "aether")), float(r.get("build_up", 40.0)))
			p.is_resonance = true
			p.aoe = true
			p.knockback = float(r.get("knockback_m", 2.5))
			p.source_x = pl.global_position.x
			p.tags["ability"] = "aether_burst"
			p.result = t.call("receive_hit", p)
			pl.report_hit(t, p)
			var st: Variant = t.get("status")
			if spread and st is StatusEffects:
				(st as StatusEffects).add_buildup("venom", 1000.0)
		GameEvents.ultimate_fx_requested.emit("aether_burst", pl.global_position, float(r.get("radius_m", 3.0)))
		Sfx.play("shockwave")
	a.cancel_after = windup + 0.15
	a.cancel_into = PackedStringArray(["attack", "dodge", "ability"])
	return a


## Sync Guard: a short Aether Shield raised the moment a big magic hit arrives.
func sync_guard(player: Player, _p: DamagePacket) -> bool:
	var sg: Dictionary = data.get("sync_guard", {})
	player.raise_aether_shield(float(sg.get("shield_s", 1.0)), 1.6)
	return true


## Fraction of max HP a magic hit must reach before the Sync Guard steps in.
func sync_guard_fraction() -> float:
	return float(data.get("sync_guard", {}).get("fraction", 0.25))


## Cataclysm Fused: a storm of meteors over 5 s, each one Aether and Frost on the enemies under it.
func ultimate_action(player: Player) -> PlayerAction:
	var u: Dictionary = data.get("ultimate", {})
	var meteors := int(u.get("meteors", 10))
	var duration := float(u.get("duration_s", 5.0))
	var a := PlayerAction.new("cataclysm_fused", duration)
	a.hyper_armor = true
	a.set_iframes(0.0, duration)
	a.steer = 0.0
	a.data["done"] = 0
	a.on_start = func(pl: Player, _act: PlayerAction) -> void:
		GameEvents.ultimate_fx_requested.emit("cataclysm_fused", pl.global_position, float(u.get("radius_m", 7.0)))
		Sfx.play("ultimate")
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		var due := mini(int(floorf(act.elapsed / (duration / float(meteors)))) + 1, meteors)
		var elements: Array = u.get("elements", ["aether", "frost"])
		while int(act.data["done"]) < due:
			var n := int(act.data["done"])
			act.data["done"] = n + 1
			var targets: Array[Node3D] = []
			var centre := Vector2(pl.global_position.x, pl.global_position.y + 0.9)
			pl.world.query_radius(centre, float(u.get("radius_m", 7.0)), CombatWorld.TEAM_ENEMY, targets)
			if targets.is_empty():
				continue
			var t: Node3D = targets[n % targets.size()]
			var p := spell_packet(pl, float(u.get("motion", 1.0)), float(u.get("posture", 15.0)),
				str(elements[n % elements.size()]), float(u.get("buildup", 25.0)))
			p.aoe = true
			p.source_x = t.global_position.x
			p.tags["ability"] = "cataclysm_fused"
			p.result = t.call("receive_hit", p)
			pl.report_hit(t, p)
			_drop_meteor(pl, t.global_position, str(elements[n % elements.size()]))
			GameEvents.ultimate_fx_requested.emit("meteor", t.global_position, 1.2)
			GameEvents.camera_shake_requested.emit(0.2)
	return a


## A falling star for one Cataclysm hit: drops from 6 m onto `where` in 0.22 s and vanishes.
func _drop_meteor(player: Player, where: Vector3, element: String) -> void:
	if player.fx_parent == null or not player.is_inside_tree():
		return
	var col := FROST_COLOR if element == "frost" else Color(0.7, 0.5, 1.0)
	var m := VfxShapes.bolt(col, 0.35)
	player.fx_parent.add_child(m)
	var land := where + Vector3(0.0, 0.5, 0.0)
	m.global_position = land + Vector3(-1.5, 6.0, 0.0)
	var tw := m.create_tween()
	tw.tween_property(m, "global_position", land, 0.22).set_ease(Tween.EASE_IN)
	tw.tween_callback(m.queue_free)


func ability_cooldown_keys() -> PackedStringArray:
	return PackedStringArray(["frost_binding", "aether_shield"])
