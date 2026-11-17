extends TestCase
## Story 035: boss music (addendum "Audio implementation": bosses play three phase clips, and
## changes wait for the next 4-bar boundary). A boss fight switches to its track at phase 1, each
## phase change asks for the next clip at the next boundary, and the win returns to the zone track.

var _zone_before: String = ""


func before_each() -> void:
	_zone_before = MusicDirector.zone
	MusicDirector.force_state("")
	MusicDirector.start_zone("zone3")


func after_each() -> void:
	MusicDirector.force_state("")
	if _zone_before != "":
		MusicDirector.start_zone(_zone_before)


func _fake_boss() -> Node:
	var n := Node.new()
	n.set_meta("music", "boss_sovereign")
	add_node(n)
	return n


func test_zone_three_and_the_boss_track_exist() -> void:
	assert_true(MusicDirector.has_zone("zone3"))
	assert_true(MusicDirector.has_zone("boss_sovereign"))


func test_boundary_at_seventy_six_bpm() -> void:
	# 4 bars of 4 beats at 76 BPM = 12.63 s.
	assert_almost(MusicDirector.next_boundary_time(0.5, 76.0, 4, 4), 16.0 * 60.0 / 76.0, 0.001)


func test_a_boss_fight_plays_phase_one_of_its_track() -> void:
	var b := _fake_boss()
	MusicDirector.boss_begin(b, "boss_sovereign")
	assert_eq(MusicDirector.zone, "boss_sovereign")
	assert_eq(MusicDirector.state, "phase1")


func test_phase_change_waits_for_the_next_boundary() -> void:
	var b := _fake_boss()
	MusicDirector.boss_begin(b, "boss_sovereign")
	MusicDirector.boss_phase(b, 1)
	assert_eq(MusicDirector.pending_state, "phase2")
	assert_gt(MusicDirector.pending_at, MusicDirector.song_time() - 0.001)
	MusicDirector.boss_phase(b, 2)
	assert_eq(MusicDirector.pending_state, "phase3", "a later phase replaces a pending one")


func test_the_rules_do_not_pull_a_boss_track_back_to_explore() -> void:
	var b := _fake_boss()
	MusicDirector.boss_begin(b, "boss_sovereign")
	await wait_frames(10)
	assert_eq(MusicDirector.state, "phase1")
	assert_eq(MusicDirector.pending_state, "")


func test_the_win_returns_to_the_zone_track() -> void:
	var b := _fake_boss()
	MusicDirector.boss_begin(b, "boss_sovereign")
	MusicDirector.boss_end(b)
	assert_eq(MusicDirector.zone, "zone3")
