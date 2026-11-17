class_name DrownedCourtier
extends EnemyBase
## Drowned Courtier (addendum enemy table, new, Zone 3): it waits under the water surface, swims
## toward the player, rises with a parryable gold-flash slash when close and sinks again after
## `dive_after_s`. Under water it cannot be hit, except by Frost. Frost freezes it in place for
## `freeze_in_water_s` while it is in water (2 s on land, the base Freeze). Out of water it fights
## as a plain swordsman. Numbers in drowned_courtier.json.

## True while it waits below the surface.
var submerged: bool = false

var _water: Water
var _up_t: float = 0.0


func _init() -> void:
	enemy_id = "drowned_courtier"


func _ready() -> void:
	super._ready()
	status.status_started.connect(_on_status)


func _hurt_size() -> Vector2:
	return Vector2(0.9, 1.75)


## Freeze length: longer in water.
static func freeze_seconds(in_pool: bool, base_s: float, water_s: float) -> float:
	return water_s if in_pool else base_s


## Is it standing or swimming in a pool?
func in_water() -> bool:
	return _water_here() != null


## Frozen and in water: held fast (the addendum's "freezes in water").
func frozen_in_place() -> bool:
	return status.has_status("frozen") and in_water()


func _water_here() -> Water:
	if not is_inside_tree():
		return null
	if _water != null and is_instance_valid(_water) and _water.depth_at(Vector2(global_position.x, global_position.y)) > 0.0:
		return _water
	_water = null
	for n in get_tree().get_nodes_in_group(Water.GROUP):
		var w := n as Water
		if w.depth_at(Vector2(global_position.x, global_position.y)) > 0.0 \
				or w.depth_at(Vector2(global_position.x, global_position.y - float(data.get("swim_depth_m", 1.6)))) > 0.0:
			_water = w
			return w
	return null


func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	if submerged and p.element != "frost":
		return DamagePacket.Result.IGNORED
	if p.element == "frost" and in_water():
		# The water around it freezes too: Frost builds up faster (one Frost Binding is enough).
		p.element_buildup *= float(data.get("water_frost_buildup_mult", 2.0))
	var r := super(p)
	if submerged and status.has_status("frozen"):
		_surface()
	return r


func _on_status(s: String) -> void:
	if s == "frozen":
		status.active["frozen"] = freeze_seconds(in_water(), float(status.active.get("frozen", 2.0)),
			float(data.get("freeze_in_water_s", 4.0)))
		Sfx.play("frost")


func _physics_process(delta: float) -> void:
	var w := _water_here()
	if w != null and is_alive() and not status.has_status("frozen"):
		if state == STATE_IDLE or state == STATE_APPROACH:
			_up_t += delta
			if not submerged and _up_t >= float(data.get("dive_after_s", 1.6)):
				_dive()
	elif submerged and w == null:
		_surface()
	super(delta)
	if w != null and is_alive():
		var target_y := w.level - (float(data.get("swim_depth_m", 1.6)) + _hurt_size().y * 0.3 if submerged else 1.1)
		global_position.y = move_toward(global_position.y, maxf(target_y, w.floor_y), 6.0 * delta)
		visual.visible = not submerged or int(state_time * 6.0) % 4 == 0


func _apply_gravity(delta: float) -> void:
	if _water_here() != null:
		velocity.y = 0.0
		return
	super(delta)


func _idle_tick(player: Node3D, delta: float) -> void:
	if _water_here() != null and not submerged and player == null:
		_dive()
	super(player, delta)


func _approach_tick(player: Node3D, delta: float) -> void:
	if submerged and player != null and not _player_hidden(player):
		var dx := player.global_position.x - global_position.x
		if absf(dx) <= float(data.get("surface_range_m", 2.4)):
			_surface()
			_face_toward(dx, 99.0)
			_begin_telegraph((data.get("attacks", []) as Array)[0])
			return
	super(player, delta)


func _choose_attack(distance: float) -> Dictionary:
	if submerged:
		return {}
	return super(distance)


func _surface() -> void:
	if not submerged:
		return
	submerged = false
	_up_t = 0.0
	visual.visible = true
	Sfx.play("splash")
	GameEvents.ultimate_fx_requested.emit("splash", global_position + Vector3(0.0, 1.2, 0.0), 1.0)


func _dive() -> void:
	submerged = true
	_up_t = 0.0
	Sfx.play("splash")


func _end_attack() -> void:
	super()
	_up_t = 0.0
