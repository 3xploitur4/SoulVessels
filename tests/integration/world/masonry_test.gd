extends TestCase
## Story 042: cracked masonry (addendum gate table) opens to Darius's Crushing Blow or
## Groundbreaker, crumbles for good (saved), ignores every other attack, and a masonry floor
## drops the player through when broken.

var world: CombatWorld
var player: Player
var rooms: RoomManager
var state: GameState


func before_each() -> void:
	world = add_node(CombatWorld.new()) as CombatWorld
	player = Player.new()
	player.world = world
	player.vessel_ids = ["darius", "caelan"]
	add_node(player)
	state = GameState.new()
	rooms = RoomManager.new()
	rooms.world = world
	rooms.player = player
	rooms.state = state
	rooms.feature_builders.append(func(m: RoomManager, r: RoomData) -> void: MasonryWall.build_for(m, r, state))
	add_node(rooms)


func _wall_room() -> RoomData:
	var grid: Array = []
	for i in range(6):
		grid.append("#..........KK......#")
	grid.append("####################")
	return RoomData.parse("t_mason", "zone4", {"grid": grid})


func _hit(tags: Dictionary) -> void:
	var p := player.make_packet(1.0, 1.0)
	for k: String in tags.keys():
		p.tags[k] = tags[k]
	for n in rooms.features_root.get_children():
		if n is MasonryWall:
			(n as MasonryWall).receive_hit(p)


func test_a_plain_attack_does_not_open_it() -> void:
	rooms.enter_data(_wall_room(), "", Vector2(5.0, 1.0))
	await wait_frames(3)
	_hit({})
	assert_true(rooms.builder.gate_active("masonry"))


func test_crushing_blow_opens_it_and_it_stays_open() -> void:
	rooms.enter_data(_wall_room(), "", Vector2(5.0, 1.0))
	await wait_frames(3)
	_hit({"breaks_masonry": true})
	await wait_frames(2)
	assert_false(rooms.builder.gate_active("masonry"), "crumbled")
	assert_true(state.opened_gates.has("t_mason:masonry:0"), "saved")
	rooms.enter_data(_wall_room(), "", Vector2(5.0, 1.0))
	await wait_frames(3)
	assert_false(rooms.builder.gate_active("masonry"), "still open on return")


func test_a_real_crushing_blow_from_darius_reaches_the_wall() -> void:
	rooms.enter_data(_wall_room(), "", Vector2(9.2, 1.0))
	await wait_frames(10)
	player.set_facing(1)
	(player.loadout.active().kit as DariusKit).ability_1_released(player, 0.0)
	await wait_frames(60)
	assert_false(rooms.builder.gate_active("masonry"), "Crushing Blow broke the wall")


func test_groundbreaker_breaks_it_too() -> void:
	rooms.enter_data(_wall_room(), "", Vector2(9.2, 1.0))
	await wait_frames(10)
	player.loadout.active().kit.ability_2(player)
	await wait_frames(60)
	assert_false(rooms.builder.gate_active("masonry"))


func test_a_masonry_floor_drops_the_player_through() -> void:
	var grid: Array = []
	for i in range(4):
		grid.append("#..................#")
	grid.append("#######KKKKK########")
	for i in range(3):
		grid.append("#..................#")
	grid.append("####################")
	rooms.enter_data(RoomData.parse("t_floor", "zone4", {"grid": grid}), "", Vector2(9.5, 5.0))
	await wait_frames(20)
	var y0 := player.global_position.y
	assert_gt(y0, 4.5, "standing on the cracked floor")
	_hit({"breaks_masonry": true})
	await wait_frames(60)
	assert_lt(player.global_position.y, 2.0, "fell through to the floor below")
