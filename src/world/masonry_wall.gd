class_name MasonryWall
extends Node3D
## Cracked masonry (story 042; addendum gate table): orange-veined stone that only a heavy blow
## breaks: a packet tagged `breaks_masonry` (Darius's Crushing Blow and Groundbreaker). It sits in
## the combat world as a target so those hits reach it; any other hit is ignored. Breaking it
## removes that one stretch of masonry (a wall or a floor), plays dust and a crash, and records it
## in the save as "<room>:masonry:<index>" so it stays open.
##
##     MasonryWall.build_for(room_manager, room_data, game_state)   # a room feature

var manager: RoomManager
var state: GameState
var gate_id: String = ""
var rect: Rect2
var body: Node3D
var team: int = CombatWorld.TEAM_ENEMY
var broken: bool = false


## One MasonryWall per masonry rect in the room; already-broken ones are removed at once.
static func build_for(m: RoomManager, room: RoomData, game_state: GameState) -> void:
	var rects: Array = room.gate_rects.get("masonry", [])
	# Story 049: some masonry gives way to an event instead (the Breach in z3_18 cracks open when
	# the Sovereign falls, so Zone 4, where Darius is found, can be reached without him).
	# Room JSON: "masonry_opens_on": "<save flag>".
	var opens_on := str(room.raw.get("masonry_opens_on", ""))
	if opens_on != "" and game_state != null and game_state.flag(opens_on):
		for i in range(rects.size()):
			GameState.add_unique(game_state.opened_gates, "%s:masonry:%d" % [room.id, i])
	var bodies: Array = m.builder.gate_bodies.get("masonry", [])
	for i in range(rects.size()):
		var w := MasonryWall.new()
		w.name = "Masonry%d" % i
		w.manager = m
		w.state = game_state
		w.gate_id = "%s:masonry:%d" % [room.id, i]
		w.rect = rects[i]
		w.body = bodies[i] if i < bodies.size() else null
		m.features_root.add_child(w)


func _ready() -> void:
	if state != null and state.opened_gates.has(gate_id):
		_remove_body()
		broken = true
		return
	if manager != null and manager.world != null:
		manager.world.register(self)


func _exit_tree() -> void:
	if manager != null and manager.world != null:
		manager.world.unregister(self)


func hurt_rect() -> Rect2:
	return rect


func is_alive() -> bool:
	return not broken


## Only a masonry-breaking blow counts.
func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	if broken or not bool(p.tags.get("breaks_masonry", false)):
		return DamagePacket.Result.IGNORED
	_break()
	return DamagePacket.Result.KILLED


func _break() -> void:
	broken = true
	if manager != null and manager.world != null:
		manager.world.unregister(self)
	_remove_body()
	if state != null:
		GameState.add_unique(state.opened_gates, gate_id)
	Sfx.play("guard_break")
	Sfx.play("gate_open")
	GameEvents.camera_shake_requested.emit(0.6)
	GameEvents.ultimate_fx_requested.emit("final_stand", Vector3(rect.get_center().x, rect.position.y, 0.0),
		maxf(rect.size.x, rect.size.y) * 0.6)
	for i in range(int(clampf(rect.size.x * rect.size.y, 2.0, 10.0))):
		GameEvents.hit_fx_requested.emit(Vector3(rect.position.x + randf() * rect.size.x,
			rect.position.y + randf() * rect.size.y, 0.3), 0.0, false, true)


func _remove_body() -> void:
	if body != null and is_instance_valid(body):
		body.queue_free()
	# The "examine" hint on this stretch of masonry (story 023) goes with it.
	if manager != null and manager.features_root != null:
		for n in manager.features_root.get_children():
			if n is SealedGate and (n as SealedGate).kind == "masonry":
				var at := Vector2((n as Node3D).global_position.x, (n as Node3D).global_position.y)
				if rect.grow(1.0).has_point(at):
					n.queue_free()
	if manager != null and manager.builder != null:
		var list: Array = manager.builder.gate_bodies.get("masonry", [])
		list.erase(body)
		if list.is_empty():
			manager.builder.gate_bodies.erase("masonry")
	body = null
