extends TestCase
## Story 043 (integration): a room's sliding floor carries a player standing still downhill and
## slows running uphill; a dark room builds its overlay with the room's lamps.

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
	for a in ["move_right", "move_left"]:
		Input.action_release(a)


func _room(extra: Dictionary) -> RoomData:
	var grid: Array = []
	for i in range(6):
		grid.append("#......................................#")
	grid.append("########################################")
	var d := {"grid": grid}
	d.merge(extra)
	return RoomData.parse("t_slide", "zone4", d)


func test_standing_on_a_slope_slides_downhill() -> void:
	rooms.enter_data(_room({"slides": [{"x": [2, 37], "y": [1, 3], "angle": 15}]}), "", Vector2(10.0, 1.0))
	await wait_frames(90)
	assert_gt(player.global_position.x, 11.0, "slid right (x %.2f)" % player.global_position.x)


func test_running_uphill_is_slower_than_on_flat_ground() -> void:
	rooms.enter_data(_room({"slides": [{"x": [2, 37], "y": [1, 3], "angle": 15}]}), "", Vector2(30.0, 1.0))
	await wait_frames(10)
	Input.action_press("move_left")
	await wait_frames(40)
	var uphill := absf(player.velocity.x)
	Input.action_release("move_left")
	assert_lt(uphill, player.stat("move_speed") * 0.85, "uphill %.2f m/s" % uphill)


func test_a_dark_room_builds_its_overlay_with_lamps() -> void:
	rooms.enter_data(_room({"dark": true, "lamps": [[20, 3]]}), "", Vector2(10.0, 1.0))
	await wait_frames(3)
	assert_not_null(rooms.darkness)
	assert_eq(rooms.darkness.lamps.size(), 1)


func test_a_lit_room_has_none() -> void:
	rooms.enter_data(_room({}), "", Vector2(10.0, 1.0))
	await wait_frames(3)
	assert_null(rooms.darkness)
