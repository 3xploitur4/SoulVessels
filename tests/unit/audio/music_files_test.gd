extends TestCase
## Story 048: every track listed in data/audio/music.json has its stem and lead files on disk, and
## the Zone 4, boss and finale tracks are listed.


func _tracks() -> Dictionary:
	var f := FileAccess.open("res://data/audio/music.json", FileAccess.READ)
	var d: Variant = JSON.parse_string(f.get_as_text())
	return (d as Dictionary).get("zones", {})


func test_m4_tracks_are_listed() -> void:
	for id: String in ["zone4", "zone4_shore", "boss_guardian", "boss_leviathan", "finale_short"]:
		assert_true(MusicDirector.has_zone(id), "missing track " + id)


func test_boss_tracks_have_three_phase_clips() -> void:
	var z := _tracks()
	for id: String in ["boss_guardian", "boss_leviathan"]:
		var t: Dictionary = z[id]
		assert_true(t.get("boss", false), id + " is a boss track")
		assert_eq((t["stems"] as Dictionary).size(), 3, id + " has p1-p3")


func test_every_listed_file_exists() -> void:
	var z := _tracks()
	for id: String in z:
		var t: Dictionary = z[id]
		var folder: String = t["folder"]
		for group: String in ["stems", "leads"]:
			var g: Dictionary = t.get(group, {})
			for k: String in g:
				var path := folder + str((g[k] as Dictionary)["file"])
				assert_true(ResourceLoader.exists(path) or FileAccess.file_exists(path), "missing " + path)
