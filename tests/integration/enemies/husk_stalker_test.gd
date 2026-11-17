extends TestCase
## Story 022: the Calcified Husk sleeps as a statue, wakes, and its spores root-snare the player;
## the snare breaks by tapping or by a Shadowstep. The Fungal Stalker hangs from the ceiling and
## drops on a player passing beneath.

var world: CombatWorld
var player: Player
var rooms: RoomManager


func before_each() -> void:
	world = add_node(CombatWorld.new()) as CombatWorld
	player = Player.new()
	player.world = world
	player.vessel_ids = ["caelan", "nyra"]
	add_node(player)
	rooms = RoomManager.new()
	rooms.world = world
	rooms.player = player
	add_node(rooms)
	var grid: Array = []
	for i in range(11):
		grid.append("#" + ".".repeat(28) + "#")
	grid.append("#".repeat(30))
	rooms.enter_data(RoomData.parse("t_hs", "zone2", {"grid": grid}), "", Vector2(3.0, 1.0))
	await wait_frames(5)


func after_each() -> void:
	for a in ["attack", "jump", "dodge", "ability_1", "move_left", "move_right"]:
		Input.action_release(a)


func _tap(action: String) -> void:
	Input.action_press(action)
	await wait_frames(2)
	Input.action_release(action)
	await wait_frames(2)


func test_husk_sleeps_until_the_player_comes_close() -> void:
	var h := rooms.spawn("calcified_husk", 14.0, 1.0) as CalcifiedHusk
	await wait_frames(30)
	assert_true(h.dormant, "a statue while the player is 11 m away")
	assert_false(h.aggro)
	player.teleport(11.5, 1.0)
	await wait_frames(5)
	assert_false(h.dormant, "wakes within 3.5 m")


func test_spores_snare_and_six_taps_break_free() -> void:
	var p := DamagePacket.new()
	p.atk = 22.0
	p.motion = 0.5
	p.kind = DamagePacket.KIND_UNBLOCKABLE
	p.source_x = player.global_position.x + 2.0
	p.tags["snare"] = true
	player.receive_hit(p)
	assert_true(player.snare.is_active())
	var x0 := player.global_position.x
	Input.action_press("move_right")
	await wait_frames(20)
	Input.action_release("move_right")
	assert_almost(player.global_position.x, x0, 0.05, "rooted: cannot walk")
	assert_eq(player.state, "rooted")
	for i in range(5):
		await _tap("attack")
	assert_true(player.snare.is_active(), "five taps are not enough")
	await _tap("jump")
	assert_false(player.snare.is_active(), "the sixth tap breaks it")


func test_the_snare_wears_off_on_its_own() -> void:
	player.snare.apply()
	await wait_frames(int(Balance.combat_f("root_snare.duration_s") * 60.0) + 5)
	assert_false(player.snare.is_active())


func test_nyra_shadowstep_breaks_the_snare_at_once() -> void:
	player.try_swap(1, true)
	player.snare.apply()
	await _tap("ability_1")
	assert_false(player.snare.is_active())


func test_stalker_hangs_then_drops_on_a_player_beneath() -> void:
	var s := rooms.spawn("fungal_stalker", 16.0, 1.0, "", 11.0) as FungalStalker
	await wait_frames(10)
	assert_true(s.hanging)
	assert_gt(s.global_position.y, 8.0, "up at the ceiling")
	player.teleport(15.5, 1.0)
	var landed := false
	for i in range(150):
		await wait_frames(1)
		if not s.hanging:
			landed = true
			break
	assert_true(landed, "dropped and landed")
	assert_lt(s.global_position.y, 1.5, "on the floor")
