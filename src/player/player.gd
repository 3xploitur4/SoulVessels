class_name Player
extends CharacterBody3D
## The Intruder's body (stories 006-009): side-on movement on the X/Y plane, timed actions from
## the active Vessel's kit, block / parry / dodge i-frames, the shared soul HP and Soul Gauge,
## Vessel swapping with Resonance Strikes, automatic Sync Guards and Sync Ultimates.
##
## Dependencies are injected before `add_child` (nothing is looked up by path):
##     var p := Player.new()
##     p.world = combat_world          # CombatWorld: hit queries
##     p.controls = input_router       # InputRouter (one is created when null)
##     p.fx_parent = arena             # where projectiles spawn
##     p.vessel_ids = ["caelan", "nyra"]
##     add_child(p)
##
## Every number comes from Balance (decision D-003).

signal action_started(action_id: String)
signal hit_landed(target: Node3D, packet: DamagePacket)
signal took_damage(amount: float)
signal died
signal respawned
signal vessel_swapped(vessel_id: String, slot: int)
signal perfect_parry(attacker: Node3D)
signal perfect_dodge(attacker: Node3D)
signal sync_guard_triggered(vessel_id: String)
signal ultimate_started(vessel_id: String)

const CAPSULE_RADIUS := 0.35
const CAPSULE_HEIGHT := 1.8
const HURT_RECT := Vector2(0.8, 1.75)
const FLINCH_S := 0.28
const RESPAWN_S := 2.5
## Collision layers (project.godot names): one-way platforms and shadow-veil curtains.
const LAYER_ONEWAY := 1 << 8
const LAYER_VEIL := 1 << 9
## How long "down + jump" ignores one-way platforms.
const DROP_THROUGH_S := 0.25

## Combat registry (injected).
var world: CombatWorld
## Input source (injected; created when null).
var controls: InputRouter
## Parent for projectiles and effects (defaults to this node's parent).
var fx_parent: Node
## Equipped Vessels in slot order (empty = the bare wisp).
var vessel_ids: Array[String] = ["caelan", "nyra"]
## Vessel id -> Affinity level, read when equipping (empty: the sandbox's fixed level).
var affinity_levels: Dictionary = {}
## Soul Core and other progression bonuses (story 020): "max_hp", "gauge_cap",
## "flask_charges", "stamina_regen" (a fraction, 0.05 = +5 %).
var bonuses: Dictionary = {}
## Vessel id -> weapon ATK multiplier from reforging (story 036), applied on equip.
var weapon_mults: Dictionary = {}
## Overdrive (story 046): unlocked by the Pure Soul Matrix; the stage of a running one (0: none,
## 1: the first Ultimate, 2: the second, 3: the finisher).
var overdrive_unlocked: bool = false
var overdrive_stage: int = 0
## Optional (vessel_id, data) -> data: patches a Vessel's balance data on equip (ranks, passives).
var data_patcher: Callable
## Difficulty row in combat.json `difficulty`.
var difficulty: String = "normal"
## Where the sandbox respawns the player.
var spawn_point: Vector3 = Vector3.ZERO
## When false the body ignores input (bots drive it through the same Input actions anyway).
var input_enabled: bool = true
## The sandbox respawns in place after a death; the game scene turns this off and runs the
## Soul Echo and altar respawn itself (story 018).
var auto_respawn: bool = true

var team: int = CombatWorld.TEAM_PLAYER
## +1 looks right, -1 left.
var facing: int = 1
var health: Health
var gauge: SoulGauge
var loadout: Loadout
## The running action, or null in free movement.
var action: PlayerAction
## Physics clock in seconds, for parry and dodge timing.
var time: float = 0.0
## Human-readable state for the HUD, debug and the bridge.
var state: String = "idle"
var flask_charges: int = 3
## Vanishing Act: enemies lose track while > 0.
var stealth_left: float = 0.0
## Next landed hit counts as a backstab (Vanishing Act).
var next_hit_backstab: bool = false
## Final Stand: damage taken multiplier while > 0.
var damage_reduction_left: float = 0.0
var damage_reduction: float = 0.0
## Id of the Vessel whose Sync Guard fired last ("" before any), for the HUD and the bridge.
var last_sync_guard: String = ""
## Seconds left on Seris's Aether Shield (absorbs magic hits, destroys enemy projectiles).
var aether_shield_left: float = 0.0
var aether_shield_radius: float = 1.6
var _shield_fx: Node3D

var _combo_index: int = 0
var _combo_timer: float = 0.0
var _air_dash_ready: bool = true
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _invulnerable_left: float = 0.0
var _block_started_at: float = -99.0
var _a1_down: bool = false
var _a1_held: float = 0.0
var _dead_left: float = 0.0
var _visual_root: Node3D
var _move: Dictionary = {}
var _move_axis: Vector2 = Vector2.ZERO
## Enemies currently hunting the player: while any exist, the Soul Gauge counts as in combat.
var _aggro_ids: Dictionary[int, bool] = {}
## One-way platforms of the current room and whether each currently collides.
var _platforms: Array[StaticBody3D] = []
var _platform_solid: Dictionary[int, bool] = {}
var _drop_left: float = 0.0
## Wall contact (story 021): +1 when the wall is to the left (its face points right), -1 when to
## the right, kept for a short grace after leaving it.
var _wall_normal_x: float = 0.0
var _wall_coyote_left: float = 0.0
var _wall_lock_left: float = 0.0
var _wall_sliding: bool = false
var _trav: Dictionary = {}
var _water_cfg: Dictionary = {}
var _slide_cfg: Dictionary = {}
## Metres under the surface of the water the player stands in (story 031); 0 on dry land.
var water_depth: float = 0.0
## Element statuses on the player (story 034: the Sovereign's Ember burns).
var status: StatusEffects
## Set by the room: returns the room's solid rects, so bolts stop at rock (story 032).
var solid_source: Callable
## The Calcified Husk root-snare (story 022): while active the body cannot move, jump or dodge.
var snare: RootSnare


func _ready() -> void:
	collision_layer = 1 << 1
	collision_mask = 1 | LAYER_ONEWAY | LAYER_VEIL
	axis_lock_linear_z = true
	floor_snap_length = 0.3
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = CAPSULE_RADIUS
	capsule.height = CAPSULE_HEIGHT
	shape.shape = capsule
	shape.position.y = CAPSULE_HEIGHT * 0.5
	add_child(shape)
	_visual_root = Node3D.new()
	_visual_root.name = "Visuals"
	add_child(_visual_root)
	if controls == null:
		controls = InputRouter.new()
		controls.name = "InputRouter"
		add_child(controls)
	if fx_parent == null:
		fx_parent = get_parent()
	_move = Balance.combat("movement")
	_trav = Balance.combat("traversal")
	var sc: Variant = Balance.combat("slide")
	_slide_cfg = sc if sc is Dictionary else {}
	var wc: Variant = Balance.combat("water")
	_water_cfg = wc if wc is Dictionary else {}
	var snare_cfg: Variant = Balance.combat("root_snare")
	snare = RootSnare.from_data(snare_cfg if snare_cfg is Dictionary else {})
	status = StatusEffects.from_balance()
	gauge = SoulGauge.from_balance()
	health = Health.new(Balance.combat_f("soul_hp_base"))
	var levels: Dictionary = affinity_levels
	if levels.is_empty():
		var sandbox_affinity: Variant = Balance.sandbox("affinity")
		for vid in vessel_ids:
			levels[vid] = int(sandbox_affinity) if sandbox_affinity != null else 0
	equip(vessel_ids, levels)
	health.reset(max_hp())
	flask_charges = flask_max()
	spawn_point = global_position
	GameEvents.enemy_aggro_changed.connect(_on_enemy_aggro)
	if world != null:
		world.register(self)
		world.player = self


func _exit_tree() -> void:
	if world != null:
		world.unregister(self)


# --- Combatant interface -------------------------------------------------------------------

func hurt_rect() -> Rect2:
	return Rect2(global_position.x - HURT_RECT.x * 0.5, global_position.y, HURT_RECT.x, HURT_RECT.y)


func is_alive() -> bool:
	return not health.is_dead()


## Hidden from enemies (Vanishing Act).
func is_hidden() -> bool:
	return stealth_left > 0.0


## Resolve an incoming hit: i-frames, Sync Guard, block / parry, then damage.
func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	if health.is_dead():
		return DamagePacket.Result.IGNORED
	gauge.mark_combat()
	var attacker := p.attacker as Node3D
	if is_invulnerable():
		_check_perfect_dodge(attacker)
		return DamagePacket.Result.DODGED
	if p.kind == DamagePacket.KIND_UNBLOCKABLE and _try_sync_guard("unblockable_hit", p):
		return DamagePacket.Result.DODGED
	if aether_shield_left > 0.0 and p.kind == DamagePacket.KIND_MAGIC:
		Sfx.play("block")
		GameEvents.hit_fx_requested.emit(global_position + Vector3(0.0, 1.0, 0.3), 0.0, false, true)
		return DamagePacket.Result.BLOCKED
	var slot := loadout.active()
	var from_front := CombatMath.hits_frontal_arc(p.source_x, global_position.x, facing, 180.0)
	var blockable := p.kind != DamagePacket.KIND_UNBLOCKABLE and (p.kind != DamagePacket.KIND_MAGIC or p.can_reflect)
	var guard_broken := false
	if is_blocking() and from_front and blockable:
		var window := Balance.combat_f("parry.window_s") * _difficulty_f("window_scale", 1.0)
		var parryable := p.kind == DamagePacket.KIND_PARRYABLE or p.can_reflect
		if parryable and CombatMath.is_perfect_parry(_block_started_at, time, window):
			return _perfect_parry(p)
		var dry := slot.stamina.drain(Balance.combat_f("stamina.block_cost_per_hit"))
		var broke := p.heavy and slot.posture.add(p.posture)
		if not dry and not broke:
			Sfx.play("block")
			return DamagePacket.Result.BLOCKED
		guard_broken = true
	var def := slot.stat("def")
	var dmg := CombatMath.damage(p.atk, p.motion, def)
	dmg *= _difficulty_f("enemy_damage", 1.0)
	dmg *= slot.kit.damage_taken_multiplier(self, is_blocking())
	if damage_reduction_left > 0.0:
		dmg *= 1.0 - damage_reduction
	if dmg >= health.current and _try_sync_guard("lethal_blow", p):
		return DamagePacket.Result.BLOCKED
	if p.kind == DamagePacket.KIND_MAGIC and dmg >= max_hp() * _magic_guard_fraction() \
			and _try_sync_guard("magic_hit_over_fraction", p):
		return DamagePacket.Result.BLOCKED
	var taken := health.damage(dmg)
	if p.element_buildup > 0.0 and status.add_buildup(p.element, p.element_buildup):
		Sfx.play("hurt")
	if bool(p.tags.get("snare", false)) and not health.is_dead():
		stop_action()
		snare.apply()
		velocity.x = 0.0
		Sfx.play("root_snare")
	gauge.gain_from_damage_taken(taken)
	took_damage.emit(taken)
	GameEvents.player_hp_changed.emit(health.current, health.max_value)
	Sfx.play("hurt")
	GameEvents.camera_shake_requested.emit(0.35)
	if health.is_dead():
		_die()
		return DamagePacket.Result.KILLED
	if guard_broken:
		_start_guard_break()
		return DamagePacket.Result.GUARD_BROKEN
	if snare.is_active():
		return DamagePacket.Result.HIT
	if action == null or not action.hyper_armor:
		_flinch(p)
	return DamagePacket.Result.HIT


# --- Public API for kits, HUD, bridge -------------------------------------------------------

## A stat of the active Vessel (with Affinity bonuses).
func stat(key: String) -> float:
	var slot := loadout.active()
	return slot.stat(key) if slot != null else 0.0


## A packet from the active Vessel: its ATK, crit, backstab and posture multiplier applied.
func make_packet(motion: float, posture: float) -> DamagePacket:
	var slot := loadout.active()
	var p := DamagePacket.new()
	p.attacker = self
	p.team = team
	p.atk = slot.stat("atk") * slot.kit.damage_dealt_multiplier(self)
	p.motion = motion
	p.posture = CombatMath.posture_damage(posture, slot.stat("posture_multiplier"))
	p.crit_chance = slot.stat("crit_chance")
	p.crit_multiplier = Balance.combat_f("damage.crit_multiplier")
	p.backstab_multiplier = slot.stat("backstab_multiplier")
	p.source_x = global_position.x
	p.tags["vessel"] = slot.id
	return p


## Start `a`, ending the current action (interrupted).
func start_action(a: PlayerAction) -> void:
	if a == null:
		return
	if action != null:
		action.finish(self, true)
	action = a
	for h in a.hits:
		h.reset()
	state = a.id
	action_started.emit(a.id)


## End the current action now.
func stop_action() -> void:
	if action != null:
		var a := action
		action = null
		a.finish(self, true)


func is_blocking() -> bool:
	return action != null and action.blocking


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0 or (action != null and action.is_invulnerable())


## Grant i-frames for `seconds` (swap, Sync Guard).
func grant_invulnerability(seconds: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left, seconds)


## Begin a block now (Royal Guard). The parry window counts from this moment.
func begin_block() -> void:
	var a := PlayerAction.new("block", 3600.0)
	a.blocking = true
	a.cancel_after = 0.0
	a.cancel_into = PackedStringArray(["dodge", "jump"])
	a.steer = 0.0
	_block_started_at = time
	start_action(a)


func end_block() -> void:
	if action != null and action.id == "block":
		stop_action()


## Burning and other damage over time; water puts a burn out.
func _tick_status(delta: float) -> void:
	status.tick(delta)
	if is_swimming() and status.has_status("burning"):
		status.active.erase("burning")
	var dot := status.dot_per_s(health.max_value)
	if dot > 0.0 and not health.is_dead():
		health.damage(dot * delta)
		GameEvents.player_hp_changed.emit(health.current, health.max_value)
		if health.is_dead():
			_die()


## The tilt in degrees of the sliding floor under the player's feet (0 off any, or in the air).
func slide_angle() -> float:
	if not is_on_floor() or not is_inside_tree():
		return 0.0
	var feet := Vector2(global_position.x, global_position.y)
	for n in get_tree().get_nodes_in_group(SlideZone.GROUP):
		var z := n as SlideZone
		if z.covers(feet):
			return z.angle
	return 0.0


## True while deep enough in water to swim (slower, strokes instead of jumps, no roll).
func is_swimming() -> bool:
	return water_depth >= float(_water_cfg.get("swim_depth_m", 0.5))


## Read the depth of whatever water the player is in, and splash on a fast entry.
func _update_water() -> void:
	var was := water_depth
	water_depth = 0.0
	if not is_inside_tree():
		return
	var feet := Vector2(global_position.x, global_position.y)
	for n in get_tree().get_nodes_in_group(Water.GROUP):
		water_depth = maxf(water_depth, (n as Water).depth_at(feet))
	if was <= 0.0 and water_depth > 0.0 and velocity.y < -3.0:
		Sfx.play("splash")
		GameEvents.ultimate_fx_requested.emit("splash", Vector3(global_position.x, global_position.y + water_depth, 0.0), 1.2)


## Set a Vessel's weapon multiplier now (after a reforge) and for later equips.
func set_weapon_mult(vessel_id: String, mult: float) -> void:
	weapon_mults[vessel_id] = mult
	var i := loadout.index_of(vessel_id)
	if i >= 0:
		loadout.slots[i].atk_mult = mult


## May Overdrive start: unlocked, a full gauge of `bars`, at least two Vessels bound?
static func overdrive_allowed(unlocked: bool, bars: int, vessels: int) -> bool:
	return unlocked and bars >= int(Balance.combat_f("overdrive.cost_bars")) and vessels >= 2


## Would pressing the Ultimate now start Overdrive?
func overdrive_ready() -> bool:
	return overdrive_stage == 0 and overdrive_allowed(overdrive_unlocked, gauge.bars(), loadout.size())


## Overdrive: the gauge empties; this Vessel's Ultimate, a free swap, the next one's, a finisher.
func _start_overdrive() -> bool:
	var first := loadout.active().kit.ultimate_action(self)
	if first == null:
		return false
	gauge.spend_bars(int(Balance.combat_f("overdrive.cost_bars")))
	overdrive_stage = 1
	_overdrive_guard()
	start_action(first)
	state = "ultimate"
	ultimate_started.emit(loadout.active().id)
	GameEvents.ultimate_fx_requested.emit("final_stand", global_position, 3.0)
	Sfx.play("ultimate")
	return true


func _overdrive_guard() -> void:
	grant_invulnerability(Balance.combat_f("overdrive.guard_s"))


func _advance_overdrive() -> void:
	_overdrive_guard()
	match overdrive_stage:
		1:
			overdrive_stage = 2
			var next := loadout.neighbour(1)
			state = "overdrive"  # not "ultimate", which refuses a swap
			try_swap(next, true)
			var second := loadout.active().kit.ultimate_action(self)
			if second != null:
				start_action(second)
				state = "ultimate"
				ultimate_started.emit(loadout.active().id)
			else:
				_advance_overdrive()
		2:
			overdrive_stage = 3
			start_action(_overdrive_finisher())
		_:
			overdrive_stage = 0


## The combined finisher: one wide blow carrying both Vessels' elements.
func _overdrive_finisher() -> PlayerAction:
	var od: Dictionary = Balance.combat("overdrive")
	var a := PlayerAction.new("overdrive_finisher", float(od.get("finisher_s", 0.7)))
	a.hyper_armor = true
	a.data["fired"] = false
	a.on_tick = func(pl: Player, act: PlayerAction, _dt: float) -> void:
		if act.data["fired"] or act.elapsed < float(od.get("finisher_windup_s", 0.3)):
			return
		act.data["fired"] = true
		var targets: Array[Node3D] = []
		var centre := Vector2(pl.global_position.x, pl.global_position.y + 0.9)
		pl.world.query_radius(centre, float(od.get("finisher_radius_m", 9.0)), CombatWorld.TEAM_ENEMY, targets)
		var elements: Array[String] = []
		for s in pl.loadout.slots:
			elements.append(str(s.data.get("primary", {}).get("element", "physical")))
		for i in range(targets.size()):
			var t := targets[i]
			var p := pl.make_packet(float(od.get("finisher_motion", 4.0)), float(od.get("finisher_posture", 120.0)))
			p.aoe = true
			p.element = elements[i % elements.size()]
			p.element_buildup = float(od.get("finisher_buildup", 60.0))
			p.source_x = pl.global_position.x
			p.tags["ability"] = "overdrive_finisher"
			p.result = t.call("receive_hit", p)
			pl.report_hit(t, p)
		GameEvents.ultimate_fx_requested.emit("final_stand", pl.global_position, float(od.get("finisher_radius_m", 9.0)))
		GameEvents.camera_shake_requested.emit(1.0)
		Sfx.play("posture_break")
	return a


## Raise Seris's Aether Shield for `seconds` with `radius` metres of reach.
func raise_aether_shield(seconds: float, radius: float) -> void:
	aether_shield_left = maxf(aether_shield_left, seconds)
	aether_shield_radius = radius
	if _shield_fx == null:
		var mi := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = radius
		s.height = radius * 2.0
		mi.mesh = s
		mi.material_override = ArenaMaterials.flat(Color(0.55, 0.78, 1.0, 0.22), 1.2, false, true)
		# A close-fitting bubble around her body; the hit reach (radius) stays wider than it looks.
		mi.scale = Vector3(0.5, 0.62, 0.3)
		_shield_fx = mi
		add_child(_shield_fx)
		_shield_fx.position = Vector3(0.0, 1.0, 0.0)
	_shield_fx.visible = true
	Sfx.play("shield")


func _magic_guard_fraction() -> float:
	var f := 1.0
	for s in loadout.slots:
		if s.kit.sync_guard_trigger() == "magic_hit_over_fraction":
			f = minf(f, s.kit.sync_guard_fraction())
	return f


func _tick_aether_shield(delta: float) -> void:
	if aether_shield_left <= 0.0:
		return
	aether_shield_left = maxf(aether_shield_left - delta, 0.0)
	if aether_shield_left <= 0.0:
		if _shield_fx != null:
			_shield_fx.visible = false
		return
	var centre := global_position + Vector3(0.0, 1.0, 0.0)
	for n in get_tree().get_nodes_in_group(Projectile.ENEMY_GROUP):
		var proj := n as Node3D
		if proj != null and not proj.is_queued_for_deletion() \
				and proj.global_position.distance_to(centre) <= aether_shield_radius:
			proj.queue_free()


## Move instantly (Shadowstep, Severing Arrival, respawn).
func teleport(x: float, y: float) -> void:
	global_position = Vector3(x, y, 0.0)
	velocity = Vector3.ZERO
	reset_physics_interpolation()


func set_facing(dir: int) -> void:
	if dir != 0:
		facing = 1 if dir > 0 else -1


## Spawn a projectile from the player (Phantom Blades, King's Judgment).
func spawn_projectile(p: DamagePacket, origin: Vector2, vel: Vector2, size: Vector2,
		max_distance: float, visual: Node3D) -> Projectile:
	var proj := Projectile.spawn(fx_parent, world, p, origin, vel, size, visual)
	proj.target_team = CombatWorld.TEAM_ENEMY
	proj.max_distance = max_distance
	proj.lifetime = max_distance / maxf(vel.length(), 0.1) + 0.1
	proj.hit_landed.connect(_on_hit_landed)
	return proj


## Called for every hit the player lands (actions, projectiles, ultimates).
func report_hit(target: Node3D, p: DamagePacket) -> void:
	_on_hit_landed(target, p)


## Swap to `index`. A normal swap pays the global cooldown, grants 0.2 s i-frames and plays the
## incoming Vessel's Resonance Strike; a `free` swap (Sync Guard) skips cooldown and Resonance.
func try_swap(index: int, free: bool = false) -> bool:
	if health.is_dead() or state == "ultimate":
		return false
	if not loadout.swap_to(index, free):
		return false
	stop_action()
	_combo_index = 0
	_show_active_visual()
	grant_invulnerability(Balance.combat_f("swap.iframe_s"))
	var slot := loadout.active()
	vessel_swapped.emit(slot.id, index)
	GameEvents.vessel_swapped.emit(slot.id, index)
	Sfx.play("swap")
	if not free:
		var res := slot.kit.resonance_action(self)
		if res != null:
			start_action(res)
	return true


## Fire the active Vessel's Sync Ultimate when bars and Affinity allow. Returns true on start.
func try_ultimate() -> bool:
	if overdrive_ready():
		return _start_overdrive()
	var slot := loadout.active()
	var cost := int(Balance.combat_f("sync_ultimate.cost_bars"))
	if slot.affinity < int(Balance.combat_f("sync_ultimate.min_affinity")) or not gauge.has_bars(cost):
		return false
	var a := slot.kit.ultimate_action(self)
	if a == null:
		return false
	gauge.spend_bars(cost)
	start_action(a)
	state = "ultimate"
	ultimate_started.emit(slot.id)
	return true


## Drink a Soul Flask: 40 % max HP over 0.8 s. False when out of charges.
func try_flask() -> bool:
	if flask_charges <= 0 or health.is_dead() or action != null:
		return false
	flask_charges -= 1
	var duration := Balance.combat_f("flask.heal_duration_s")
	var total := health.max_value * (Balance.combat_f("flask.heal_fraction") + float(bonuses.get("flask_heal", 0.0)))
	var a := PlayerAction.new("flask", duration)
	a.steer = 0.35
	a.on_tick = func(pl: Player, _act: PlayerAction, dt: float) -> void:
		pl.health.heal(total * dt / duration)
		GameEvents.player_hp_changed.emit(pl.health.current, pl.health.max_value)
	start_action(a)
	return true


## Equip `ids` (wheel order; empty = the wisp) with Affinity `levels`. The active Vessel stays
## active when it is still equipped. Max HP follows the loadout; current HP keeps its share.
func equip(ids: Array[String], levels: Dictionary = {}) -> void:
	var prev := ""
	if loadout != null and loadout.active() != null:
		prev = loadout.active().id
		for slot in loadout.slots:
			if slot.visual != null:
				slot.visual.queue_free()
	var ratio := health.ratio() if health != null and health.max_value > 0.0 else 1.0
	var list: Array[String] = ids.duplicate()
	if list.is_empty():
		list = ["wisp"]
	vessel_ids = list
	loadout = Loadout.from_balance()
	for vid in list:
		var vdata: Dictionary = Balance.vessel(vid)
		if data_patcher.is_valid():
			vdata = data_patcher.call(vid, vdata)
		var slot := VesselSlot.create(vid, int(levels.get(vid, 0)), vdata)
		slot.atk_mult = float(weapon_mults.get(vid, 1.0))
		slot.visual = VesselVisual.build(slot.data)
		slot.visual.visible = false
		_visual_root.add_child(slot.visual)
		loadout.add(slot)
	if prev != "" and loadout.index_of(prev) >= 0:
		loadout.active_index = loadout.index_of(prev)
	_apply_slot_bonuses()
	if health != null:
		health.max_value = max_hp()
		health.current = clampf(health.max_value * ratio, 1.0, health.max_value)
		GameEvents.player_hp_changed.emit(health.current, health.max_value)
	_combo_index = 0
	stop_action()
	_show_active_visual()
	GameEvents.vessel_swapped.emit(loadout.active().id, loadout.active_index)


## Apply Soul Core bonuses (story 020): max HP (the gain is also healed), Soul Gauge cap, stamina
## regen, flask charges (new charges arrive full) and flask healing.
func apply_bonuses(mods: Dictionary) -> void:
	var old_max := health.max_value
	var old_flasks := flask_max()
	bonuses = mods.duplicate()
	health.max_value = max_hp()
	health.current = clampf(health.current + maxf(health.max_value - old_max, 0.0), 1.0, health.max_value)
	gauge.max_value = Balance.combat_f("soul_gauge.max") + float(bonuses.get("gauge_cap", 0.0))
	flask_charges = mini(flask_charges + maxi(flask_max() - old_flasks, 0), flask_max())
	_apply_slot_bonuses()
	GameEvents.player_hp_changed.emit(health.current, health.max_value)


func _apply_slot_bonuses() -> void:
	var regen := Balance.combat_f("stamina.regen_per_s") * (1.0 + float(bonuses.get("stamina_regen", 0.0)))
	for slot in loadout.slots:
		slot.stamina.regen_per_s = regen


## Update Affinity levels without re-equipping (a level-up mid-run).
func set_affinity(vessel_id: String, level: int) -> void:
	var i := loadout.index_of(vessel_id)
	if i >= 0:
		loadout.slots[i].affinity = level


## True while the Intruder has no Vessel.
func is_wisp() -> bool:
	return loadout.active() != null and loadout.active().id == "wisp"


## Soul HP: the base pool, every equipped Vessel's bonus and Soul Core nodes.
func max_hp() -> float:
	return Balance.combat_f("soul_hp_base") + loadout.hp_bonus_total() + float(bonuses.get("max_hp", 0.0))


## Flask charges when full (3, up to 6 with Soul Core nodes).
func flask_max() -> int:
	return int(Balance.combat_f("flask.charges")) + int(bonuses.get("flask_charges", 0))


## Rest at an altar: full HP and flasks, stamina and posture reset, no move.
func rest() -> void:
	stop_action()
	health.reset(max_hp())
	flask_charges = flask_max()
	for slot in loadout.slots:
		slot.stamina.restore(slot.stamina.max_value)
		slot.posture.value = 0.0
	GameEvents.player_hp_changed.emit(health.current, health.max_value)


## Back to full at the spawn point (sandbox death, debug, altar rest).
func respawn() -> void:
	snare.break_now()
	status.clear()
	health.reset(max_hp())
	flask_charges = flask_max()
	stop_action()
	_dead_left = 0.0
	state = "idle"
	teleport(spawn_point.x, spawn_point.y)
	if loadout.active().visual != null:
		loadout.active().visual.rotation = Vector3.ZERO
	GameEvents.player_hp_changed.emit(health.current, health.max_value)
	respawned.emit()


## The current room's one-way platforms (story 015). Each collides only while the feet are at or
## above its top and the player is not dropping through.
func set_room_platforms(bodies: Array[StaticBody3D]) -> void:
	for b in _platforms:
		if is_instance_valid(b):
			remove_collision_exception_with(b)
	_platforms = bodies.duplicate()
	_platform_solid.clear()
	_update_platforms(0.0)


## Die now (void falls, debug, tests).
func kill() -> void:
	if health.is_dead():
		return
	health.damage(health.current)
	GameEvents.player_hp_changed.emit(health.current, health.max_value)
	_die()


func on_floor() -> bool:
	return is_on_floor()


## A snapshot for the HUD, debug HUD and bridge.
func snapshot() -> Dictionary:
	var slot := loadout.active()
	return {
		"x": snappedf(global_position.x, 0.01),
		"y": snappedf(global_position.y, 0.01),
		"vx": snappedf(velocity.x, 0.01),
		"vy": snappedf(velocity.y, 0.01),
		"facing": facing,
		"state": state,
		"on_floor": is_on_floor(),
		"hp": snappedf(health.current, 0.1),
		"hp_max": health.max_value,
		"vessel": slot.id,
		"slot": loadout.active_index,
		"stamina": snappedf(slot.stamina.value, 0.1),
		"exhausted": slot.stamina.is_exhausted(),
		"posture": snappedf(slot.posture.value, 0.1),
		"gauge": snappedf(gauge.value, 0.1),
		"bars": gauge.bars(),
		"swap_cd": snappedf(loadout.swap_cooldown_left, 0.01),
		"invulnerable": is_invulnerable(),
		"blocking": is_blocking(),
		"hidden": is_hidden(),
		"flasks": flask_charges,
		"last_sync_guard": last_sync_guard,
		"cooldowns": slot.cooldowns.duplicate(),
		"rooted": snare.is_active(),
		"shield": snappedf(aether_shield_left, 0.01),
		"snare_taps_left": snare.taps_left(),
		"water_depth": snappedf(water_depth, 0.01),
		"burning": status.has_status("burning"),
	}


# --- Frame loop -----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	time += delta
	loadout.tick(delta)
	if not _aggro_ids.is_empty():
		gauge.mark_combat()
	gauge.tick(delta)
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	stealth_left = maxf(stealth_left - delta, 0.0)
	damage_reduction_left = maxf(damage_reduction_left - delta, 0.0)
	_tick_aether_shield(delta)
	# Overdrive moves to its next step whenever the current one has ended, however it ended.
	if overdrive_stage > 0 and action == null and not health.is_dead():
		_advance_overdrive()
	_update_water()
	loadout.active().kit.tick(delta)
	_tick_status(delta)
	if health.is_dead():
		_dead_tick(delta)
		return
	_move_axis = controls.move_axis() if input_enabled else Vector2.ZERO
	if snare.is_active():
		_rooted_tick(delta)
		return
	_read_buttons(delta)
	_update_platforms(delta)
	if action != null:
		_run_action(delta)
	else:
		_free_move(delta)
	_apply_gravity(delta)
	# Shadow veils (story 023) stop everything except a Shadowstep.
	set_collision_mask_value(10, not (action != null and action.id == "shadowstep"))
	move_and_slide()
	if global_position.z != 0.0:
		global_position.z = 0.0
	if is_on_floor():
		_air_dash_ready = true
		_coyote_left = float(_move.get("coyote_s", 0.08))
	else:
		_coyote_left = maxf(_coyote_left - delta, 0.0)
	_update_wall_contact(delta)
	_update_state_name()
	_animate(delta)


func _read_buttons(delta: float) -> void:
	if not input_enabled or state == "ultimate":
		return
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	if controls.just_pressed("jump"):
		_jump_buffer_left = float(_move.get("jump_buffer_s", 0.1))
	if controls.just_pressed("swap_next"):
		try_swap(loadout.neighbour(1))
	elif controls.just_pressed("swap_prev"):
		try_swap(loadout.neighbour(-1))
	if controls.ultimate_just_pressed():
		try_ultimate()
	if controls.just_pressed("flask"):
		try_flask()
	var kit := loadout.active().kit
	if controls.just_pressed("ability_1") and _can_start("ability"):
		_a1_down = true
		_a1_held = 0.0
		kit.ability_1_pressed(self)
	elif _a1_down and controls.pressed("ability_1"):
		_a1_held += delta
		kit.ability_1_held(self, _a1_held)
	elif _a1_down:
		_a1_down = false
		kit.ability_1_released(self, _a1_held)
	if controls.ability_2_just_pressed() and _can_start("ability"):
		kit.ability_2(self)
	_combo_timer = maxf(_combo_timer - delta, 0.0)
	if _combo_timer <= 0.0 and action == null:
		_combo_index = 0
	if controls.just_pressed("attack") and _can_start("attack"):
		_start_primary()
	if controls.just_pressed("dodge") and _can_start("dodge"):
		_start_dodge()


## May an input of `kind` start now (free, or the action allows a cancel)?
func _can_start(kind: String) -> bool:
	if action == null:
		return true
	return action.can_cancel_into(kind)


func _start_primary() -> void:
	var kit := loadout.active().kit
	var a := kit.primary_action(self, _combo_index)
	if a == null:
		return
	_combo_index = (_combo_index + 1) % maxi(kit.combo_length(), 1)
	_combo_timer = a.duration + kit.combo_reset_s()
	if _move_axis.x != 0.0:
		set_facing(int(signf(_move_axis.x)))
	start_action(a)


func _start_dodge() -> void:
	var kit := loadout.active().kit
	# No roll or flip under water; a blink (Rift Step) still works.
	if is_swimming() and str(kit.data.get("dodge", {}).get("kind", "roll")) != "blink":
		return
	if _move_axis.x != 0.0:
		set_facing(int(signf(_move_axis.x)))
	var a: PlayerAction
	if is_on_floor() or _coyote_left > 0.0:
		a = kit.dodge_action(self)
	elif _air_dash_ready:
		a = kit.air_dash_action(self)
		if a != null:
			_air_dash_ready = false
	if a != null:
		a.data["started_at"] = time
		start_action(a)


func _run_action(delta: float) -> void:
	var a := action
	if _jump_buffer_left > 0.0 and a.can_cancel_into("jump") and (is_on_floor() or _coyote_left > 0.0):
		stop_action()
		_free_move(delta)
		return
	var running := a.advance(self, delta)
	if action != a:
		return  # the callback started another action
	var vx := a.current_velocity_x()
	if not is_nan(vx):
		velocity.x = vx * float(facing)
	elif a.steer > 0.0:
		velocity.x = _move_axis.x * stat("move_speed") * a.steer
	else:
		velocity.x = move_toward(velocity.x, 0.0, float(_move.get("ground_decel", 80.0)) * delta)
	if not is_nan(a.velocity_y):
		velocity.y = a.velocity_y
	var origin := Vector2(global_position.x, global_position.y)
	for h in a.hits:
		if h.is_active(a.elapsed):
			h.sweep(world, origin, facing, CombatWorld.TEAM_ENEMY, _on_hit_landed)
	if not running:
		action = null
		a.finish(self, false)


func _free_move(delta: float) -> void:
	var speed := stat("move_speed")
	if is_swimming():
		speed *= float(_water_cfg.get("move_mult", 0.6))
	var slope := slide_angle()
	if slope != 0.0 and absf(_move_axis.x) > 0.01:
		speed = SlideZone.run_speed(speed, slope, int(signf(_move_axis.x)), float(_slide_cfg.get("uphill_penalty", 1.6)))
	var target_vx := _move_axis.x * speed
	var accel := float(_move.get("ground_accel", 60.0)) if absf(target_vx) > 0.01 else float(_move.get("ground_decel", 80.0))
	if slope != 0.0 and absf(target_vx) <= 0.01:
		# Coasting on a slope: no braking, the slope carries you (capped below).
		accel = 0.0
	if not is_on_floor():
		accel *= float(_move.get("air_control", 0.9))
	_wall_lock_left = maxf(_wall_lock_left - delta, 0.0)
	# Right after a wall-jump the kick carries: steering waits out the lock.
	if _wall_lock_left <= 0.0:
		velocity.x = move_toward(velocity.x, target_vx, accel * delta)
		if absf(_move_axis.x) > 0.2:
			set_facing(int(signf(_move_axis.x)))
	if _jump_buffer_left > 0.0 and not is_on_floor() and _coyote_left <= 0.0 and _wall_coyote_left > 0.0:
		_wall_jump()
	if _jump_buffer_left > 0.0 and is_on_floor() and _move_axis.y > 0.5 and _standing_on_platform():
		# Down + jump drops through a one-way platform.
		_drop_left = DROP_THROUGH_S
		_jump_buffer_left = 0.0
		_update_platforms(0.0)
	elif _jump_buffer_left > 0.0 and is_swimming() and not is_on_floor():
		# A stroke under water; near the surface, a jump out.
		var near_top := water_depth <= float(_water_cfg.get("float_depth", 1.2)) + 0.3
		var jump_out := float(_move.get("jump_velocity", 11.5)) * float(_water_cfg.get("surface_jump_mult", 0.95))
		velocity.y = jump_out if near_top else float(_water_cfg.get("stroke_mps", 5.0))
		_jump_buffer_left = 0.0
		Sfx.play("jump")
	elif _jump_buffer_left > 0.0 and (is_on_floor() or _coyote_left > 0.0):
		velocity.y = float(_move.get("jump_velocity", 11.5))
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
		Sfx.play("jump")
	if input_enabled and controls.just_released("jump") and velocity.y > 0.0:
		velocity.y *= 0.5
	if slope != 0.0:
		velocity.x += SlideZone.slide_accel(slope, float(_move.get("gravity", 30.0)), float(_slide_cfg.get("friction", 0.6))) * delta
		var cap := float(_slide_cfg.get("max_slide_mps", 7.0))
		if absf(_move_axis.x) <= 0.01:
			velocity.x = clampf(velocity.x, -cap, cap)


## Kick off the wall just touched: away and up, with a short steering lock, and the air-dash back.
func _wall_jump() -> void:
	var v: Array = _trav.get("wall_jump_velocity", [7.0, 10.5])
	velocity.x = _wall_normal_x * float(v[0])
	velocity.y = float(v[1])
	set_facing(int(_wall_normal_x))
	_wall_lock_left = float(_trav.get("wall_jump_lock_s", 0.16))
	_wall_coyote_left = 0.0
	_jump_buffer_left = 0.0
	_air_dash_ready = true
	Sfx.play("wall_jump")


## Track the wall being touched in the air, and slow the fall while pressing into it.
func _update_wall_contact(delta: float) -> void:
	_wall_sliding = false
	if is_on_floor():
		_wall_coyote_left = 0.0
		return
	var touching := false
	if is_on_wall():
		var n := get_wall_normal()
		if absf(n.x) > 0.7:
			touching = true
			_wall_normal_x = signf(n.x)
			_wall_coyote_left = float(_trav.get("wall_coyote_s", 0.1))
	if not touching:
		_wall_coyote_left = maxf(_wall_coyote_left - delta, 0.0)
		return
	var pressing := _move_axis.x * -_wall_normal_x > 0.2
	var slide := float(_trav.get("wall_slide_max_fall_mps", 3.5))
	if pressing and action == null and velocity.y < -slide:
		velocity.y = -slide
		_wall_sliding = true


## Rooted by a Husk: no movement, jump or dodge. Attack, jump and dodge taps count toward breaking
## free; Nyra's Shadowstep (ability 1) breaks it at once and goes ahead.
func _rooted_tick(delta: float) -> void:
	snare.tick(delta)
	state = "rooted"
	velocity.x = 0.0
	if input_enabled:
		for a: String in ["attack", "jump", "dodge"]:
			if controls.just_pressed(a) and snare.tap():
				Sfx.play("root_break")
		for a: String in ["ability_1", "dodge"]:
			if controls.just_pressed(a) and snare.is_active() and loadout.active().kit.breaks_snare_on(a):
				snare.break_now()
				Sfx.play("root_break")
	_apply_gravity(delta)
	move_and_slide()
	if global_position.z != 0.0:
		global_position.z = 0.0
	if not snare.is_active():
		state = "idle"
	_animate(delta)


## Thrown upward by a bounce mushroom at `speed` m/s (story 021).
func bounce(speed: float) -> void:
	if health.is_dead():
		return
	stop_action()
	velocity.y = speed
	_air_dash_ready = true
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	Sfx.play("bounce")


## Damage from the world, not an attack (falling out of a room): no i-frames, no block. Returns
## true when it killed.
func hurt_by_world(amount: float) -> bool:
	if health.is_dead():
		return true
	var taken := health.damage(amount)
	took_damage.emit(taken)
	GameEvents.player_hp_changed.emit(health.current, health.max_value)
	Sfx.play("hurt")
	if health.is_dead():
		_die()
		return true
	return false


func _update_platforms(delta: float) -> void:
	_drop_left = maxf(_drop_left - delta, 0.0)
	for b in _platforms:
		if not is_instance_valid(b):
			continue
		var top := b.global_position.y + 0.125
		var solid := _drop_left <= 0.0 and global_position.y >= top - 0.06 and velocity.y <= 0.5
		var key := b.get_instance_id()
		if _platform_solid.get(key, true) == solid and _platform_solid.has(key):
			continue
		_platform_solid[key] = solid
		if solid:
			remove_collision_exception_with(b)
		else:
			add_collision_exception_with(b)


func _standing_on_platform() -> bool:
	for b in _platforms:
		if is_instance_valid(b) and absf(global_position.y - (b.global_position.y + 0.125)) < 0.08:
			var half := (b.get_child(0) as CollisionShape3D).shape.get("size").x * 0.5 as float
			if absf(global_position.x - b.global_position.x) <= half + CAPSULE_RADIUS:
				return true
	return false


func _apply_gravity(delta: float) -> void:
	# In water deeper than the float depth, buoyancy lifts her even off the bottom.
	var floating := water_depth > float(_water_cfg.get("float_depth", 1.2))
	if is_on_floor() and velocity.y <= 0.0 and not floating:
		return
	if water_depth > 0.05 and (action == null or is_nan(action.velocity_y)):
		velocity.y = Water.swim_vy(velocity.y, water_depth, delta, float(_move.get("gravity", 30.0)), _water_cfg)
		return
	var scale := action.gravity_scale if action != null else 1.0
	if action != null and not is_nan(action.velocity_y):
		return
	# Story 054 (D-063): falling pulls harder than rising, so a jump comes down with weight.
	if velocity.y < 0.0 and action == null:
		scale *= float(_move.get("fall_gravity_mult", 1.0))
	velocity.y = maxf(velocity.y - float(_move.get("gravity", 30.0)) * scale * delta,
		-float(_move.get("max_fall_speed", 30.0)))


func _on_hit_landed(target: Node3D, p: DamagePacket) -> void:
	gauge.mark_combat()
	match p.result:
		DamagePacket.Result.HIT, DamagePacket.Result.KILLED, DamagePacket.Result.SHIELDED:
			gauge.gain("per_hit")
			if p.is_resonance:
				gauge.gain("per_resonance_hit")
			if p.result == DamagePacket.Result.KILLED:
				gauge.gain("per_kill")
			next_hit_backstab = false
			GameEvents.hitstop_requested.emit(Balance.combat_f("hitstop.hit_s"))
			GameEvents.camera_shake_requested.emit(0.12 if not p.was_crit else 0.25)
			# Story 055: a killing blow lands heavier than a hit.
			Sfx.play("kill" if p.result == DamagePacket.Result.KILLED else "hit", randf_range(0.94, 1.06))
			if p.is_primary:
				loadout.active().kit.on_primary_landed(self, target, p)
	hit_landed.emit(target, p)


func _perfect_parry(p: DamagePacket) -> DamagePacket.Result:
	var slot := loadout.active()
	slot.stamina.restore(Balance.combat_f("parry.stamina_restore"))
	gauge.gain("per_perfect_parry")
	var attacker := p.attacker as Node3D
	if attacker != null and is_instance_valid(attacker) and attacker.has_method("on_parried"):
		attacker.call("on_parried", self, Balance.combat_f("parry.posture_damage"))
	GameEvents.perfect_parry.emit(attacker)
	perfect_parry.emit(attacker)
	GameEvents.hitstop_requested.emit(Balance.combat_f("hitstop.parry_s"))
	GameEvents.camera_shake_requested.emit(0.3)
	Sfx.play("parry")
	var reflected := false
	if p.can_reflect and attacker != null and is_instance_valid(attacker) and attacker.has_method("receive_reflect"):
		attacker.call("receive_reflect", p)
		reflected = true
	slot.kit.on_perfect_parry(self, attacker, p)
	return DamagePacket.Result.REFLECTED if reflected else DamagePacket.Result.PARRIED


func _check_perfect_dodge(attacker: Node3D) -> void:
	var window := Balance.combat_f("dodge.perfect_window_s") * _difficulty_f("window_scale", 1.0)
	if action == null or not action.is_invulnerable() or action.data.get("perfect_dodged", false):
		return
	if action.id != "dodge" and action.id != "air_dash":
		return
	if action.time_into_iframes() <= window:
		action.data["perfect_dodged"] = true
		gauge.gain("per_perfect_dodge")
		GameEvents.perfect_dodge.emit(attacker)
		perfect_dodge.emit(attacker)
		Sfx.play("perfect_dodge")


## Look for a Vessel (active first) whose Sync Guard matches `trigger` and can pay for it.
func _try_sync_guard(trigger: String, p: DamagePacket) -> bool:
	var order: Array[int] = [loadout.active_index]
	for i in range(loadout.size()):
		if i != loadout.active_index:
			order.append(i)
	var cost := int(Balance.combat_f("sync_guard.cost_bars"))
	var min_aff := int(Balance.combat_f("sync_guard.min_affinity"))
	for i in order:
		var slot := loadout.slots[i]
		if slot.kit.sync_guard_trigger() != trigger:
			continue
		if slot.affinity < min_aff or slot.sync_guard_left > 0.0 or not gauge.has_bars(cost):
			continue
		gauge.spend_bars(cost)
		# Darius's Unkillable (story 050) shortens his guard's cooldown in his own data.
		slot.sync_guard_left = float(slot.data.get("sync_guard", {}).get("cooldown_s",
			Balance.combat_f("sync_guard.cooldown_s")))
		if i != loadout.active_index:
			try_swap(i, true)
		grant_invulnerability(0.5)
		slot.kit.sync_guard(self, p)
		# A Sync passive may make the guard heal too (Caelan's King's Mercy, story 037).
		var heal := float(slot.data.get("sync_guard", {}).get("heal_fraction", 0.0))
		if heal > 0.0:
			health.heal(max_hp() * heal)
			GameEvents.player_hp_changed.emit(health.current, health.max_value)
		last_sync_guard = slot.id
		sync_guard_triggered.emit(slot.id)
		Sfx.play("sync_guard")
		return true
	return false


func _flinch(p: DamagePacket) -> void:
	var a := PlayerAction.new("hurt", FLINCH_S)
	var away := signf(global_position.x - p.source_x)
	if away == 0.0:
		away = -float(facing)
	a.set_velocity(maxf(p.knockback, 2.5) * away * float(facing), 0.0, FLINCH_S * 0.6)
	start_action(a)


func _start_guard_break() -> void:
	var a := PlayerAction.new("guard_break", Balance.combat_f("posture.player_guard_break_s"))
	a.set_velocity(-1.5, 0.0, 0.2)
	start_action(a)


func _die() -> void:
	stop_action()
	state = "dead"
	_dead_left = RESPAWN_S
	velocity = Vector3.ZERO
	died.emit()


func _dead_tick(delta: float) -> void:
	velocity.x = 0.0
	_apply_gravity(delta)
	move_and_slide()
	_dead_left -= delta
	var vis := loadout.active().visual
	if vis != null:
		vis.rotation.z = lerpf(vis.rotation.z, -PI * 0.5 * float(facing), minf(delta * 8.0, 1.0))
	if _dead_left <= 0.0 and auto_respawn:
		respawn()


func _on_enemy_aggro(enemy: Node, on: bool) -> void:
	if on:
		_aggro_ids[enemy.get_instance_id()] = true
	else:
		_aggro_ids.erase(enemy.get_instance_id())


func _difficulty_f(key: String, fallback: float) -> float:
	var v: Variant = Balance.combat("difficulty.%s.%s" % [difficulty, key])
	return float(v) if v != null else fallback


func _show_active_visual() -> void:
	for i in range(loadout.size()):
		var vis := loadout.slots[i].visual
		if vis != null:
			vis.visible = i == loadout.active_index


func _update_state_name() -> void:
	if action != null:
		if state != "ultimate":
			state = action.id
		return
	if is_on_floor():
		state = "run" if absf(velocity.x) > 0.3 else "idle"
	elif _wall_sliding:
		state = "wall_slide"
	elif is_swimming():
		state = "swim"
	else:
		state = "jump" if velocity.y > 0.0 else "fall"


func _animate(delta: float) -> void:
	var vis := loadout.active().visual as VesselVisual
	if vis == null:
		return
	var progress := action.elapsed / action.duration if action != null and action.duration > 0.0 else 0.0
	vis.pose(state, progress, facing, absf(velocity.x) / maxf(stat("move_speed"), 0.1), delta)
	vis.set_hidden_look(is_hidden())
	vis.set_glow(1.0 + 1.5 * float(gauge.bars()) / 3.0)
