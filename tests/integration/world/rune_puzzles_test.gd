extends TestCase
## Story 032 (integration): rune doors in rooms built by RoomManager. Arcane Bolts light runes, the
## door opens and stays open in the save, a mirror-shield bounces a bolt up to a rune, a sequence
## puzzle resets on a wrong rune, bolts stop at rock, and a rune above the bank can only be lit
## from ice frozen on the water.

var world: CombatWorld
var player: Player
var rooms: RoomManager
var state: GameState


func before_each() -> void:
	world = add_node(CombatWorld.new()) as CombatWorld
	player = Player.new()
	player.world = world
	player.vessel_ids = ["seris"]
	add_node(player)
	state = GameState.new()
	rooms = RoomManager.new()
	rooms.world = world
	rooms.player = player
	rooms.state = state
	rooms.feature_builders.append(func(m: RoomManager, r: RoomData) -> void:
		RunePuzzle.build_for(m, r, state))
	add_node(rooms)


## A 24 m room, floor at y 1, a rune door at x 20-21.
func _enter(runes: Dictionary, mirrors: Array = [], extra_rows: Array = []) -> void:
	var grid: Array = []
	for i in range(7):
		grid.append("#...................RR.#")
	for row in extra_rows:
		grid.append(row)
	grid.append("########################")
	var d := {"grid": grid, "runes": runes}
	if not mirrors.is_empty():
		d["mirrors"] = mirrors
	rooms.enter_data(RoomData.parse("t_runes", "zone3", d), "", Vector2(3.0, 1.0))


func _fire(dir: int) -> void:
	player.set_facing(dir)
	(player.loadout.active().kit as SerisKit).fire_bolt(player, 0)
	await wait_frames(70)


func test_a_bolt_lights_a_rune_and_the_door_opens_for_good() -> void:
	_enter({"id": "t_door", "kind": "all", "runes": [[19.5, 1.95]]})
	await wait_frames(4)
	assert_true(rooms.builder.gate_active("rune"), "shut before")
	await _fire(1)
	assert_false(rooms.builder.gate_active("rune"), "open after the rune is lit")
	assert_true(state.opened_gates.has("t_door"), "saved")


func test_an_opened_door_stays_open_on_return() -> void:
	state.opened_gates.append("t_door")
	_enter({"id": "t_door", "kind": "all", "runes": [[19.5, 1.95]]})
	await wait_frames(4)
	assert_false(rooms.builder.gate_active("rune"))
	var p := rooms.features_root.get_node_or_null("RunePuzzle") as RunePuzzle
	assert_true(p.sequence.solved, "its runes show lit")


func test_sequence_resets_on_the_wrong_rune() -> void:
	# Runes at three heights; the first in the mural order is the high one, out of the bolt's line.
	_enter({"id": "t_seq", "kind": "sequence", "runes": [[12.5, 4.5], [10.5, 1.95], [14.5, 1.95]]})
	await wait_frames(4)
	await _fire(1)
	var p := rooms.features_root.get_node_or_null("RunePuzzle") as RunePuzzle
	assert_eq(p.sequence.lit_count(), 0, "lighting rune 2 first puts everything out")
	assert_true(rooms.builder.gate_active("rune"))


func test_a_mirror_bounces_a_bolt_up_to_a_rune() -> void:
	_enter({"id": "t_mirror", "kind": "all", "runes": [[9.5, 5.5]]}, [{"pos": [9.5, 1.95], "angle": 135}])
	await wait_frames(4)
	await _fire(1)
	assert_false(rooms.builder.gate_active("rune"), "the bolt went up off the mirror into the rune")


func test_bolts_stop_at_rock() -> void:
	# A pillar between the player and the rune.
	_enter({"id": "t_rock", "kind": "all", "runes": [[15.5, 1.95]]})
	await wait_frames(2)
	rooms.builder.data.solids.append(Rect2(10.0, 1.0, 1.0, 3.0))
	await _fire(1)
	assert_true(rooms.builder.gate_active("rune"), "the pillar caught the bolt")


func test_turning_a_mirror_by_interacting() -> void:
	_enter({"id": "t_turn", "kind": "all", "runes": [[9.5, 5.5]]}, [{"pos": [9.5, 1.95], "angle": 90}])
	await wait_frames(2)
	var m := rooms.features_root.get_node_or_null("Mirror0") as MirrorShield
	m.interact(null)
	assert_almost(m.angle, 135.0)
	await _fire(1)
	assert_false(rooms.builder.gate_active("rune"))


func test_a_sequence_in_a_row_is_lit_near_to_far() -> void:
	# A lit rune lets later bolts through, so runes in one line light in order, nearest first.
	_enter({"id": "t_row", "kind": "sequence", "runes": [[8.5, 1.95], [12.5, 1.95], [16.5, 1.95]]})
	await wait_frames(4)
	for i in range(3):
		await _fire(1)
	assert_false(rooms.builder.gate_active("rune"), "three bolts, three runes, door open")


func test_tide_rune_is_lit_from_the_ice() -> void:
	# A deep pool with a rune 2.4 m above the floor's bolt line: out of reach from the floor,
	# in line from ice frozen on the surface.
	var grid: Array = []
	for i in range(7):
		grid.append("#...................RR.#")
	grid.append("########################")
	var d := {"grid": grid, "runes": {"id": "t_tide", "kind": "all", "runes": [[17.5, 4.35]]},
		"water": [{"id": "pool", "x": [8, 20], "level": 3.4, "floor": 0.95}]}
	rooms.enter_data(RoomData.parse("t_tide", "zone3", d), "", Vector2(3.0, 1.0))
	await wait_frames(4)
	await _fire(1)
	assert_true(rooms.builder.gate_active("rune"), "a bolt from the floor passes under the rune")
	GameEvents.frost_field_cast.emit(Rect2(9.0, 3.0, 4.0, 1.4), 3.0)
	player.teleport(10.0, 3.6)
	await wait_frames(40)
	assert_true(player.is_on_floor(), "on the ice")
	await _fire(1)
	assert_false(rooms.builder.gate_active("rune"), "from the ice the bolt is in line with the rune")
