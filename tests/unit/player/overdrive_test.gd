extends TestCase
## Story 046: Overdrive (addendum "Overdrive (3 bars, after the Leviathan)": two Ultimates back to
## back with a combined finisher; unlocked by the Pure Soul Matrix).

class Dummy extends Node3D:
	var team: int = CombatWorld.TEAM_ENEMY
	var rect := Rect2(1.0, 0.0, 1.0, 2.0)
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
var dummy: Dummy


func before_each() -> void:
	holder = add_node(Node3D.new()) as Node3D
	world = CombatWorld.new()
	add_node(world)
	player = Player.new()
	player.world = world
	player.fx_parent = holder
	player.vessel_ids = ["caelan", "nyra"]
	add_node(player)
	for v in ["caelan", "nyra"]:
		player.set_affinity(v, 3)
	dummy = Dummy.new()
	add_node(dummy)
	world.register(dummy)


func test_the_rule_for_starting_it() -> void:
	assert_true(Player.overdrive_allowed(true, 3, 2))
	assert_false(Player.overdrive_allowed(false, 3, 2), "not before the Matrix")
	assert_false(Player.overdrive_allowed(true, 2, 2), "needs a full gauge")
	assert_false(Player.overdrive_allowed(true, 3, 1), "needs a second Vessel")


func test_with_two_bars_the_ultimate_is_a_plain_ultimate() -> void:
	player.overdrive_unlocked = true
	player.gauge.add(200.0)
	assert_true(player.try_ultimate())
	assert_eq(player.overdrive_stage, 0)


func test_it_chains_both_ultimates_then_a_finisher() -> void:
	player.overdrive_unlocked = true
	player.gauge.add(300.0)
	assert_true(player.try_ultimate())
	assert_eq(player.overdrive_stage, 1)
	assert_almost(player.gauge.value, 0.0, 0.01, "the gauge empties")
	var vessels: Array[String] = [player.loadout.active().id]
	var finisher := false
	for i in range(900):
		await wait_frames(1)
		# The test world has no floor: keep the dummy beside the falling player.
		dummy.rect = Rect2(player.global_position.x + 1.0, player.global_position.y, 1.0, 2.0)
		assert_true(player.is_invulnerable() or player.overdrive_stage == 0, "invulnerable throughout")
		var v := player.loadout.active().id
		if not vessels.has(v):
			vessels.append(v)
		for p in dummy.packets:
			if str(p.tags.get("ability", "")) == "overdrive_finisher":
				finisher = true
		if player.overdrive_stage == 0:
			break
	assert_eq(vessels, ["caelan", "nyra"], "Caelan's Ultimate, then Nyra's")
	assert_true(finisher, "the combined finisher hits")
	assert_eq(player.overdrive_stage, 0)


func test_the_ready_state_needs_the_unlock() -> void:
	player.gauge.add(300.0)
	assert_false(player.overdrive_ready())
	player.overdrive_unlocked = true
	assert_true(player.overdrive_ready())
