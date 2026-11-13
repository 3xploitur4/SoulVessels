extends TestCase
## Story 004: the addendum damage formula and the pure combat predicates.


func test_damage_with_zero_def_equals_atk_times_motion() -> void:
	# Caelan 40 ATK, first combo hit 1.0, Echo Crawler 0 DEF.
	assert_almost(CombatMath.damage(40.0, 1.0, 0.0), 40.0)


func test_damage_with_def_follows_100_over_100_plus_def() -> void:
	# 40 x 1.0 x 100 / 130 = 30.769
	assert_almost(CombatMath.damage(40.0, 1.0, 30.0), 30.769, 0.01)


func test_nyra_backstab_crit_multiplies_through() -> void:
	# 32 ATK x 0.6 motion x crit 1.5 x backstab 2.5 = 72 against 0 DEF.
	assert_almost(CombatMath.damage(32.0, 0.6, 0.0, 1.5, 1.0, 2.5), 72.0)


func test_negative_def_is_clamped_to_zero() -> void:
	assert_almost(CombatMath.damage(10.0, 1.0, -50.0), 10.0)


func test_element_multiplier_weakness_resist_neutral() -> void:
	assert_almost(CombatMath.element_multiplier("frost", ["frost"], [], 1.5, 0.5), 1.5)
	assert_almost(CombatMath.element_multiplier("venom", [], ["venom"], 1.5, 0.5), 0.5)
	assert_almost(CombatMath.element_multiplier("ember", ["frost"], ["venom"], 1.5, 0.5), 1.0)
	assert_almost(CombatMath.element_multiplier("", ["frost"], [], 1.5, 0.5), 1.0, 0.001, "no element")


func test_backstab_is_behind_the_facing() -> void:
	# Target at x=0 looking right (+1): an attacker on the left is behind.
	assert_true(CombatMath.is_backstab(-1.0, 0.0, 1))
	assert_false(CombatMath.is_backstab(1.0, 0.0, 1))
	assert_true(CombatMath.is_backstab(1.0, 0.0, -1))
	assert_false(CombatMath.is_backstab(0.0, 0.0, 1), "same x is never a backstab")


func test_frontal_arc_and_shield_fraction() -> void:
	assert_true(CombatMath.hits_frontal_arc(2.0, 0.0, 1, 120.0))
	assert_false(CombatMath.hits_frontal_arc(-2.0, 0.0, 1, 120.0), "behind the shield")
	assert_true(CombatMath.hits_frontal_arc(-2.0, 0.0, 1, 360.0), "no shield gap")
	# Branded Warden: 80 % blocked from the front.
	assert_almost(CombatMath.shielded_damage(100.0, true, true, 0.8), 20.0)
	assert_almost(CombatMath.shielded_damage(100.0, false, true, 0.8), 100.0)
	assert_almost(CombatMath.shielded_damage(100.0, true, false, 0.8), 100.0, 0.001, "shield broken")


func test_perfect_parry_window_edges() -> void:
	# Window 0.18 s: a block 0.17 s before the hit parries, 0.19 s does not, after the hit never.
	assert_true(CombatMath.is_perfect_parry(0.83, 1.0, 0.18))
	assert_false(CombatMath.is_perfect_parry(0.81, 1.0, 0.18))
	assert_true(CombatMath.is_perfect_parry(0.82, 1.0, 0.18), "inclusive edge")
	assert_false(CombatMath.is_perfect_parry(1.01, 1.0, 0.18), "block after impact")


func test_perfect_dodge_needs_iframes_and_tight_timing() -> void:
	# Dodge at t=0, i-frames 0.05..0.30, perfect window 0.1 after they begin.
	assert_true(CombatMath.is_perfect_dodge(0.0, 0.10, 0.05, 0.25, 0.1))
	assert_false(CombatMath.is_perfect_dodge(0.0, 0.20, 0.05, 0.25, 0.1), "in i-frames, not perfect")
	assert_false(CombatMath.is_perfect_dodge(0.0, 0.02, 0.05, 0.25, 0.1), "before i-frames")


func test_crit_roll_uses_injected_rng() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var hits := 0
	for _i in range(10000):
		if CombatMath.roll_crit(0.2, rng):
			hits += 1
	assert_gt(hits, 1800.0, "Nyra 20 % crit, lower bound")
	assert_lt(hits, 2200.0, "Nyra 20 % crit, upper bound")


func test_posture_damage_and_missing_hp_bonus() -> void:
	assert_almost(CombatMath.posture_damage(12.0, 1.2), 14.4)
	assert_almost(CombatMath.posture_damage(12.0, 2.5, 1.2), 36.0)
	# Last Survivor: +1 % per 2 % missing, cap 50 %.
	assert_almost(CombatMath.missing_hp_bonus(50.0, 100.0, 0.01, 0.02, 0.5), 0.25)
	assert_almost(CombatMath.missing_hp_bonus(0.0, 100.0, 0.01, 0.02, 0.5), 0.5, 0.001, "capped")
	assert_almost(CombatMath.missing_hp_bonus(100.0, 100.0, 0.01, 0.02, 0.5), 0.0)
