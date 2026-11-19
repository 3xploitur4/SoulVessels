extends TestCase
## Story 056 (D-067): bosses are drawn and hit bigger than their paintings' base size, and the
## camera frames a boss fight so the player is never at the edge.


func test_a_boss_scale_grows_its_picture_and_its_hurt_box_together() -> void:
	var g := GuardianBelow.new()
	add_node(g)
	var s := float(Balance.enemy("guardian_below").get("visual_scale", 1.0))
	assert_gt(s, 1.0, "the Guardian is drawn bigger")
	assert_almost(g.size_scale, s, 0.001)
	assert_almost(g.visual.scale.y, s, 0.001, "picture")
	assert_almost(g.hurt_size().y, g._hurt_size().y * s, 0.001, "hurt box")


func test_an_ordinary_enemy_keeps_its_size() -> void:
	var e := EchoCrawler.new()
	add_node(e)
	assert_almost(e.size_scale, 1.0, 0.001)
	assert_almost(e.hurt_size().x, e._hurt_size().x, 0.001)


func test_the_boss_view_sits_between_and_keeps_the_player_on_screen() -> void:
	var cam := SideCamera.new()
	cam.boss_bias = 0.4
	cam.boss_edge_m = 3.0
	assert_almost(cam.framed_x(0.0, 10.0, 12.0), 4.0, 0.001, "part way to the boss")
	assert_almost(cam.framed_x(0.0, 60.0, 12.0), 9.0, 0.001, "a far boss never pushes the player off the edge")
	assert_almost(cam.framed_x(5.0, 5.0, 12.0), 5.0, 0.001, "on top of each other: on the player")
	cam.free()
