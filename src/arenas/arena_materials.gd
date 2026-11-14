class_name ArenaMaterials
extends RefCounted
## Every placeholder material in one place, so final art swaps by changing this file only
## (story 005). Materials are built once and cached for the whole run: a material made in code
## frees its shader pipelines when its last user goes, and recompiles on the next use
## (cheat sheet section 6.6), so the cache also prevents hitches.
##
##     mesh_instance.material_override = ArenaMaterials.get_material("marble")

## Palette: Whispering Cavern, collapsed marble aqueducts (bible section 5).
const PALETTE := {
	"marble": {"albedo": Color(0.62, 0.62, 0.66), "roughness": 0.55},
	"marble_dark": {"albedo": Color(0.32, 0.33, 0.38), "roughness": 0.7},
	"marble_far": {"albedo": Color(0.2, 0.22, 0.27), "roughness": 0.8},
	"pier_far": {"albedo": Color(0.11, 0.12, 0.16), "roughness": 0.9},
	"slate": {"albedo": Color(0.17, 0.19, 0.23), "roughness": 0.85},
	"slate_floor": {"albedo": Color(0.22, 0.24, 0.27), "roughness": 0.8},
	"cavern_wall": {"albedo": Color(0.08, 0.09, 0.12), "roughness": 1.0},
	"moss": {"albedo": Color(0.12, 0.22, 0.2), "roughness": 0.95},
	"teal_glow": {"albedo": Color(0.1, 0.5, 0.5), "emission": Color(0.25, 0.95, 0.9), "emission_energy": 2.2},
	"rune_cyan": {"albedo": Color(0.1, 0.4, 0.6), "emission": Color(0.35, 0.85, 1.0), "emission_energy": 3.0},
	"torch_warm": {"albedo": Color(0.9, 0.5, 0.2), "emission": Color(1.0, 0.55, 0.2), "emission_energy": 4.0},
	"water_dark": {"albedo": Color(0.03, 0.07, 0.1), "roughness": 0.1, "metallic": 0.3},
	"foreground": {"albedo": Color(0.02, 0.02, 0.03), "roughness": 1.0},
	"plank": {"albedo": Color(0.36, 0.3, 0.24), "roughness": 0.85},
	# Luminous Mycelium Forest (bible section 5: bioluminescent fungal chasms).
	"myc_rock": {"albedo": Color(0.27, 0.25, 0.33), "roughness": 0.85},
	"myc_trim": {"albedo": Color(0.2, 0.42, 0.4), "emission": Color(0.25, 0.85, 0.7), "emission_energy": 0.6},
	"myc_far": {"albedo": Color(0.1, 0.1, 0.15), "roughness": 0.95},
	"myc_wall": {"albedo": Color(0.05, 0.05, 0.09), "roughness": 1.0},
	"stalk": {"albedo": Color(0.46, 0.43, 0.42), "roughness": 0.8},
	"stalk_far": {"albedo": Color(0.2, 0.19, 0.22), "roughness": 0.9},
	"cap_glow": {"albedo": Color(0.25, 0.5, 0.75), "emission": Color(0.35, 0.75, 1.0), "emission_energy": 1.6},
	"cap_violet": {"albedo": Color(0.45, 0.3, 0.65), "emission": Color(0.65, 0.4, 1.0), "emission_energy": 1.4},
	"cap_dim": {"albedo": Color(0.16, 0.22, 0.3), "emission": Color(0.25, 0.45, 0.6), "emission_energy": 0.45},
	"spore_glow": {"albedo": Color(0.6, 0.95, 0.7), "emission": Color(0.55, 1.0, 0.65), "emission_energy": 3.0},
	"mushroom_cap": {"albedo": Color(0.85, 0.35, 0.55), "emission": Color(1.0, 0.45, 0.7), "emission_energy": 1.2},
	# Gates (addendum gate table): each reads at a glance, colour plus shape.
	"ward_gold": {"albedo": Color(0.85, 0.65, 0.2), "metallic": 0.7, "emission": Color(1.0, 0.75, 0.25), "emission_energy": 0.8},
	"crystal": {"albedo": Color(0.4, 0.8, 1.0), "emission": Color(0.45, 0.9, 1.0), "emission_energy": 2.0},
	"rune_dark": {"albedo": Color(0.1, 0.1, 0.16), "emission": Color(0.3, 0.3, 0.55), "emission_energy": 0.6},
	"masonry": {"albedo": Color(0.35, 0.28, 0.24), "emission": Color(1.0, 0.45, 0.1), "emission_energy": 0.35},
	"flood": {"albedo": Color(0.08, 0.2, 0.3), "roughness": 0.1, "metallic": 0.3},
	"lock_bars": {"albedo": Color(0.3, 0.3, 0.34), "metallic": 0.6, "emission": Color(0.8, 0.2, 0.2), "emission_energy": 0.4},
	"altar_stone": {"albedo": Color(0.55, 0.55, 0.6), "roughness": 0.6},
	# --- Art pass (story 028): textured, world-space (triplanar) surfaces after the zone paintings.
	# "tex" is a file in assets/art/textures, "tile_m" the metres one tile covers.
	# Zone 1, The Whispering Cavern: blue-grey rock, ashlar ruins, pale worn slabs, teal pools.
	"z1_rock": {"albedo": Color(0.2, 0.23, 0.3), "roughness": 0.95, "tex": "cave_rock", "tile_m": 7.0},
	"z1_ledge": {"albedo": Color(0.44, 0.47, 0.55), "roughness": 0.85, "tex": "stone_blocks", "tile_m": 3.0},
	"z1_top": {"albedo": Color(0.62, 0.66, 0.74), "roughness": 0.6, "tex": "slab", "tile_m": 3.0},
	"z1_ruin_mid": {"albedo": Color(0.2, 0.23, 0.29), "roughness": 0.9, "tex": "stone_blocks", "tile_m": 3.5},
	"z1_ruin_far": {"albedo": Color(0.1, 0.12, 0.16), "roughness": 0.95, "tex": "stone_blocks", "tile_m": 4.5},
	"z1_pool": {"albedo": Color(0.04, 0.3, 0.32), "emission": Color(0.2, 0.95, 0.88), "emission_energy": 1.5, "roughness": 0.1},
	"silhouette": {"albedo": Color(0.008, 0.01, 0.018), "roughness": 1.0},
	# Zone 2, The Luminous Mycelium Forest: violet-dark rock, glowing moss, teal and violet caps.
	"z2_rock": {"albedo": Color(0.2, 0.17, 0.3), "roughness": 0.95, "tex": "cave_rock", "tile_m": 7.0},
	"z2_ledge": {"albedo": Color(0.4, 0.34, 0.5), "roughness": 0.9, "tex": "myc_bark", "tile_m": 3.0},
	"z2_top": {"albedo": Color(0.26, 0.62, 0.55), "roughness": 0.85, "tex": "moss", "tile_m": 3.0,
		"emission": Color(0.15, 0.7, 0.6), "emission_energy": 0.32, "emission_tex": true},
	"z2_stalk": {"albedo": Color(0.72, 0.86, 0.86), "roughness": 0.8, "tex": "myc_bark", "tile_m": 2.5,
		"emission": Color(0.25, 0.55, 0.55), "emission_energy": 0.25},
	"z2_stalk_far": {"albedo": Color(0.2, 0.3, 0.36), "roughness": 0.9, "tex": "myc_bark", "tile_m": 4.0},
	"z2_cap_teal": {"albedo": Color(0.2, 0.7, 0.62), "roughness": 0.6, "tex": "cap_spots", "tile_m": 3.0,
		"emission": Color(0.18, 0.85, 0.72), "emission_energy": 0.8, "emission_tex": true},
	"z2_cap_violet": {"albedo": Color(0.5, 0.34, 0.74), "roughness": 0.6, "tex": "cap_spots", "tile_m": 3.0,
		"emission": Color(0.55, 0.34, 0.85), "emission_energy": 0.8, "emission_tex": true},
	"z2_cap_far_teal": {"albedo": Color(0.12, 0.42, 0.42), "roughness": 0.8, "tex": "cap_spots", "tile_m": 5.0,
		"emission": Color(0.12, 0.55, 0.5), "emission_energy": 0.7, "emission_tex": true},
	"z2_cap_far_violet": {"albedo": Color(0.3, 0.2, 0.46), "roughness": 0.8, "tex": "cap_spots", "tile_m": 5.0,
		"emission": Color(0.36, 0.22, 0.6), "emission_energy": 0.7, "emission_tex": true},
	"z2_gill": {"albedo": Color(0.08, 0.16, 0.2), "roughness": 1.0},
	"z2_vine": {"albedo": Color(0.06, 0.16, 0.13), "roughness": 1.0},
	"z2_sprout": {"albedo": Color(1.0, 0.5, 0.8), "emission": Color(1.0, 0.45, 0.8), "emission_energy": 2.2},
	"planks": {"albedo": Color(0.78, 0.66, 0.54), "roughness": 0.85, "tex": "planks", "tile_m": 2.0},
	"rope": {"albedo": Color(0.42, 0.34, 0.24), "roughness": 1.0},
	"brazier": {"albedo": Color(0.2, 0.2, 0.24), "roughness": 0.5, "metallic": 0.6},
	# Altars and gates (story 028).
	"altar_ashlar": {"albedo": Color(0.7, 0.72, 0.8), "roughness": 0.7, "tex": "stone_blocks", "tile_m": 1.6},
	"altar_basin": {"albedo": Color(0.5, 0.52, 0.6), "roughness": 0.45, "metallic": 0.3},
	"iron_dark": {"albedo": Color(0.1, 0.1, 0.12), "roughness": 0.45, "metallic": 0.8},
	"ember_glow": {"albedo": Color(0.8, 0.15, 0.1), "emission": Color(1.0, 0.2, 0.12), "emission_energy": 2.2},
	"gold_light": {"albedo": Color(1.0, 0.8, 0.35), "emission": Color(1.0, 0.78, 0.3), "emission_energy": 3.2},
	"door_stone": {"albedo": Color(0.3, 0.32, 0.4), "roughness": 0.85, "tex": "stone_blocks", "tile_m": 2.2},
	"rune_glow": {"albedo": Color(0.3, 0.3, 0.6), "emission": Color(0.42, 0.4, 0.95), "emission_energy": 1.6},
	"vein_orange": {"albedo": Color(1.0, 0.5, 0.15), "emission": Color(1.0, 0.45, 0.1), "emission_energy": 2.6},
	"flood_water": {"albedo": Color(0.05, 0.3, 0.38), "roughness": 0.08, "metallic": 0.3,
		"emission": Color(0.08, 0.5, 0.55), "emission_energy": 0.6},
}

const TEXTURE_DIR := "res://assets/art/textures/"

static var _cache: Dictionary[String, StandardMaterial3D] = {}


## The shared material for `name` from PALETTE (magenta when unknown, so a typo shows).
static func get_material(name: String) -> StandardMaterial3D:
	if _cache.has(name):
		return _cache[name]
	var mat := StandardMaterial3D.new()
	var spec: Dictionary = PALETTE.get(name, {"albedo": Color(1, 0, 1)})
	mat.albedo_color = spec.get("albedo", Color.WHITE)
	mat.roughness = float(spec.get("roughness", 0.8))
	mat.metallic = float(spec.get("metallic", 0.0))
	if spec.has("emission"):
		mat.emission_enabled = true
		mat.emission = spec["emission"]
		mat.emission_energy_multiplier = float(spec.get("emission_energy", 1.0))
	if spec.has("tex"):
		# World-space triplanar: no UV work on code-built meshes, and merged meshes tile seamlessly.
		var tex := TexBank.get_tex("%s%s.png" % [TEXTURE_DIR, spec["tex"]])
		var scale := 1.0 / maxf(float(spec.get("tile_m", 4.0)), 0.1)
		mat.albedo_texture = tex
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3(scale, scale, scale)
		mat.normal_enabled = true
		mat.normal_texture = TexBank.get_tex("%s%s_n.png" % [TEXTURE_DIR, spec["tex"]])
		mat.normal_scale = float(spec.get("normal", 1.0))
		if bool(spec.get("emission_tex", false)):
			mat.emission_texture = tex
			mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	_cache[name] = mat
	return mat


## A character material: the colour lifted for readability on dark scenes and a rim light so
## the silhouette edge catches light (bible: high-contrast mobile combat readability). Cached.
static func character(color: Color, lift: float = 0.18) -> StandardMaterial3D:
	var key := "char_%s_%s" % [color.to_html(), lift]
	if _cache.has(key):
		return _cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color.lightened(lift)
	mat.roughness = 0.6
	mat.rim_enabled = true
	mat.rim = 0.7
	mat.rim_tint = 0.35
	_cache[key] = mat
	return mat


## A one-off coloured material (characters, VFX), cached by colour and flags.
static func flat(color: Color, emission_energy: float = 0.0, unshaded: bool = false,
		transparent: bool = false) -> StandardMaterial3D:
	var key := "flat_%s_%s_%s_%s" % [color.to_html(), emission_energy, unshaded, transparent]
	if _cache.has(key):
		return _cache[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.75
	if emission_energy > 0.0:
		mat.emission_enabled = true
		mat.emission = Color(color.r, color.g, color.b)
		mat.emission_energy_multiplier = emission_energy
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cache[key] = mat
	return mat
