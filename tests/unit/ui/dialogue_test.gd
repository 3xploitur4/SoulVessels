extends TestCase
## Story 060 (D-071): conversations when a new character is met, lines in passing, lore read aloud.


func test_every_vessel_and_boss_has_a_meeting() -> void:
	for t in ["possessed:caelan", "freed:nyra", "freed:seris", "freed:darius", "awakened:ilyr",
			"boss:weeping_sovereign", "boss:guardian_below", "boss:abyssal_leviathan"]:
		assert_ne(DialogueBox.conversation_for(t), "", t)
	assert_eq(DialogueBox.conversation_for("freed:nobody"), "")


func test_every_line_speaker_and_lore_exists() -> void:
	var portraits := DialogueBox.portraits()
	for id: String in DialogueBox.conversations().keys():
		for l: Dictionary in DialogueBox.conversations()[id]["lines"]:
			if l.has("lore"):
				assert_false(LoreDb.entry(str(l["lore"])).is_empty(), "%s: lore %s" % [id, l["lore"]])
				continue
			assert_ne(tr(str(l["line"])), str(l["line"]), "%s: %s is written" % [id, l["line"]])
			assert_true(portraits.has(str(l["speaker"])), "%s: %s has a portrait and voice" % [id, l["speaker"]])


func test_every_speaker_has_a_voice_file() -> void:
	for k: String in DialogueBox.portraits().keys():
		var voice := str(DialogueBox.portraits()[k].get("voice", ""))
		assert_true(ResourceLoader.exists("res://assets/audio/sfx/%s.wav" % voice), "%s: %s" % [k, voice])


func test_a_conversation_waits_for_a_press_and_pauses_play() -> void:
	var d := DialogueBox.new()
	add_node(d)
	assert_true(d.play("nyra"))
	assert_true(tree.paused, "play waits")
	assert_eq(d.current_speaker(), "VESSEL_NYRA")
	var first := d.current_text()
	d._advance()          # shows the rest of the line
	assert_eq(d.current_text(), first, "still the first line")
	d._advance()          # the next line
	assert_ne(d.current_text(), first)
	d._advance()
	d._advance()          # the memory, read by the narrating voice
	assert_eq(d.current_speaker(), "SPEAKER_MEMORY")
	d._advance()
	d._advance()
	assert_false(d.is_open(), "the conversation is over")
	assert_true(tree.paused, "the closing press is not also a swing")
	await tree.create_timer(DialogueBox.RESUME_DELAY_S + 0.1, true, false, true).timeout
	assert_false(tree.paused, "play goes on")


func test_without_anyone_to_press_a_conversation_plays_in_passing() -> void:
	var d := DialogueBox.new()
	d.auto_advance = true
	add_node(d)
	d.play("darius")
	assert_false(tree.paused, "nothing waits")
	assert_eq(d.current_speaker(), "VESSEL_DARIUS")


func test_a_line_in_passing_finds_its_speaker_by_name() -> void:
	var d := DialogueBox.new()
	add_node(d)
	d.say(tr("SPEAKER_VOICE"), tr("SOV_Z1_THIEF"))
	assert_eq(d.current_speaker(), "SPEAKER_VOICE")
	assert_eq(d.current_text(), tr("SOV_Z1_THIEF"))
	assert_false(tree.paused, "lines in passing never stop play")


func test_found_lore_is_read_aloud() -> void:
	var d := DialogueBox.new()
	add_node(d)
	d.read_lore("parchment_01")
	assert_eq(d.current_text(), tr(LoreDb.body_key("parchment_01")))
	assert_eq(d.current_speaker(), "SPEAKER_MEMORY")
