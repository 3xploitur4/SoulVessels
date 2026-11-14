class_name FxLayer
extends Node3D
## Pooled hit sparks, damage numbers and ultimate effects (story 007/009). Listens to
## `GameEvents.hit_fx_requested` and `ultimate_fx_requested`; nothing allocates during combat
## after `_ready` (addendum: pooled VFX). Pool sizes are fixed; the oldest effect is reused.
##
##     var fx := FxLayer.new()
##     fx.show_numbers = true
##     arena.add_child(fx)

const SPARKS := 16
const NUMBERS := 12
const RINGS := 3
const SPARK_S := 0.16
const NUMBER_S := 0.7
const RING_S := 0.55

## Floating damage numbers (sandbox / debug).
var show_numbers: bool = true

var _sparks: Array[MeshInstance3D] = []
var _spark_t: Array[float] = []
var _numbers: Array[Label3D] = []
var _number_t: Array[float] = []
var _rings: Array[MeshInstance3D] = []
var _ring_t: Array[float] = []
var _ring_size: Array[float] = []
var _next_spark: int = 0
var _next_number: int = 0
var _next_ring: int = 0
var _spark_mat_hit: Material
var _spark_mat_crit: Material
var _spark_mat_block: Material


func _ready() -> void:
	_spark_mat_hit = ArenaMaterials.flat(Color(1.0, 0.9, 0.7), 4.0, true)
	_spark_mat_crit = ArenaMaterials.flat(Color(1.0, 0.45, 0.2), 6.0, true)
	_spark_mat_block = ArenaMaterials.flat(Color(0.7, 0.75, 0.85), 2.0, true)
	var spark_mesh := SphereMesh.new()
	spark_mesh.radius = 0.18
	spark_mesh.height = 0.36
	spark_mesh.radial_segments = 8
	spark_mesh.rings = 4
	for i in range(SPARKS):
		var mi := MeshInstance3D.new()
		mi.mesh = spark_mesh
		mi.material_override = _spark_mat_hit
		mi.visible = false
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		_sparks.append(mi)
		_spark_t.append(-1.0)
	for i in range(NUMBERS):
		var l := Label3D.new()
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = true
		l.font_size = 64
		l.outline_size = 12
		l.pixel_size = 0.006
		l.visible = false
		add_child(l)
		_numbers.append(l)
		_number_t.append(-1.0)
	for i in range(RINGS):
		var r := VfxShapes.ring(Color(0.45, 0.75, 1.0), 1.0)
		r.visible = false
		r.rotation_degrees.x = 90.0
		add_child(r)
		_rings.append(r)
		_ring_t.append(-1.0)
		_ring_size.append(1.0)
	GameEvents.hit_fx_requested.connect(_on_hit_fx)
	GameEvents.ultimate_fx_requested.connect(_on_ultimate_fx)


func _on_hit_fx(where: Vector3, amount: float, crit: bool, blocked: bool) -> void:
	var s := _sparks[_next_spark]
	_spark_t[_next_spark] = 0.0
	_next_spark = (_next_spark + 1) % SPARKS
	s.global_position = where
	s.material_override = _spark_mat_block if blocked else (_spark_mat_crit if crit else _spark_mat_hit)
	s.visible = true
	if not show_numbers or amount <= 0.0:
		return
	var l := _numbers[_next_number]
	_number_t[_next_number] = 0.0
	_next_number = (_next_number + 1) % NUMBERS
	l.text = str(int(roundf(amount)))
	l.modulate = Color(1.0, 0.55, 0.25) if crit else (Color(0.7, 0.72, 0.78) if blocked else Color.WHITE)
	l.global_position = where + Vector3(0.0, 0.4, 0.3)
	l.visible = true


## A floating text (Essence gained, "Recovered"), from the number pool.
func popup(text: String, where: Vector3, color: Color) -> void:
	var l := _numbers[_next_number]
	_number_t[_next_number] = 0.0
	_next_number = (_next_number + 1) % NUMBERS
	l.text = text
	l.modulate = color
	l.global_position = where + Vector3(0.0, 0.6, 0.3)
	l.visible = true


func _on_ultimate_fx(kind: String, where: Vector3, size: float) -> void:
	match kind:
		"final_stand", "dance_of_shadows":
			var r := _rings[_next_ring]
			_ring_t[_next_ring] = 0.0
			_ring_size[_next_ring] = size
			_next_ring = (_next_ring + 1) % RINGS
			r.global_position = where + Vector3(0.0, 0.9, 0.0)
			r.visible = true
		"slash":
			_on_hit_fx(where + Vector3(0.0, 0.9, 0.4), 0.0, true, false)


func _process(delta: float) -> void:
	for i in range(SPARKS):
		if _spark_t[i] < 0.0:
			continue
		_spark_t[i] += delta
		var k := _spark_t[i] / SPARK_S
		_sparks[i].scale = Vector3.ONE * (0.4 + 1.6 * k)
		if k >= 1.0:
			_spark_t[i] = -1.0
			_sparks[i].visible = false
	for i in range(NUMBERS):
		if _number_t[i] < 0.0:
			continue
		_number_t[i] += delta
		_numbers[i].position.y += delta * 1.2
		_numbers[i].modulate.a = clampf(1.0 - _number_t[i] / NUMBER_S, 0.0, 1.0)
		if _number_t[i] >= NUMBER_S:
			_number_t[i] = -1.0
			_numbers[i].visible = false
	for i in range(RINGS):
		if _ring_t[i] < 0.0:
			continue
		_ring_t[i] += delta
		var k := _ring_t[i] / RING_S
		_rings[i].scale = Vector3.ONE * lerpf(0.3, _ring_size[i], k)
		if k >= 1.0:
			_ring_t[i] = -1.0
			_rings[i].visible = false
