class_name FractureTear
extends Node3D
## Ilyr's Fracture (story 047): a shimmering tear in the air that cuts every enemy inside it each
## `tick_s` for `duration` seconds. The look is a flickering jagged crack: pale rims around a black void line.

var player: Player
var rect: Rect2
var duration: float = 3.0
var tick_s: float = 0.5
var motion: float = 0.35
var posture: float = 4.0

var _age: float = 0.0
var _next: float = 0.0
var _slit: Node3D


func _ready() -> void:
	global_position = Vector3(rect.get_center().x, rect.position.y + rect.size.y * 0.5, 0.2)
	# Story 053: a jagged crack in the air instead of a flat slit. A soft pale glow behind, a
	# zigzag of bright rims, and a black void line down the middle of each segment.
	var h := rect.size.y
	_slit = Node3D.new()
	add_child(_slit)
	_slit.add_child(_glow_quad(Vector2(1.4, h * 1.15), Color(0.62, 0.8, 1.0, 0.45), -0.05))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(rect.position.x * 97.0) ^ 0x5eed
	var pts: Array[Vector2] = []
	var n := 7
	for i in range(n + 1):
		var y := -h * 0.5 + h * float(i) / float(n)
		var x := 0.0 if i == 0 or i == n else rng.randf_range(-0.22, 0.22)
		pts.append(Vector2(x, y))
	for i in range(n):
		var a := pts[i]
		var b := pts[i + 1]
		var mid := (a + b) * 0.5
		var ang := (b - a).angle() - PI * 0.5
		var length := a.distance_to(b) + 0.04
		var rim := _glow_quad(Vector2(0.34, length * 1.25), Color(0.9, 0.96, 1.0, 0.9), 0.0)
		rim.position = Vector3(mid.x, mid.y, 0.0)
		rim.rotation.z = ang
		_slit.add_child(rim)
		var core := MeshInstance3D.new()
		var cq := QuadMesh.new()
		cq.size = Vector2(0.06, length)
		core.mesh = cq
		core.material_override = ArenaMaterials.flat(Color(0.01, 0.01, 0.04), 0.0, true)
		core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		core.position = Vector3(mid.x, mid.y, 0.03)
		core.rotation.z = ang
		_slit.add_child(core)


func _glow_quad(size: Vector2, c: Color, z: float) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SpriteArt.blob()
	mat.albedo_color = c
	mat.disable_fog = true
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position.z = z
	return m


func _physics_process(delta: float) -> void:
	_age += delta
	if _slit != null:
		_slit.scale = Vector3(0.85 + 0.3 * absf(sin(_age * 21.0)), 1.0, 1.0)
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
