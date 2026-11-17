class_name FractureTear
extends Node3D
## Ilyr's Fracture (story 047): a shimmering tear in the air that cuts every enemy inside it each
## `tick_s` for `duration` seconds. The look is a pale, flickering slit with a dark core.

var player: Player
var rect: Rect2
var duration: float = 3.0
var tick_s: float = 0.5
var motion: float = 0.35
var posture: float = 4.0

var _age: float = 0.0
var _next: float = 0.0
var _slit: MeshInstance3D


func _ready() -> void:
	global_position = Vector3(rect.get_center().x, rect.position.y + rect.size.y * 0.5, 0.2)
	_slit = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.35, rect.size.y)
	_slit.mesh = q
	_slit.material_override = ArenaMaterials.flat(Color(0.92, 0.95, 1.0, 0.85), 2.4, true, true)
	add_child(_slit)
	var core := MeshInstance3D.new()
	var cq := QuadMesh.new()
	cq.size = Vector2(0.12, rect.size.y * 0.9)
	core.mesh = cq
	core.position.z = 0.02
	core.material_override = ArenaMaterials.flat(Color(0.02, 0.02, 0.05), 0.0, true)
	add_child(core)


func _physics_process(delta: float) -> void:
	_age += delta
	if _slit != null:
		_slit.scale = Vector3(0.7 + 0.5 * absf(sin(_age * 21.0)), 1.0, 1.0)
	if _age >= _next and player != null and is_instance_valid(player):
		_next += tick_s
		var targets: Array[Node3D] = []
		player.world.query_rect(rect, CombatWorld.TEAM_ENEMY, targets)
		for t in targets:
			var p := player.make_packet(motion, posture)
			p.element = "aether"
			p.element_buildup = 10.0
			p.source_x = rect.get_center().x
			p.tags["ability"] = "fracture"
			p.result = t.call("receive_hit", p)
			player.report_hit(t, p)
	if _age >= duration:
		queue_free()
