class_name Pickup
extends Node3D
## An item lying in the world (story 019): a bobbing orb in its rarity colour with a soft halo.
## Within the magnet radius it drifts to the player and is collected on touch; a drop from an
## enemy also homes in after a short delay, so loot is never left behind. Placed pickups carry a
## `pickup_id` so the save remembers they were taken.
##
##     var p := Pickup.new()
##     p.item = "lesser_soul_shard"; p.pickup_id = "z1_05:0"; p.player = player
##     p.collected.connect(game._on_pickup)

signal collected(pickup: Pickup)

var item: String = ""
var count: int = 1
## "" for enemy drops; "room:index" for placed pickups.
var pickup_id: String = ""
var player: Node3D
var magnet_radius: float = 1.5
## Seconds before a drop homes in from any distance; negative = never (placed pickups).
var homing_after_s: float = -1.0

var _t: float = 0.0
var _orb: MeshInstance3D
var _halo: MeshInstance3D
var _base_y: float = 0.0
var _done: bool = false
var _vel: Vector3 = Vector3.ZERO


func _ready() -> void:
	var c := ItemDb.color(item)
	var big := pickup_id != ""
	_orb = _sphere(0.2 if big else 0.13, ArenaMaterials.flat(c, 3.5, true))
	_halo = _sphere(0.45 if big else 0.28, ArenaMaterials.flat(Color(c.r, c.g, c.b, 0.22), 1.2, true, true))
	# Story 053: a painted icon for the kind of item; the orb stays as its glow.
	var art := icon_for(item)
	if PropArt.has(art):
		var icon := PropArt.icon(art, 0.62 if big else 0.42)
		icon.position.y = 0.0
		_orb.add_child(icon)
		_orb.material_override = ArenaMaterials.flat(Color(c.r, c.g, c.b, 0.0), 0.0, true, true)
	_base_y = global_position.y
	if pickup_id == "":
		# A drop pops up out of the body first.
		_vel = Vector3(randf_range(-2.0, 2.0), 5.0, 0.0)


## The painted icon for item `id`: a scroll for parchments and truths, a keepsake for relics,
## a crystal for soul shards, a basalt core for every other material.
static func icon_for(id: String) -> String:
	var d := ItemDb.item(id)
	if str(d.get("kind", "")) == "lore":
		return "item_relic" if str(d.get("lore_kind", "")) == "relic" else "item_parchment"
	if id.contains("shard") or id.contains("matrix"):
		return "item_shard"
	return "item_core"


func _sphere(radius: float, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 12
	s.rings = 6
	m.mesh = s
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position.y = 0.6
	add_child(m)
	return m


func _process(delta: float) -> void:
	_t += delta
	_orb.position.y = 0.6 + 0.12 * sin(_t * 3.0)
	_halo.scale = Vector3.ONE * (1.0 + 0.1 * sin(_t * 4.0))
	if _done or player == null or not is_instance_valid(player):
		return
	var target := player.global_position + Vector3(0, 0.9, 0)
	var me := global_position + Vector3(0, 0.6, 0)
	var d := target - me
	var homing := homing_after_s >= 0.0 and _t >= homing_after_s
	if _vel != Vector3.ZERO and not homing:
		_vel.y -= 18.0 * delta
		global_position += _vel * delta
		if global_position.y <= _base_y:
			global_position.y = _base_y
			_vel = Vector3.ZERO
	if d.length() <= 0.45:
		_done = true
		collected.emit(self)
		queue_free()
	elif homing or d.length() <= magnet_radius:
		global_position += d.normalized() * minf(d.length(), (6.0 + _t * 4.0) * delta)
