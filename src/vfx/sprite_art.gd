class_name SpriteArt
extends RefCounted
## The painted sprites cut from the concept sheets (story 027) and how each stands in the world:
## `data/art/sprites.json` gives the world height of the whole image, which way the painting
## faces, where its feet are and where its tell glows. Textures are loaded once, with mipmaps.
##
##     if SpriteArt.has("caelan"):
##         var body := SpriteBody.create("caelan")

const PATH := "res://data/art/sprites.json"

static var _cfg: Dictionary = {}
static var _shader: Shader
static var _blob: Texture2D
static var _discs: Dictionary[float, Texture2D] = {}


static func has(id: String) -> bool:
	_ensure()
	var s: Dictionary = (_cfg.get("sprites", {}) as Dictionary).get(id, {})
	return not s.is_empty() and ResourceLoader.exists(str(s.get("file", "")))


## The sprite's config block (height_m, faces, anchor, tell...).
static func spec(id: String) -> Dictionary:
	_ensure()
	return (_cfg.get("sprites", {}) as Dictionary).get(id, {})


## A top-level number from sprites.json.
static func num(key: String, fallback: float) -> float:
	_ensure()
	return float(_cfg.get(key, fallback))


static func texture(id: String) -> Texture2D:
	# Mipmaps: sprites are drawn at about half size on a 1080p screen and smaller on phones.
	return TexBank.get_tex(str(spec(id).get("file", "")))


static func shader() -> Shader:
	if _shader == null:
		_shader = load("res://src/vfx/spatial_char_sprite_body.gdshader") as Shader
	return _shader


## A soft round blob for ground shadows and glows.
static func blob() -> Texture2D:
	if _blob == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_blob = t
	return _blob


## A round soft disc: solid out to `core` (share of the radius), then fading to clear at the
## edge (story 054: ground shadows read as a shape, not a faint smudge). Cached per core.
static func disc(core: float) -> Texture2D:
	var key := snappedf(core, 0.01)
	if not _discs.has(key):
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(clampf(key, 0.0, 0.95), Color(1, 1, 1, 1))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 64
		t.height = 64
		_discs[key] = t
	return _discs[key]


static func _ensure() -> void:
	if not _cfg.is_empty():
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if parsed is Dictionary:
		_cfg = parsed
	else:
		push_error("SpriteArt: %s does not parse" % PATH)
		_cfg = {"sprites": {}}
