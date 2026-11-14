extends Node3D
## Soul Vessels main scene (story 016): the title screen, starting and continuing a save slot,
## the run (player, rooms, HUD, touch controls, prompts), pause, autosave on zone entry and the
## suspend-save when Android backgrounds the app. Room features register here through
## `register_feature`, so each lives in its own file.
##
## Command-line user args (after `--`), for tests and the playtest bridge:
##   --new-game SLOT [--difficulty story|normal]   skip the title, start a new run in SLOT
##   --continue SLOT                                skip the title, continue SLOT
##   --room ID [--loadout caelan,nyra]              start a throwaway run in a room (slot 2)
##   --save-dir PATH                                save folder (default user://saves)
##   --bridge                                       playtest bridge in a release build

const BOOT_MARKER := "SOULVESSELS_BOOT_OK"
## The room shown behind the title screen.
const TITLE_ROOM := "z1_04"

signal run_started
signal run_ended

## Set before add_child to override the save folder (tests).
var save_dir: String = ""
## Set false before add_child to skip the playtest bridge (tests).
var enable_bridge: bool = true
var saves: SaveSystem
var state: GameState
var slot: int = -1
var playing: bool = false

var input_router: InputRouter
var world: CombatWorld
var camera: SideCamera
var rooms: RoomManager
var fader: Fader
var prompts: Prompts
var fx: FxLayer
var hud: Hud
var touch: TouchControls
var debug_hud: DebugHud
var title: TitleScreen
var pause_menu: PauseMenu
var altar_menu: AltarMenu
var player: Player
var bridge_handler: Node

var _zone: String = ""
var _interact_target: Interactable
var _camera_anchor: Node3D
var _hitstop_token: int = 0
var _features: Array[Callable] = []


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	saves = SaveSystem.new(save_dir if save_dir != "" else _arg(args, "--save-dir", "user://saves"))
	input_router = InputRouter.new()
	input_router.name = "InputRouter"
	add_child(input_router)
	world = CombatWorld.new()
	world.name = "CombatWorld"
	add_child(world)
	_camera_anchor = Node3D.new()
	_camera_anchor.name = "CameraAnchor"
	add_child(_camera_anchor)
	camera = SideCamera.new()
	camera.name = "SideCamera"
	camera.target = _camera_anchor
	add_child(camera)
	rooms = RoomManager.new()
	rooms.name = "Rooms"
	rooms.world = world
	rooms.camera = camera
	add_child(rooms)
	rooms.room_entered.connect(_on_room_entered)
	register_feature(_build_altar)
	fx = FxLayer.new()
	fx.name = "Fx"
	fx.show_numbers = true
	add_child(fx)
	fader = Fader.new()
	fader.name = "Fader"
	add_child(fader)
	rooms.fader = fader
	prompts = Prompts.new()
	prompts.name = "Prompts"
	prompts.router = input_router
	add_child(prompts)
	debug_hud = DebugHud.new()
	debug_hud.name = "DebugHud"
	debug_hud.sandbox = self
	add_child(debug_hud)
	GameEvents.hitstop_requested.connect(_on_hitstop)
	GameEvents.camera_shake_requested.connect(camera.add_trauma)
	GameEvents.ultimate_fx_requested.connect(_on_ultimate_fx)
	if enable_bridge and (OS.is_debug_build() or args.has("--bridge")):
		_start_bridge()
	print("%s version=%s renderer=%s physics=%s" % [BOOT_MARKER,
		ProjectSettings.get_setting("application/config/version"),
		RenderingServer.get_current_rendering_method(),
		ProjectSettings.get_setting("physics/3d/physics_engine")])
	var new_slot := int(_arg(args, "--new-game", "-1"))
	var cont_slot := int(_arg(args, "--continue", "-1"))
	var room := _arg(args, "--room", "")
	if new_slot >= 0:
		start_new(new_slot, _arg(args, "--difficulty", "normal"))
	elif cont_slot >= 0:
		continue_game(cont_slot)
	elif room != "":
		var gs := GameState.new_game(_arg(args, "--difficulty", "normal"))
		for v in _arg(args, "--loadout", "").split(",", false):
			gs.unlock_vessel(v)
		gs.checkpoint = {"room": room, "x": -1.0, "y": -1.0}
		begin_run(2, gs)
	else:
		show_title()


## Room features (altars, pickups, gates): `build(manager, room)` runs for every room built.
func register_feature(build: Callable) -> void:
	_features.append(build)
	rooms.feature_builders.append(build)


# --- Title ----------------------------------------------------------------------------------

func show_title() -> void:
	if title != null:
		title.queue_free()
		title = null
	close_pause()
	_end_run()
	prompts.clear()
	_camera_anchor.position = Vector3(13.0, 4.0, 0.0)
	camera.target = _camera_anchor
	rooms.enter(TITLE_ROOM)
	camera.snap()
	_play_music("title")
	title = TitleScreen.new()
	title.name = "Title"
	title.summaries = _summaries()
	title.new_game_requested.connect(start_new)
	title.continue_requested.connect(continue_game)
	title.delete_requested.connect(func(i: int) -> void:
		saves.delete(i)
		title.refresh(_summaries()))
	add_child(title)
	fader.fade_to(0.0, 0.4)


func _summaries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(SaveSystem.SLOTS):
		out.append(saves.summary(i))
	return out


# --- Runs -----------------------------------------------------------------------------------

func start_new(new_slot: int, difficulty: String) -> void:
	var gs := GameState.new_game(difficulty)
	saves.save(new_slot, gs)
	begin_run(new_slot, gs)


func continue_game(load_slot: int) -> void:
	var gs := saves.load_slot(load_slot)
	if gs == null:
		push_error("Game: slot %d is empty" % load_slot)
		return
	begin_run(load_slot, gs)


## Start playing `gs` in `run_slot`: build the player and the HUD, enter the resume point (once)
## or the checkpoint.
func begin_run(run_slot: int, gs: GameState) -> void:
	if title != null:
		title.queue_free()
		title = null
	_end_run()
	slot = run_slot
	state = gs
	_zone = ""
	player = Player.new()
	player.name = "Player"
	player.world = world
	player.controls = input_router
	player.vessel_ids = state.loadout.duplicate()
	player.difficulty = state.difficulty
	player.affinity_levels = affinity_levels()
	add_child(player)
	camera.target = player
	rooms.player = player
	rooms.state = state
	MusicDirector.listener = player
	hud = Hud.new()
	hud.name = "Hud"
	hud.player = player
	hud.world = world
	hud.camera = camera
	hud.state = state
	add_child(hud)
	touch = TouchControls.new()
	touch.name = "TouchControls"
	touch.router = input_router
	touch.player = player
	add_child(touch)
	var entry := state.resume if not state.resume.is_empty() else state.checkpoint
	state.resume = {}
	var at := Vector2(float(entry.get("x", -1.0)), float(entry.get("y", -1.0)))
	rooms.enter(str(entry.get("room", GameState.START_ROOM)), "", at if at.x >= 0.0 else Vector2.INF)
	playing = true
	fader.fade_to(0.0, 0.4)
	run_started.emit()


## Vessel id -> Affinity level for the player.
func affinity_levels() -> Dictionary:
	var out := {}
	for v in state.unlocked_vessels:
		out[v] = 0
	return out


## Save the slot now. `resume` also records where the player stands, so Continue starts there.
func save_now(resume: bool = false) -> bool:
	if state == null or slot < 0:
		return false
	if resume and player != null and rooms.data != null:
		state.resume = {"room": rooms.data.id, "x": player.global_position.x, "y": player.global_position.y}
	var ok := saves.save(slot, state)
	if resume:
		state.resume = {}
	return ok


func quit_to_title() -> void:
	close_pause()
	save_now(true)
	await fader.fade_to(1.0, 0.3)
	show_title()


func _end_run() -> void:
	if altar_menu != null:
		altar_menu.queue_free()
		altar_menu = null
		get_tree().paused = false
	playing = false
	_interact_target = null
	if player != null:
		player.queue_free()
		player = null
	for n: Node in [hud, touch]:
		if n != null and is_instance_valid(n):
			n.queue_free()
	hud = null
	touch = null
	rooms.player = null
	rooms.state = null
	if was_running():
		run_ended.emit()


func was_running() -> bool:
	return state != null and slot >= 0


func _on_room_entered(room_id: String) -> void:
	if not playing and player == null:
		return
	var zone := WorldData.zone_of(room_id)
	if zone != _zone:
		var first := _zone == ""
		_zone = zone
		prompts.title_card(tr(str(WorldData.zone(zone).get("title", ""))))
		_play_music(str(WorldData.zone(zone).get("music", zone)))
		if not first and state != null:
			# Zone-entry autosave: Continue starts at this door.
			state.checkpoint = {"room": room_id, "x": player.global_position.x, "y": player.global_position.y}
			save_now()


func _play_music(zone_id: String) -> void:
	if MusicDirector.has_zone(zone_id) and MusicDirector.zone != zone_id:
		MusicDirector.start_zone(zone_id)
		if player != null:
			MusicDirector.set_vessel(player.loadout.active().id)


# --- Soul Altars (story 017) ---------------------------------------------------------------

func _build_altar(manager: RoomManager, room: RoomData) -> void:
	if not room.markers.has("altar"):
		return
	var spec: Dictionary = room.raw.get("altar", {})
	var a := Altar.new()
	a.name = "Altar"
	a.altar_id = str(spec.get("id", room.id + "_altar"))
	a.name_key = str(spec.get("name", "ALTAR"))
	a.lit = state != null and state.lit_altars.has(a.altar_id)
	manager.features_root.add_child(a)
	var pos: Vector2 = room.markers["altar"]
	a.global_position = Vector3(pos.x, pos.y, 0.0)


## Rest at `altar` (addendum "Soul Altars"): light it, full heal and flasks, ordinary enemies
## return (killed elites stay dead), it becomes the respawn point, save, then the altar menu.
func rest_at_altar(altar: Altar) -> void:
	if state == null or player == null:
		return
	if GameState.add_unique(state.lit_altars, altar.altar_id):
		altar.set_lit(true)
		prompts.toast(tr("ALTAR_KINDLED"), UiKit.COL_GOLD)
	state.rested_altar = {"room": rooms.data.id, "altar": altar.altar_id}
	state.checkpoint = {"room": rooms.data.id, "x": altar.global_position.x + 1.2, "y": altar.global_position.y}
	player.rest()
	state.reset_commons()
	rooms.respawn_enemies()
	save_now()
	open_altar_menu(altar)


func open_altar_menu(altar: Altar) -> void:
	if altar_menu != null:
		return
	altar_menu = AltarMenu.new()
	altar_menu.state = state
	altar_menu.altar_name = tr(altar.name_key)
	altar_menu.loadout_requested.connect(apply_loadout)
	altar_menu.lore_read_requested.connect(read_lore)
	altar_menu.leave_requested.connect(close_altar_menu)
	add_child(altar_menu)
	prompts.show_interact("")
	get_tree().paused = true
	_play_music("altar")


func close_altar_menu() -> void:
	if altar_menu == null:
		return
	altar_menu.queue_free()
	altar_menu = null
	get_tree().paused = false
	save_now()
	_play_music(str(WorldData.zone(_zone).get("music", _zone)))


## Equip `ids` (wheel order) from the altar's Loadout page.
func apply_loadout(ids: Array[String]) -> void:
	var list: Array[String] = []
	for v in ids:
		if state.unlocked_vessels.has(v) and not list.has(v) and list.size() < Loadout.MAX_SLOTS:
			list.append(v)
	if list.is_empty():
		return
	state.loadout = list
	player.equip(list, affinity_levels())
	MusicDirector.set_vessel(player.loadout.active().id)


## Mark lore `id` read. A Vessel memory read for the first time grants that Vessel +1 Affinity
## (addendum "Affinity": reading that Vessel's lore at a Soul Altar).
func read_lore(id: String) -> void:
	if not state.lore_found.has(id) or not GameState.add_unique(state.lore_read, id):
		return
	var vessel := LoreDb.vessel_of(id)
	if vessel != "":
		state.affinity_bonus[vessel] = int(state.affinity_bonus.get(vessel, 0)) + 1
		player.set_affinity(vessel, int(affinity_levels().get(vessel, 0)))
		prompts.toast(tr("AFFINITY_BONUS") % tr("VESSEL_" + vessel.to_upper()), UiKit.COL_GOLD)


# --- Frame ----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not playing or player == null:
		return
	state.play_time_s += delta
	if camera.zoom_in > 0.0 and player.state != "ultimate":
		camera.zoom_in = maxf(camera.zoom_in - delta * 2.0, 0.0)
	_update_interact()


func _update_interact() -> void:
	var best: Interactable = null
	var best_d := INF
	if player.is_alive() and not rooms.transitioning:
		for n in get_tree().get_nodes_in_group(Interactable.GROUP):
			var it := n as Interactable
			if it == null or not it.is_inside_tree() or not it.in_reach(player) or not it.can_interact(player):
				continue
			var d := absf(it.global_position.x - player.global_position.x)
			if d < best_d:
				best = it
				best_d = d
	_interact_target = best
	prompts.show_interact(tr(best.verb_key) if best != null else "")
	if touch != null:
		touch.context_label = tr(best.verb_key) if best != null else ""
	if best != null and input_router.just_pressed("interact"):
		best.interact(self)


## The interactable the prompt is showing, or null (bridge).
func interact_target() -> Interactable:
	return _interact_target


func _unhandled_input(event: InputEvent) -> void:
	if not playing:
		return
	if event.is_action_pressed("pause") and pause_menu == null and altar_menu == null:
		open_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.is_pressed() and not event.is_echo() and OS.is_debug_build():
		if (event as InputEventKey).physical_keycode == KEY_F6:
			player.gauge.add(300.0)


func open_pause() -> void:
	if pause_menu != null or not playing:
		return
	pause_menu = PauseMenu.new()
	pause_menu.name = "Pause"
	pause_menu.state = state
	pause_menu.resume_requested.connect(close_pause)
	pause_menu.quit_requested.connect(quit_to_title)
	add_child(pause_menu)
	prompts.show_interact("")
	get_tree().paused = true


func close_pause() -> void:
	if pause_menu != null:
		pause_menu.queue_free()
		pause_menu = null
	get_tree().paused = false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			# Suspend-save (addendum): Android may kill a backgrounded app without warning.
			if playing:
				save_now(true)
		NOTIFICATION_WM_GO_BACK_REQUEST:
			if altar_menu != null:
				close_altar_menu()
			elif playing and pause_menu == null:
				open_pause()
			elif pause_menu != null:
				close_pause()


# --- Sandbox-compatible API (debug HUD and bridge) ------------------------------------------

func enemies() -> Array[EnemyBase]:
	return rooms.enemies()


func spawn(enemy_id: String, x: float) -> EnemyBase:
	var y := player.global_position.y if player != null else 1.0
	return rooms.spawn(enemy_id, x, y)


func kill_all() -> void:
	rooms.kill_all()


# --- Effects --------------------------------------------------------------------------------

func _on_hitstop(duration: float) -> void:
	if duration <= 0.0:
		return
	_hitstop_token += 1
	var token := _hitstop_token
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	if token == _hitstop_token:
		Engine.time_scale = 1.0


func _on_ultimate_fx(kind: String, _where: Vector3, _size: float) -> void:
	if kind == "final_stand" or kind == "dance_of_shadows":
		camera.add_trauma(0.4)
		camera.zoom_in = 1.0


func _start_bridge() -> void:
	var port := 9177
	var env := OS.get_environment("BRIDGE_PORT")
	if env.is_valid_int():
		port = int(env)
	bridge_handler = DebugBridge.new()
	bridge_handler.name = "DebugBridge"
	bridge_handler.process_mode = Node.PROCESS_MODE_ALWAYS
	(bridge_handler as DebugBridge).sandbox = self
	add_child(bridge_handler)
	var b := Bridge.new()
	b.name = "Bridge"
	b.process_mode = Node.PROCESS_MODE_ALWAYS
	b.handler = bridge_handler
	add_child(b)
	b.start(port)


# --- Bridge commands (DebugBridge calls bridge_<cmd>) -----------------------------------------

## {"slot", "difficulty"}: start a new run without the title screen.
func bridge_new_game(args: Dictionary) -> Dictionary:
	close_pause()
	start_new(int(args.get("slot", 0)), str(args.get("difficulty", "normal")))
	await get_tree().process_frame
	return bridge_game_state({})


func bridge_continue(args: Dictionary) -> Dictionary:
	close_pause()
	continue_game(int(args.get("slot", 0)))
	await get_tree().process_frame
	return bridge_game_state({})


func bridge_title(_args: Dictionary) -> Dictionary:
	close_pause()
	show_title()
	await get_tree().process_frame
	return {"title": title != null, "slots": _summaries()}


## {"room", "exit"} or {"room", "x", "y"}: jump to a room (with the fade unless "instant").
func bridge_goto(args: Dictionary) -> Dictionary:
	var room := str(args.get("room", ""))
	var at := Vector2(float(args.get("x", -1.0)), float(args.get("y", -1.0)))
	var where := at if at.x >= 0.0 else Vector2.INF
	if bool(args.get("instant", false)):
		rooms.enter(room, str(args.get("exit", "")), where)
	else:
		await rooms.travel(room, str(args.get("exit", "")), where)
	return {"room": rooms.data.id, "x": player.global_position.x, "y": player.global_position.y}


## The save state, the room and the prompts.
func bridge_game_state(_args: Dictionary) -> Dictionary:
	return {
		"slot": slot,
		"playing": playing,
		"paused": get_tree().paused,
		"room": rooms.data.id if rooms.data != null else "",
		"zone": _zone,
		"state": state.to_dict() if state != null else {},
		"interact": _interact_target.verb_key if _interact_target != null else "",
		"prompt": prompts.interact_text(),
		"tutorial": prompts.tutorial_text(),
		"subtitle": prompts.subtitle_text(),
		"toasts": prompts.toast_texts(),
		"title": title != null,
		"pause": pause_menu != null,
		"altar_menu": altar_menu != null,
		"fader": fader.alpha(),
	}


func bridge_save(args: Dictionary) -> Dictionary:
	return {"ok": save_now(bool(args.get("resume", false)))}


## Use the interactable in reach now (as the interact control would).
func bridge_interact(_args: Dictionary) -> Dictionary:
	if _interact_target == null:
		return {"error": "nothing in reach"}
	var verb := _interact_target.verb_key
	_interact_target.interact(self)
	await get_tree().process_frame
	return {"used": verb}


func bridge_leave_altar(_args: Dictionary) -> Dictionary:
	close_altar_menu()
	return {"paused": get_tree().paused}


func bridge_pause(_args: Dictionary) -> Dictionary:
	open_pause()
	return {"paused": get_tree().paused}


func bridge_resume(_args: Dictionary) -> Dictionary:
	close_pause()
	return {"paused": get_tree().paused}


## {"name"}: press the visible menu button with this node name (title, pause, altar menus).
func bridge_ui_press(args: Dictionary) -> Dictionary:
	var wanted := str(args.get("name", ""))
	for root: Node in [title, pause_menu, altar_menu]:
		if root == null:
			continue
		var b := root.find_child(wanted, true, false) as BaseButton
		if b != null and b.is_visible_in_tree() and not b.disabled:
			b.pressed.emit()
			await get_tree().process_frame
			await get_tree().process_frame
			return {"pressed": wanted}
	return {"error": "no visible button %s" % wanted}


## Names of the visible buttons in open menus (to drive menus by name).
func bridge_ui_buttons(_args: Dictionary) -> Dictionary:
	var out: Array[String] = []
	for root: Node in [title, pause_menu, altar_menu]:
		if root == null:
			continue
		for b in root.find_children("*", "BaseButton", true, false):
			if (b as Control).is_visible_in_tree():
				out.append(str(b.name) + ("" if not (b as BaseButton).disabled else " (disabled)"))
	var focus := get_viewport().gui_get_focus_owner()
	return {"buttons": out, "focus": str(focus.name) if focus != null else ""}


static func _arg(args: PackedStringArray, key: String, fallback: String) -> String:
	var i := args.find(key)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else fallback
