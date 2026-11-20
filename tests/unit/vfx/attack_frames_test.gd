extends TestCase
## Story 058 (D-069): drawn attack frames replace the cut-out parts for Caelan's attacks.


func test_caelan_attacks_play_as_drawn_frames_and_his_run_does_not() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	assert_true(b.has_frames("attack_0"))
	assert_true(b.has_frames("attack_3"))
	assert_false(b.has_frames("run"), "the run stays on the rig")


func test_a_frame_shows_from_its_progress_until_the_next() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	var keys: Array = JSON.parse_string(FileAccess.get_file_as_string(RigBody.FRAMES_PATH))["caelan"]["clips"]["attack_0"]
	assert_eq(str(b.frame_at("attack_0", 0.0)[0]), str(keys[0][1]), "the wind-up first")
	assert_eq(str(b.frame_at("attack_0", float(keys[1][0]) + 0.01)[0]), str(keys[1][1]), "then the strike")
	assert_eq(str(b.frame_at("attack_0", 1.0)[0]), str(keys[keys.size() - 1][1]), "the last frame holds")


func test_playing_an_attack_hides_the_parts_and_shows_the_frame() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	b.pose_now("attack_0", 0.5)
	assert_ne(b.frame_shown(), "")
	assert_false(b.find_child("Rig", true, false).visible, "the parts are hidden")
	b.pose_now("idle", 0.0)
	assert_eq(b.frame_shown(), "", "back on the rig")
	assert_true(b.find_child("Rig", true, false).visible)


func test_every_frame_the_clips_name_was_cut() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RigBody.FRAMES_PATH))
	for id: String in cfg.keys():
		if id.begins_with("_"):
			continue
		var folder := str(cfg[id]["folder"])
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "frames.json"))["frames"]
		for clip: String in (cfg[id]["clips"] as Dictionary).keys():
			for k: Array in cfg[id]["clips"][clip]:
				assert_true(meta.has(str(k[1])), "%s %s: %s" % [id, clip, k[1]])
				assert_true(ResourceLoader.exists(folder + str(k[1]) + ".png"), "%s.png" % k[1])


func test_a_vessel_borrowing_his_rig_does_not_borrow_his_drawings() -> void:
	var nyra := add_node(SpriteBody.create("nyra")) as RigBody
	assert_false(nyra.has_frames("attack_0"))


func test_a_second_weapon_look_goes_back_to_the_parts() -> void:
	var b := add_node(SpriteBody.create("caelan")) as RigBody
	b.apply_look({"hide": ["shield"]})
	assert_false(b.has_frames("attack_0"), "the drawings show the shield and the first sword")
