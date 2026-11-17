class_name SlideZone
extends Node3D
## A sliding floor (story 043; addendum Zone 4 "sliding floors", the Guardian's elevator tilting
## 15 degrees). Inside its rect the floor counts as tilted by `angle` degrees (positive: downhill
## to the right): standing still you slide downhill, and running uphill is slower. The angle can
## change over time (`tilt_to`). Looks like a polished, wet strip with streaks running downhill.
##
##     var z := SlideZone.new()
##     z.setup(Vector2(4, 20), Vector2(2, 5), 12.0)
##     features_root.add_child(z)

const GROUP := &"slide_zone"

var x_range: Vector2 = Vector2.ZERO
var y_range: Vector2 = Vector2.ZERO
var angle: float = 0.0
## Hide the strip (the Guardian's arena shows its tilt another way).
var show_strip: bool = true

var _target: float = 0.0
var _rate: float = 0.0
var _strip: MeshInstance3D
var _t: float = 0.0


## Downhill acceleration on a floor tilted `angle_deg`, for gravity `g` and a friction `factor`.
static func slide_accel(angle_deg: float, g: float, factor: float) -> float:
	return g * sin(deg_to_rad(angle_deg)) * factor


## Run speed facing `dir` (+1 right) on a floor tilted `angle_deg`: full speed downhill, slower
## uphill (never below 30 %).
static func run_speed(speed: float, angle_deg: float, dir: int, penalty: float) -> float:
	var uphill := signf(float(dir)) != signf(angle_deg) and angle_deg != 0.0
	if not uphill:
		return speed
	return speed * maxf(1.0 - absf(sin(deg_to_rad(angle_deg))) * penalty, 0.3)


func setup(xs: Vector2, ys: Vector2, tilt: float) -> void:
	x_range = xs
	y_range = ys
	angle = tilt
	_target = tilt


## Tilt to `target` degrees over `seconds`.
func tilt_to(target: float, seconds: float) -> void:
	_target = target
	_rate = absf(target - angle) / maxf(seconds, 0.001)


func step(delta: float) -> void:
	angle = move_toward(angle, _target, _rate * delta)


## Is `pos` (room x, y of the feet) on this floor?
func covers(pos: Vector2) -> bool:
	return pos.x >= x_range.x and pos.x <= x_range.y and pos.y >= y_range.x - 0.1 and pos.y <= y_range.y


func _ready() -> void:
	add_to_group(GROUP)
	if show_strip:
		_strip = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(x_range.y - x_range.x, 0.04, 1.8)
		_strip.mesh = box
		_strip.material_override = ArenaMaterials.flat(Color(0.55, 0.62, 0.72, 0.55), 0.5, false, true)
		add_child(_strip)
		_strip.global_position = Vector3((x_range.x + x_range.y) * 0.5, y_range.x + 0.09, 0.2)
		for i in range(int((x_range.y - x_range.x) / 2.0)):
			var streak := MeshInstance3D.new()
			var q := BoxMesh.new()
			q.size = Vector3(1.1, 0.03, 0.08)
			streak.mesh = q
			streak.material_override = ArenaMaterials.flat(Color(0.85, 0.95, 1.0), 2.2)
			_strip.add_child(streak)
			streak.position = Vector3(-(x_range.y - x_range.x) * 0.5 + 1.0 + 2.0 * i, 0.03, -0.6 + 0.4 * (i % 4))


func _physics_process(delta: float) -> void:
	step(delta)
	_t += delta
	if _strip != null:
		var dir := signf(angle)
		for i in range(_strip.get_child_count()):
			var s := _strip.get_child(i) as Node3D
			var span := x_range.y - x_range.x
			s.position.x = fposmod(-span * 0.5 + 1.0 + 2.0 * i + _t * 2.5 * dir + span * 0.5, span) - span * 0.5
