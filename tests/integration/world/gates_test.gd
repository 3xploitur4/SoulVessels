extends TestCase
## Story 023: the shield ward burns an unguarded player and opens when Caelan's block throws the
## beam onto the crystal; a shadow veil stops walking and lets a Shadowstep through.

var world: CombatWorld
var player: Player
var rooms: RoomManager
var state: GameState


func before_each() -> void:
	world = add_node(CombatWorld.new()) as CombatWorld
	player = Player.new()
	player.world = world
	player.vessel_ids = ["caelan", "nyra"]
	add_node(player)
	state = GameState.new_game()
	rooms = RoomManager.new()
	rooms.world = world
	rooms.player = player
	rooms.state = state
	add_node(rooms)


func after_each() -> void:
	for a in ["ability_1", "move_left", "move_right"]:
		Input.action_release(a)


func _ward() -> ShieldWard:
	rooms.enter("z1_08", "0")
	var w := ShieldWard.new()
	w.room = rooms.data
	w.manager = rooms
	w.player = player
	w.state = state
	rooms.features_root.add_child(w)
	return w


func test_the_beam_burns_a_player_who_does_not_guard() -> void:
	_ward()
	player.teleport(12.0, 2.0)
	var hp := player.health.current
	await wait_frames(40)
	assert_lt(player.health.current, hp, "burned")


func test_guarding_throws_the_beam_onto_the_crystal_and_opens_the_bars() -> void:
	var w := _ward()
	# The statue holds the crystal above its head (x 22-23, y 5-6.5); the 30 degree reflection
	# reaches it from x 16.8 to 18.4.
	player.teleport(17.6, 2.0)
	player.set_facing(1)
	await wait_frames(5)
	player.begin_block()
	var hp := player.health.current
	for i in range(120):
		await wait_frames(1)
		if w.is_open:
			break
	assert_true(w.is_open, "opened (charge %.2f)" % w.charge)
	assert_almost(player.health.current, hp, 0.01, "a guarded beam does no harm")
	assert_false(rooms.builder.gate_bodies.has("ward"), "the bars are gone")
	assert_true(state.opened_gates.has("z1_08:ward"), "saved")


func test_guarding_in_the_wrong_spot_does_not_charge() -> void:
	var w := _ward()
	player.teleport(9.0, 2.0)
	player.set_facing(1)
	await wait_frames(5)
	player.begin_block()
	await wait_frames(90)
	assert_false(w.is_open)
	assert_almost(w.charge, 0.0, 0.01)


func test_an_opened_ward_stays_open_on_return() -> void:
	state.opened_gates.append("z1_08:ward")
	var w := _ward()
	await wait_frames(2)
	assert_true(w.is_open)
	assert_false(rooms.builder.gate_bodies.has("ward"))


func test_the_veil_stops_walking_and_lets_a_shadowstep_through() -> void:
	rooms.enter("z1_05", "", Vector2(12.0, 7.0))
	await wait_frames(10)
	Input.action_press("move_left")
	await wait_frames(60)
	Input.action_release("move_left")
	assert_gt(player.global_position.x, 9.9, "the curtain at x 9-10 stops a walk")
	player.try_swap(1, true)
	player.set_facing(-1)
	await wait_frames(2)
	Input.action_press("ability_1")
	await wait_frames(2)
	Input.action_release("ability_1")
	await wait_frames(30)
	assert_lt(player.global_position.x, 9.0, "the Shadowstep passed through")


func test_too_close_to_the_statue_the_reflection_passes_under_the_crystal() -> void:
	var w := _ward()
	player.teleport(20.6, 2.0)
	player.set_facing(1)
	await wait_frames(5)
	player.begin_block()
	await wait_frames(90)
	assert_false(w.is_open, "the ray passes below the crystal")
