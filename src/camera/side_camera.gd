class_name SideCamera
extends Camera3D
## Side-on perspective follow camera (story 005, decision D-004). Follows `target`'s
## interpolated transform with look-ahead along its facing and a vertical dead zone, clamps to
## the arena, and shakes from a trauma value scaled by the accessibility setting.
##
##     var cam := SideCamera.new()
##     cam.target = player
##     cam.bounds = Vector2(-21, 21)
##     add_child(cam)

## The node to follow (needs `global_position`; `facing` is read when present).
var target: Node3D
## Arena x limits the view must not cross.
var bounds: Vector2 = Vector2(-21.0, 21.0)
## Room y limits (bottom, top) the view must not cross; ignored while `use_v_bounds` is false
## (the sandbox arena has no ceiling in view).
var v_bounds: Vector2 = Vector2(0.0, 12.0)
var use_v_bounds: bool = false
## Distance from the play plane. 11.5 m shows 7.25 m of height: a Vessel fills about a quarter
## of the screen, so the painted art reads on a phone (decision D-032).
var distance: float = 11.5
## Height of the camera above the target's feet.
var height: float = 2.5
## Metres the view leads in the facing direction.
var look_ahead: float = 2.0
## Target may move this far up or down before the camera follows.
var vertical_dead_zone: float = 1.0
var follow_speed: float = 6.0
## 0..1 accessibility setting, multiplies every shake.
var shake_scale: float = 1.0
## Extra zoom (0 = none, 1 = 40 % closer), for ultimates.
var zoom_in: float = 0.0
## Story 054: rows of the pixel-art grid the screen is divided into (0 = off). The camera moves in
## whole grid cells so the pixel picture does not crawl as it follows.
var pixel_rows: float = 0.0

var _trauma: float = 0.0
var _focus: Vector3 = Vector3.ZERO
var _lead: float = 0.0
var _rng := RandomNumberGenerator.new()
var _time: float = 0.0
## Camera roll in degrees (a tilting arena), eased toward `_roll_target`.
var roll_deg: float = 0.0
var _roll_target: float = 0.0
var _roll_rate: float = 0.0


func _ready() -> void:
	fov = 35.0
	near = 0.3
	far = 120.0
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_rng.seed = 4242
	if target != null:
		_focus = target.global_position
	current = true


## Add shake (0..1 trauma; it decays and is squared for the offset).
## Roll to `degrees` over `seconds`; a new room resets it.
func roll_to(degrees: float, seconds: float) -> void:
	_roll_target = degrees
	_roll_rate = absf(degrees - roll_deg) / maxf(seconds, 0.01)


func add_trauma(amount: float) -> void:
	_trauma = clampf(_trauma + amount, 0.0, 1.0)


## Jump straight to the target (after a teleport or a respawn).
func snap() -> void:
	if target != null:
		_focus = target.global_transform.origin
		_update_transform(0.0)


func _process(delta: float) -> void:
	_time += delta
	if target != null and is_instance_valid(target):
		var t := target.get_global_transform_interpolated().origin
		var facing: float = float(target.get("facing")) if target.get("facing") != null else 1.0
		_lead = lerpf(_lead, look_ahead * facing, minf(delta * 2.5, 1.0))
		_focus.x = lerpf(_focus.x, t.x, minf(delta * follow_speed, 1.0))
		if absf(t.y - _focus.y) > vertical_dead_zone:
			var goal := t.y - signf(t.y - _focus.y) * vertical_dead_zone
			_focus.y = lerpf(_focus.y, goal, minf(delta * follow_speed, 1.0))
	_trauma = maxf(_trauma - delta * 1.6, 0.0)
	_update_transform(delta)


func _update_transform(_delta: float) -> void:
	var half_width := _half_view_width()
	var x := _focus.x + _lead
	if bounds.y - bounds.x > half_width * 2.0:
		x = clampf(x, bounds.x + half_width, bounds.y - half_width)
	elif use_v_bounds:
		x = (bounds.x + bounds.y) * 0.5
	var d := distance * (1.0 - 0.4 * zoom_in)
	var cam_y := _focus.y + height
	if use_v_bounds:
		cam_y = _clamp_height(cam_y)
	else:
		cam_y = maxf(_focus.y, 0.0) + height
	if pixel_rows > 0.0:
		var cell := 2.0 * tan(deg_to_rad(fov) * 0.5) * d / pixel_rows
		x = roundf(x / cell) * cell
		cam_y = roundf(cam_y / cell) * cell
	var pos := Vector3(x, cam_y, d)
	var shake := _trauma * _trauma * shake_scale
	if shake > 0.0:
		pos += Vector3(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0), 0.0) * 0.35 * shake
	global_position = pos
	look_at(Vector3(x, pos.y - 1.1, 0.0), Vector3.UP)
	roll_deg = move_toward(roll_deg, _roll_target, _roll_rate * _delta)
	if roll_deg != 0.0:
		rotate_object_local(Vector3(0.0, 0.0, 1.0), deg_to_rad(roll_deg))


## Keep the visible band inside `v_bounds`. The camera looks 1.1 m below its own height, so the
## view centre on the play plane is `cam_y - 1.1`, with `half_h` above and below it.
func _clamp_height(cam_y: float) -> float:
	var half_h := tan(deg_to_rad(fov) * 0.5) * distance
	var lo := v_bounds.x + half_h + 1.1
	var hi := v_bounds.y - half_h + 1.1
	if hi < lo:
		return (v_bounds.x + v_bounds.y) * 0.5 + 1.1
	return clampf(cam_y, lo, hi)


func _half_view_width() -> float:
	var vp := get_viewport()
	var aspect := 16.0 / 9.0
	if vp != null:
		var size := vp.get_visible_rect().size
		if size.y > 0.0:
			aspect = size.x / size.y
	var half_h := tan(deg_to_rad(fov) * 0.5) * distance
	return half_h * aspect
