extends TestCase
## Story 012: 4-bar boundary maths for the adaptive music.

const BPM := 70.0


func test_beat_length_at_70_bpm() -> void:
	assert_almost(MusicDirector.beat_length(BPM), 60.0 / 70.0, 0.00001)


func test_next_boundary_from_mid_phrase() -> void:
	var span := 60.0 / 70.0 * 16.0  # 13.714 s
	assert_almost(MusicDirector.next_boundary_time(1.0, BPM, 4, 4), span, 0.0001)
	assert_almost(MusicDirector.next_boundary_time(span + 0.2, BPM, 4, 4), span * 2.0, 0.0001)


func test_time_on_a_boundary_stays() -> void:
	var span := 60.0 / 70.0 * 16.0
	assert_almost(MusicDirector.next_boundary_time(span, BPM, 4, 4), span, 0.0001)
	assert_almost(MusicDirector.next_boundary_time(0.0, BPM, 4, 4), 0.0, 0.0001)


func test_one_bar_boundaries() -> void:
	var bar := 60.0 / 70.0 * 4.0
	assert_almost(MusicDirector.next_boundary_time(bar * 2.5, BPM, 4, 1), bar * 3.0, 0.0001)


func test_music_config_has_every_stem_of_the_addendum() -> void:
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/music.json"))
	assert_true(cfg is Dictionary)
	var zone: Dictionary = (cfg as Dictionary)["zones"]["zone1"]
	for stem in ["bed", "pulse", "combat", "elite"]:
		assert_true((zone["stems"] as Dictionary).has(stem), "stem %s" % stem)
	for v in ["caelan", "nyra", "seris", "darius", "ilyr"]:
		assert_true((zone["leads"] as Dictionary).has(v), "lead %s" % v)
	assert_eq(zone["bpm"], 70.0)
