extends TestCase
## Story 014: save slots on disk (a temp folder under user://, removed after each test).

const DIR := "user://test_saves"

var saves: SaveSystem


func before_each() -> void:
	_clear()
	saves = SaveSystem.new(DIR)


func after_each() -> void:
	_clear()


func _clear() -> void:
	var abs_dir := ProjectSettings.globalize_path(DIR)
	if DirAccess.dir_exists_absolute(abs_dir):
		for f in DirAccess.get_files_at(abs_dir):
			DirAccess.remove_absolute(abs_dir.path_join(f))
		DirAccess.remove_absolute(abs_dir)


func test_empty_slot_reads_as_empty() -> void:
	assert_false(saves.exists(0))
	assert_null(saves.load_slot(0))
	assert_eq(saves.summary(0), {"exists": false})


func test_save_then_load_round_trips() -> void:
	var gs := GameState.new_game("normal")
	gs.essence = 77
	gs.add_item("lesser_soul_shard", 2)
	assert_true(saves.save(1, gs))
	var back := saves.load_slot(1)
	assert_not_null(back)
	assert_eq(back.essence, 77)
	assert_eq(back.item_count("lesser_soul_shard"), 2)
	assert_false(saves.exists(0), "other slots untouched")


func test_overwrite_replaces_and_leaves_no_temp_file() -> void:
	var gs := GameState.new_game()
	gs.essence = 1
	saves.save(0, gs)
	gs.essence = 2
	assert_true(saves.save(0, gs), "rename over an existing save works on this platform")
	assert_eq(saves.load_slot(0).essence, 2)
	assert_false(FileAccess.file_exists(saves.path(0) + ".tmp"))


func test_summary_has_the_title_card_values() -> void:
	var gs := GameState.new_game("story")
	gs.current_room = "z1_04"
	gs.essence = 300
	gs.play_time_s = 61.0
	gs.unlock_vessel("caelan")
	saves.save(2, gs)
	var s := saves.summary(2)
	assert_true(bool(s["exists"]))
	assert_eq(str(s["room"]), "z1_04")
	assert_eq(str(s["difficulty"]), "story")
	assert_eq(int(s["essence"]), 300)
	assert_gt(float(s["saved_at"]), 0.0)


func test_corrupt_file_reads_empty_and_is_kept_aside() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
	var f := FileAccess.open(saves.path(0), FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	assert_null(saves.load_slot(0))
	assert_false(saves.exists(0))
	assert_true(FileAccess.file_exists(saves.path(0) + ".bad"))


func test_delete_and_bad_slot_numbers() -> void:
	saves.save(0, GameState.new_game())
	saves.delete(0)
	assert_false(saves.exists(0))
	assert_false(saves.save(3, GameState.new_game()), "only 3 slots")
	assert_false(saves.save(-1, GameState.new_game()))
