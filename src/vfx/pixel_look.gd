class_name PixelLook
extends CanvasLayer
## Draws the game world as pixel art (story 054, decision D-059; data/art/look.json "pixel").
## Sits above the world and its darkness overlay (layer 3) and below the HUD (layer 5), so menus
## and text stay sharp.
##
##     var p := PixelLook.new()
##     add_child(p)

const PATH := "res://data/art/look.json"

var _rect: ColorRect


## The look settings (camera and pixel), or {} when the file is missing.
static func config() -> Dictionary:
	if not FileAccess.file_exists(PATH):
		return {}
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	return d if d is Dictionary else {}


## Virtual pixels the screen is tall (0 when the pixel look is off).
static func virtual_height() -> float:
	var px: Dictionary = config().get("pixel", {})
	return float(px.get("height", 360.0)) if bool(px.get("enabled", false)) else 0.0


func _ready() -> void:
	layer = 4
	process_mode = Node.PROCESS_MODE_ALWAYS
	var px: Dictionary = config().get("pixel", {})
	_rect = ColorRect.new()
	_rect.name = "Pixels"
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://src/vfx/canvas_post_pixel.gdshader") as Shader
	mat.set_shader_parameter("virtual_height", float(px.get("height", 360.0)))
	mat.set_shader_parameter("levels", float(px.get("levels", 22.0)))
	mat.set_shader_parameter("dither_amount", float(px.get("dither", 0.55)))
	mat.set_shader_parameter("outline", float(px.get("outline", 0.35)))
	_rect.material = mat
	add_child(_rect)
	visible = bool(px.get("enabled", false))


## Turn the pixel look on or off (a setting).
func set_enabled(on: bool) -> void:
	visible = on
