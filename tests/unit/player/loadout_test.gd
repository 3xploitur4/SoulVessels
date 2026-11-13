extends TestCase
## Story 009: the swap rules and per-Vessel slots.


func _loadout() -> Loadout:
	var lo := Loadout.new()
	lo.swap_cooldown_s = 1.5
	lo.inactive_regen_multiplier = 2.0
	lo.add(VesselSlot.create("caelan", 3))
	lo.add(VesselSlot.create("nyra", 3))
	return lo


func test_swap_starts_the_global_cooldown() -> void:
	var lo := _loadout()
	assert_true(lo.can_swap())
	assert_true(lo.swap_to(1))
	assert_eq(lo.active().id, "nyra")
	assert_false(lo.can_swap(), "1.5 s cooldown")
	assert_false(lo.swap_to(0))
	lo.tick(1.4)
	assert_false(lo.can_swap())
	lo.tick(0.11)
	assert_true(lo.can_swap())


func test_free_swap_ignores_and_keeps_the_cooldown() -> void:
	var lo := _loadout()
	lo.swap_to(1)
	assert_true(lo.swap_to(0, true), "Sync Guard pulls a Vessel in during the cooldown")
	assert_almost(lo.swap_cooldown_left, 1.5, 0.001, "a free swap does not restart it")


func test_swap_to_self_or_out_of_range_fails() -> void:
	var lo := _loadout()
	assert_false(lo.swap_to(0))
	assert_false(lo.swap_to(5))
	assert_false(lo.swap_to(-1))


func test_neighbour_wraps() -> void:
	var lo := _loadout()
	assert_eq(lo.neighbour(1), 1)
	assert_eq(lo.neighbour(-1), 1)
	lo.swap_to(1)
	assert_eq(lo.neighbour(1), 0)


func test_three_slots_max() -> void:
	var lo := _loadout()
	assert_true(lo.add(VesselSlot.create("seris", 0)))
	assert_false(lo.add(VesselSlot.create("darius", 0)))


func test_hp_bonus_sums_the_loadout() -> void:
	var lo := _loadout()
	assert_almost(lo.hp_bonus_total(), 120.0 + 40.0, 0.001, "Caelan +120, Nyra +40")


func test_inactive_slot_regens_twice_as_fast() -> void:
	var lo := _loadout()
	lo.slots[0].stamina.spend(60.0)
	lo.slots[1].stamina.spend(60.0)
	lo.tick(1.0)
	var active_gain := lo.slots[0].stamina.value - 40.0
	var inactive_gain := lo.slots[1].stamina.value - 40.0
	assert_almost(inactive_gain, active_gain * 2.0, 0.01)


func test_affinity_3_adds_5_percent_atk() -> void:
	var low := VesselSlot.create("caelan", 2)
	var high := VesselSlot.create("caelan", 3)
	assert_almost(low.stat("atk"), 40.0)
	assert_almost(high.stat("atk"), 42.0)


func test_slot_cooldowns_tick_down() -> void:
	var s := VesselSlot.create("nyra", 3)
	s.start_cooldown("shadowstep", 3.0)
	assert_false(s.cooldown_ready("shadowstep"))
	s.tick(3.0, true, 2.0)
	assert_true(s.cooldown_ready("shadowstep"))
