extends TestCase
## Story 010: Branded Warden shield, guard break, riposte and Echo Bonus; Crawler AoE weakness.

var world: CombatWorld


func before_each() -> void:
	world = CombatWorld.new()
	add_node(world)


func _warden(facing: int) -> BrandedWarden:
	var w := BrandedWarden.new()
	w.world = world
	w.rng_seed = 7
	add_node(w)
	w.global_position = Vector3.ZERO
	w.facing = facing
	return w


func _packet(source_x: float, atk: float = 100.0) -> DamagePacket:
	var p := DamagePacket.new()
	p.atk = atk
	p.motion = 1.0
	p.posture = 10.0
	p.source_x = source_x
	return p


func test_frontal_hit_is_80_percent_blocked() -> void:
	var w := _warden(1)
	var front := _packet(2.0)
	assert_eq(w.receive_hit(front), DamagePacket.Result.SHIELDED)
	# 100 x 100 / 125 = 80, then 20 % gets through.
	assert_almost(front.dealt, 16.0, 0.01)


func test_hit_from_behind_ignores_the_shield_and_backstabs() -> void:
	var w := _warden(1)
	var back := _packet(-2.0)
	assert_eq(w.receive_hit(back), DamagePacket.Result.HIT)
	assert_true(back.was_backstab)
	assert_almost(back.dealt, 80.0 * 1.3, 0.01, "backstab 1.3x")


func test_counterstrike_opens_the_guard_for_2_s() -> void:
	var w := _warden(1)
	w.open_guard(2.0)
	assert_false(w.shield_up)
	var p := _packet(2.0)
	assert_eq(w.receive_hit(p), DamagePacket.Result.HIT, "guard open: full damage from the front")
	assert_almost(p.dealt, 80.0, 0.01)


func test_crushing_blow_breaks_the_shield_for_good() -> void:
	var w := _warden(1)
	var p := _packet(2.0)
	p.breaks_shield = true
	w.receive_hit(p)
	assert_true(w.shield_broken)
	assert_false(w.shield_up)


func test_posture_break_then_riposte_doubles_and_ends_stagger() -> void:
	var w := _warden(1)
	w.open_guard(5.0)
	var heavy := _packet(2.0, 1.0)
	heavy.posture = 220.0
	w.receive_hit(heavy)
	assert_true(w.posture.is_staggered())
	var riposte := _packet(2.0)
	riposte.is_primary = true
	w.receive_hit(riposte)
	assert_true(riposte.was_riposte)
	assert_almost(riposte.dealt, 160.0, 0.01, "2x on a staggered enemy")
	assert_false(w.posture.is_staggered(), "a riposte ends the stagger")


func test_echo_bonus_guaranteed_crit_vs_staggered() -> void:
	var w := _warden(1)
	w.open_guard(5.0)
	var heavy := _packet(2.0, 1.0)
	heavy.posture = 220.0
	w.receive_hit(heavy)
	var p := _packet(2.0)
	p.crit_chance = 0.0
	p.tags["echo"] = {"against": "staggered", "guaranteed_crit": true}
	w.receive_hit(p)
	assert_true(p.was_crit)


func test_crawler_takes_50_percent_more_from_aoe() -> void:
	var c := EchoCrawler.new()
	c.world = world
	add_node(c)
	c.facing = 1
	var single := _packet(2.0, 10.0)
	c.receive_hit(single)
	var area := _packet(2.0, 10.0)
	area.aoe = true
	c.receive_hit(area)
	assert_almost(area.dealt, single.dealt * 1.5, 0.01)


func test_perfect_parry_hook_adds_posture_and_cancels_the_attack() -> void:
	var w := _warden(1)
	w.on_parried(null, 35.0)
	assert_almost(w.posture.value, 35.0, 0.01)
	assert_eq(w.state, EnemyBase.STATE_RECOVER)
