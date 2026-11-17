extends TestCase
## Story 041: Darius (addendum kit table): hyper-armored hammer, Crushing Blow, Groundbreaker,
## shoulder charge, Last Survivor, the 1 HP Sync Guard, Worldbreaker, his AoE killing Crawlers
## outright, and his distrust (Affinity XP x0.75 until the Leviathan falls).

class Dummy extends Node3D:
	var team: int = CombatWorld.TEAM_ENEMY
	var rect := Rect2(2.0, 0.0, 1.0, 2.0)
	var packets: Array[DamagePacket] = []

	func hurt_rect() -> Rect2:
		return rect

	func receive_hit(p: DamagePacket) -> DamagePacket.Result:
		packets.append(p)
		return DamagePacket.Result.HIT

	func is_alive() -> bool:
		return true


var world: CombatWorld
var player: Player
var holder: Node3D


func before_each() -> void:
	holder = add_node(Node3D.new()) as Node3D
	world = CombatWorld.new()
	add_node(world)
	player = Player.new()
	player.world = world
	player.fx_parent = holder
	player.vessel_ids = ["darius", "caelan"]
	add_node(player)


func _kit() -> DariusKit:
	return player.loadout.slots[0].kit as DariusKit


func test_darius_gets_his_own_kit_with_a_hyper_armored_three_hit_combo() -> void:
	assert_true(player.loadout.slots[0].kit is DariusKit)
	assert_eq(_kit().combo_length(), 3)
	assert_true(_kit().primary_action(player, 0).hyper_armor)


func test_last_survivor_adds_one_percent_per_two_percent_missing_up_to_fifty() -> void:
	assert_almost(DariusKit.last_survivor(1.0, 0.01, 0.02, 0.5), 1.0)
	assert_almost(DariusKit.last_survivor(0.8, 0.01, 0.02, 0.5), 1.1)
	assert_almost(DariusKit.last_survivor(0.0, 0.01, 0.02, 0.5), 1.5, 0.001, "capped")


func test_his_packets_carry_last_survivor() -> void:
	var full := player.make_packet(1.0, 1.0).atk
	player.health.current = player.health.max_value * 0.5
	assert_almost(player.make_packet(1.0, 1.0).atk, full * 1.25, 0.01)


func test_crushing_blow_breaks_shields_and_masonry_with_150_posture() -> void:
	var a := _kit().crushing_blow_action(player)
	var p := a.hits[0].packet
	assert_true(p.breaks_shield)
	assert_true(bool(p.tags.get("breaks_masonry", false)))
	assert_almost(p.posture, 150.0, 0.01)


func test_sync_guard_leaves_him_at_one_hp_with_last_survivor_at_full() -> void:
	player.set_affinity("darius", 3)
	player.gauge.add(300.0)
	var p := DamagePacket.new()
	p.atk = 9999.0
	p.source_x = player.global_position.x + 1.0
	player.receive_hit(p)
	assert_almost(player.health.current, 1.0, 0.001)
	assert_almost(_kit().damage_dealt_multiplier(player), 1.5, 0.001, "3 s of Last Survivor at maximum")


func test_his_heavy_aoe_kills_a_crawler_outright() -> void:
	var crawler := EnemyFactory.create("echo_crawler")
	crawler.world = world
	holder.add_child(crawler)
	await wait_frames(2)
	var p := player.make_packet(0.1, 1.0)
	p.aoe = true
	p.tags["heavy_aoe"] = true
	crawler.receive_hit(p)
	assert_false(crawler.is_alive(), "Darius's AoE kills Crawlers instantly")


func test_a_plain_aoe_does_not() -> void:
	var crawler := EnemyFactory.create("echo_crawler")
	crawler.world = world
	holder.add_child(crawler)
	await wait_frames(2)
	var p := player.make_packet(0.1, 1.0)
	p.aoe = true
	crawler.receive_hit(p)
	assert_true(crawler.is_alive())


func test_worldbreaker_breaks_every_enemy_posture_in_range() -> void:
	var near := EnemyFactory.create("branded_warden")
	near.world = world
	holder.add_child(near)
	near.global_position = Vector3(6.0, 0.05, 0.0)
	await wait_frames(2)
	_kit().worldbreaker_strike(player)
	assert_true(near.posture.is_staggered())


func test_distrust_slows_his_affinity_until_the_leviathan_falls() -> void:
	var gs := GameState.new_game("normal")
	assert_almost(Affinity.xp_multiplier(gs, "darius"), 0.75)
	assert_almost(Affinity.xp_multiplier(gs, "caelan"), 1.0)
	gs.set_flag("boss_abyssal_leviathan")
	assert_almost(Affinity.xp_multiplier(gs, "darius"), 1.0)
	Affinity.add_xp(gs, "darius", "kill", 10.0)
	assert_almost(float(gs.affinity_xp.get("darius", 0.0)), Affinity.xp_for("kill") * 10.0)
