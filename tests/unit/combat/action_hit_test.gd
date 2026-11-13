extends TestCase
## Story 007: rect hits, once per target per swing, facing mirror, segment test.

class Dummy extends Node3D:
	var team: int = CombatWorld.TEAM_ENEMY
	var rect := Rect2(2.0, 0.0, 1.0, 2.0)
	var received: int = 0

	func hurt_rect() -> Rect2:
		return rect

	func receive_hit(_p: DamagePacket) -> DamagePacket.Result:
		received += 1
		return DamagePacket.Result.HIT

	func is_alive() -> bool:
		return true


func test_hit_lands_once_per_window() -> void:
	var world: CombatWorld = add_node(CombatWorld.new())
	var d := Dummy.new()
	add_node(d)
	world.register(d)
	var h := ActionHit.new(0.0, 0.2, Vector2(1.5, 1.0), Vector2(2.0, 1.4), DamagePacket.new())
	for _i in range(5):
		h.sweep(world, Vector2.ZERO, 1, CombatWorld.TEAM_ENEMY, Callable())
	assert_eq(d.received, 1, "five sweeps, one hit")
	h.reset()
	h.sweep(world, Vector2.ZERO, 1, CombatWorld.TEAM_ENEMY, Callable())
	assert_eq(d.received, 2, "a new swing hits again")


func test_facing_left_mirrors_the_rect() -> void:
	var world: CombatWorld = add_node(CombatWorld.new())
	var d := Dummy.new()
	add_node(d)
	world.register(d)
	var h := ActionHit.new(0.0, 0.2, Vector2(1.5, 1.0), Vector2(2.0, 1.4), DamagePacket.new())
	h.sweep(world, Vector2.ZERO, -1, CombatWorld.TEAM_ENEMY, Callable())
	assert_eq(d.received, 0, "target is to the right, swing goes left")


func test_wrong_team_is_never_hit() -> void:
	var world: CombatWorld = add_node(CombatWorld.new())
	var d := Dummy.new()
	d.team = CombatWorld.TEAM_PLAYER
	add_node(d)
	world.register(d)
	var h := ActionHit.new(0.0, 0.2, Vector2(1.5, 1.0), Vector2(2.0, 1.4), DamagePacket.new())
	h.sweep(world, Vector2.ZERO, 1, CombatWorld.TEAM_ENEMY, Callable())
	assert_eq(d.received, 0)


func test_segment_rect_intersection() -> void:
	var r := Rect2(0.0, 0.0, 1.0, 2.0)
	assert_true(CombatWorld.segment_hits_rect(Vector2(-5, 1), Vector2(5, 1), r))
	assert_false(CombatWorld.segment_hits_rect(Vector2(-5, 3), Vector2(5, 3), r))
	assert_true(CombatWorld.segment_hits_rect(Vector2(0.5, 0.5), Vector2(9, 9), r), "starts inside")


func test_player_action_iframes_and_cancel() -> void:
	var a := PlayerAction.new("roll", 0.45)
	a.set_iframes(0.05, 0.30)
	a.cancel_after = 0.30
	a.cancel_into = PackedStringArray(["attack"])
	a.elapsed = 0.04
	assert_false(a.is_invulnerable())
	a.elapsed = 0.05
	assert_true(a.is_invulnerable())
	a.elapsed = 0.30
	assert_true(a.is_invulnerable(), "0.25 s of i-frames, inclusive")
	assert_true(a.can_cancel_into("attack"), "last 0.15 s cancels into attack")
	assert_false(a.can_cancel_into("dodge"))
	a.elapsed = 0.31
	assert_false(a.is_invulnerable())
