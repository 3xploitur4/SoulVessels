class_name Arena
extends Node
## A locked-room fight (story 024 Warden set-piece, story 025 Husk ambush gauntlet). The room's
## `L` bars stand open until the player walks into the trigger span, then shut; when every enemy
## of every wave is dead they open for good and the arena is saved as cleared. A cleared arena
## never closes again. Room data:
##
##     "arena": {"id": "z2_13_gauntlet", "trigger_x": [6, 34], "waves": [[0, 1], [2, 3, 4]]}
##
## `waves` lists the room's enemy markers by reading order (0 = first letter in the grid). Wave 0
## stands in the room from the start; each later wave is held back and appears when the wave
## before it is dead. Without `waves` the whole room is one wave.
##
##     var a := Arena.new()
##     a.room = room_data; a.manager = room_manager; a.player = player; a.state = game_state
##     features_root.add_child(a)

signal started(arena_id: String)
## Wave `index` (1-based for later waves) has appeared.
signal wave_started(arena_id: String, index: int)
signal cleared(arena_id: String)

var room: RoomData
var manager: RoomManager
var player: Player
var state: GameState
var arena_id: String = ""
var running: bool = false
var done: bool = false
## Index of the wave in play (0 before and during the first).
var wave: int = 0

var _span: Vector2 = Vector2(-INF, INF)
## Later waves: each a list of spawn records (from `room.spawns`) held back until their turn.
var _held: Array = []


func _ready() -> void:
	var spec: Dictionary = room.raw.get("arena", {})
	arena_id = str(spec.get("id", room.id))
	var t: Array = spec.get("trigger_x", [])
	if t.size() == 2:
		_span = Vector2(float(t[0]), float(t[1]))
	done = state != null and state.cleared_arenas.has(arena_id)
	if done:
		manager.builder.open_gate("lock")
		return
	manager.builder.set_gate_active("lock", false)
	var waves: Array = spec.get("waves", [])
	for i in range(1, waves.size()):
		var group: Array = []
		for idx in waves[i]:
			var n := int(idx)
			if n >= 0 and n < room.spawns.size():
				group.append(room.spawns[n])
		_held.append(group)
	# Hold the later waves back: they were spawned with the room.
	var held_ids := {}
	for group: Array in _held:
		for s: Dictionary in group:
			held_ids[str(s["spawn_id"])] = true
	for e in manager.enemies():
		if held_ids.has(e.spawn_id):
			e.get_parent().remove_child(e)
			e.queue_free()


## Waves still to come after the one in play.
func waves_left() -> int:
	return _held.size()


func _physics_process(_delta: float) -> void:
	if done or player == null or not is_instance_valid(player) or not player.is_alive():
		return
	if not running:
		var x := player.global_position.x
		if x >= _span.x and x <= _span.y and (not manager.enemies().is_empty() or not _held.is_empty()):
			running = true
			manager.builder.set_gate_active("lock", true)
			started.emit(arena_id)
		return
	if not manager.enemies().is_empty():
		return
	if not _held.is_empty():
		wave += 1
		var group: Array = _held.pop_front()
		for s: Dictionary in group:
			var pos: Vector2 = s["pos"]
			var e := manager.spawn(str(s["id"]), pos.x, pos.y, str(s["spawn_id"]), float(s.get("ceiling_y", NAN)))
			# An ambush: statues in a later wave come already awake.
			if e != null and e.has_method("wake"):
				e.call("wake")
		wave_started.emit(arena_id, wave)
		return
	running = false
	done = true
	manager.builder.open_gate("lock")
	if state != null:
		GameState.add_unique(state.cleared_arenas, arena_id)
	cleared.emit(arena_id)
