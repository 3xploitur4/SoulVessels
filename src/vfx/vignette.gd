class_name Vignette
extends CanvasLayer
## Darkened corners over the game view, under the HUD (story 028): frames the scene like the
## concept paintings and keeps the eye on the play plane.
##
##     add_child(Vignette.new())

var _rect: ColorRect


func _ready() -> void:
	layer = 1
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://src/vfx/canvas_post_vignette.gdshader") as Shader
	_rect.material = mat
	add_child(_rect)


## 0 (off) to 1 (heavy).
func set_strength(value: float) -> void:
	(_rect.material as ShaderMaterial).set_shader_parameter("strength", clampf(value, 0.0, 1.0))
