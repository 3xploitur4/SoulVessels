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

## The Soul Core tree (story 020).
var soul_core: SoulCore
## Weapon reforging and Censer Core crafting rules (story 036).
var reforge: Reforge
## The chapter-end screen while it shows (story 047).
var chapter_end: ChapterEnd
## Ability ranks and Sync passives (story 037).
var ranks: AbilityRanks
var passives: SyncPassives
## Second weapons and Affinity 5 signature passives (story 050).
var weapons: Weapons
## The pixel-art pass over the world (story 054).
var pixel_look: PixelLook
## Loot rolls (story 019) and the run's random source for them.
var loot: LootTable
var loot_rng := RandomNumberGenerator.new()
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
	# Story 054: zoomed out (smaller characters, more of the room), snapped to the pixel grid.
	var cam_cfg: Dictionary = PixelLook.config().get("camera", {})
	camera.distance = float(cam_cfg.get("distance", camera.distance))
	camera.height = float(cam_cfg.get("height", camera.height))
	camera.look_ahead = float(cam_cfg.get("look_ahead", camera.look_ahead))
	camera.look_drop = float(cam_cfg.get("look_drop", camera.look_drop))
	camera.ground_below = float(cam_cfg.get("ground_below_m", camera.ground_below))
	camera.pixel_rows = PixelLook.virtual_height()
	add_child(camera)
	rooms = RoomManager.new()
	rooms.name = "Rooms"
	rooms.world = world
	rooms.camera = camera
	add_child(rooms)
	rooms.room_entered.connect(_on_room_entered)
	rooms.spiked.connect(_on_spiked)
	register_feature(_build_altar)
	register_feature(_build_echo)
	register_feature(_build_pickups)
	register_feature(_build_mushrooms)
	register_feature(_build_gates)
	register_feature(func(m: RoomManager, r: RoomData) -> void: RunePuzzle.build_for(m, r, state))
	register_feature(func(m: RoomManager, r: RoomData) -> void: MasonryWall.build_for(m, r, state))
	register_feature(func(m: RoomManager, r: RoomData) -> void: IlyrAwakening.build_for(self, m, r))
	register_feature(func(m: RoomManager, r: RoomData) -> void: RiftPortal.build_for(m, r, state))
	register_feature(_build_story)
	rooms.fell_out.connect(_on_fell_out)
	rooms.exit_blocked.connect(_on_exit_blocked)
	loot = LootTable.from_data()
	soul_core = SoulCore.from_data()
	reforge = Reforge.from_data()
	ranks = AbilityRanks.from_data()
	passives = SyncPassives.from_data()
	weapons = Weapons.from_data()
	GameEvents.perfect_parry.connect(func(_a: Node3D) -> void: _award_xp("perfect_parry"))
	GameEvents.perfect_dodge.connect(func(_a: Node3D) -> void: _award_xp("perfect_dodge"))
	GameEvents.enemy_died.connect(_on_enemy_died)
	fx = FxLayer.new()
	fx.name = "Fx"
	fx.show_numbers = true
	add_child(fx)
	var vignette := Vignette.new()
	vignette.name = "Vignette"
	add_child(vignette)
	pixel_look = PixelLook.new()
	pixel_look.name = "PixelLook"
	add_child(pixel_look)
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
	GameEvents.camera_roll_requested.connect(camera.roll_to)
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
	# The chapter-end screen (story 047) goes too, however the title is reached.
	if chapter_end != null:
		chapter_end.queue_free()
		chapter_end = null
	close_pause()
	_end_run()
	prompts.clear()
	_camera_anchor.position = Vector3(13.0, 4.0, 0.0)
	camera.target = _camera_anchor
	rooms.enter(TITLE_ROOM)
	camera.snap()
	_play_music("title")
	title = TitleScreen.new()
	title.abyssal_unlocked = saves.chapter_complete()
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
	loot_rng.randomize()
	player = Player.new()
	player.name = "Player"
	player.world = world
	player.controls = input_router
	player.vessel_ids = state.loadout.duplicate()
	player.difficulty = state.difficulty
	player.affinity_levels = affinity_levels()
	player.weapon_mults = weapon_mults()
	player.data_patcher = _patch_vessel
	player.overdrive_unlocked = state.flag("unlock_overdrive")
	player.auto_respawn = false
	add_child(player)
	player.apply_bonuses(soul_core.modifiers(state.soul_core))
	player.died.connect(_on_player_died)
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
		out[v] = Affinity.level(state, v)
	return out


## Give the active Vessel Affinity XP from `source` (story 020). A new level shows a toast, turns
## on what it unlocks, and at the memory level adds that Vessel's memory to the lore.
func _award_xp(source: String, amount: float = 1.0) -> void:
	if not playing or player == null or state == null:
		return
	var vessel := player.loadout.active().id
	var lvl := Affinity.add_xp(state, vessel, source, amount)
	if lvl == -1:
		return
	_on_affinity_changed(vessel, lvl)


func _on_affinity_changed(vessel: String, lvl: int) -> void:
	player.set_affinity(vessel, lvl)
	var vessel_name := tr("VESSEL_" + vessel.to_upper())
	prompts.toast(tr("AFFINITY_LEVEL") % [vessel_name, lvl], UiKit.COL_GOLD)
	if lvl == int(Balance.combat_f("sync_guard.min_affinity")):
		prompts.toast(tr("AFFINITY_UNLOCK_GUARD"), UiKit.COL_ACCENT)
	elif lvl == int(Balance.combat_f("sync_ultimate.min_affinity")):
		prompts.toast(tr("AFFINITY_UNLOCK_ULTIMATE"), UiKit.COL_ACCENT)
	elif weapons != null and weapons.signatures.has(vessel) and weapons.signature_active(vessel, lvl) 			and not weapons.signature_active(vessel, lvl - 1):
		# Story 050: the Affinity 5 signature passive; re-bind so the Vessel's data carries it.
		prompts.toast(tr("AFFINITY_UNLOCK_SIGNATURE") % tr(str(weapons.signatures[vessel].get("name_key", ""))),
			UiKit.COL_ACCENT)
		_rebind_vessels()
	var memory := "memory_" + vessel
	if lvl >= Affinity.memory_level() and not LoreDb.entry(memory).is_empty() \
			and GameState.add_unique(state.lore_found, memory):
		prompts.toast(tr("AFFINITY_MEMORY") % vessel_name, UiKit.COL_GOLD)


## Buy Soul Core node `id` at an altar (request from the altar screen).
func buy_core(id: String) -> void:
	if state == null or not soul_core.buy(state, id):
		return
	player.apply_bonuses(soul_core.modifiers(state.soul_core))
	Sfx.play("altar_kindle")
	save_now()
	if altar_menu != null:
		altar_menu.refresh_core()


## Vessel id -> weapon ATK multiplier from the save's reforge levels.
func weapon_mults() -> Dictionary:
	var out := {}
	for v: String in state.weapon_levels.keys():
		out[v] = reforge.atk_multiplier(int(state.weapon_levels[v]))
	return out


## Reforge a Vessel's weapon at an altar (story 036).
func reforge_weapon(vessel_id: String) -> void:
	if state == null or not reforge.reforge(state, vessel_id):
		return
	player.set_weapon_mult(vessel_id, reforge.atk_multiplier(reforge.level(state, vessel_id)))
	Sfx.play("gate_open")
	save_now()
	if altar_menu != null:
		altar_menu.show_reforge()


## A Vessel's balance data with its bought ranks and slotted Sync passive applied.
func _patch_vessel(vessel_id: String, data: Dictionary) -> Dictionary:
	if state == null:
		return data
	var out := passives.patched(ranks.patched(data, state, vessel_id), state, vessel_id)
	return weapons.patched(out, state, vessel_id, Affinity.level(state, vessel_id))


## Buy the next rank of a Vessel's ability (story 037); the Vessels are re-bound to pick it up.
func buy_rank(vessel_id: String, ability: String) -> void:
	if state == null or not ranks.buy(state, vessel_id, ability):
		return
	_rebind_vessels()
	Sfx.play("altar_kindle")
	save_now()
	if altar_menu != null:
		altar_menu.show_upgrade(vessel_id)


## Buy a Sync passive, or slot one already owned (free).
func choose_passive(vessel_id: String, passive_id: String) -> void:
	if state == null:
		return
	var ok := false
	if passives.owned(state, vessel_id, passive_id):
		ok = passives.equip(state, vessel_id, passive_id)
	else:
		ok = passives.buy(state, vessel_id, passive_id) and passives.equip(state, vessel_id, passive_id)
	if not ok:
		return
	_rebind_vessels()
	Sfx.play("sync_guard")
	save_now()
	if altar_menu != null:
		altar_menu.show_upgrade(vessel_id)


## Take up a Vessel's second weapon, or go back to the first ("" ; story 050).
func choose_weapon(vessel_id: String, weapon_id: String) -> void:
	if state == null or not weapons.equip(state, vessel_id, weapon_id):
		return
	_rebind_vessels()
	Sfx.play("altar_kindle")
	save_now()
	if altar_menu != null:
		altar_menu.show_upgrade(vessel_id)


func _rebind_vessels() -> void:
	player.equip(player.vessel_ids.duplicate(), affinity_levels())


## Ilyr's awakening is over: the chapter-end screen, then the title.
func show_chapter_end() -> void:
	if chapter_end != null:
		return
	chapter_end = ChapterEnd.new()
	chapter_end.state = state
	chapter_end.title_requested.connect(func() -> void:
		chapter_end.queue_free()
		chapter_end = null
		show_title())
	add_child(chapter_end)


## Craft an item from its recipe at an altar (the Censer Core).
func craft_item(item: String) -> void:
	if state == null or not reforge.craft(state, item):
		return
	Sfx.play("altar_kindle")
	save_now()
	if altar_menu != null:
		altar_menu.show_reforge()


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
		if not first and state != null:
			# Zone-entry autosave: Continue starts at this door.
			state.checkpoint = {"room": room_id, "x": player.global_position.x, "y": player.global_position.y}
			save_now()
	# The zone's track, or the room's own (story 049: the Starless Shore has its own).
	var track := str(WorldData.zone(zone).get("music", zone))
	if rooms.data != null:
		track = str(rooms.data.raw.get("music", track))
	_play_music(track)
	# Story 049: a checkpoint before a boss. Death returns here, not to the last altar.
	if state != null and rooms.data != null and bool(rooms.data.raw.get("checkpoint", false)):
		state.rested_altar = {"room": room_id, "altar": ""}
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
		Sfx.play("altar_kindle")
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
	altar_menu.soul_core = soul_core
	altar_menu.core_buy_requested.connect(buy_core)
	altar_menu.reforge = reforge
	altar_menu.reforge_requested.connect(reforge_weapon)
	altar_menu.craft_requested.connect(craft_item)
	altar_menu.ranks = ranks
	altar_menu.passives = passives
	altar_menu.rank_requested.connect(buy_rank)
	altar_menu.passive_requested.connect(choose_passive)
	weapons.refresh(state)
	altar_menu.weapons = weapons
	altar_menu.weapon_requested.connect(choose_weapon)
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
		var before := Affinity.level(state, vessel)
		state.affinity_bonus[vessel] = int(state.affinity_bonus.get(vessel, 0)) + 1
		prompts.toast(tr("AFFINITY_BONUS") % tr("VESSEL_" + vessel.to_upper()), UiKit.COL_GOLD)
		if Affinity.level(state, vessel) != before:
			_on_affinity_changed(vessel, Affinity.level(state, vessel))


# --- Soul Essence, death and the Soul Echo (story 018) ----------------------------------------

func _on_enemy_died(enemy: Node) -> void:
	if not playing or state == null or not enemy is EnemyBase:
		return
	var e := enemy as EnemyBase
	var amount := int(e.data.get("essence", 0))
	if amount <= 0:
		return
	state.essence += amount
	fx.popup("+%d" % amount, e.global_position + Vector3(0, 1.2, 0), Color(0.6, 0.92, 1.0))
	_award_xp("elite_kill" if e.tier == "elite" or e.tier == "boss" else "kill")
	if e.tier == "boss":
		_on_boss_defeated(e)
	for d: Dictionary in loot.roll(e.data, _zone, loot_rng, state):
		spawn_pickup(str(d["item"]), int(d["count"]), "", Vector2(e.global_position.x, e.global_position.y))


## A boss fell (story 034): its flag, Affinity gifts and closing line from data `on_defeat`,
## then a save. The Sovereign gives Caelan his goodbye (+1 Affinity).
func _on_boss_defeated(e: EnemyBase) -> void:
	var od: Dictionary = e.data.get("on_defeat", {})
	if od.has("flag"):
		state.set_flag(str(od["flag"]))
	for f: Variant in od.get("flags", []):
		state.set_flag(str(f))
	if state.flag("unlock_overdrive") and not player.overdrive_unlocked:
		player.overdrive_unlocked = true
		prompts.toast(tr("OVERDRIVE_UNLOCKED"), UiKit.COL_GOLD)
	camera.roll_to(0.0, 1.5)
	var gifts: Dictionary = od.get("affinity_bonus", {})
	for v: String in gifts.keys():
		state.affinity_bonus[v] = int(state.affinity_bonus.get(v, 0)) + int(gifts[v])
		_on_affinity_changed(v, Affinity.level(state, v))
	if od.has("line"):
		prompts.subtitle(tr(str(od.get("speaker", "SPEAKER_VOICE"))), tr(str(od["line"])), Color(0.75, 0.85, 1.0))
	camera.add_trauma(0.6)
	save_now()


func _build_echo(manager: RoomManager, room: RoomData) -> void:
	if state == null or state.echo.is_empty() or str(state.echo.get("room", "")) != room.id:
		return
	var e := SoulEcho.new()
	e.name = "SoulEcho"
	e.essence = int(state.echo.get("essence", 0))
	e.player = player
	e.recovered.connect(_on_echo_recovered)
	manager.features_root.add_child(e)
	e.global_position = Vector3(float(state.echo.get("x", 0.0)), float(state.echo.get("y", 0.0)), 0.0)


func _on_echo_recovered() -> void:
	var got := DeathRules.recover(state)
	if got > 0:
		prompts.toast(tr("ECHO_RECOVERED") % got, Color(0.6, 0.92, 1.0))
		Sfx.play("echo_recover")


## Death (addendum "Death, saving"): Essence becomes a Soul Echo at the last safe ground, an older
## echo is lost (unless the difficulty says never), ordinary enemies return, and the player wakes
## at the rested altar with full HP and flasks.
func _on_player_died() -> void:
	if state == null:
		return
	var lose := bool(Balance.combat("difficulty.%s.echo_lost_on_second_death" % state.difficulty))
	var result := DeathRules.on_death(state, rooms.data.id, rooms.last_safe, lose)
	if int(result["lost"]) > 0:
		prompts.toast(tr("ECHO_LOST") % int(result["lost"]), Color(0.7, 0.7, 0.75))
	await get_tree().create_timer(Balance.combat_f("death.respawn_delay_s"), false).timeout
	if player == null or not playing:
		return
	await fader.fade_to(1.0, 0.5)
	var p := DeathRules.respawn_point(state)
	var room := str(p.get("room", GameState.START_ROOM))
	var at := Vector2(float(p.get("x", -1.0)), float(p.get("y", -1.0)))
	if at.x < 0.0:
		var r := WorldData.room(room)
		if r != null and r.markers.has("altar"):
			var ap: Vector2 = r.markers["altar"]
			at = Vector2(ap.x + 1.2, ap.y)
	player.respawn()
	rooms.enter(room, "", at if at.x >= 0.0 else Vector2.INF)
	save_now()
	await fader.fade_to(0.0, 0.6)


# --- Traversal (story 021) -------------------------------------------------------------------

func _build_mushrooms(manager: RoomManager, room: RoomData) -> void:
	var height := Balance.combat_f("traversal.bounce_height_m")
	var speed := sqrt(2.0 * Balance.combat_f("movement.gravity") * height)
	for pos: Vector2 in room.mushrooms:
		var m := BounceMushroom.new()
		m.name = "BounceMushroom"
		m.player = player
		m.launch_speed = speed
		manager.features_root.add_child(m)
		m.global_position = Vector3(pos.x, pos.y, 0.0)


## Falling out of a room costs a share of max HP and returns the player to the last safe
## ground; if that kills, it is an ordinary death (the echo forms at that safe ground).
func _on_fell_out() -> void:
	if player == null or not playing:
		return
	var cost := player.health.max_value * Balance.combat_f("traversal.void_damage_fraction")
	if player.hurt_by_world(cost):
		return
	player.teleport(rooms.last_safe.x, rooms.last_safe.y + 0.05)
	player.grant_invulnerability(1.0)
	camera.snap()
	camera.add_trauma(0.3)


## Spikes (story 054): a share of max HP, then back to the last safe ground, like a fall.
func _on_spiked() -> void:
	if player == null or not playing:
		return
	var cost := player.health.max_value * Balance.combat_f("traversal.spike_damage_fraction")
	GameEvents.hit_fx_requested.emit(player.global_position + Vector3(0.0, 0.6, 0.3), 0.0, true, false)
	Sfx.play("hit")
	if player.hurt_by_world(cost):
		return
	player.teleport(rooms.last_safe.x, rooms.last_safe.y + 0.05)
	player.grant_invulnerability(1.0)
	camera.snap()
	camera.add_trauma(0.35)


# --- Gates (story 023) -----------------------------------------------------------------------

func _build_gates(manager: RoomManager, room: RoomData) -> void:
	if room.markers.has("statue") and room.gate_rects.has("ward"):
		var w := ShieldWard.new()
		w.name = "ShieldWard"
		w.room = room
		w.manager = manager
		w.player = player
		w.state = state
		manager.features_root.add_child(w)
	for kind: String in ["rune", "masonry", "flood"]:
		for r: Rect2 in room.gate_rects.get(kind, []):
			_add_sealed(manager, kind, Vector2(r.get_center().x, r.position.y))
	for pos: Vector2 in room.rift_scars:
		_add_sealed(manager, "rift", pos)


func _add_sealed(manager: RoomManager, kind: String, at: Vector2) -> void:
	var g := SealedGate.new()
	g.name = "Sealed_" + kind
	g.kind = kind
	manager.features_root.add_child(g)
	g.global_position = Vector3(at.x, at.y, 0.0)


# --- Zone story: possession, arenas, tutorials and lines (story 024) -------------------------

## The room's story triggers (null in rooms without any); arena and possession events go here.
var story: StoryTriggers


func _build_story(manager: RoomManager, room: RoomData) -> void:
	story = null
	if player == null:
		return
	if room.raw.has("story"):
		story = StoryTriggers.new()
		story.name = "Story"
		story.room = room
		story.player = player
		story.state = state
		story.fired.connect(_on_story)
		manager.features_root.add_child(story)
	for ev: Dictionary in room.events:
		var v := str(ev["kind"])
		var vid := str(ev["vessel"])
		var pos: Vector2 = ev["pos"]
		if v == "possess" and not (state != null and state.flag("possessed_" + vid)):
			var b := PossessionBody.new()
			b.name = "Body_" + vid
			b.vessel = vid
			manager.features_root.add_child(b)
			b.global_position = Vector3(pos.x, pos.y, -0.1)
		elif (v == "roots" or v == "crystal" or v == "rubble") and not (state != null and state.flag("freed_" + vid)):
			# Story 025: a Vessel bound in roots (Nyra); story 038: sealed in crystal (Seris).
			# Break the bonds, then free her.
			var r := RootPrison.new()
			r.name = v.capitalize() + "_" + vid
			r.vessel = vid
			r.look = v
			r.world = world
			r.roots_cut.connect(func(left: int) -> void:
				if left == 0 and story != null:
					story.event(v + "_cut"))
			manager.features_root.add_child(r)
			r.global_position = Vector3(pos.x, pos.y, -0.1)
	if room.raw.has("arena") and room.gate_rects.has("lock"):
		var a := Arena.new()
		a.name = "Arena"
		a.room = room
		a.manager = manager
		a.player = player
		a.state = state
		a.started.connect(func(_id: String) -> void:
			camera.add_trauma(0.35)
			Sfx.play("gate_open")
			if story != null:
				story.event("arena_start"))
		a.wave_started.connect(func(_id: String, _i: int) -> void:
			camera.add_trauma(0.3)
			if story != null:
				story.event("arena_wave"))
		a.cleared.connect(func(_id: String) -> void:
			Sfx.play("gate_open")
			save_now()
			if story != null:
				story.event("arena_clear"))
		manager.features_root.add_child(a)


## Take the body of `vessel` (the wisp's possession, addendum Narrative 1): bind and equip it,
## remember it in the save, and remove the empty body.
func possess(vessel: String, body: Node3D = null) -> void:
	if state == null or player == null:
		return
	state.unlock_vessel(vessel)
	state.set_flag("possessed_" + vessel)
	player.equip(state.loadout, affinity_levels())
	player.health.reset(player.max_hp())
	GameEvents.player_hp_changed.emit(player.health.current, player.health.max_value)
	MusicDirector.set_vessel(player.loadout.active().id)
	var at := player.global_position + Vector3(0.0, 1.0, 0.4)
	GameEvents.hit_fx_requested.emit(at, 0.0, true, false)
	camera.add_trauma(0.4)
	Sfx.play("altar_kindle")
	if body != null and is_instance_valid(body):
		player.teleport(body.global_position.x, body.global_position.y + 0.05)
		body.queue_free()
	prompts.hide_tutorial()
	prompts.toast(tr("POSSESSED") % tr("VESSEL_" + vessel.to_upper()), UiKit.COL_GOLD)
	if story != null:
		story.event("possessed")
	save_now()


## Free `vessel` from its root prison (story 025): bind her, add her to the loadout when there is
## room (the active Vessel stays), remember it in the save, remove the empty prison.
func free_vessel(vessel: String, prison: Node3D = null) -> void:
	if state == null or player == null:
		return
	state.unlock_vessel(vessel)
	state.set_flag("freed_" + vessel)
	# Story 049 (D-055): a freed Vessel always joins. With three already carried, she or he takes
	# the last slot that is not the one in hand; the one set aside waits at the altars.
	if not state.loadout.has(vessel):
		var in_hand := player.loadout.active().id
		for i in range(state.loadout.size() - 1, -1, -1):
			if state.loadout[i] != in_hand:
				state.loadout[i] = vessel
				break
	player.equip(state.loadout, affinity_levels())
	var at := player.global_position + Vector3(0.0, 1.0, 0.4)
	GameEvents.hit_fx_requested.emit(at, 0.0, true, false)
	camera.add_trauma(0.3)
	Sfx.play("altar_kindle")
	if prison != null and is_instance_valid(prison):
		prison.queue_free()
	prompts.hide_tutorial()
	prompts.toast(tr("FREED") % tr("VESSEL_" + vessel.to_upper()), UiKit.COL_GOLD)
	if story != null:
		story.event("freed")
	save_now()


func _on_story(e: Dictionary) -> void:
	var key := str(e.get("key", ""))
	if str(e.get("kind", "")) == "tutorial":
		prompts.tutorial(tr(key))
	else:
		var speaker := str(e.get("speaker", "SPEAKER_VOICE"))
		prompts.subtitle(tr(speaker), tr(key), Color(str(e.get("color", "#b8d4ff"))))


func _on_exit_blocked(_exit: String, need: String) -> void:
	prompts.tutorial(tr("BLOCKED_" + need.to_upper()))


# --- Loot and pickups (story 019) -------------------------------------------------------------

func _build_pickups(_manager: RoomManager, room: RoomData) -> void:
	if state == null:
		return
	for p: Dictionary in room.pickups:
		var pid := str(p["pickup_id"])
		if state.taken_pickups.has(pid) or str(p["item"]) == "":
			continue
		var pos: Vector2 = p["pos"]
		spawn_pickup(str(p["item"]), 1, pid, pos)


## Put `item` in the world at room point `at`. Enemy drops (no `pickup_id`) home in on the player.
func spawn_pickup(item: String, count: int, pickup_id: String, at: Vector2) -> Pickup:
	var p := Pickup.new()
	p.item = item
	p.count = count
	p.pickup_id = pickup_id
	p.player = player
	p.magnet_radius = loot.num("magnet_radius_m", 1.5)
	p.homing_after_s = -1.0 if pickup_id != "" else loot.num("drop_homing_after_s", 0.8)
	p.collected.connect(_on_pickup)
	var parent := rooms.features_root if pickup_id != "" else rooms.transient_root
	parent.add_child(p)
	p.global_position = Vector3(at.x, at.y, 0.0)
	return p


func _on_pickup(p: Pickup) -> void:
	if p.pickup_id != "":
		GameState.add_unique(state.taken_pickups, p.pickup_id)
	collect_item(p.item, p.count)


## Add `item` to the run. Lore items become the next unread lore entry of their kind (Essence
## once every entry of that kind is found).
func collect_item(item: String, count: int) -> void:
	var lore_kind := str(ItemDb.item(item).get("lore_kind", ""))
	if lore_kind != "":
		for i in range(count):
			var lore_id := LoreDb.next_unfound(lore_kind, state.lore_found)
			if lore_id == "":
				var extra := int(loot.num("%s_overflow_essence" % lore_kind, 25.0))
				state.essence += extra
				prompts.toast("+%d %s" % [extra, tr("HUD_ESSENCE")], Color(0.6, 0.92, 1.0))
			else:
				state.lore_found.append(lore_id)
				prompts.toast(tr("LORE_FOUND") % tr(LoreDb.title_key(lore_id)), ItemDb.color(item))
		Sfx.play("pickup")
		return
	state.add_item(item, count)
	prompts.toast("+%d %s" % [count, tr(ItemDb.name_key(item))], ItemDb.color(item))
	Sfx.play("pickup")


# --- Frame ----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not playing or player == null:
		return
	state.play_time_s += delta
	if player.snare.is_active():
		prompts.show_status(tr("SNARE_BREAK") % player.snare.taps_left())
	if player.is_alive() and player.gauge.in_combat():
		_award_xp("combat_s", delta)
	if camera.zoom_in > 0.0 and player.state != "ultimate":
		camera.zoom_in = maxf(camera.zoom_in - delta * 2.0, 0.0)
	_update_interact()


func _update_interact() -> void:
	if player.snare.is_active():
		return
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
	if player != null:
		pause_menu.player_pos = Vector2(player.global_position.x, player.global_position.y)
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


## {"tier", "value"}: change a drop chance for this run (playtests).
func bridge_drop_chance(args: Dictionary) -> Dictionary:
	(loot.config["drop_chance"] as Dictionary)[str(args.get("tier", "common"))] = float(args.get("value", 0.35))
	return {"drop_chance": loot.config["drop_chance"]}


## {"vessel", "source", "amount"}: give Affinity XP (playtests).
func bridge_affinity(args: Dictionary) -> Dictionary:
	var vessel := str(args.get("vessel", player.loadout.active().id))
	var lvl := Affinity.add_xp(state, vessel, str(args.get("source", "kill")), float(args.get("amount", 1.0)))
	if lvl != -1:
		_on_affinity_changed(vessel, lvl)
	return {"vessel": vessel, "level": Affinity.level(state, vessel), "xp": state.affinity_xp.get(vessel, 0.0)}


## {"item", "count"}: give an item as if picked up.
func bridge_give(args: Dictionary) -> Dictionary:
	collect_item(str(args.get("item", "")), int(args.get("count", 1)))
	return {"inventory": state.inventory, "lore": state.lore_found}


func bridge_pause(_args: Dictionary) -> Dictionary:
	open_pause()
	return {"paused": get_tree().paused}


func bridge_resume(_args: Dictionary) -> Dictionary:
	close_pause()
	return {"paused": get_tree().paused}


## {"name"}: press the visible menu button with this node name (title, pause, altar menus).
func bridge_ui_press(args: Dictionary) -> Dictionary:
	var wanted := str(args.get("name", ""))
	for root: Node in [title, pause_menu, altar_menu, chapter_end]:
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
	for root: Node in [title, pause_menu, altar_menu, chapter_end]:
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
