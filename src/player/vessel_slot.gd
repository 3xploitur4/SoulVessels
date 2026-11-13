class_name VesselSlot
extends RefCounted
## One equipped Vessel: its data, kit, own stamina and hidden posture, Affinity, ability
## cooldowns and Sync Guard lockout (addendum: "Stamina and Posture are per Vessel").
##
##     var slot := VesselSlot.create("caelan", 3)
##     if slot.cooldown_ready("kings_judgment"): slot.start_cooldown("kings_judgment", 6.0)

var id: String = ""
var data: Dictionary = {}
var kit: VesselKit
var stamina: Stamina
var posture: Posture
var affinity: int = 0
var sync_guard_left: float = 0.0
var cooldowns: Dictionary[String, float] = {}
## Built by the player; shown only while active.
var visual: Node3D


## Build a slot from Balance data. `affinity` comes from the save (the sandbox sets it).
static func create(vessel_id: String, vessel_affinity: int) -> VesselSlot:
	var s := VesselSlot.new()
	s.id = vessel_id
	s.data = Balance.vessel(vessel_id)
	s.kit = VesselKit.create(vessel_id, s.data)
	s.stamina = Stamina.from_balance()
	s.posture = Posture.for_player()
	s.affinity = vessel_affinity
	return s


## A stat from `data.stats`, with the Affinity 3 +5 % applied to atk/def.
func stat(key: String) -> float:
	var stats: Dictionary = data.get("stats", {})
	var v := float(stats.get(key, 0.0))
	if affinity >= 3 and (key == "atk" or key == "def"):
		v *= 1.05
	return v


func cooldown_ready(name: String) -> bool:
	return cooldowns.get(name, 0.0) <= 0.0


func cooldown_left(name: String) -> float:
	return maxf(cooldowns.get(name, 0.0), 0.0)


func start_cooldown(name: String, seconds: float) -> void:
	cooldowns[name] = seconds


## Advance timers. Inactive Vessels regen stamina at `inactive_regen_multiplier`.
func tick(delta: float, active: bool, inactive_multiplier: float) -> void:
	stamina.tick(delta, 1.0 if active else inactive_multiplier)
	posture.tick(delta)
	sync_guard_left = maxf(sync_guard_left - delta, 0.0)
	for key: String in cooldowns.keys():
		cooldowns[key] = maxf(cooldowns[key] - delta, 0.0)
