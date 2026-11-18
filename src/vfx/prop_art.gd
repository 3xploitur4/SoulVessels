class_name PropArt
extends RefCounted
## Painted props (story 053): the v2 paintings cut out to `assets/art/props/` and shown as flat
## quads in the room (the Soul Altar, the masonry, rune door and portcullis gates, item icons).
## Lit by the room like the walls, with a little self-light so they still read in dark rooms.
##
##     var q := PropArt.quad("altar", Vector2(2.0, 3.0))
##     add_child(q)

const DIR := "res://assets/art/props/"


## True when the painting `name` exists.
static func has(name: String) -> bool:
	return ResourceLoader.exists(DIR + name + ".png")


## The painting's width / height.
static func aspect(name: String) -> float:
	var t := TexBank.get_tex(DIR + name + ".png")
	return float(t.get_width()) / float(maxi(t.get_height(), 1)) if t != null else 1.0


## A quad of `size` metres (bottom-centred at the node origin) showing painting `name`, repeated
## `repeat` times along x and y, at `brightness` (1 = the painting as painted).
static func quad(name: String, size: Vector2, repeat: Vector2 = Vector2.ONE, brightness: float = 0.8) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	q.center_offset = Vector3(0.0, size.y * 0.5, 0.0)
	m.mesh = q
	var tex := TexBank.get_tex(DIR + name + ".png")
	var mat := StandardMaterial3D.new()
	# Unshaded at a set brightness, like the characters' self-light: the paintings carry their own
	# lighting, and room lights only washed them out.
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = tex
	mat.albedo_color = Color(brightness, brightness, brightness)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.uv1_scale = Vector3(repeat.x, repeat.y, 1.0)
	mat.disable_fog = true
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return m


## A camera-facing icon of painting `name`, `height_m` tall, centred on the node origin.
static func icon(name: String, height_m: float) -> Sprite3D:
	var s := Sprite3D.new()
	var tex := TexBank.get_tex(DIR + name + ".png")
	s.texture = tex
	s.pixel_size = height_m / float(maxi(tex.get_height(), 1)) if tex != null else 0.01
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return s
