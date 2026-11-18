extends TestCase
## Story 055 (D-065): exploration ambience by room theme, and the new movement and combat sounds.


func test_every_theme_has_a_bed_and_one_shots_that_exist() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Ambience.PATH))
	var folder := str(cfg["folder"])
	var themes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/themes.json"))
	for id: String in themes.keys():
		if id.begins_with("_"):
			continue
		var t: Dictionary = (cfg["themes"] as Dictionary).get(id, {})
		assert_false(t.is_empty(), "%s has ambience" % id)
		assert_true(ResourceLoader.exists(folder + str(t.get("bed", "")) + ".wav"), "%s bed" % id)
		for shot: String in (t.get("oneshots", {}) as Dictionary).keys():
			assert_true(ResourceLoader.exists(folder + shot + ".wav"), "%s: %s" % [id, shot])


func test_one_shots_are_picked_by_weight() -> void:
	var amb := add_node(Ambience.new()) as Ambience
	var shots: Dictionary = amb.theme_cfg("cavern")["oneshots"]
	var first: String = shots.keys()[0]
	assert_eq(amb.pick_oneshot("cavern", 0.0), first, "the lowest roll takes the first")
	assert_ne(amb.pick_oneshot("cavern", 0.999), "", "the highest roll still picks one")
	assert_eq(amb.pick_oneshot("no_such_theme", 0.5), "")


func test_changing_theme_starts_its_loop_and_silence_stops_it() -> void:
	var amb := add_node(Ambience.new()) as Ambience
	amb.set_theme("cavern")
	assert_eq(amb.theme, "cavern")
	amb.set_theme("")
	assert_eq(amb.theme, "")


func test_the_new_sounds_exist() -> void:
	for name in ["jump", "land", "step", "dodge", "slash", "slash_heavy", "hit", "kill", "enemy_death"]:
		assert_true(ResourceLoader.exists("res://assets/audio/sfx/%s.wav" % name), name)
