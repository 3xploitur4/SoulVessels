extends TestCase
## Story 006/007: stamina, posture, health, status effects and the Soul Gauge.


func _stamina() -> Stamina:
	var s := Stamina.new()
	s.max_value = 100.0
	s.value = 100.0
	s.regen_per_s = 40.0
	s.regen_delay_s = 0.6
	s.exhausted_s = 1.5
	return s


func test_stamina_regen_waits_for_delay_then_runs_at_40_per_s() -> void:
	var s := _stamina()
	assert_true(s.spend(20.0))
	s.tick(0.5)
	assert_almost(s.value, 80.0, 0.001, "no regen inside the 0.6 s delay")
	s.tick(0.1)
	s.tick(0.25)
	assert_almost(s.value, 80.0 + 40.0 * 0.25, 0.01, "regen only after the 0.6 s delay")


func test_inactive_vessel_regens_twice_as_fast() -> void:
	var a := _stamina()
	var b := _stamina()
	a.spend(50.0)
	b.spend(50.0)
	a.tick(1.0)
	b.tick(1.0, 2.0)
	assert_almost(a.value, 66.0, 0.01, "0.4 s of regen past the delay")
	assert_almost(b.value - 50.0, 2.0 * (a.value - 50.0), 0.01)


func test_zero_stamina_exhausts_for_1_5_s() -> void:
	var s := _stamina()
	s.spend(60.0)
	assert_true(s.spend(60.0), "allowed while above 0, souls rule")
	assert_almost(s.value, 0.0)
	assert_true(s.is_exhausted())
	assert_false(s.can_spend(), "no dodge while exhausted")
	s.tick(1.4)
	assert_true(s.is_exhausted())
	s.tick(0.2)
	assert_false(s.is_exhausted())
	assert_true(s.can_spend(), "regen started after the delay")


func test_restore_lifts_exhaustion() -> void:
	var s := _stamina()
	s.spend(100.0)
	assert_true(s.is_exhausted())
	s.restore(15.0)
	assert_false(s.is_exhausted(), "perfect parry gives 15 back")
	assert_almost(s.value, 15.0)


func _posture(max_v: float) -> Posture:
	var p := Posture.new()
	p.max_value = max_v
	p.drain_per_s = 10.0
	p.drain_delay_s = 2.0
	p.stagger_s = 2.5
	return p


func test_posture_fills_to_stagger_and_resets() -> void:
	var p := _posture(40.0)
	assert_false(p.add(35.0))
	assert_true(p.add(10.0), "the hit that fills the bar breaks it")
	assert_true(p.is_staggered())
	assert_almost(p.value, 0.0)
	assert_false(p.add(50.0), "no posture while staggered")
	p.tick(2.4)
	assert_true(p.is_staggered())
	p.tick(0.2)
	assert_false(p.is_staggered(), "2.5 s stagger")


func test_posture_drains_after_2_s_without_hits() -> void:
	var p := _posture(100.0)
	p.add(50.0)
	p.tick(1.9)
	assert_almost(p.value, 50.0)
	p.tick(0.1)
	p.tick(1.0)
	assert_almost(p.value, 40.0, 0.01, "10/s after the delay")


func test_riposte_ends_stagger_early() -> void:
	var p := _posture(10.0)
	p.add(10.0)
	assert_true(p.is_staggered())
	p.end_stagger()
	assert_false(p.is_staggered())


func test_health_damage_clamps_and_dies_once() -> void:
	var h := Health.new(90.0)
	var deaths := [0]
	h.died.connect(func() -> void: deaths[0] += 1)
	assert_almost(h.damage(40.0), 40.0)
	assert_almost(h.damage(80.0), 50.0, 0.001, "only what was left")
	assert_true(h.is_dead())
	assert_almost(h.damage(10.0), 0.0)
	assert_eq(deaths[0], 1)


func test_status_buildup_triggers_and_expires() -> void:
	var s := StatusEffects.new({"frost": {"threshold": 100, "decay_per_s": 0, "freeze_s": 2.0,
		"slow": 0.3, "frozen_damage_taken": 1.25}})
	assert_false(s.add_buildup("frost", 60.0))
	assert_true(s.is_chilled())
	assert_almost(s.move_multiplier(), 0.7, 0.001, "chill -30 %")
	assert_true(s.add_buildup("frost", 60.0))
	assert_true(s.has_status("frozen"))
	assert_almost(s.move_multiplier(), 0.0)
	assert_almost(s.damage_taken_multiplier(), 1.25)
	s.tick(2.1)
	assert_false(s.has_status("frozen"))


func test_venom_dot_is_2_percent_max_hp() -> void:
	var s := StatusEffects.new({"venom": {"threshold": 100, "pct_max_hp_per_s": 0.02, "duration_s": 6}})
	s.add_buildup("venom", 100.0)
	assert_almost(s.dot_per_s(900.0), 18.0)


func _gauge() -> SoulGauge:
	var g := SoulGauge.new()
	g._gains = {"per_hit": 2, "per_perfect_parry": 10, "per_kill": 5, "per_10_damage_taken": 1}
	return g


func test_soul_gauge_gains_and_bars() -> void:
	var g := _gauge()
	for _i in range(50):
		g.gain("per_hit")
	assert_almost(g.value, 100.0)
	assert_eq(g.bars(), 1)
	g.gain("per_perfect_parry")
	g.gain("per_kill")
	assert_almost(g.value, 115.0)
	g.add(1000.0)
	assert_almost(g.value, 300.0, 0.001, "capped at 3 bars")
	assert_true(g.spend_bars(2))
	assert_almost(g.value, 100.0)
	assert_false(g.spend_bars(2), "not enough bars")


func test_soul_gauge_damage_taken_carries_remainder() -> void:
	var g := _gauge()
	g.gain_from_damage_taken(15.0)
	assert_almost(g.value, 1.0)
	g.gain_from_damage_taken(5.0)
	assert_almost(g.value, 2.0, 0.001, "15 + 5 = 20 damage = 2 points")


func test_soul_gauge_drains_only_out_of_combat() -> void:
	var g := _gauge()
	g.add(50.0)
	g.mark_combat()
	g.tick(5.0)
	assert_almost(g.value, 50.0)
	g.tick(1.0)
	g.tick(2.0)
	assert_almost(g.value, 48.0, 0.01, "1/s after 6 s calm")
