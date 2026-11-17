class_name FrostField
extends Node3D
## Seris's Frost Binding (story 030): an ice field on the ground for `duration` seconds. Each enemy
## whose hurt rect touches it is hit once with `packet` (its Frost build-up), so standing in the
## field chills and then freezes. Pure placement and timing; the look is a pale disc on the floor.
##
##     var f := FrostField.spawn(parent, world, packet, Rect2(x, y, 4.0, 1.4), 3.0)

## Called with (target, packet) after each hit.
signal hit_landed(target: Node3D, packet: DamagePacket)

var world: CombatWorld
var packet: DamagePacket
var rect: Rect2
var duration: float = 3.0
var target_team: int = CombatWorld.TEAM_ENEMY

var _age: float = 0.0
var _hit_ids: Dictionary[int, bool] = {}
var _scratch: Array[Node3D] = []


## Build, add under `parent` and return it.
static func spawn(parent: Node, combat_world: CombatWorld, p: DamagePacket, area: Rect2,
		seconds: float) -> FrostField:
	var f := FrostField.new()
	f.world = combat_world
	f.packet = p
	f.rect = area
	f.duration = seconds
	parent.add_child(f)
	f.global_position = Vector3(area.get_center().x, area.position.y + 0.42, 0.0)
	f._build_look()
	return f


func _physics_process(delta: float) -> void:
	_age += delta
	_scratch.clear()
	world.query_rect(rect, target_team, _scratch)
	for t in _scratch:
		var id := t.get_instance_id()
		if _hit_ids.has(id):
			continue
		_hit_ids[id] = true
		var p := packet.duplicate_packet()
		p.source_x = rect.get_center().x
		p.result = t.call("receive_hit", p)
		hit_landed.emit(t, p)
	var fade := clampf((duration - _age) / 0.5, 0.0, 1.0)
	scale = Vector3(1.0, maxf(fade, 0.01), 1.0)
	if _age >= duration:
		queue_free()


## A sheet of frost on the floor and a row of ice crystals of uneven height, leaning outward.
## Fixed offsets (no randomness) so every cast looks the same and screenshots compare.
const SHARDS := [[-0.46, 0.55, -12.0, 0.1], [-0.33, 0.9, 6.0, -0.2], [-0.2, 0.45, -4.0, 0.25],
	[-0.08, 1.1, 3.0, 0.0], [0.05, 0.6, -8.0, -0.25], [0.17, 0.95, 10.0, 0.15], [0.3, 0.5, -6.0, -0.1],
	[0.42, 0.75, 14.0, 0.2]]


func _build_look() -> void:
	var sheet := MeshInstance3D.new()
	var plane := BoxMesh.new()
	plane.size = Vector3(rect.size.x, 0.03, 1.2)
	sheet.mesh = plane
	var ice := ArenaMaterials.flat(Color(0.72, 0.9, 1.0, 0.55), 0.9, false, true)
	sheet.material_override = ice
	add_child(sheet)
	var crystal := ArenaMaterials.flat(SerisKit.FROST_COLOR, 1.8)
	for s: Array in SHARDS:
		var mi := MeshInstance3D.new()
		var prism := PrismMesh.new()
		var h := float(s[1]) * rect.size.y * 0.75
		prism.size = Vector3(0.22, h, 0.22)
		mi.mesh = prism
		mi.material_override = crystal
		mi.position = Vector3(float(s[0]) * rect.size.x, h * 0.5, float(s[3]))
		mi.rotation_degrees = Vector3(0.0, 45.0, float(s[2]))
		add_child(mi)
