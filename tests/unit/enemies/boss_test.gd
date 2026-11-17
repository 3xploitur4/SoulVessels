extends TestCase
## Story 034: the boss framework and the Weeping Sovereign (addendum boss table): phases at 60 %
## and 25 %, a 1.5 s invulnerable phase change that may stretch up to 1 s to land on the next
## 4-bar boundary, 4 s vulnerable at 2x damage after a full posture break, and at least 2
## parryable, 2 unblockable and 1 magic attack in every phase.

var world: CombatWorld
var holder: Node3D


func before_each() -> void:
	holder = add_node(Node3D.new()) as Node3D
	world = CombatWorld.new()
	holder.add_child(world)


func _sovereign() -> WeepingSovereign:
	var b := EnemyFactory.create("weeping_sovereign") as WeepingSovereign
	b.world = world
	b.boundary_source = func(_after: float) -> float: return -1.0
	holder.add_child(b)
	b.global_position = Vector3(10.0, 0.05, 0.0)
	return b


func _hit(atk: float, posture: float = 0.0) -> DamagePacket:
	var p := DamagePacket.new()
	p.atk = atk
	p.posture = posture
	p.crit_chance = 0.0
	p.source_x = 7.0
	return p


func test_phase_from_health_fraction() -> void:
	var at: Array[float] = [0.6, 0.25]
	assert_eq(Boss.phase_for_fraction(1.0, at), 0)
	assert_eq(Boss.phase_for_fraction(0.61, at), 0)
	assert_eq(Boss.phase_for_fraction(0.6, at), 1)
	assert_eq(Boss.phase_for_fraction(0.26, at), 1)
	assert_eq(Boss.phase_for_fraction(0.25, at), 2)
	assert_eq(Boss.phase_for_fraction(0.0, at), 2)


func test_transition_stretches_to_the_next_boundary_by_at_most_one_second() -> void:
	assert_almost(Boss.transition_length(1.5, -1.0, 1.0), 1.5, 0.001, "no music: the base time")
	assert_almost(Boss.transition_length(1.5, 1.9, 1.0), 1.9, 0.001, "boundary 0.4 s after the base")
	assert_almost(Boss.transition_length(1.5, 3.4, 1.0), 2.5, 0.001, "capped at base + 1 s")
	assert_almost(Boss.transition_length(1.5, 1.0, 1.0), 1.5, 0.001, "never shorter than the base")


func test_every_phase_has_two_parryable_two_unblockable_one_magic() -> void:
	var data := Balance.enemy("weeping_sovereign")
	var phases: Array = data.get("phases", [])
	assert_eq(phases.size(), 3)
	for ph in range(phases.size()):
		var count := {"parryable": 0, "unblockable": 0, "magic": 0}
		for a: Dictionary in data.get("attacks", []):
			if (a.get("phases", []) as Array).has(float(ph)) or (a.get("phases", []) as Array).has(ph):
				var k := str(a.get("kind", ""))
				if count.has(k):
					count[k] += 1
		assert_true(count["parryable"] >= 2 and count["unblockable"] >= 2 and count["magic"] >= 1,
			"phase %d: %s" % [ph + 1, str(count)])


func test_phase_three_burns() -> void:
	var data := Balance.enemy("weeping_sovereign")
	var ember := false
	for a: Dictionary in data.get("attacks", []):
		if (a.get("phases", []) as Array).has(2.0) and str(a.get("element", "")) == "ember":
			ember = true
	assert_true(ember)


func test_crossing_sixty_percent_starts_phase_two_and_its_invulnerable_change() -> void:
	var b := _sovereign()
	await wait_frames(2)
	var changes: Array[int] = []
	b.phase_changed.connect(func(p: int) -> void: changes.append(p))
	b.health.current = b.health.max_value * 0.62
	b.receive_hit(_hit(400.0))
	assert_eq(b.phase, 1)
	assert_eq(changes, [1])
	assert_true(b.in_transition())
	var hp := b.health.current
	assert_eq(b.receive_hit(_hit(400.0)), DamagePacket.Result.IGNORED, "invulnerable while it changes")
	assert_almost(b.health.current, hp)
	await wait_frames(100)
	assert_false(b.in_transition(), "hittable again after 1.5 s")


func test_a_posture_break_leaves_it_open_four_seconds_at_double_damage() -> void:
	var b := _sovereign()
	await wait_frames(2)
	var hp0 := b.health.current
	b.receive_hit(_hit(100.0))
	var normal := hp0 - b.health.current
	b.posture.add(b.posture.max_value)
	assert_true(b.posture.is_staggered())
	assert_almost(b.posture.stagger_left(), 4.0, 0.05)
	var hp1 := b.health.current
	var p := _hit(100.0)
	p.is_primary = true
	b.receive_hit(p)
	assert_almost(hp1 - b.health.current, normal * 2.0, 0.5, "2x, and a primary hit does not end it")
	assert_true(b.posture.is_staggered())


func test_phase_two_raises_the_arena_water() -> void:
	var w := Water.new()
	w.setup("arena", Vector2(0.0, 30.0), 0.0, 0.5)
	holder.add_child(w)
	var b := _sovereign()
	await wait_frames(2)
	b.health.current = b.health.max_value * 0.61
	b.receive_hit(_hit(400.0))
	await wait_frames(150)
	assert_almost(w.level, 2.0, 0.05, "rose 1.5 m")


func test_a_boss_is_its_own_tier_and_drops_its_whole_list() -> void:
	var data := Balance.enemy("weeping_sovereign")
	assert_eq(str(data.get("tier")), "boss")
	var lt := LootTable.from_data()
	var drops := lt.roll(data, "zone3", RandomNumberGenerator.new(), null)
	var items := drops.map(func(d: Dictionary) -> String: return str(d["item"]))
	assert_true(items.has("sovereigns_crown_fragment"), str(items))
