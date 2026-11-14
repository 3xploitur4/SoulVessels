class_name RoomManager
extends Node3D
## Runs the room the player is in (story 015): builds it, spawns its enemies (skipping the ones
## the save says are dead), places the player at the arrival point of the exit they came through,
## clamps the camera, and moves to the next room when the player steps into an exit, behind a
## fade. Room features (altars, pickups, gates, events) are built by callables registered in
## `feature_builders`, so each feature lives in its own file and tests can leave them out.
##
## Inject before add_child:
##     var rm := RoomManager.new()
##     rm.world = combat_world; rm.player = player; rm.camera = camera
##     rm.state = game_state; rm.fader = fader      # fader may be null (instant)
##     add_child(rm)
##     rm.enter("z1_01")

signal room_entered(room_id: String)
signal room_left(room_id: String)

const FADE_OUT_S := 0.18
const FADE_IN_S := 0.25

var world: CombatWorld
var player: Player
var camera: SideCamera
var state: GameState
var fader: Fader
## func(manager: RoomManager, room: RoomData) -> void, called after geometry and enemies.
var feature_builders: Array[Callable] = []

var data: RoomData
var builder: RoomBuilder
var enemies_root: Node3D
## Room features (altars, pickups, gates); cleared on every room change.
var features_root: Node3D
## Projectiles and short-lived effects; cleared on every room change.
var transient_root: Node3D
var transitioning: bool = false

var _ignore_exit: String = ""
var _spawn_seed: int = 5000


func _ready() -> void:
	GameEvents.enemy_died.connect(_on_enemy_died)


## Build `room_id` now (no fade) and place the player: through `exit` when given, else at
## `at` (room metres), else at the room's start marker or its centre.
func enter(room_id: String, exit: String = "", at: Vector2 = Vector2.INF) -> bool:
	var next := WorldData.room(room_id)
	if next == null:
		return false
	if data != null:
		room_left.emit(data.id)
	_clear()
	data = next
	builder = RoomBuilder.new()
	builder.name = "Room_%s" % room_id
	builder.data = data
	add_child(builder)
	enemies_root = Node3D.new()
	enemies_root.name = "Enemies"
	add_child(enemies_root)
	features_root = Node3D.new()
	features_root.name = "Features"
	add_child(features_root)
	transient_root = Node3D.new()
	transient_root.name = "Transient"
	add_child(transient_root)
	if player != null:
		player.fx_parent = transient_root
		player.set_room_platforms(builder.oneway_bodies)
	_spawn_enemies()
	for build: Callable in feature_builders:
		build.call(self, data)
	_place_player(exit, at)
	if camera != null:
		camera.bounds = Vector2(0.0, float(data.cols))
		camera.v_bounds = Vector2(0.0, float(data.rows))
		camera.use_v_bounds = true
		camera.snap()
	if state != null:
		state.current_room = room_id
		GameState.add_unique(state.visited_rooms, room_id)
	room_entered.emit(room_id)
	return true


## Fade out, enter `room_id` through `exit`, fade in. Awaitable; ignored while one runs.
func travel(room_id: String, exit: String = "", at: Vector2 = Vector2.INF) -> void:
	if transitioning:
		return
	transitioning = true
	if player != null:
		player.input_enabled = false
	if fader != null:
		await fader.fade_to(1.0, FADE_OUT_S)
	enter(room_id, exit, at)
	if player != null:
		player.input_enabled = true
	if fader != null:
		await fader.fade_to(0.0, FADE_IN_S)
	transitioning = false


## Living enemies in this room.
func enemies() -> Array[EnemyBase]:
	var out: Array[EnemyBase] = []
	if enemies_root == null:
		return out
	for e in enemies_root.get_children():
		if e is EnemyBase and (e as EnemyBase).is_alive():
			out.append(e as EnemyBase)
	return out


## Spawn `enemy_id` with its feet at (x, y) (room metres). `spawn_id` ties it to the save.
func spawn(enemy_id: String, x: float, y: float, spawn_id: String = "", ceiling_y: float = NAN) -> EnemyBase:
	var e := EnemyFactory.create(enemy_id)
	if e == null:
		return null
	_spawn_seed += 1
	e.world = world
	e.rng_seed = _spawn_seed
	e.spawn_id = spawn_id
	var diff := state.difficulty if state != null else "normal"
	e.damage_scale = float(Balance.combat("difficulty.%s.enemy_damage" % diff))
	e.name = "%s_%d" % [enemy_id, _spawn_seed]
	if not is_nan(ceiling_y) and e.has_method("set_ceiling"):
		e.call("set_ceiling", ceiling_y)
	enemies_root.add_child(e)
	e.global_position = Vector3(x, y + EnemyFactory.spawn_height(enemy_id), 0.0)
	if player != null:
		e.facing = -1 if x > player.global_position.x else 1
	e.reset_physics_interpolation()
	return e


func kill_all() -> void:
	if enemies_root == null:
		return
	for e in enemies_root.get_children():
		enemies_root.remove_child(e)
		e.queue_free()


## Altar rest and respawn: clear this room's enemies and spawn the ones the save says are alive.
func respawn_enemies() -> void:
	kill_all()
	if data != null:
		_spawn_enemies()


## Is `p` (room metres) inside rock?
func is_solid(p: Vector2) -> bool:
	if data == null:
		return false
	for r in data.solids:
		if r.has_point(p):
			return true
	return false


func _physics_process(_delta: float) -> void:
	if data == null or player == null or transitioning or not player.is_alive():
		return
	var centre := Vector2(player.global_position.x, player.global_position.y + 0.9)
	var digit := data.exit_at(centre)
	if digit == "":
		_ignore_exit = ""
		return
	if digit == _ignore_exit:
		return
	var ex: Dictionary = data.exits[digit]
	var to := str(ex.get("to", ""))
	if to == "" or WorldData.room(to) == null:
		return
	travel(to, str(ex.get("exit", "")))


func _spawn_enemies() -> void:
	for s: Dictionary in data.spawns:
		var sid := str(s["spawn_id"])
		if state != null and state.is_spawn_dead(sid, bool(s["elite"])):
			continue
		var pos: Vector2 = s["pos"]
		spawn(str(s["id"]), pos.x, pos.y, sid, float(s.get("ceiling_y", NAN)))


func _place_player(exit: String, at: Vector2) -> void:
	if player == null:
		return
	var pos := Vector2(float(data.cols) * 0.5, 1.0)
	var boost := false
	if exit != "" and data.exits.has(exit):
		pos = data.exits[exit]["arrive"]
		boost = bool(data.exits[exit]["boost"])
		_ignore_exit = exit
	elif at != Vector2.INF and at.x >= 0.0:
		pos = at
		_ignore_exit = data.exit_at(Vector2(at.x, at.y + 0.9))
	elif data.markers.has("start"):
		pos = data.markers["start"]
	player.teleport(pos.x, pos.y + 0.05)
	player.spawn_point = player.global_position
	if boost:
		player.velocity.y = float(Balance.combat("movement.jump_velocity")) * 1.05


func _clear() -> void:
	for n: Node in [builder, enemies_root, features_root, transient_root]:
		if n != null and is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	builder = null
	enemies_root = null
	features_root = null
	transient_root = null


func _on_enemy_died(enemy: Node) -> void:
	if state == null or not enemy is EnemyBase:
		return
	var e := enemy as EnemyBase
	if e.spawn_id == "":
		return
	if e.tier == "elite":
		GameState.add_unique(state.killed_elites, e.spawn_id)
	else:
		GameState.add_unique(state.killed_commons, e.spawn_id)
