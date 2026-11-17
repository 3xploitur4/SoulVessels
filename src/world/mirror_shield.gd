class_name MirrorShield
extends Interactable
## A rotatable mirror-shield on a pedestal (story 032, addendum puzzle 2 "Reflection"). An Arcane
## Bolt that touches it leaves at the mirrored angle (`WardMath.mirror_reflect`). Interact to turn
## it 45 degrees; with Caelan active, interact picks it up and sets it down instead (he carries it
## in front of him).
##
##     var m := MirrorShield.new()
##     m.angle = 135.0   # a rightward bolt goes up
##     features_root.add_child(m)

## Normal direction in degrees: 0 upright (a bolt comes straight back), 45 / 135 diagonal, 90 flat.
var angle: float = 45.0
var player: Player
var carried: bool = false

const HIT := Vector2(0.9, 0.9)

var _plate: Node3D
var _recent: Dictionary[int, float] = {}


## The setting after one turn: 45 -> 90 -> 135 -> 0 -> 45 (a two-sided mirror has four).
static func next_angle(a: float) -> float:
	return fmod(a + 45.0, 180.0)


func _ready() -> void:
	super._ready()
	radius = 1.4
	_build_look()
	_refresh()


func can_interact(_p: Player) -> bool:
	return true


func interact(_game: Node) -> void:
	if player != null and player.loadout != null and player.loadout.active().id == "caelan":
		carried = not carried
		if not carried:
			global_position = Vector3(player.global_position.x + 0.8 * player.facing,
				player.global_position.y + 0.95, 0.0)
		Sfx.play("pickup")
	else:
		angle = next_angle(angle)
		Sfx.play("block")
	_refresh()


func _physics_process(delta: float) -> void:
	if carried and player != null and is_instance_valid(player):
		global_position = Vector3(player.global_position.x + 0.8 * player.facing,
			player.global_position.y + 0.95, 0.0)
	for k: int in _recent.keys():
		_recent[k] -= delta
		if _recent[k] <= 0.0:
			_recent.erase(k)
	var me := Rect2(Vector2(global_position.x, global_position.y) - HIT * 0.5, HIT)
	for n in get_tree().get_nodes_in_group(SerisKit.BOLT_GROUP):
		var bolt := n as Projectile
		if bolt == null or bolt.is_queued_for_deletion() or _recent.has(bolt.get_instance_id()):
			continue
		var b := Rect2(Vector2(bolt.global_position.x, bolt.global_position.y) - bolt.size * 0.5, bolt.size)
		if not me.intersects(b):
			continue
		bolt.velocity = WardMath.mirror_reflect(bolt.velocity, angle)
		# Leave from the mirror's centre so the new path is exact.
		var out := bolt.velocity.normalized() * 0.5
		bolt.global_position = Vector3(global_position.x + out.x, global_position.y + out.y, 0.0)
		_recent[bolt.get_instance_id()] = 0.25
		Sfx.play("parry")


func _refresh() -> void:
	verb_key = "UI_CARRY" if not carried else "UI_SET_DOWN"
	if player == null or player.loadout == null or player.loadout.active().id != "caelan":
		verb_key = "UI_ROTATE"
	if _plate != null:
		_plate.rotation_degrees = Vector3(0.0, 0.0, angle)


func _build_look() -> void:
	var stand := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.18
	cyl.height = 0.95
	stand.mesh = cyl
	stand.position = Vector3(0.0, -0.95 * 0.5, -0.1)
	stand.material_override = ArenaMaterials.flat(Color(0.55, 0.45, 0.25), 0.2)
	add_child(stand)
	_plate = Node3D.new()
	add_child(_plate)
	# The plate lies across the normal: thin along x (the normal at angle 0), long along y.
	var face := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.1, 1.1, 0.5)
	face.mesh = box
	face.material_override = ArenaMaterials.flat(Color(0.82, 0.88, 0.95), 1.4)
	_plate.add_child(face)
	var rim := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(0.16, 1.22, 0.42)
	rim.mesh = rb
	rim.position = Vector3(0.0, 0.0, -0.06)
	rim.material_override = ArenaMaterials.flat(Color(0.95, 0.78, 0.35), 0.6)
	_plate.add_child(rim)
