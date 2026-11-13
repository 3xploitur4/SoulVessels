class_name TelegraphIcons
extends RefCounted
## The three standard telegraph shapes (addendum "Telegraphs"), drawn into textures at first use:
## a ring (parryable), an X (unblockable) and a diamond (magic). White with a dark rim, tinted by
## the caller, so colour-blind palettes only change the tint while the shape carries the meaning.
## No emoji, no font glyphs.
##
##     sprite.texture = TelegraphIcons.texture("unblockable")

const SIZE := 128

static var _cache: Dictionary[String, ImageTexture] = {}


## Texture for a telegraph kind: "parryable", "unblockable", "magic".
static func texture(kind: String) -> ImageTexture:
	if _cache.has(kind):
		return _cache[kind]
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var c := float(SIZE) * 0.5
	for y in range(SIZE):
		for x in range(SIZE):
			var px := float(x) + 0.5 - c
			var py := float(y) + 0.5 - c
			var d := _shape_distance(kind, px, py)
			# d < 0 inside the stroke. Rim band 0..5 px is dark for contrast on bright scenes.
			var a_fill := clampf(0.5 - d, 0.0, 1.0)
			var a_rim := clampf(0.5 - (d - 5.0), 0.0, 1.0)
			var col := Color(1, 1, 1, a_fill)
			if a_fill < 1.0 and a_rim > 0.0:
				col = Color(0.05, 0.03, 0.03, a_rim * 0.85).blend(Color(1, 1, 1, a_fill))
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	_cache[kind] = tex
	return tex


## Signed distance (pixels) to the stroke of each shape; negative inside.
static func _shape_distance(kind: String, x: float, y: float) -> float:
	match kind:
		"parryable":
			var r := sqrt(x * x + y * y)
			return absf(r - 44.0) - 9.0
		"unblockable":
			var d1 := absf(x - y) / sqrt(2.0)
			var d2 := absf(x + y) / sqrt(2.0)
			var along := maxf(absf(x), absf(y))
			var bar := minf(d1, d2) - 9.0
			return maxf(bar, along - 46.0)
		"magic":
			var dd := (absf(x) + absf(y)) / sqrt(2.0)
			var outer := absf(dd - 33.0) - 8.0
			var inner := dd - 9.0
			return minf(outer, inner)
	return 999.0
