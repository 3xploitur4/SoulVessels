class_name Arena
extends Node
## A locked-room fight (story 024; addendum zone table "Branded Warden set-piece"). The room's
## `L` bars stand open until the player walks into the trigger span, then shut; when every enemy
## in the room is dead they open for good and the arena is saved as cleared. A cleared arena
## never closes again. Room data: `"arena": {"id": "z1_12_warden", "trigger_x": [8, 32]}`.
##
##     var a := Arena.new()
##     a.room = room_data; a.manager = room_manager; a.player = player; a.state = game_state
##     features_root.add_child(a)

signal started(arena_id: String)
signal cleared(arena_id: String)

var room: RoomData
var manager: RoomManager
var player: Player
var state: GameState
var arena_id: String = ""
var running: bool = false
var done: bool = false

var _span: Vector2 = Vector2(-INF, INF)


func _ready() -> void:
	var spec: Dictionary = room.raw.get("arena", {})
	arena_id = str(spec.get("id", room.id))
	var t: Array = spec.get("trigger_x", [])
	if t.size() == 2:
		_span = Vector2(float(t[0]), float(t[1]))
	done = state != null and state.cleared_arenas.has(arena_id)
	if done:
		manager.builder.open_gate("lock")
	else:
		manager.builder.set_gate_active("lock", false)


func _physics_process(_delta: float) -> void:
	if done or player == null or not is_instance_valid(player) or not player.is_alive():
		return
	if not running:
		var x := player.global_position.x
		if x >= _span.x and x <= _span.y and not manager.enemies().is_empty():
			running = true
			manager.builder.set_gate_active("lock", true)
			started.emit(arena_id)
		return
	if manager.enemies().is_empty():
		running = false
		done = true
		manager.builder.open_gate("lock")
		if state != null:
			GameState.add_unique(state.cleared_arenas, arena_id)
		cleared.emit(arena_id)
