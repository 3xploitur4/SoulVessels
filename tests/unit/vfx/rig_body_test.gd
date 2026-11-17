extends TestCase
## Story 029: the cut-out rig loads its parts, samples its clips between keys and turns its
## joints, and SpriteBody.create picks it when a rig exists.


func test_create_picks_the_rig_when_one_exists() -> void:
	var b := add_node(SpriteBody.create("caelan")) as SpriteBody
	assert_true(b is RigBody, "Caelan has a rig")
	var n := add_node(SpriteBody.create("nyra")) as SpriteBody
	assert_false(n is RigBody, "Nyra is still a whole painting")


func test_every_part_of_the_rig_becomes_a_bone() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	for p: Dictionary in b.rig["parts"]:
		assert_true(b.find_child(str(p["id"]), true, false) != null, "bone %s" % p["id"])


func test_sampling_between_keys_eases_from_one_to_the_next() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	b.clips = {"t": {"keys": [[0.0, {"head": 0.0}], [1.0, {"head": 40.0}]]}}
	assert_almost(float(b.sample("t", 0.0)["head"]), 0.0, 0.001)
	assert_almost(float(b.sample("t", 0.5)["head"]), 20.0, 0.001, "smoothstep midpoint")
	assert_almost(float(b.sample("t", 1.0)["head"]), 40.0, 0.001)
	assert_lt(float(b.sample("t", 0.25)["head"]), 10.0, "eased, not linear")


func test_a_joint_missing_from_a_key_counts_as_rest() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	b.clips = {"t": {"keys": [[0.0, {}], [1.0, {"sword": 30.0}]]}}
	assert_almost(float(b.sample("t", 0.5)["sword"]), 15.0, 0.001)


func test_pose_now_turns_the_joints_at_once() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	var at: Array = (b.clips["attack_0"]["keys"] as Array)[2]
	b.pose_now("attack_0", float(at[0]))
	var key: Dictionary = at[1]
	assert_almost(b.joint_deg("arm_upper"), float(key["arm_upper"]), 0.01)
	var bone := b.find_child("arm_upper", true, false) as Node3D
	assert_almost(rad_to_deg(bone.rotation.z), float(key["arm_upper"]), 0.01)


func test_ticking_blends_toward_the_clip_instead_of_snapping() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	b.play("block")
	b.tick(1.0 / 60.0)
	var target := float((b.clips["block"]["keys"] as Array)[0][1]["shield_arm"])
	assert_gt(b.joint_deg("shield_arm"), 0.0, "started moving")
	assert_lt(b.joint_deg("shield_arm"), target, "not there in one frame")
	for i in range(60):
		b.tick(1.0 / 60.0)
	assert_almost(b.joint_deg("shield_arm"), target, 0.1, "settled")


func test_turning_around_keeps_the_sword_in_front_of_the_body() -> void:
	# Visuals face left by turning half a circle about the vertical, which would put the
	# front-most part (the sword) behind the torso unless the rig corrects its depth.
	var holder := add_node(Node3D.new()) as Node3D
	var b := SpriteBody.create("caelan") as RigBody
	holder.add_child(b)
	var cam_dir := Vector3(0, 0, 1)
	for turn in [0.0, PI]:
		holder.rotation.y = turn
		b.tick(1.0 / 60.0)
		var sword := (b.find_child("sword", true, false) as Node3D).get_node("Pic") as Node3D
		var torso := (b.find_child("torso", true, false) as Node3D).get_node("Pic") as Node3D
		assert_gt(sword.global_position.dot(cam_dir), torso.global_position.dot(cam_dir),
			"sword nearer the camera at turn %.2f" % turn)


func test_a_blow_accelerates_into_its_key_and_a_wind_up_settles_into_it() -> void:
	assert_lt(RigBody.ease_key(0.5, "in"), 0.2, "in: still slow at half way")
	assert_gt(RigBody.ease_key(0.5, "out"), 0.8, "out: nearly there at half way")
	assert_almost(RigBody.ease_key(0.5, "linear"), 0.5, 0.001)
	assert_almost(RigBody.ease_key(1.0, "in"), 1.0, 0.001)
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	b.clips = {"t": {"keys": [[0.0, {"sword": 0.0}], [1.0, {"sword": 100.0}, "in"]]}}
	assert_lt(float(b.sample("t", 0.5)["sword"]), 20.0, "the key's easing is used")


func test_the_cape_trails_behind_a_running_body_and_settles_when_it_stops() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	b.tick(1.0 / 60.0)
	for i in range(30):
		b.position.x += 6.0 / 60.0
		b.tick(1.0 / 60.0)
	assert_lt(b.secondary_deg("cape"), -10.0, "swung back while running forward")
	for i in range(120):
		b.tick(1.0 / 60.0)
	assert_almost(b.secondary_deg("cape"), 0.0, 1.0, "settled at rest")


func test_a_teleport_does_not_fling_the_cape() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	b.tick(1.0 / 60.0)
	b.position.x += 40.0
	b.tick(1.0 / 60.0)
	assert_almost(b.secondary_deg("cape"), 0.0, 0.5)


func test_squash_coils_the_crawler_down_and_wide() -> void:
	var b := add_node(SpriteBody.create("echo_crawler")) as RigBody
	b.pose_now("telegraph", 0.0)
	var rig := b.find_child("Rig", true, false) as Node3D
	assert_lt(rig.scale.y, 0.95, "lower")
	assert_gt(absf(rig.scale.x), 1.02, "wider")


func test_an_unknown_clip_falls_back_to_idle() -> void:
	var b := add_node(SpriteBody.create("echo_crawler")) as RigBody
	b.play("no_such_clip")
	assert_eq(b.clip, "idle")
