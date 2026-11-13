extends TestCase
## Story 015: the room manager builds rooms, spawns enemies with save ids, and moves the player
## through exits to the arrival point of the matching exit.

var world: CombatWorld
var player: Player
var rooms: RoomManager
var state: GameState


func before_each() -> void:
	world = add_node(CombatWorld.new()) as CombatWorld
	player = Player.new()
	player.world = world
	player.vessel_ids = ["caelan"]
	add_node(player)
	player.input_enabled = false
	state = GameState.new_game()
	rooms = RoomManager.new()
	rooms.world = world
	rooms.player = player
	rooms.state = state
	add_node(rooms)


func test_enter_places_player_at_the_start_marker() -> void:
	assert_true(rooms.enter("z1_01"))
	var start: Vector2 = rooms.data.markers["start"]
	assert_almost(player.global_position.x, start.x, 0.01)
	assert_true(state.visited_rooms.has("z1_01"))
	assert_eq(state.current_room, "z1_01")


func test_walking_into_an_exit_travels_to_the_linked_room() -> void:
	rooms.enter("z1_01")
	var ex: Dictionary = rooms.data.exits["0"]
	var r: Rect2 = ex["rect"]
	player.teleport(r.position.x + 0.5, r.position.y)
	await wait_frames(4)
	assert_eq(rooms.data.id, "z1_02")
	var arrive: Vector2 = rooms.data.exits["0"]["arrive"]
	assert_almost(player.global_position.x, arrive.x, 0.3, "arrived at exit 0 of z1_02")
	await wait_frames(4)
	assert_eq(rooms.data.id, "z1_02", "arriving inside nothing does not bounce back")


func test_spawns_skip_enemies_the_save_says_are_dead() -> void:
	rooms.enter("z1_03")
	assert_eq(rooms.enemies().size(), 2)
	state.killed_commons.append("z1_03:0")
	rooms.enter("z1_03")
	await wait_frames(1)
	assert_eq(rooms.enemies().size(), 1)
	assert_eq(rooms.enemies()[0].spawn_id, "z1_03:1")


func test_a_kill_is_recorded_by_spawn_id() -> void:
	rooms.enter("z1_03")
	var e := rooms.enemies()[0]
	GameEvents.enemy_died.emit(e)
	assert_true(state.killed_commons.has(e.spawn_id))
