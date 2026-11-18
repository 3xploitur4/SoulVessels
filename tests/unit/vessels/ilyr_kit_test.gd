extends TestCase
## Story 047: Ilyr's Chapter I kit (addendum kit table): a 4-hit dimensional blade, Fracture (a
## 3 s spatial tear), Distortion (pulls an enemy in), Null Space (a blink that erases projectiles)
## and Echo (every 5th attack repeats at 70 %).

class Dummy extends Node3D:
	var team: int = CombatWorld.TEAM_ENEMY
	var rect := Rect2(3.0, 0.0, 1.0, 2.0)
	var packets: Array[DamagePacket] = []
	var facing: int = -1

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
	player.vessel_ids = ["ilyr"]
	add_node(player)


func _kit() -> IlyrKit:
	return player.loadout.active().kit as IlyrKit


func test_ilyr_has_his_own_four_hit_kit() -> void:
	assert_true(player.loadout.active().kit is IlyrKit)
	assert_eq(_kit().combo_length(), 4)


func test_every_fifth_attack_echoes() -> void:
	assert_false(IlyrKit.echo_due(4, 5))
	assert_true(IlyrKit.echo_due(5, 5))
	assert_true(IlyrKit.echo_due(10, 5))


func test_the_echo_repeats_a_hit_at_seventy_percent() -> void:
	var d := Dummy.new()
	add_node(d)
	world.register(d)
	var p := player.make_packet(1.0, 10.0)
	p.is_primary = true
	for i in range(5):
		_kit().on_primary_landed(player, d, p)
	assert_eq(d.packets.size(), 1, "one echo after five hits")
	assert_almost(d.packets[0].motion, 0.7, 0.001)


func test_fracture_tears_for_three_seconds() -> void:
	var d := Dummy.new()
	add_node(d)
	world.register(d)
	player.set_facing(1)
	_kit().ability_1_released(player, 0.0)
	await wait_frames(200)
	assert_gt(d.packets.size(), 3, "it ticked several times (%d)" % d.packets.size())
	assert_lt(d.packets.size(), 9)


func test_distortion_pulls_the_nearest_enemy_in() -> void:
	var e := EnemyFactory.create("echo_crawler")
	e.world = world
	holder.add_child(e)
	e.global_position = Vector3(6.0, 0.05, 0.0)
	await wait_frames(2)
	player.set_facing(1)
	_kit().ability_2(player)
	await wait_frames(2)
	assert_lt(e.global_position.x, 2.5, "pulled to Ilyr (x %.2f)" % e.global_position.x)


func test_null_space_erases_projectiles_it_passes() -> void:
	var p := DamagePacket.new()
	var orb := Projectile.spawn(holder, world, p, Vector2(2.0, 1.0), Vector2(-0.5, 0.0), Vector2(0.4, 0.4))
	orb.target_team = CombatWorld.TEAM_PLAYER
	orb.lifetime = 5.0
	await wait_frames(2)
	player.set_facing(1)
	_kit().erase_projectiles(player, Vector2(0.0, 1.0), Vector2(5.0, 1.0))
	await wait_frames(2)
	assert_false(is_instance_valid(orb) and not orb.is_queued_for_deletion(), "the orb was erased")


func test_fracture_shows_a_short_cast_pose_any_input_cuts() -> void:
	_kit().ability_1_released(player, 0.0)
	assert_not_null(player.action, "a pose starts")
	assert_eq(player.action.id, "fracture")
	assert_eq(player.action.cancel_after, 0.0, "cancellable at once")
	assert_eq(player.action.steer, 1.0, "full steering")
	assert_true(_kit().data.size() > 0)
	assert_true(VesselSpriteVisual.clip_for_rig("fracture", {"fracture": {}}) == "fracture", "the rig plays its own clip")
