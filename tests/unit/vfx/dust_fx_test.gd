extends TestCase
## Story 054 (D-062): dust kicked off the ground, and the shadow cast on the ground under a body.


func test_every_kind_of_dust_is_complete() -> void:
	var kinds: Dictionary = DustFx.config().get("kinds", {})
	for k in ["step", "land", "jump", "skid", "scuff", "slam", "wall"]:
		assert_true(kinds.has(k), k)
		var d: Dictionary = kinds.get(k, {})
		assert_gt(int(d.get("amount", 0)), 0, "%s amount" % k)
		assert_gt(float(d.get("life", 0.0)), 0.0, "%s life" % k)


func test_a_faster_run_steps_more_often() -> void:
	assert_lt(DustFx.step_interval(1.3), DustFx.step_interval(0.7))


func test_a_landing_sprays_both_ways_and_throws_grit() -> void:
	var host := add_node(Node3D.new()) as Node3D
	var made := DustFx.spawn(host, "land", Vector3(2.0, 1.0, 0.0))
	assert_eq(made.size(), 4, "two puffs and two grit sprays")
	var dirs := []
	for p in made:
		assert_true(p.one_shot and p.emitting)
		dirs.append(signf(p.direction.x))
	assert_true(dirs.has(1.0) and dirs.has(-1.0))
	for p in made:
		p.queue_free()


func test_a_skid_sprays_one_way() -> void:
	var host := add_node(Node3D.new()) as Node3D
	var made := DustFx.spawn(host, "skid", Vector3.ZERO, -1.0)
	assert_gt(made.size(), 0)
	for p in made:
		assert_lt(p.direction.x, 0.0)
		p.queue_free()


func test_no_dust_outside_a_scene_or_for_an_unknown_kind() -> void:
	assert_eq(DustFx.spawn(Node3D.new(), "land", Vector3.ZERO).size(), 0, "not in a tree")
	var host := add_node(Node3D.new()) as Node3D
	assert_eq(DustFx.spawn(host, "sneeze", Vector3.ZERO).size(), 0)


func test_the_shadow_lies_on_the_ground_and_shrinks_with_height() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 1.0, 2.0)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position = Vector3(0.0, -0.5, 0.0)
	add_node(floor_body)
	var b := add_node(SpriteBody.create("caelan")) as SpriteBody
	await wait_frames(2)
	b.tick(1.0 / 60.0)
	var shadow := b._shadow
	assert_true(shadow.visible, "on the ground")
	assert_almost(shadow.global_position.y, SpriteBody.SHADOW_LIFT_M, 0.02, "laid on the floor")
	var near := shadow.scale.x
	b.position.y = 4.0
	b.tick(1.0 / 60.0)
	assert_true(shadow.visible, "still under a jump")
	assert_almost(shadow.global_position.y, SpriteBody.SHADOW_LIFT_M, 0.02, "stays on the floor")
	assert_lt(shadow.scale.x, near, "smaller")
	b.position.x = 40.0
	b.tick(1.0 / 60.0)
	assert_false(shadow.visible, "no ground below, no shadow")
