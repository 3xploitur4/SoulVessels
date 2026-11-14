extends TestCase
## Story 021 (integration, headless physics): wall-jump, bounce mushrooms, one-way platforms and
## falling out of a room, in small rooms built inline.

var world: CombatWorld
var player: Player
var rooms: RoomManager


func before_each() -> void:
	world = add_node(CombatWorld.new()) as CombatWorld
	player = Player.new()
	player.world = world
	player.vessel_ids = ["caelan"]
	add_node(player)
	rooms = RoomManager.new()
	rooms.world = world
	rooms.player = player
	add_node(rooms)


func after_each() -> void:
	for a in ["move_right", "move_left", "move_down", "jump"]:
		Input.action_release(a)


func _room(grid: Array) -> RoomData:
	return RoomData.parse("t_trav", "zone1", {"grid": grid})


## Hold jump for `frames` (releasing early cuts a jump short, by design).
func _tap_jump(frames: int = 14) -> void:
	Input.action_press("jump")
	await wait_frames(frames)
	Input.action_release("jump")


func test_wall_jump_climbs_a_shaft_between_two_walls() -> void:
	# Two walls three metres apart, twelve metres tall, a floor at the bottom.
	var grid: Array = []
	for i in range(13):
		grid.append("###...###")
	grid.append("#########")
	rooms.enter_data(_room(grid), "", Vector2(4.5, 1.0))
	await wait_frames(10)
	var side := "move_left"
	Input.action_press(side)
	await _tap_jump()
	var peak := player.global_position.y
	for i in range(420):
		await wait_frames(1)
		peak = maxf(peak, player.global_position.y)
		if not player.is_on_floor() and player.is_on_wall() and player.velocity.y < 6.0:
			Input.action_release(side)
			side = "move_right" if side == "move_left" else "move_left"
			Input.action_press(side)
			await _tap_jump()
		if peak > 9.0:
			break
	assert_gt(peak, 9.0, "climbed to %.1f m; a plain jump reaches about 3.2" % peak)


func test_wall_slide_caps_the_fall_while_pressing_in() -> void:
	var grid: Array = []
	for i in range(13):
		grid.append("###...###")
	grid.append("#########")
	rooms.enter_data(_room(grid), "", Vector2(3.4, 10.0))
	Input.action_press("move_left")
	var worst := 0.0
	for i in range(50):
		await wait_frames(1)
		if i > 20 and not player.is_on_floor():
			worst = minf(worst, player.velocity.y)
	assert_gt(worst, -float(Balance.combat("traversal.wall_slide_max_fall_mps")) - 0.6, "fell at %.1f m/s" % worst)
	assert_lt(worst, -1.0, "still slides down")


func test_bounce_mushroom_reaches_the_data_height() -> void:
	rooms.enter_data(_room([
		"..........",
		"..........",
		"..........",
		"..........",
		"..........",
		"..........",
		"..........",
		"..........",
		"..........",
		"..........",
		"..........",
		"##########",
	]), "", Vector2(5.0, 1.0))
	var m := BounceMushroom.new()
	m.player = player
	m.launch_speed = sqrt(2.0 * Balance.combat_f("movement.gravity") * Balance.combat_f("traversal.bounce_height_m"))
	rooms.features_root.add_child(m)
	m.global_position = Vector3(5.0, 1.0, 0.0)
	player.teleport(5.0, 3.0)
	var peak := 0.0
	for i in range(110):
		await wait_frames(1)
		peak = maxf(peak, player.global_position.y)
	var want := 1.0 + BounceMushroom.CAP_TOP + Balance.combat_f("traversal.bounce_height_m")
	assert_almost(peak, want, 0.6, "apex %.2f m, wanted about %.2f" % [peak, want])


func test_one_way_platform_passes_up_holds_and_drops() -> void:
	rooms.enter_data(_room([
		"......",
		"......",
		"......",
		".====.",
		"......",
		"######",
	]), "", Vector2(3.0, 1.0))
	await wait_frames(10)
	await _tap_jump()
	await wait_frames(70)
	assert_almost(player.global_position.y, 3.0, 0.1, "jumped up through and stands on the platform")
	Input.action_press("move_down")
	await wait_frames(2)
	await _tap_jump(2)
	await wait_frames(50)
	Input.action_release("move_down")
	assert_almost(player.global_position.y, 1.0, 0.1, "down + jump drops through")


func test_falling_out_of_a_room_is_reported_once() -> void:
	var fell: Array[int] = [0]
	rooms.fell_out.connect(func() -> void: fell[0] += 1)
	rooms.enter_data(_room([
		"......",
		"......",
		"###...",
	]), "", Vector2(1.5, 1.0))
	await wait_frames(10)
	assert_almost(rooms.last_safe.x, 1.5, 0.2)
	player.teleport(4.5, 1.0)
	await wait_frames(60)
	assert_eq(fell[0], 1)
	assert_almost(rooms.last_safe.x, 1.5, 0.2, "safe ground is still the ledge")
