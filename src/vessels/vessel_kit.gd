class_name VesselKit
extends RefCounted
## What a Vessel does with each button. The base class builds the data-driven primary combo and
## dodge; subclasses (CaelanKit, NyraKit) add abilities, the Resonance Strike, Sync Guard and the
## Sync Ultimate. A kit never owns nodes: it builds `PlayerAction`s and calls the player's API.
##
##     var kit := VesselKit.create("caelan", Balance.vessel("caelan"))
##     player.start_action(kit.primary_action(player, 0))

var id: String = ""
var data: Dictionary = {}


## The kit for `vessel_id`: CaelanKit, NyraKit, or the plain base kit for Vessels whose full kit
## arrives in a later milestone (they still attack, dodge and swap).
static func create(vessel_id: String, vessel_data: Dictionary) -> VesselKit:
	var kit: VesselKit
	match vessel_id:
		"caelan":
			kit = CaelanKit.new()
		"nyra":
			kit = NyraKit.new()
		_:
			kit = VesselKit.new()
	kit.id = vessel_id
	kit.data = vessel_data
	return kit


## Number of hits in the primary chain.
func combo_length() -> int:
	return (data.get("primary", {}).get("hits", []) as Array).size()


## Seconds after the last hit's end before the chain resets to hit 0.
func combo_reset_s() -> float:
	return float(data.get("primary", {}).get("combo_reset_s", 0.6))


## The `index`th primary hit as an action. Timings scale by attack speed.
func primary_action(player: Player, index: int) -> PlayerAction:
	var hits: Array = data.get("primary", {}).get("hits", [])
	if hits.is_empty():
		return null
	var h: Dictionary = hits[clampi(index, 0, hits.size() - 1)]
	var speed := maxf(player.stat("attack_speed"), 0.1)
	var windup := float(h.get("windup_s", 0.12)) / speed
	var active := float(h.get("active_s", 0.1)) / speed
	var recover := float(h.get("recover_s", 0.2)) / speed
	var reach := float(h.get("range_m", 2.0))
	var a := PlayerAction.new("primary_%d" % index, windup + active + recover)
	a.cancel_after = windup + active
	a.cancel_into = PackedStringArray(["attack", "dodge", "jump", "ability"])
	a.set_velocity(1.6, 0.0, windup + active)
	a.gravity_scale = 0.55
	a.data["combo_index"] = index
	a.data["windup"] = windup
	a.data["active"] = active
	var p := player.make_packet(float(h.get("motion", 1.0)), float(h.get("posture", 10.0)))
	p.is_primary = true
	p.heavy = bool(h.get("heavy", false))
	a.add_hit(ActionHit.new(windup, windup + active, Vector2(reach * 0.5 + 0.15, 1.0),
		Vector2(reach, 1.7), p))
	if p.heavy:
		a.on_start = func(pl: Player, _act: PlayerAction) -> void:
			var slot := pl.loadout.active()
			if slot.stamina.can_spend():
				slot.stamina.spend(Balance.combat_f("stamina.heavy_cost"))
	return a


## The ground dodge for this Vessel (roll, flip, blink...). Null when it cannot be paid.
func dodge_action(player: Player) -> PlayerAction:
	var d: Dictionary = data.get("dodge", {})
	var slot := player.loadout.active()
	if not slot.stamina.can_spend():
		return null
	var cost := float(d.get("stamina_cost", Balance.combat_f("stamina.dodge_cost")))
	var duration := Balance.combat_f("dodge.roll_s")
	if str(d.get("kind", "roll")) == "flip":
		duration *= 0.85
	var iframe_start := Balance.combat_f("dodge.iframe_start_s")
	var iframe_len := Balance.combat_f("dodge.iframe_s")
	var cancel := Balance.combat_f("dodge.cancel_window_s")
	slot.stamina.spend(cost)
	var a := PlayerAction.new("dodge", duration)
	a.set_iframes(iframe_start, iframe_start + iframe_len)
	a.set_velocity(float(d.get("distance_m", 3.0)) / (duration - cancel), 0.0, duration - cancel)
	a.cancel_after = duration - cancel
	a.cancel_into = PackedStringArray(["attack"])
	a.data["kind"] = str(d.get("kind", "roll"))
	return a


## Air-dash: once per airborne period, horizontal, i-frames throughout.
func air_dash_action(player: Player) -> PlayerAction:
	var slot := player.loadout.active()
	if not slot.stamina.can_spend():
		return null
	slot.stamina.spend(Balance.combat_f("stamina.air_dash_cost"))
	var duration := Balance.combat_f("dodge.air_dash_s")
	var a := PlayerAction.new("air_dash", duration)
	a.set_iframes(0.0, Balance.combat_f("dodge.air_dash_iframe_s"))
	a.set_velocity(Balance.combat_f("dodge.air_dash_distance_m") / duration, 0.0, duration)
	a.velocity_y = 0.0
	a.gravity_scale = 0.0
	a.cancel_after = duration * 0.8
	a.cancel_into = PackedStringArray(["attack"])
	return a


## Ability 1 pressed this frame.
func ability_1_pressed(_player: Player) -> void:
	pass


## Ability 1 still held, `held_s` seconds since the press.
func ability_1_held(_player: Player, _held_s: float) -> void:
	pass


## Ability 1 released after `held_s` seconds.
func ability_1_released(_player: Player, _held_s: float) -> void:
	pass


func ability_2(_player: Player) -> void:
	pass


## The Resonance Strike played on swap-in, or null.
func resonance_action(_player: Player) -> PlayerAction:
	return null


## The Sync Ultimate, or null. The player has already checked bars and Affinity.
func ultimate_action(_player: Player) -> PlayerAction:
	return null


## The automatic Sync Guard. Return true when it handled the hit. `p` is the incoming hit.
func sync_guard(_player: Player, _p: DamagePacket) -> bool:
	return false


## What triggers this kit's Sync Guard ("lethal_blow", "unblockable_hit", ...).
func sync_guard_trigger() -> String:
	return str(data.get("sync_guard", {}).get("trigger", ""))


## Called after a perfect parry by this Vessel.
func on_perfect_parry(_player: Player, _attacker: Node3D, _p: DamagePacket) -> void:
	pass


## Multiplier on damage this Vessel takes (Iron Resolve).
func damage_taken_multiplier(_player: Player, _blocking: bool) -> float:
	return 1.0


## Ids and cooldown keys for the HUD's two ability buttons.
func ability_cooldown_keys() -> PackedStringArray:
	return PackedStringArray([str(data.get("ability_1", {}).get("id", "")),
		str(data.get("ability_2", {}).get("id", ""))])
