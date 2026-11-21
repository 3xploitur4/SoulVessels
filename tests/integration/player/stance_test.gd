extends TestCase
## Story 060: crouching (down held on the ground) and the slow walk (the walk key, or a stick pushed
## part way).

var player: Player
var arena: Node3D


func before_each() -> void:
	arena = Node3D.new()
	add_node(arena)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60.0, 1.0, 4.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	arena.add_child(floor_body)
	player = Player.new()
	player.vessel_ids = ["caelan"] as Array[String]
	arena.add_child(player)
	await wait_frames(10)


func after_each() -> void:
	for a in ["move_down", "move_right", "walk"]:
		Input.action_release(a)


func test_down_on_the_ground_crouches_low_and_slow() -> void:
	var full := player.hurt_rect().size.y
	Input.action_press("move_down")
	await wait_frames(4)
	assert_true(player.crouching)
	assert_eq(player.state, "crouch")
	assert_lt(player.hurt_rect().size.y, full * 0.7, "chest-high attacks pass over")
	Input.action_press("move_right")
	await wait_frames(30)
	assert_eq(player.state, "crouch_walk")
	assert_lt(absf(player.velocity.x), player.stat("move_speed") * 0.4, "slow")
	Input.action_release("move_down")
	await wait_frames(4)
	assert_false(player.crouching, "standing again")


func test_the_walk_key_walks_slowly() -> void:
	Input.action_press("walk")
	Input.action_press("move_right")
	await wait_frames(40)
	assert_eq(player.state, "walk")
	var walk_speed := player.stat("move_speed") * Balance.combat_f("movement.walk_mult")
	assert_almost(absf(player.velocity.x), walk_speed, 0.3)
	Input.action_release("walk")
	await wait_frames(40)
	assert_eq(player.state, "run", "letting go runs again")
