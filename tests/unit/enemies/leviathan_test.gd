extends TestCase
## Story 045: the Abyssal Leviathan (addendum boss table): 12 eyes of 300 HP, every 3 destroyed a
## 5 s stagger; phase 2 plunges the arena into darkness with only its eyes lit; strikes from behind
## in the dark; 2 parryable, 2 unblockable, 1 magic per phase; its fall unlocks Overdrive.

var world: CombatWorld
var holder: Node3D


func before_each() -> void:
	holder = add_node(Node3D.new()) as Node3D
	world = CombatWorld.new()
	holder.add_child(world)


func _leviathan() -> AbyssalLeviathan:
	var l := EnemyFactory.create("abyssal_leviathan") as AbyssalLeviathan
	l.world = world
	l.boundary_source = func(_a: float) -> float: return -1.0
	holder.add_child(l)
	l.global_position = Vector3(20.0, 0.05, 0.0)
	return l


func _hit(atk: float) -> DamagePacket:
	var p := DamagePacket.new()
	p.atk = atk
	p.posture = 50.0
	p.crit_chance = 0.0
	p.source_x = 16.0
	return p


func test_it_has_twelve_eyes_of_three_hundred() -> void:
	var l := _leviathan()
	await wait_frames(2)
	assert_eq(l.eyes.size(), 12)
	assert_almost(l.eyes[0].hp, 300.0)
	assert_eq(l.eyes_left(), 12)


func test_every_third_eye_destroyed_staggers_it_five_seconds() -> void:
	var l := _leviathan()
	await wait_frames(2)
	l.eyes[0].receive_hit(_hit(320.0))
	l.eyes[1].receive_hit(_hit(320.0))
	assert_false(l.posture.is_staggered())
	l.eyes[2].receive_hit(_hit(320.0))
	assert_eq(l.eyes_left(), 9)
	assert_true(l.posture.is_staggered(), "three eyes: stagger")
	assert_almost(l.posture.stagger_left(), 5.0, 0.05)


func test_eye_damage_also_wounds_it() -> void:
	var l := _leviathan()
	await wait_frames(2)
	var hp := l.health.current
	l.eyes[0].receive_hit(_hit(100.0))
	assert_lt(l.health.current, hp)
	assert_lt(l.eyes[0].hp, 300.0)


func test_body_hits_build_no_posture() -> void:
	var l := _leviathan()
	await wait_frames(2)
	l.receive_hit(_hit(100.0))
	assert_almost(l.posture.value, 0.0, 0.001)


func test_every_phase_has_two_parryable_two_unblockable_one_magic() -> void:
	var data := Balance.enemy("abyssal_leviathan")
	for ph in range(3):
		var count := {"parryable": 0, "unblockable": 0, "magic": 0}
		for a: Dictionary in data.get("attacks", []):
			var phases: Array = a.get("phases", [])
			if phases.has(ph) or phases.has(float(ph)):
				var k := str(a.get("kind", ""))
				if count.has(k):
					count[k] += 1
		assert_true(count["parryable"] >= 2 and count["unblockable"] >= 2 and count["magic"] >= 1,
			"phase %d: %s" % [ph + 1, str(count)])


func test_phase_two_brings_the_dark_with_only_its_eyes_lit() -> void:
	var l := _leviathan()
	await wait_frames(2)
	l.health.current = l.health.max_value * 0.64
	l.receive_hit(_hit(10.0))
	assert_eq(l.phase, 1)
	await wait_frames(2)
	assert_not_null(l.darkness)
	assert_eq((l.darkness.glow_points.call() as Dictionary).size(), 12, "every live eye glows")
	await wait_frames(100)
	l.eyes[0].receive_hit(_hit(320.0))
	assert_eq((l.darkness.glow_points.call() as Dictionary).size(), 11)


func test_phase_three_lifts_the_dark() -> void:
	var l := _leviathan()
	await wait_frames(2)
	l.health.current = l.health.max_value * 0.64
	l.receive_hit(_hit(10.0))
	await wait_frames(100)
	l.health.current = l.health.max_value * 0.29
	l.receive_hit(_hit(10.0))
	assert_eq(l.phase, 2)
	assert_almost(l.darkness._target, 0.0, 0.001, "fading out")


func test_a_blindside_strike_comes_from_behind_the_player() -> void:
	assert_almost(AbyssalLeviathan.blindside_x(10.0, 1, 3.0), 7.0, 0.001, "player faces right: from the left")
	assert_almost(AbyssalLeviathan.blindside_x(10.0, -1, 3.0), 13.0, 0.001)


func test_its_fall_unlocks_overdrive_and_ends_darius_distrust() -> void:
	var od: Dictionary = Balance.enemy("abyssal_leviathan").get("on_defeat", {})
	assert_eq(str(od.get("flag")), "boss_abyssal_leviathan")
	assert_true((od.get("flags", []) as Array).has("unlock_overdrive"))
	assert_true((od.get("flags", []) as Array).has("rift_open"))
