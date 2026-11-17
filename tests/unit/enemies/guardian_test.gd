extends TestCase
## Story 044: the Guardian Below (addendum boss table): posture only from its fists (phases 1-2)
## and its core (phase 3), the elevator tilting 15 degrees in phase 2 with rocks sliding every 6 s,
## +40 % attack speed in phase 3, and 2 parryable, 2 unblockable, 1 magic attack per phase.

var world: CombatWorld
var holder: Node3D


func before_each() -> void:
	holder = add_node(Node3D.new()) as Node3D
	world = CombatWorld.new()
	holder.add_child(world)


func _guardian() -> GuardianBelow:
	var g := EnemyFactory.create("guardian_below") as GuardianBelow
	g.world = world
	g.boundary_source = func(_a: float) -> float: return -1.0
	holder.add_child(g)
	g.global_position = Vector3(12.0, 0.05, 0.0)
	return g


func _hit(posture: float) -> DamagePacket:
	var p := DamagePacket.new()
	p.atk = 100.0
	p.posture = posture
	p.crit_chance = 0.0
	p.source_x = 9.0
	return p


func test_which_zone_builds_posture_in_which_phase() -> void:
	assert_true(GuardianBelow.posture_counts("fist", 0))
	assert_true(GuardianBelow.posture_counts("fist", 1))
	assert_false(GuardianBelow.posture_counts("fist", 2))
	assert_false(GuardianBelow.posture_counts("core", 0))
	assert_true(GuardianBelow.posture_counts("core", 2))
	assert_false(GuardianBelow.posture_counts("body", 0))


func test_every_phase_has_two_parryable_two_unblockable_one_magic() -> void:
	var data := Balance.enemy("guardian_below")
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


func test_a_fist_hit_builds_posture_and_the_core_is_armoured_early() -> void:
	var g := _guardian()
	await wait_frames(2)
	g.zone_hit(_hit(50.0), "fist")
	assert_gt(g.posture.value, 0.0)
	var hp := g.health.current
	assert_eq(g.zone_hit(_hit(50.0), "core"), DamagePacket.Result.SHIELDED, "the core is closed in phase 1")
	assert_almost(g.health.current, hp, 0.01)


func test_the_core_opens_in_phase_three() -> void:
	var g := _guardian()
	await wait_frames(2)
	g.health.current = g.health.max_value * 0.29
	g.zone_hit(_hit(0.0), "fist")
	await wait_frames(2)
	assert_eq(g.phase, 2)
	await wait_frames(100)
	var before := g.posture.value
	g.zone_hit(_hit(40.0), "core")
	assert_gt(g.posture.value, before, "core hits now build posture")
	assert_true(g.core_open())


func test_phase_two_tilts_the_elevator() -> void:
	var z := SlideZone.new()
	z.setup(Vector2(0.0, 30.0), Vector2(0.0, 3.0), 0.0)
	holder.add_child(z)
	var g := _guardian()
	await wait_frames(2)
	g.health.current = g.health.max_value * 0.64
	g.zone_hit(_hit(0.0), "fist")
	assert_eq(g.phase, 1)
	await wait_frames(150)
	assert_almost(z.angle, 15.0, 0.1)


func test_phase_three_attacks_faster() -> void:
	var g := _guardian()
	await wait_frames(2)
	var a: Dictionary = (Balance.enemy("guardian_below")["attacks"] as Array)[0]
	var normal := float(g.scaled_attack(a)["telegraph_s"])
	g.health.current = g.health.max_value * 0.29
	g.zone_hit(_hit(0.0), "fist")
	assert_almost(float(g.scaled_attack(a)["telegraph_s"]), normal / 1.4, 0.001)


func test_rocks_roll_every_six_seconds_from_phase_two() -> void:
	var g := _guardian()
	await wait_frames(2)
	assert_eq(g.rock_interval(), 0.0, "none in phase 1")
	g.health.current = g.health.max_value * 0.6
	g.zone_hit(_hit(0.0), "fist")
	assert_almost(g.rock_interval(), 6.0)
