class_name SaveSystem
extends RefCounted
## Three save slots as JSON files (story 014). Writes are atomic: the new file is written next to
## the old one and renamed over it, so a crash or a killed app never leaves half a save. A file
## that will not parse is kept as `slot_N.json.bad` and the slot reads as empty.
##
##     var saves := SaveSystem.new()          # user://saves
##     saves.save(0, game_state)
##     var gs := saves.load_slot(0)           # null when empty
##     var card := saves.summary(0)           # for the title screen

const SLOTS := 3

## Folder for the slot files (tests point it at a temp folder).
var dir: String = "user://saves"


func _init(folder: String = "user://saves") -> void:
	dir = folder


func path(slot: int) -> String:
	return dir.path_join("slot_%d.json" % slot)


func exists(slot: int) -> bool:
	return FileAccess.file_exists(path(slot))


## Write `state` to `slot`. False on any file error (the old save stays intact).
func save(slot: int, state: GameState) -> bool:
	if slot < 0 or slot >= SLOTS or state == null:
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var data := state.to_dict()
	data["saved_at"] = int(Time.get_unix_time_from_system())
	var tmp := path(slot) + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: cannot write %s (%d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.flush()
	f.close()
	var final_path := ProjectSettings.globalize_path(path(slot))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), final_path)
	if err != OK:
		# Some platforms refuse to rename over an existing file: replace it in two steps.
		DirAccess.remove_absolute(final_path)
		err = DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), final_path)
	if err != OK:
		push_error("SaveSystem: cannot move %s into place (%d)" % [tmp, err])
		return false
	return true


## The state in `slot`, or null when the slot is empty or corrupt.
func load_slot(slot: int) -> GameState:
	var raw := _read(slot)
	return GameState.from_dict(raw) if not raw.is_empty() else null


## What the title screen shows for `slot`: {"exists": false} or the save's headline values.
func summary(slot: int) -> Dictionary:
	var raw := _read(slot)
	if raw.is_empty():
		return {"exists": false}
	var gs := GameState.from_dict(raw)
	return {
		"exists": true,
		"room": gs.current_room,
		"difficulty": gs.difficulty,
		"essence": gs.essence,
		"play_time_s": gs.play_time_s,
		"vessels": gs.unlocked_vessels.duplicate(),
		"saved_at": int(raw.get("saved_at", 0)),
	}


## Has any run finished Chapter I? (Abyssal difficulty unlocks for new games; story 047.)
func chapter_complete() -> bool:
	if not FileAccess.file_exists(dir.path_join("profile.json")):
		return false
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("profile.json")))
	return d is Dictionary and bool((d as Dictionary).get("chapter1_complete", false))


## Record that Chapter I was finished, beside the save slots.
func mark_chapter_complete() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var f := FileAccess.open(dir.path_join("profile.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"chapter1_complete": true}))


func delete(slot: int) -> void:
	if exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path(slot)))


func _read(slot: int) -> Dictionary:
	if not exists(slot):
		return {}
	var text := FileAccess.get_file_as_string(path(slot))
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	push_error("SaveSystem: slot %d is corrupt; kept as .bad" % slot)
	var abs_path := ProjectSettings.globalize_path(path(slot))
	DirAccess.remove_absolute(abs_path + ".bad")
	DirAccess.rename_absolute(abs_path, abs_path + ".bad")
	return {}
