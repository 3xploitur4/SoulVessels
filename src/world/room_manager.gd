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
## The player fell below the room (story 021). The game scene decides what it costs.
signal fell_out
## Story 054: the player touched spikes.
signal spiked
## The player walked into an exit that waits on story flag `flag` (story 024).
signal exit_blocked(exit: String, flag: String)

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
## Last place the player stood on solid ground in this room (Soul Echo spot, void-fall return).
var last_safe: Vector2 = Vector2.ZERO
var _spike_cooldown: float = 0.0

var _ignore_exit: String = ""
var _fell: bool = false
var _spawn_seed: int = 5000


func _ready() -> void:
	GameEvents.enemy_died.connect(_on_enemy_died)


## Build `room_id` now (no fade) and place the player: through `exit` when given, else at
## `at` (room metres), else at the room's start marker or its centre.
func enter(room_id: String, exit: String = "", at: Vector2 = Vector2.INF) -> bool:
	var next := WorldData.room(room_id)
	if next == null:
		return false
	return enter_data(next, exit, at)


## As `enter`, for a room that is not in the world files (tests build small rooms inline).
func enter_data(next: RoomData, exit: String = "", at: Vector2 = Vector2.INF) -> bool:
	var room_id := next.id
	_fell = false
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
		player.solid_source = solid_rects
		player.set_room_platforms(builder.oneway_bodies)
	_spawn_enemies()
	_build_water()
	_build_slides_and_dark()
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
	var cd: Variant = Balance.combat("difficulty.%s.enemy_cooldown" % diff)
	e.cooldown_scale = float(cd) if cd != null else 1.0
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


## Is there floor (rock top or one-way platform) right under a body standing at `feet`, at
## least `margin` metres in from the edge? Safe ground must pass this, so a fall never
## returns the player to a ledge lip or over a pit.
func has_ground(feet: Vector2, margin: float = 0.3) -> bool:
	if data == null:
		return false
	for r in data.solids:
		if absf(r.end.y - feet.y) <= 0.25 and feet.x >= r.position.x + margin and feet.x <= r.end.x - margin:
			return true
	for o in data.oneway:
		if absf(o.position.y - feet.y) <= 0.25 and feet.x >= o.position.x + margin and feet.x <= o.end.x - margin:
			return true
	return false


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
	var feet := Vector2(player.global_position.x, player.global_position.y)
	# Spikes first, so standing on them never becomes the safe ground.
	if not data.spikes.is_empty() and _spike_cooldown <= 0.0:
		var body := Rect2(feet.x - 0.3, feet.y, 0.6, 1.6)
		for s in data.spikes:
			if body.intersects(Rect2(s.position.x + 0.1, s.position.y, s.size.x - 0.2, s.size.y * 0.6)):
				_spike_cooldown = 0.6
				spiked.emit()
				return
	_spike_cooldown = maxf(_spike_cooldown - _delta, 0.0)
	if player.is_on_floor() and player.velocity.y <= 0.01 and has_ground(feet):
		last_safe = feet
		_fell = false
	if not _fell and player.global_position.y < -float(Balance.combat("traversal.void_depth_m")):
		_fell = true
		fell_out.emit()
		return
	var centre := Vector2(player.global_position.x, player.global_position.y + 0.9)
	var digit := data.exit_at(centre)
	if digit == "":
		_ignore_exit = ""
		return
	if digit == _ignore_exit:
		return
	var ex: Dictionary = data.exits[digit]
	# Story 024: an exit may wait on a story flag (`exit_needs` in the room data), e.g. the wisp
	# cannot leave the Knight's Vigil before it has taken Caelan's body.
	var need := str((data.raw.get("exit_needs", {}) as Dictionary).get(digit, ""))
	if need != "" and state != null and not state.flag(need):
		var inward := signf(float(data.cols) * 0.5 - player.global_position.x)
		player.teleport(player.global_position.x + inward * 0.8, player.global_position.y)
		player.velocity.x = 0.0
		exit_blocked.emit(digit, need)
		return
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
	var pos := data.fallback_spawn()
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
	last_safe = Vector2(pos.x, pos.y + 0.05)
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
	if e.tier == "elite" or e.tier == "boss":
		GameState.add_unique(state.killed_elites, e.spawn_id)
	else:
		GameState.add_unique(state.killed_commons, e.spawn_id)


# --- Water (story 031) -----------------------------------------------------------------------

## The room's Water node whose id is water_id, or null.
func water(water_id: String) -> Water:
	if features_root == null:
		return null
	for n in features_root.get_children():
		if n is Water and (n as Water).id == water_id:
			return n
	return null


func _build_water() -> void:
	for w: Dictionary in data.water:
		var xs: Array = w.get("x", [0, 1])
		var node := Water.new()
		node.name = "Water_%s" % str(w.get("id", "pool"))
		node.setup(str(w.get("id", "pool")), Vector2(float(xs[0]), float(xs[1])), float(w.get("floor", 0.0)),
			float(w.get("level", 1.0)))
		features_root.add_child(node)


## Rock and every gate still standing, in room metres (bolts stop at these; story 032).
func solid_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if data == null:
		return out
	out.append_array(data.solids)
	if builder != null:
		for kind: String in data.gate_rects.keys():
			if builder.gate_active(kind):
				out.append_array(data.gate_rects[kind])
	return out


# --- Sliding floors and darkness (story 043) --------------------------------------------------

## The room's Darkness overlay, or null in a lit room.
var darkness: Darkness


func _build_slides_and_dark() -> void:
	for s: Dictionary in data.slides:
		var xs: Array = s.get("x", [0, 1])
		var ys: Array = s.get("y", [0, 1])
		var z := SlideZone.new()
		z.name = "Slide"
		z.setup(Vector2(float(xs[0]), float(xs[1])), Vector2(float(ys[0]), float(ys[1])), float(s.get("angle", 0.0)))
		# "strip": false hides the polished strip (a lift floor that only tilts in a boss phase).
		z.show_strip = bool(s.get("strip", true))
		features_root.add_child(z)
	if darkness != null and is_instance_valid(darkness):
		darkness.queue_free()
		darkness = null
	if data.dark:
		darkness = Darkness.new()
		darkness.name = "Darkness"
		darkness.player = player as Player
		darkness.lamps = data.lamps.duplicate()
		var c: Variant = Balance.combat("darkness")
		darkness.lamp_radius_m = float((c as Dictionary).get("lamp_radius_m", 3.0)) if c is Dictionary else 3.0
		features_root.add_child(darkness)
