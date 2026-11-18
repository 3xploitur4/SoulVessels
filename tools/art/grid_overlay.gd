extends SceneTree
## Draw a pixel grid over sprites so rig outlines can be placed by eye (story 053).
##
##   godot --headless --path . -s tools/art/grid_overlay.gd -- caelan [nyra ...]
##
## Writes builds/art/grid_<id>.png: the sprite on dark grey, a thin line every 50 px and a bright
## line every 100 px (yellow on x, cyan on y), with the 500 px lines in red.


func _init() -> void:
	for id in OS.get_cmdline_user_args():
		var src := Image.load_from_file(ProjectSettings.globalize_path("res://assets/art/sprites/%s.png" % id))
		src.convert(Image.FORMAT_RGBA8)
		var out := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
		out.fill(Color(0.16, 0.16, 0.18))
		out.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i.ZERO)
		for x in range(0, out.get_width(), 50):
			var c := Color(1, 0.2, 0.2) if x % 500 == 0 else (Color(1, 0.9, 0.2, 1) if x % 100 == 0 else Color(1, 0.9, 0.2, 0.35))
			for y in range(out.get_height()):
				out.set_pixel(x, y, out.get_pixel(x, y).lerp(Color(c.r, c.g, c.b), c.a))
		for y in range(0, out.get_height(), 50):
			var c := Color(1, 0.2, 0.2) if y % 500 == 0 else (Color(0.2, 0.9, 1, 1) if y % 100 == 0 else Color(0.2, 0.9, 1, 0.35))
			for x in range(out.get_width()):
				out.set_pixel(x, y, out.get_pixel(x, y).lerp(Color(c.r, c.g, c.b), c.a))
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/art"))
		out.save_png(ProjectSettings.globalize_path("res://builds/art/grid_%s.png" % id))
		print("grid: %s %dx%d" % [id, out.get_width(), out.get_height()])
	quit()
