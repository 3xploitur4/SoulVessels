class_name SoulEcho
extends Node3D
## The Soul Echo (story 018): the Essence you carried, left where you fell, as a pale flickering
## figure of light. Touching it (no button) returns the Essence. The game scene builds it in the
## echo's room and handles the recovery through `recovered`.
##
##     var e := SoulEcho.new()
##     e.essence = 120
##     e.recovered.connect(game._on_echo_recovered)

signal recovered

## Pickup distance in metres.
const REACH := 1.1

var essence: int = 0
var player: Node3D

var _core: MeshInstance3D
var _shell: MeshInstance3D
var _label: Label3D
var _t: float = 0.0
var _done: bool = false


func _ready() -> void:
	_core = _orb(0.28, ArenaMaterials.flat(Color(0.6, 0.95, 1.0), 4.5, true))
	_shell = _orb(0.75, ArenaMaterials.flat(Color(0.4, 0.8, 1.0, 0.18), 1.5, true, true))
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.text = str(essence)
	_label.font_size = 48
	_label.outline_size = 10
	_label.pixel_size = 0.006
	_label.modulate = Color(0.75, 0.95, 1.0)
	_label.position = Vector3(0, 1.9, 0.3)
	add_child(_label)


func _orb(radius: float, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 16
	s.rings = 8
	m.mesh = s
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = Vector3(0, 1.0, 0)
	add_child(m)
	return m


func _process(delta: float) -> void:
	_t += delta
	var flicker := 0.85 + 0.15 * sin(_t * 9.0) * sin(_t * 2.3)
	_core.scale = Vector3.ONE * flicker
	_shell.scale = Vector3(1.0, 1.0 + 0.1 * sin(_t * 2.0), 1.0)
	_core.position.y = 1.0 + 0.08 * sin(_t * 1.7)
	if _done or player == null or not is_instance_valid(player):
		return
	if not bool(player.call("is_alive")):
		return
	var d := player.global_position + Vector3(0, 0.9, 0) - (global_position + Vector3(0, 1.0, 0))
	if absf(d.x) <= REACH and absf(d.y) <= REACH + 0.6:
		_done = true
		recovered.emit()
		queue_free()
