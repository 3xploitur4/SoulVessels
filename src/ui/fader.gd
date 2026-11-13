class_name Fader
extends CanvasLayer
## Full-screen fade to black for room transitions, death and menus (story 015).
##
##     await fader.fade_to(1.0, 0.2)   # black
##     await fader.fade_to(0.0, 0.25)  # clear

var _rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_rect)


## Current opacity (0 clear, 1 black).
func alpha() -> float:
	return _rect.color.a


## Fade to `target` opacity over `seconds` (real time). Awaitable.
func fade_to(target: float, seconds: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if seconds <= 0.0:
		_rect.color.a = target
		return
	_tween = create_tween()
	_tween.set_ignore_time_scale(true)
	_tween.tween_property(_rect, "color:a", target, seconds)
	await _tween.finished
