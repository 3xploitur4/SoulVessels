extends TestCase
## Story 033: the Drowned Courtier and the Choir Prelate (addendum enemy table).
## Prelate: a golden aura gives allies within 8 m +30 % ATK and DEF, Unravel (Aether) strips it,
## and it teleports when the player comes close. Courtier: waits under water, rises to slash,
## and Frost freezes it in place for longer while it is in water.

var world: CombatWorld
var holder: Node3D


func before_each() -> void:
	holder = add_node(Node3D.new()) as Node3D
	world = CombatWorld.new()
	holder.add_child(world)


func _enemy(id: String, x: float) -> EnemyBase:
	var e := EnemyFactory.create(id)
	e.world = world
	holder.add_child(e)
	e.global_position = Vector3(x, 0.05, 0.0)
	return e


func test_both_are_built_by_the_factory() -> void:
	assert_true(EnemyFactory.create("drowned_courtier") is DrownedCourtier)
	assert_true(EnemyFactory.create("choir_prelate") is ChoirPrelate)


func test_aura_buffs_allies_in_eight_metres_only() -> void:
	var prelate := _enemy("choir_prelate", 0.0)
	var near := _enemy("echo_crawler", 5.0)
	var far := _enemy("echo_crawler", 12.0)
	await wait_frames(20)
	assert_almost(near.buff_multiplier(), 1.3)
	assert_almost(far.buff_multiplier(), 1.0)
	assert_almost(prelate.buff_multiplier(), 1.0, 0.001, "not itself")


func test_a_buffed_ally_hits_harder_and_takes_less() -> void:
	_enemy("choir_prelate", 0.0)
	var near := _enemy("echo_crawler", 5.0)
	await wait_frames(20)
	var p := near.call("_make_packet", {"motion": 1.0}) as DamagePacket
	assert_almost(p.atk, float(near.data.get("atk")) * 1.3, 0.01)


func test_unravel_strips_the_aura() -> void:
	var prelate := _enemy("choir_prelate", 0.0)
	var near := _enemy("echo_crawler", 5.0)
	await wait_frames(20)
	prelate.status.apply("unraveled", 5.0)
	await wait_frames(60)
	assert_almost(near.buff_multiplier(), 1.0, 0.001, "the buff faded within a second")
	assert_false(prelate.aura_active())


func test_prelate_teleports_only_when_the_player_is_close() -> void:
	var prelate := _enemy("choir_prelate", 0.0) as ChoirPrelate
	assert_true(prelate.wants_teleport(2.5))
	assert_false(prelate.wants_teleport(4.0))


func test_teleport_waits_for_its_cooldown() -> void:
	var prelate := _enemy("choir_prelate", 0.0) as ChoirPrelate
	prelate.call("_start_teleport_cooldown")
	assert_false(prelate.wants_teleport(1.0))


func test_teleport_goes_to_the_side_away_from_the_player() -> void:
	assert_almost(ChoirPrelate.teleport_x(10.0, 12.0, 7.0), 3.0, 0.001, "player to the right: jump left")
	assert_almost(ChoirPrelate.teleport_x(10.0, 8.0, 7.0), 17.0, 0.001, "player to the left: jump right")


func test_courtier_freezes_longer_in_water() -> void:
	assert_almost(DrownedCourtier.freeze_seconds(true, 2.0, 4.0), 4.0)
	assert_almost(DrownedCourtier.freeze_seconds(false, 2.0, 4.0), 2.0)


func test_courtier_in_water_is_held_by_frost() -> void:
	var w := Water.new()
	w.setup("pool", Vector2(-5.0, 5.0), 0.0, 2.5)
	holder.add_child(w)
	var c := _enemy("drowned_courtier", 0.0) as DrownedCourtier
	await wait_frames(3)
	assert_true(c.in_water())
	c.status.add_buildup("frost", 200.0)
	await wait_frames(2)
	assert_true(c.frozen_in_place())
	assert_gt(c.status.active.get("frozen", 0.0), 3.0, "Freeze lengthened to the in-water time")


func test_courtier_on_dry_land_is_not_held() -> void:
	var c := _enemy("drowned_courtier", 0.0) as DrownedCourtier
	await wait_frames(3)
	assert_false(c.in_water())
	c.status.add_buildup("frost", 200.0)
	await wait_frames(2)
	assert_false(c.frozen_in_place())


func test_submerged_courtier_cannot_be_hit_except_by_frost() -> void:
	var w := Water.new()
	w.setup("pool", Vector2(-5.0, 5.0), 0.0, 2.5)
	holder.add_child(w)
	var c := _enemy("drowned_courtier", 0.0) as DrownedCourtier
	await wait_frames(3)
	assert_true(c.submerged)
	var p := DamagePacket.new()
	p.atk = 40.0
	assert_eq(c.receive_hit(p), DamagePacket.Result.IGNORED)
	p.element = "frost"
	p.element_buildup = 200.0
	assert_ne(c.receive_hit(p), DamagePacket.Result.IGNORED)
	assert_true(c.frozen_in_place())


func test_one_frost_binding_freezes_a_courtier_in_water_but_not_on_land() -> void:
	# Found in play: Frost Binding gives 60 build-up of 100, so it never froze a Courtier.
	var w := Water.new()
	w.setup("pool", Vector2(-5.0, 5.0), 0.0, 2.5)
	holder.add_child(w)
	var wet := _enemy("drowned_courtier", 0.0) as DrownedCourtier
	var dry := _enemy("drowned_courtier", 20.0) as DrownedCourtier
	await wait_frames(3)
	for c: DrownedCourtier in [wet, dry]:
		var p := DamagePacket.new()
		p.atk = 1.0
		p.element = "frost"
		p.element_buildup = 60.0
		c.receive_hit(p)
	assert_true(wet.status.has_status("frozen"), "in water")
	assert_false(dry.status.has_status("frozen"), "on land")
