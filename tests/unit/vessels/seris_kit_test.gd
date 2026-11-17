extends TestCase
## Story 030: Seris's kit (addendum "Ability mapping"): Arcane Bolt, Frost Binding, Aether Shield,
## Rift Step breaking a root-snare, and her spell-damage passive.

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
	player.vessel_ids = ["seris", "caelan"]
	add_node(player)


func _dummy(x: float) -> Dummy:
	var d := Dummy.new()
	d.rect = Rect2(x - 0.4, 0.0, 0.8, 1.8)
	add_node(d)
	world.register(d)
	return d


func test_seris_gets_her_own_kit() -> void:
	assert_true(player.loadout.slots[0].kit is SerisKit)
	assert_eq(player.loadout.slots[0].kit.combo_length(), 3, "Arcane Bolt is a 3-shot chain")


func test_passive_adds_ten_percent_per_enemy_up_to_thirty() -> void:
	assert_almost(SerisKit.spell_multiplier(0, 0.1, 0.3), 1.0)
	assert_almost(SerisKit.spell_multiplier(2, 0.1, 0.3), 1.2)
	assert_almost(SerisKit.spell_multiplier(5, 0.1, 0.3), 1.3, 0.001, "capped at +30 %")


func test_passive_counts_only_enemies_within_ten_metres() -> void:
	_dummy(3.0)
	_dummy(8.0)
	_dummy(14.0)
	var kit := player.loadout.slots[0].kit as SerisKit
	assert_eq(kit.enemies_near(player), 2)


func test_arcane_bolt_is_a_magic_aether_projectile_with_twenty_metre_range() -> void:
	var kit := player.loadout.slots[0].kit as SerisKit
	var proj := kit.fire_bolt(player, 0)
	assert_not_null(proj)
	assert_almost(proj.max_distance, 20.0)
	assert_eq(proj.packet.element, "aether")
	assert_almost(proj.packet.element_buildup, 12.0)
	assert_eq(proj.packet.kind, DamagePacket.KIND_MAGIC)
	assert_true(proj.is_in_group(SerisKit.BOLT_GROUP), "rune doors and mirrors find bolts by group")


func test_arcane_bolt_stops_at_twenty_metres() -> void:
	var far := _dummy(21.5)
	var kit := player.loadout.slots[0].kit as SerisKit
	kit.fire_bolt(player, 0)
	await wait_frames(70)
	assert_eq(far.packets.size(), 0, "a target past 20 m is never reached")


func test_frost_binding_builds_frost_once_on_enemies_inside_the_field() -> void:
	var inside := _dummy(1.5)
	var outside := _dummy(6.0)
	var field := FrostField.spawn(holder, world, player.make_packet(0.4, 5.0),
		Rect2(-0.5, 0.0, 4.0, 1.4), 3.0)
	field.packet.element = "frost"
	field.packet.element_buildup = 60.0
	await wait_frames(6)
	assert_eq(inside.packets.size(), 1, "hit once, not every frame")
	assert_almost(inside.packets[0].element_buildup, 60.0)
	assert_eq(outside.packets.size(), 0)
	field.queue_free()


func test_frost_binding_has_an_eight_second_cooldown() -> void:
	var kit := player.loadout.slots[0].kit
	var slot := player.loadout.slots[0]
	kit.ability_1_released(player, 0.0)
	assert_almost(slot.cooldown_left("frost_binding"), 8.0)
	player.stop_action()
	slot.stamina.value = slot.stamina.max_value
	kit.ability_1_released(player, 0.0)
	assert_eq(player.action, null, "a second cast during the cooldown does nothing")


func test_aether_shield_absorbs_magic_hits() -> void:
	var kit := player.loadout.slots[0].kit
	kit.ability_2(player)
	assert_almost(player.loadout.slots[0].cooldown_left("aether_shield"), 10.0)
	var before := player.health.current
	var p := DamagePacket.new()
	p.atk = 50.0
	p.kind = DamagePacket.KIND_MAGIC
	p.source_x = 3.0
	assert_eq(player.receive_hit(p), DamagePacket.Result.BLOCKED)
	assert_almost(player.health.current, before)


func test_aether_shield_destroys_enemy_projectiles_it_touches() -> void:
	var kit := player.loadout.slots[0].kit
	kit.ability_2(player)
	var p := DamagePacket.new()
	p.kind = DamagePacket.KIND_MAGIC
	var orb := Projectile.spawn(holder, world, p, Vector2(1.0, 1.0), Vector2(-1.0, 0.0), Vector2(0.4, 0.4))
	orb.target_team = CombatWorld.TEAM_PLAYER
	orb.lifetime = 5.0
	await wait_frames(3)
	assert_false(is_instance_valid(orb) and not orb.is_queued_for_deletion(), "the orb is gone")


func test_shield_runs_out_after_three_seconds() -> void:
	player.loadout.slots[0].kit.ability_2(player)
	assert_almost(player.aether_shield_left, 3.0)


func test_rift_step_and_shadowstep_break_a_root_snare_caelan_does_not() -> void:
	assert_true(player.loadout.slots[0].kit.breaks_snare_on("dodge"))
	assert_false(player.loadout.slots[1].kit.breaks_snare_on("dodge"))
	var nyra := VesselKit.create("nyra", Balance.vessel("nyra"))
	assert_true(nyra.breaks_snare_on("ability_1"))
