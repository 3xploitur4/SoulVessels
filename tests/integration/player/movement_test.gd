extends TestCase
## Story 006 (integration, headless physics): the body runs, jumps, dodges with i-frames on a
## real floor with Jolt.

var world: CombatWorld
var player: Player


func before_each() -> void:
	world = CombatWorld.new()
	add_node(world)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 10.0)
	shape.shape = box
	floor_body.add_child(shape)
	add_node(floor_body)
	floor_body.global_position = Vector3(0.0, -0.5, 0.0)
	player = Player.new()
	player.world = world
	add_node(player)
	player.global_position = Vector3(0.0, 0.05, 0.0)


func after_each() -> void:
	for a in ["move_right", "jump", "dodge"]:
		Input.action_release(a)


func test_runs_at_caelan_speed() -> void:
	await wait_frames(10)
	var x0 := player.global_position.x
	Input.action_press("move_right")
	await wait_frames(120)
	Input.action_release("move_right")
	var moved := player.global_position.x - x0
	# 6 m/s for 2 s, minus the 0.1 s acceleration ramp.
	assert_almost(moved, 11.7, 0.4, "moved %.2f m" % moved)
	assert_eq(player.facing, 1)
	assert_almost(player.global_position.z, 0.0, 0.0001, "locked to the play plane")


func test_jump_reaches_the_height_its_data_gives() -> void:
	await wait_frames(10)
	var y0 := player.global_position.y
	var peak := y0
	Input.action_press("jump")
	for _i in range(40):
		await wait_frames(1)
		peak = maxf(peak, player.global_position.y)
	Input.action_release("jump")
	# v^2 / 2g from data/balance/combat.json (story 054: about 3.3 m, clearing 3-cell ledges with room).
	var v := Balance.combat_f("movement.jump_velocity")
	var want := v * v / (2.0 * Balance.combat_f("movement.gravity"))
	# Stepping at 60 Hz loses a little of the ideal height.
	assert_almost(peak - y0, want, 0.3, "apex %.2f m" % (peak - y0))
	assert_gt(peak - y0, 3.2, "a 3-cell ledge is cleared with room to spare")
	assert_lt(peak - y0, 3.8, "a 4-cell wall still blocks")
	await wait_frames(40)
	assert_true(player.is_on_floor(), "lands")


func test_dodge_grants_iframes_then_ends() -> void:
	await wait_frames(10)
	Input.action_press("dodge")
	await wait_frames(1)
	Input.action_release("dodge")
	var inv_frames := 0
	for _i in range(30):
		await wait_frames(1)
		if player.is_invulnerable():
			inv_frames += 1
	# 0.25 s of i-frames at 60 Hz is 15 frames (one either way for sampling).
	assert_true(inv_frames >= 14 and inv_frames <= 16, "i-frame frames: %d" % inv_frames)
	assert_almost(player.loadout.active().stamina.value, 80.0, 1.5, "20 stamina, regen not started")


func test_exhausted_vessel_cannot_dodge() -> void:
	await wait_frames(5)
	player.loadout.active().stamina.spend(100.0)
	Input.action_press("dodge")
	await wait_frames(2)
	Input.action_release("dodge")
	assert_false(player.action != null and player.action.id == "dodge", "no dodge while Exhausted")
