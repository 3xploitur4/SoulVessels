extends TestCase
## Story 008: Caelan and Nyra kits build their actions from data.

var world: CombatWorld
var player: Player


func before_each() -> void:
	world = CombatWorld.new()
	add_node(world)
	player = Player.new()
	player.world = world
	player.vessel_ids = ["caelan", "nyra"]
	add_node(player)


func test_kits_are_the_right_classes() -> void:
	assert_true(player.loadout.slots[0].kit is CaelanKit)
	assert_true(player.loadout.slots[1].kit is NyraKit)
	assert_true(VesselKit.create("seris", Balance.vessel("seris")) is VesselKit)


func test_caelan_combo_motion_values_from_data() -> void:
	var kit := player.loadout.slots[0].kit
	assert_eq(kit.combo_length(), 4)
	var motions: Array[float] = []
	for i in range(4):
		var a := kit.primary_action(player, i)
		motions.append(a.hits[0].packet.motion)
	assert_eq(motions, [1.0, 1.0, 1.2, 1.6])
	assert_true(kit.primary_action(player, 3).hits[0].packet.heavy, "the 4th hit is heavy")


func test_caelan_hit_window_follows_windup() -> void:
	var a := player.loadout.slots[0].kit.primary_action(player, 0)
	assert_almost(a.hits[0].start, 0.14, 0.001)
	assert_almost(a.hits[0].end, 0.24, 0.001)
	assert_almost(a.cancel_after, 0.24, 0.001, "cancel into the next hit after the active frames")


func test_nyra_flurry_is_faster_by_attack_speed() -> void:
	player.try_swap(1, true)
	var kit := player.loadout.active().kit
	assert_eq(kit.combo_length(), 6)
	var a := kit.primary_action(player, 0)
	var raw := 0.08 + 0.08 + 0.10
	assert_almost(a.duration, raw / 1.6, 0.001, "1.6x attack speed")


func test_iron_resolve_multipliers() -> void:
	var kit := player.loadout.slots[0].kit
	assert_almost(kit.damage_taken_multiplier(player, false), 0.85)
	assert_almost(kit.damage_taken_multiplier(player, true), 0.70)


func test_kings_judgment_respects_cooldown_and_stamina() -> void:
	var kit := player.loadout.slots[0].kit
	kit.ability_2(player)
	assert_eq(player.action.id, "kings_judgment")
	assert_almost(player.loadout.active().stamina.value, 85.0, 0.001, "15 stamina")
	assert_almost(player.loadout.active().cooldown_left("kings_judgment"), 6.0, 0.001)
	player.stop_action()
	kit.ability_2(player)
	assert_null(player.action, "on cooldown: nothing starts")


func test_resonance_packets_are_flagged() -> void:
	var lunge := player.loadout.slots[0].kit.resonance_action(player)
	assert_true(lunge.hits[0].packet.is_resonance)
	assert_almost(lunge.hits[0].packet.posture, 60.0, 0.001, "Oathbreaker Lunge: 60 posture")
	assert_eq(lunge.hits[0].packet.tags["echo"]["against"], "frozen")
	player.try_swap(1, true)
	var arrival := player.loadout.active().kit.resonance_action(player)
	assert_true(arrival.hits[0].packet.force_backstab, "Severing Arrival: guaranteed backstab")
	assert_eq(arrival.hits[0].packet.tags["echo"]["against"], "staggered")


func test_sync_guard_triggers_from_data() -> void:
	assert_eq(player.loadout.slots[0].kit.sync_guard_trigger(), "lethal_blow")
	assert_eq(player.loadout.slots[1].kit.sync_guard_trigger(), "unblockable_hit")


func test_counterstrike_follows_a_perfect_parry() -> void:
	var kit := player.loadout.slots[0].kit
	kit.on_perfect_parry(player, null, DamagePacket.new())
	assert_eq(player.action.id, "counterstrike")
	assert_almost(player.action.hits[0].packet.motion, 1.5, 0.001)
