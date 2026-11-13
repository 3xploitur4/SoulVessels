extends Node3D
## M1 combat sandbox (story 013): builds the arena, the player, the camera, enemy waves, the HUD,
## touch controls, the debug HUD and (debug builds or `--bridge`) the playtest bridge. Everything
## is constructed here and injected, so tests can build any piece alone.
##
## Command-line user args (after `--`):
##   --no-waves        start with an empty arena (bridge scripts spawn what they need)
##   --bridge          enable the playtest bridge in a release build
##   --wave N          start at wave N (0-based)
##   --vessel ID       start with this Vessel active

const BOOT_MARKER := "SOULVESSELS_BOOT_OK"

var world: CombatWorld
var arena: SandboxArena
var player: Player
var camera: SideCamera
var input_router: InputRouter
var fx: FxLayer
var hud: CanvasLayer
var touch: CanvasLayer
var debug_hud: CanvasLayer
var bridge_handler: Node
## Where enemies live (cleared by `kill_all`).
var enemies_root: Node3D
var waves_enabled: bool = true
var wave_index: int = 0

var _wave_delay_left: float = -1.0
var _spawn_seed: int = 1000
var _hitstop_token: int = 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	waves_enabled = not args.has("--no-waves")
	var start_wave := args.find("--wave")
	if start_wave >= 0 and start_wave + 1 < args.size():
		wave_index = int(args[start_wave + 1])
	input_router = InputRouter.new()
	input_router.name = "InputRouter"
	add_child(input_router)
	world = CombatWorld.new()
	world.name = "CombatWorld"
	add_child(world)
	arena = SandboxArena.new()
	arena.name = "Arena"
	add_child(arena)
	enemies_root = Node3D.new()
	enemies_root.name = "Enemies"
	add_child(enemies_root)
	fx = FxLayer.new()
	fx.name = "Fx"
	fx.show_numbers = bool(Balance.sandbox("show_damage_numbers"))
	add_child(fx)
	_spawn_player(args)
	camera = SideCamera.new()
	camera.name = "SideCamera"
	camera.target = player
	camera.bounds = Vector2(arena.left_bound, arena.right_bound)
	add_child(camera)
	camera.snap()
	_build_ui()
	GameEvents.hitstop_requested.connect(_on_hitstop)
	GameEvents.camera_shake_requested.connect(camera.add_trauma)
	GameEvents.enemy_died.connect(_on_enemy_died)
	GameEvents.ultimate_fx_requested.connect(_on_ultimate_fx)
	player.ultimate_started.connect(func(_id: String) -> void: camera.zoom_in = 1.0)
	MusicDirector.listener = player
	MusicDirector.start_zone("zone1")
	MusicDirector.set_vessel(player.loadout.active().id)
	if OS.is_debug_build() or args.has("--bridge"):
		_start_bridge()
	if waves_enabled:
		spawn_wave(wave_index)
	print("%s version=%s renderer=%s physics=%s" % [
		BOOT_MARKER,
		ProjectSettings.get_setting("application/config/version"),
		RenderingServer.get_current_rendering_method(),
		ProjectSettings.get_setting("physics/3d/physics_engine"),
	])


func _process(delta: float) -> void:
	if camera.zoom_in > 0.0 and player.state != "ultimate":
		camera.zoom_in = maxf(camera.zoom_in - delta * 2.0, 0.0)
	if _wave_delay_left > 0.0:
		_wave_delay_left -= delta
		if _wave_delay_left <= 0.0:
			wave_index = (wave_index + 1) % _wave_count()
			spawn_wave(wave_index)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key := (event as InputEventKey).physical_keycode
		if key == KEY_F5:
			kill_all()
			spawn_wave(wave_index)
		elif key == KEY_F6:
			player.gauge.add(300.0)


# --- Spawning (also used by the bridge) ------------------------------------------------------

## Spawn enemy `enemy_id` at x on the floor. Returns the enemy, or null for an unknown id.
func spawn(enemy_id: String, x: float) -> EnemyBase:
	var e := EnemyFactory.create(enemy_id)
	if e == null:
		return null
	_spawn_seed += 1
	e.world = world
	e.rng_seed = _spawn_seed
	e.damage_scale = float(Balance.combat("difficulty.%s.enemy_damage" % player.difficulty))
	e.name = "%s_%d" % [enemy_id, _spawn_seed]
	enemies_root.add_child(e)
	var y := 0.05
	if enemy_id == "subterranean_watcher":
		y = float(Balance.enemy(enemy_id).get("hover_height_m", 4.0))
	e.global_position = Vector3(clampf(x, arena.left_bound + 1.0, arena.right_bound - 1.0), y, 0.0)
	e.facing = -1 if x > player.global_position.x else 1
	e.reset_physics_interpolation()
	return e


func spawn_wave(index: int) -> void:
	var waves: Array = Balance.sandbox("waves") if Balance.sandbox("waves") is Array else []
	if waves.is_empty():
		return
	for entry: Dictionary in waves[index % waves.size()]:
		spawn(str(entry.get("id", "")), float(entry.get("x", 0.0)))


func kill_all() -> void:
	_wave_delay_left = -1.0
	for e in enemies_root.get_children():
		e.queue_free()


func enemies() -> Array[EnemyBase]:
	var out: Array[EnemyBase] = []
	for e in enemies_root.get_children():
		if e is EnemyBase and (e as EnemyBase).is_alive():
			out.append(e as EnemyBase)
	return out


func _wave_count() -> int:
	var waves: Variant = Balance.sandbox("waves")
	return (waves as Array).size() if waves is Array else 1


# --- Setup ----------------------------------------------------------------------------------

func _spawn_player(args: PackedStringArray) -> void:
	player = Player.new()
	player.name = "Player"
	player.world = world
	player.controls = input_router
	player.fx_parent = self
	var ids: Array[String] = []
	var lo: Variant = Balance.sandbox("loadout")
	if lo is Array:
		for v in lo:
			ids.append(str(v))
	if not ids.is_empty():
		player.vessel_ids = ids
	var diff: Variant = Balance.sandbox("difficulty")
	if diff != null:
		player.difficulty = str(diff)
	var sp: Variant = Balance.sandbox("player_spawn")
	var spawn_at := Vector3(-4.0, 0.2, 0.0)
	if sp is Array and (sp as Array).size() >= 2:
		spawn_at = Vector3(float(sp[0]), float(sp[1]), 0.0)
	add_child(player)
	player.global_position = spawn_at
	player.spawn_point = spawn_at
	player.reset_physics_interpolation()
	var v := args.find("--vessel")
	if v >= 0 and v + 1 < args.size():
		var idx := player.loadout.index_of(args[v + 1])
		if idx >= 0:
			player.try_swap(idx, true)


func _build_ui() -> void:
	hud = Hud.new()
	hud.name = "Hud"
	(hud as Hud).player = player
	(hud as Hud).world = world
	(hud as Hud).camera = camera
	add_child(hud)
	touch = TouchControls.new()
	touch.name = "TouchControls"
	(touch as TouchControls).router = input_router
	(touch as TouchControls).player = player
	add_child(touch)
	debug_hud = DebugHud.new()
	debug_hud.name = "DebugHud"
	(debug_hud as DebugHud).sandbox = self
	add_child(debug_hud)


func _start_bridge() -> void:
	var port := 9177
	var env := OS.get_environment("BRIDGE_PORT")
	if env.is_valid_int():
		port = int(env)
	bridge_handler = DebugBridge.new()
	bridge_handler.name = "DebugBridge"
	(bridge_handler as DebugBridge).sandbox = self
	add_child(bridge_handler)
	var b := Bridge.new()
	b.name = "Bridge"
	b.handler = bridge_handler
	add_child(b)
	b.start(port)


# --- Events ---------------------------------------------------------------------------------

func _on_hitstop(duration: float) -> void:
	if duration <= 0.0:
		return
	_hitstop_token += 1
	var token := _hitstop_token
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	if token == _hitstop_token:
		Engine.time_scale = 1.0


func _on_enemy_died(_enemy: Node) -> void:
	if not waves_enabled:
		return
	# The dying enemy is still in the tree for its dissolve; count the living.
	if enemies().is_empty() and _wave_delay_left <= 0.0:
		_wave_delay_left = float(Balance.sandbox("wave_delay_s"))


func _on_ultimate_fx(kind: String, _where: Vector3, _size: float) -> void:
	if kind == "final_stand" or kind == "dance_of_shadows":
		camera.add_trauma(0.4)
