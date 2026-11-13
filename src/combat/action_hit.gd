class_name ActionHit
extends RefCounted
## One hit window inside a timed action: active between `start` and `end` seconds of the action,
## a rect in front of the owner (mirrored by facing), and the packet it deals. Each target is hit
## once per window. Used by player actions and enemy attacks alike.
##
##     var h := ActionHit.new(0.14, 0.24, Vector2(1.0, 0.9), Vector2(2.0, 1.4), packet)
##     h.sweep(world, owner_pos, facing, CombatWorld.TEAM_ENEMY, on_hit)

var start: float = 0.0
var end: float = 0.1
## Rect centre offset from the owner's feet, x along facing.
var offset: Vector2 = Vector2(1.0, 0.9)
var size: Vector2 = Vector2(2.0, 1.4)
var packet: DamagePacket

var _hit_ids: Dictionary[int, bool] = {}
var _scratch: Array[Node3D] = []


func _init(t_start: float = 0.0, t_end: float = 0.1, rect_offset: Vector2 = Vector2(1.0, 0.9),
		rect_size: Vector2 = Vector2(2.0, 1.4), p: DamagePacket = null) -> void:
	start = t_start
	end = t_end
	offset = rect_offset
	size = rect_size
	packet = p


func is_active(t: float) -> bool:
	return t >= start and t <= end


## The world rect for an owner at `origin` facing `facing` (+1 right, -1 left).
func world_rect(origin: Vector2, facing: int) -> Rect2:
	var centre := Vector2(origin.x + offset.x * float(facing), origin.y + offset.y)
	return Rect2(centre - size * 0.5, size)


## Hit every not-yet-hit target of `team` in the rect. `on_hit(target, packet_copy)` is called
## after `receive_hit` so the owner can react (gauge, hitstop, combo bonuses).
func sweep(world: CombatWorld, origin: Vector2, facing: int, team: int, on_hit: Callable) -> void:
	if world == null or packet == null:
		return
	_scratch.clear()
	world.query_rect(world_rect(origin, facing), team, _scratch)
	for target in _scratch:
		var id := target.get_instance_id()
		if _hit_ids.has(id):
			continue
		_hit_ids[id] = true
		var p := packet.duplicate_packet()
		p.source_x = origin.x
		p.result = target.call("receive_hit", p)
		if on_hit.is_valid():
			on_hit.call(target, p)


func reset() -> void:
	_hit_ids.clear()


func hit_count() -> int:
	return _hit_ids.size()
