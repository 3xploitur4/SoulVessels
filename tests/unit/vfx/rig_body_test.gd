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
	b.pose_now("attack_0", 0.22)
	var key: Dictionary = (b.clips["attack_0"]["keys"] as Array)[1][1]
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


func test_an_unknown_clip_falls_back_to_idle() -> void:
	var b := add_node(SpriteBody.create("echo_crawler")) as RigBody
	b.play("no_such_clip")
	assert_eq(b.clip, "idle")
