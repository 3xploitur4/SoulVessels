class_name Loadout
extends RefCounted
## Up to 3 equipped Vessels and the swap rule (addendum "Swapping"): 1.5 s global cooldown,
## inactive Vessels regen stamina at 2x. Pure: the player owns the body, i-frames and the
## Resonance Strike; this only decides who is active and when a swap is allowed.
##
##     var lo := Loadout.new()
##     lo.add(VesselSlot.create("caelan", 3))
##     if lo.can_swap(): lo.swap_to(1)

const MAX_SLOTS := 3

var slots: Array[VesselSlot] = []
var active_index: int = 0
var swap_cooldown_s: float = 1.5
var inactive_regen_multiplier: float = 2.0
var swap_cooldown_left: float = 0.0


static func from_balance() -> Loadout:
	var lo := Loadout.new()
	lo.swap_cooldown_s = Balance.combat_f("swap.cooldown_s")
	lo.inactive_regen_multiplier = Balance.combat_f("stamina.inactive_regen_multiplier")
	return lo


## Append a slot; false when full.
func add(slot: VesselSlot) -> bool:
	if slots.size() >= MAX_SLOTS:
		return false
	slots.append(slot)
	return true


func active() -> VesselSlot:
	return slots[active_index] if active_index < slots.size() else null


func size() -> int:
	return slots.size()


func index_of(vessel_id: String) -> int:
	for i in range(slots.size()):
		if slots[i].id == vessel_id:
			return i
	return -1


func can_swap() -> bool:
	return slots.size() > 1 and swap_cooldown_left <= 0.0


## Index of the next (`direction` +1) or previous (-1) slot, wrapping.
func neighbour(direction: int) -> int:
	if slots.is_empty():
		return 0
	return posmod(active_index + direction, slots.size())


## Make `index` active. A normal swap needs `can_swap()` and starts the cooldown; a `free` swap
## (Sync Guard pulling an inactive Vessel in) ignores and does not start it.
func swap_to(index: int, free: bool = false) -> bool:
	if index < 0 or index >= slots.size() or index == active_index:
		return false
	if not free and not can_swap():
		return false
	active_index = index
	if not free:
		swap_cooldown_left = swap_cooldown_s
	return true


## Sum of every equipped Vessel's HP bonus (the soul pool grows with the loadout).
func hp_bonus_total() -> float:
	var total := 0.0
	for s in slots:
		total += s.stat("hp_bonus")
	return total


func tick(delta: float) -> void:
	swap_cooldown_left = maxf(swap_cooldown_left - delta, 0.0)
	for i in range(slots.size()):
		slots[i].tick(delta, i == active_index, inactive_regen_multiplier)
