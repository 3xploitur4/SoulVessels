extends TestCase
## Story 012 (integration): state requests wait for the next 4-bar boundary; a Vessel swap
## crossfades the leads at once.


func test_state_change_is_scheduled_on_a_4_bar_boundary() -> void:
	MusicDirector.start_zone("zone1")
	await wait_frames(30)
	MusicDirector.force_state("combat")
	var span := MusicDirector.beat_length(MusicDirector.bpm) * float(MusicDirector.beats_per_bar) * 4.0
	var at := MusicDirector.pending_at
	assert_eq(MusicDirector.pending_state, "combat")
	assert_almost(fmod(at, span), 0.0, 0.001, "pending at %.3f s" % at)
	assert_gt(at, MusicDirector.song_time(), "in the future")
	assert_eq(MusicDirector.state, "explore", "unchanged until the boundary")
	MusicDirector.force_state("")


func test_vessel_swap_targets_only_its_lead() -> void:
	MusicDirector.start_zone("zone1")
	MusicDirector.set_vessel("nyra")
	assert_almost(MusicDirector._target_db["lead_nyra"], -6.0, 0.001)
	assert_almost(MusicDirector._target_db["lead_caelan"], MusicDirector.silent_db(), 0.001)
	var beat := MusicDirector.beat_length(MusicDirector.bpm)
	# Nyra's lead fades in from silence over exactly one beat.
	var span := absf(-6.0 - MusicDirector._current_db["lead_nyra"])
	assert_almost(MusicDirector._rate_db["lead_nyra"] * beat, span, 0.5)


func test_explore_plays_bed_only() -> void:
	MusicDirector.start_zone("zone1")
	assert_almost(MusicDirector._target_db["bed"], -4.0, 0.001)
	assert_almost(MusicDirector._target_db["pulse"], MusicDirector.silent_db(), 0.001)
	assert_almost(MusicDirector._target_db["elite"], MusicDirector.silent_db(), 0.001)
