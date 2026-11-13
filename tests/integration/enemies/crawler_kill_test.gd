extends TestCase
## Story 010 (integration): the addendum's tuning target "a common enemy dies in 3-5 hits with no
## upgrades" for Caelan vs an Echo Crawler, with real hit rects and the combo chain.

var world: CombatWorld
var player: Player


func before_each() -> void:
	world = CombatWorld.new()
	add_node(world)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100.0, 1.0, 10.0)
	shape.shape = box
	floor_body.add_child(shape)
	add_node(floor_body)
	floor_body.global_position = Vector3(0.0, -0.5, 0.0)
	player = Player.new()
	player.world = world
	add_node(player)
	player.global_position = Vector3(0.0, 0.05, 0.0)


func after_each() -> void:
	Input.action_release("attack")


func test_caelan_kills_a_crawler_in_3_to_5_hits() -> void:
	var c := EchoCrawler.new()
	c.world = world
	c.rng_seed = 3
	add_node(c)
	c.global_position = Vector3(1.6, 0.05, 0.0)
	c.facing = -1
	await wait_frames(5)
	var hits := 0
	var last_hp := c.health.current
	for _i in range(8):
		if not c.is_alive():
			break
		Input.action_press("attack")
		await wait_frames(1)
		Input.action_release("attack")
		await wait_frames(30)
		if c.health.current < last_hp:
			hits += 1
			last_hp = c.health.current
		# Keep it in reach: the lunge or knockback can move it.
		c.global_position.x = player.global_position.x + 1.6 * float(player.facing)
	assert_false(c.is_alive(), "crawler still alive at %.1f HP" % c.health.current)
	assert_true(hits >= 3 and hits <= 5, "took %d hits" % hits)
