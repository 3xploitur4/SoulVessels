class_name TexBank
extends RefCounted
## Loads art textures once and gives them mipmaps (stories 027/028). Godot imports a PNG without
## mipmaps until the editor sees it used in 3D; the game and the exported APK load textures at
## run time, so the mip chain is built here. Without it, far surfaces shimmer and sprites alias.
##
##     material.albedo_texture = TexBank.get_tex("res://assets/art/textures/stone_blocks.png")

static var _cache: Dictionary[String, Texture2D] = {}


## The texture at `path` with mipmaps, or null (with an error) when it does not exist.
static func get_tex(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		push_error("TexBank: missing texture %s" % path)
		return null
	var src := load(path) as Texture2D
	var img := src.get_image()
	if img.is_compressed():
		img.decompress()
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[path] = tex
	return tex
