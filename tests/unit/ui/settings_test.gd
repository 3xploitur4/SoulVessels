extends TestCase
## Story 059 (D-070): the settings page: volumes kept and applied to the buses, and a game's
## difficulty changed from the pause menu.

const TEST_PATH := "user://test_settings.json"

var _old_path: String
var _old_volumes: Dictionary


func before_each() -> void:
	_old_path = GameSettings.path
	_old_volumes = GameSettings.volumes.duplicate()
	GameSettings.path = TEST_PATH
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	GameSettings.path = _old_path
	GameSettings.volumes = _old_volumes
	GameSettings.apply()


func test_a_volume_is_applied_to_its_bus_and_kept() -> void:
	GameSettings.load_and_apply()
	var music := AudioServer.get_bus_index("Music")
	var full := AudioServer.get_bus_volume_db(music)
	GameSettings.set_volume("music", 0.5)
	assert_lt(AudioServer.get_bus_volume_db(music), full - 6.0, "half way is clearly quieter")
	GameSettings.volumes["music"] = 1.0
	GameSettings.load_and_apply()
	assert_almost(GameSettings.volume("music"), 0.5, 0.001, "read back from the file")


func test_zero_mutes_and_an_ambience_bus_exists() -> void:
	GameSettings.load_and_apply()
	assert_true(AudioServer.get_bus_index("Ambience") >= 0)
	GameSettings.set_volume("effects", 0.0)
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))
	assert_true(AudioServer.is_bus_mute(AudioServer.get_bus_index("Telegraph")), "telegraph cues follow the effects")
	GameSettings.set_volume("effects", 1.0)
	assert_false(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))


func test_a_broken_file_leaves_everything_at_full() -> void:
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	GameSettings.load_and_apply()
	for k in GameSettings.KEYS:
		assert_almost(GameSettings.volume(k), 1.0, 0.001, k)


func test_the_panel_shows_four_sliders_and_the_difficulty_in_a_game() -> void:
	var p := SettingsPanel.new()
	p.difficulty = "normal"
	add_node(p)
	assert_eq(p.sliders.size(), 4)
	assert_true(p.difficulty_buttons["normal"].button_pressed, "the current difficulty is marked")
	assert_true(p.difficulty_buttons["abyssal"].disabled, "Abyssal waits for Chapter I")
	var asked: Array[String] = []
	p.difficulty_requested.connect(func(d: String) -> void: asked.append(d))
	p.difficulty_buttons["story"].pressed.emit()
	assert_eq(asked, ["story"] as Array[String], "the panel asks; the game decides")


func test_on_the_title_screen_the_panel_has_no_difficulty() -> void:
	var p := SettingsPanel.new()
	add_node(p)
	assert_eq(p.difficulty_buttons.size(), 0)


func test_moving_a_slider_sets_the_volume() -> void:
	GameSettings.load_and_apply()
	var p := SettingsPanel.new()
	add_node(p)
	p.sliders["ambience"].value = 40.0
	assert_almost(GameSettings.volume("ambience"), 0.4, 0.001)
