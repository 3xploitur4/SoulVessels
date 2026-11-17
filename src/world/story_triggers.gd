class_name StoryTriggers
extends Node
## Tutorials and spoken lines placed in a room (story 024; addendum Narrative 1 "Awakening" and
## the Zone 1 tutorials). Each entry in the room's `"story"` list fires once per save:
##
##     {"kind": "tutorial" | "line", "key": "TUT_ATTACK", "speaker": "SPEAKER_VOICE",
##      "x": [3, 9],            # optional: fires when the player is in this span (else on entry)
##      "on": "arena_start",    # optional: fires on that named event instead (see `event`)
##      "needs": "wisp" | "vessel"}   # optional: only while the player is (not) the bare wisp
##
## The game scene listens to `fired` and shows the text; this node never touches the UI.

signal fired(entry: Dictionary)

var room: RoomData
var player: Player
var state: GameState

var _entries: Array[Dictionary] = []


func _ready() -> void:
	for e: Dictionary in room.raw.get("story", []):
		_entries.append(e)


## Fire every entry waiting on event `name` ("arena_start", "arena_clear", "possessed").
func event(name: String) -> void:
	for e in _entries:
		if str(e.get("on", "")) == name:
			_fire(e)


func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player) or not player.is_alive():
		return
	for e in _entries:
		if e.has("on") or _seen(e) or not _needs_met(e):
			continue
		var span: Array = e.get("x", [])
		if span.size() == 2:
			var x := player.global_position.x
			if x < float(span[0]) or x > float(span[1]):
				continue
		_fire(e)


func _fire(e: Dictionary) -> void:
	if _seen(e) or not _needs_met(e):
		return
	if state != null:
		state.set_flag(_flag(e))
	fired.emit(e)


func _needs_met(e: Dictionary) -> bool:
	match str(e.get("needs", "")):
		"wisp":
			return player.is_wisp()
		"vessel":
			return not player.is_wisp()
	return true


func _seen(e: Dictionary) -> bool:
	return state != null and state.flag(_flag(e))


static func _flag(e: Dictionary) -> String:
	return "story_" + str(e.get("key", ""))
