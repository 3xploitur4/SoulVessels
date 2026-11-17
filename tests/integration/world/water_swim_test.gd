extends TestCase
## Story 031 (integration, headless physics): a player in a room with a pool floats up to the
## surface, swims slower than they run, jumps out from the surface, and stands on ice frozen by
## Frost Binding.

var world: CombatWorld
var player: Player
var rooms: RoomManager


func before_each() -> void:
	world = add_node(CombatWorld.new()) as CombatWorld
	player = Player.new()
	player.world = world
	player.vessel_ids = ["seris"]
	add_node(player)
	rooms = RoomManager.new()
	rooms.world = world
	rooms.player = player
	add_node(rooms)
	# A 20 m room; a 4 m deep pool between x 6 and 16 with its surface at y 4 (the banks are 4 m high).
	var grid: Array = []
	for i in range(6):
		grid.append("#..................#")
	for i in range(4):
		grid.append("######..........####")
	grid.append("####################")
	var d := {"grid": grid, "water": [{"id": "pool", "x": [6, 16], "level": 4.6, "floor": 1.0}]}
	rooms.enter_data(RoomData.parse("t_water", "zone3", d), "", Vector2(11.0, 1.2))


func after_each() -> void:
	for a in ["move_right", "move_left", "jump"]:
		Input.action_release(a)


func test_the_room_builds_its_pool() -> void:
	await wait_frames(2)
	var w := rooms.water("pool")
	assert_not_null(w)
	assert_almost(w.level, 4.6)


func test_a_player_at_the_bottom_floats_up_near_the_surface() -> void:
	await wait_frames(150)
	var y := player.global_position.y
	assert_gt(y, 2.6, "floated up from the bottom (y %.2f)" % y)
	assert_lt(y, 4.6, "stays in the water, head above it (y %.2f)" % y)
	assert_true(player.is_swimming())


func test_swimming_is_slower_than_running() -> void:
	await wait_frames(120)
	Input.action_press("move_right")
	await wait_frames(30)
	var swim_vx := absf(player.velocity.x)
	Input.action_release("move_right")
	assert_lt(swim_vx, player.stat("move_speed") * 0.7, "swim speed %.2f" % swim_vx)


func test_a_jump_at_the_surface_clears_the_bank() -> void:
	await wait_frames(150)
	player.teleport(15.2, player.global_position.y)
	Input.action_press("move_right")
	await wait_frames(4)
	Input.action_press("jump")
	await wait_frames(16)
	Input.action_release("jump")
	await wait_frames(60)
	assert_gt(player.global_position.x, 16.0, "out of the pool onto the bank (x %.2f)" % player.global_position.x)
	assert_almost(player.water_depth, 0.0)


func test_ice_from_frost_binding_holds_the_player_up() -> void:
	await wait_frames(2)
	var w := rooms.water("pool")
	GameEvents.frost_field_cast.emit(Rect2(8.0, 4.0, 4.0, 1.4), 3.0)
	assert_eq(w.patches.size(), 1, "the surface froze")
	player.teleport(10.0, 6.0)
	await wait_frames(60)
	assert_true(player.is_on_floor(), "standing on the ice")
	assert_gt(player.global_position.y, 4.4, "on top of it (y %.2f)" % player.global_position.y)


func test_walking_in_over_flat_ground_still_floats() -> void:
	# Found in play: walking from dry ground into standing water kept her on the floor, because
	# standing on the bottom skipped the water rule, so she never floated.
	var grid: Array = []
	for i in range(6):
		grid.append("#..................#")
	grid.append("####################")
	var d := {"grid": grid, "water": [{"id": "flat", "x": [6, 16], "level": 2.9, "floor": 0.95}]}
	rooms.enter_data(RoomData.parse("t_flat", "zone3", d), "", Vector2(2.0, 1.0))
	await wait_frames(20)
	Input.action_press("move_right")
	await wait_frames(80)
	Input.action_release("move_right")
	await wait_frames(90)
	assert_gt(player.water_depth, 0.5, "in the water")
	assert_gt(player.global_position.y, 1.4, "rose off the floor (y %.2f)" % player.global_position.y)
