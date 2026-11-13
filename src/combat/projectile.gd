class_name Projectile
extends Node3D
## A straight-moving hit in the X/Y plane: Phantom Blades, King's Judgment's ground wave, a
## reflected Watcher beam. Moves `velocity` per second, hits each target of `target_team` once
## (or `pierce` false: stops at the first), dies after `lifetime` or `max_distance`.
##
##     var p := Projectile.spawn(parent, world, packet, Vector2(x, y), Vector2(22, 0), Vector2(0.6, 0.3))
##     p.target_team = CombatWorld.TEAM_ENEMY

## Called with (target, packet) after each hit.
signal hit_landed(target: Node3D, packet: DamagePacket)

var world: CombatWorld
var packet: DamagePacket
var velocity: Vector2 = Vector2.ZERO
var size: Vector2 = Vector2(0.6, 0.4)
var target_team: int = CombatWorld.TEAM_ENEMY
var pierce: bool = true
var lifetime: float = 1.0
var max_distance: float = INF
var travelled: float = 0.0

var _hit_ids: Dictionary[int, bool] = {}
var _scratch: Array[Node3D] = []
var _age: float = 0.0


## Build, add under `parent`, place at `origin` (x, y) and return it. `visual` is optional.
static func spawn(parent: Node, combat_world: CombatWorld, p: DamagePacket, origin: Vector2,
		vel: Vector2, hit_size: Vector2, visual: Node3D = null) -> Projectile:
	var proj := Projectile.new()
	proj.world = combat_world
	proj.packet = p
	proj.velocity = vel
	proj.size = hit_size
	if visual != null:
		proj.add_child(visual)
	parent.add_child(proj)
	proj.global_position = Vector3(origin.x, origin.y, 0.0)
	return proj


func _physics_process(delta: float) -> void:
	_age += delta
	var step := velocity * delta
	global_position += Vector3(step.x, step.y, 0.0)
	travelled += step.length()
	if velocity.x != 0.0:
		rotation.y = 0.0 if velocity.x > 0.0 else PI
	_scratch.clear()
	var centre := Vector2(global_position.x, global_position.y)
	world.query_rect(Rect2(centre - size * 0.5, size), target_team, _scratch)
	for target in _scratch:
		var id := target.get_instance_id()
		if _hit_ids.has(id):
			continue
		_hit_ids[id] = true
		var p := packet.duplicate_packet()
		p.source_x = centre.x - signf(velocity.x) * 0.5
		p.result = target.call("receive_hit", p)
		hit_landed.emit(target, p)
		if not pierce:
			queue_free()
			return
	if _age >= lifetime or travelled >= max_distance:
		queue_free()
