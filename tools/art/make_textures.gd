extends SceneTree
## Generate the tileable surface textures for the rooms (story 028, decision D-033).
##
##   godot --headless --path . -s tools/art/make_textures.gd
##
## Writes 512 px albedo and normal maps to assets/art/textures/: ashlar stone blocks (the ruined
## aqueducts), cave rock, worn floor slabs, planks, fungal bark, spotted mushroom cap, mossy
## ground. All are grey with a faint hue so a material's colour tints them per zone, and all tile
## seamlessly (noise is cross-faded at the edges; brick and plank grids divide the size evenly).
## Swap any file for hand-painted art of the same name and the rooms pick it up.

const SIZE := 512
const OUT := "res://assets/art/textures"

var _noise := FastNoiseLite.new()
var _cell := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_octaves = 4
	_noise.frequency = 1.0
	_cell.noise_type = FastNoiseLite.TYPE_CELLULAR
	_cell.cellular_return_type = FastNoiseLite.RETURN_DISTANCE
	_cell.fractal_octaves = 2
	_cell.frequency = 1.0
	_rng.seed = 20261114
	_stone_blocks()
	_cave_rock()
	_slab()
	_planks()
	_bark()
	_cap()
	_moss()
	print("textures: done")
	quit()


## Seamless noise in 0..1: the field is cross-faded with copies shifted by one tile.
func _tile(n: FastNoiseLite, x: float, y: float, freq: float) -> float:
	var s := float(SIZE)
	var fx := x / s
	var fy := y / s
	var a := n.get_noise_2d(x * freq, y * freq)
	var b := n.get_noise_2d((x - s) * freq, y * freq)
	var c := n.get_noise_2d(x * freq, (y - s) * freq)
	var d := n.get_noise_2d((x - s) * freq, (y - s) * freq)
	var v := lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)
	return clampf(v * 0.5 + 0.5, 0.0, 1.0)


func _save(name: String, albedo: Image, height: Image, bump: float) -> void:
	albedo.save_png(ProjectSettings.globalize_path("%s/%s.png" % [OUT, name]))
	var normal := height.duplicate() as Image
	normal.bump_map_to_normal_map(bump)
	normal.save_png(ProjectSettings.globalize_path("%s/%s_n.png" % [OUT, name]))
	print("textures: %s" % name)


func _images() -> Array[Image]:
	return [Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8), Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)]


## Ashlar masonry: 8 courses of 4 blocks, every other course shifted half a block.
func _stone_blocks() -> void:
	var im := _images()
	var rows := 8
	var cols := 4
	var bh := SIZE / rows
	var bw := SIZE / cols
	var shade: Array[float] = []
	for i in range(rows * cols):
		shade.append(_rng.randf_range(0.82, 1.08))
	for y in range(SIZE):
		var row := y / bh
		var off := (bw / 2) if row % 2 == 1 else 0
		for x in range(SIZE):
			var bx := (x + off) % SIZE
			var col := bx / bw
			var lx := bx % bw
			var ly := y % bh
			var edge := float(mini(mini(lx, bw - 1 - lx), mini(ly, bh - 1 - ly)))
			var mortar := smoothstep(1.0, 5.0, edge)
			var grain := _tile(_noise, float(x), float(y), 0.03)
			var pit := _tile(_cell, float(x), float(y), 0.05)
			var v := (0.5 + 0.22 * grain - 0.1 * pit) * shade[row * cols + col]
			v = lerpf(0.12, v, mortar)
			im[0].set_pixel(x, y, Color(v * 0.96, v, v * 1.05))
			var hgt := mortar * (0.7 + 0.3 * grain) - 0.15 * pit
			im[1].set_pixel(x, y, Color(hgt, hgt, hgt))
	_save("stone_blocks", im[0], im[1], 6.0)


## Craggy cave rock: ridges from folded noise, cracks from cell edges.
func _cave_rock() -> void:
	var im := _images()
	for y in range(SIZE):
		for x in range(SIZE):
			# Two scales of folded noise make ledges; cell distance makes the dark cracks between them.
			var a := _tile(_noise, float(x), float(y), 0.005)
			var ridge := pow(1.0 - absf(a * 2.0 - 1.0), 1.6)
			var b := _tile(_noise, float(x) + 900.0, float(y) + 300.0, 0.018)
			var ridge2 := 1.0 - absf(b * 2.0 - 1.0)
			var fine := _tile(_noise, float(x) + 40.0, float(y) + 80.0, 0.09)
			var crack := smoothstep(0.04, 0.32, _tile(_cell, float(x), float(y), 0.011))
			var v := (0.16 + 0.42 * ridge + 0.2 * ridge2 + 0.08 * fine) * lerpf(0.35, 1.0, crack)
			im[0].set_pixel(x, y, Color(v * 0.94, v, v * 1.08))
			var hgt := ridge * 0.6 + ridge2 * 0.25 + crack * 0.35
			im[1].set_pixel(x, y, Color(hgt, hgt, hgt))
	_save("cave_rock", im[0], im[1], 9.0)


## Worn floor slabs: 2 x 2 big flags with hairline cracks.
func _slab() -> void:
	var im := _images()
	var t := SIZE / 2
	for y in range(SIZE):
		for x in range(SIZE):
			var lx := x % t
			var ly := y % t
			var edge := float(mini(mini(lx, t - 1 - lx), mini(ly, t - 1 - ly)))
			var joint := smoothstep(1.0, 6.0, edge)
			var grain := _tile(_noise, float(x), float(y), 0.02)
			var crack := smoothstep(0.0, 0.06, absf(_tile(_noise, float(x) + 400.0, float(y), 0.008) - 0.5))
			var v := lerpf(0.2, 0.62 + 0.16 * grain, joint) * lerpf(0.6, 1.0, crack)
			im[0].set_pixel(x, y, Color(v * 0.97, v, v * 1.04))
			var hgt := joint * crack * (0.8 + 0.2 * grain)
			im[1].set_pixel(x, y, Color(hgt, hgt, hgt))
	_save("slab", im[0], im[1], 5.0)


## Planks running along x: 8 boards with grain and nail heads.
func _planks() -> void:
	var im := _images()
	var boards := 8
	var bh := SIZE / boards
	var shade: Array[float] = []
	for i in range(boards):
		shade.append(_rng.randf_range(0.8, 1.1))
	for y in range(SIZE):
		var b := y / bh
		var ly := y % bh
		var gap := smoothstep(0.0, 4.0, float(mini(ly, bh - 1 - ly)))
		for x in range(SIZE):
			var grain := _tile(_noise, float(x) * 0.25, float(y) * 3.0 + float(b) * 77.0, 0.02)
			var v := (0.42 + 0.22 * grain) * shade[b]
			v = lerpf(0.08, v, gap)
			im[0].set_pixel(x, y, Color(v * 1.15, v * 0.92, v * 0.7))
			var hgt := gap * (0.7 + 0.3 * grain)
			im[1].set_pixel(x, y, Color(hgt, hgt, hgt))
	_save("planks", im[0], im[1], 5.0)


## Fungal bark: long vertical fibres.
func _bark() -> void:
	var im := _images()
	for y in range(SIZE):
		for x in range(SIZE):
			var fibre := _tile(_noise, float(x) * 4.0, float(y) * 0.35, 0.02)
			var blot := _tile(_noise, float(x) + 200.0, float(y) + 700.0, 0.01)
			var v := 0.38 + 0.3 * fibre + 0.14 * blot
			im[0].set_pixel(x, y, Color(v, v * 0.98, v * 1.03))
			im[1].set_pixel(x, y, Color(fibre, fibre, fibre))
	_save("myc_bark", im[0], im[1], 4.0)


## Mushroom cap: pale round spots on a darker field (the material colour tints it).
func _cap() -> void:
	var im := _images()
	var spots: Array[Vector3] = []
	for i in range(34):
		spots.append(Vector3(_rng.randf() * SIZE, _rng.randf() * SIZE, _rng.randf_range(10.0, 34.0)))
	for y in range(SIZE):
		for x in range(SIZE):
			var s := 0.0
			for sp in spots:
				var dx := absf(float(x) - sp.x)
				var dy := absf(float(y) - sp.y)
				dx = minf(dx, float(SIZE) - dx)
				dy = minf(dy, float(SIZE) - dy)
				s = maxf(s, 1.0 - smoothstep(sp.z * 0.7, sp.z, sqrt(dx * dx + dy * dy)))
			var grain := _tile(_noise, float(x), float(y), 0.02)
			var v := lerpf(0.5 + 0.12 * grain, 1.0, s)
			im[0].set_pixel(x, y, Color(v, v, v))
			im[1].set_pixel(x, y, Color(s * 0.6 + grain * 0.2, 0, 0))
	_save("cap_spots", im[0], im[1], 3.0)


## Mossy ground: mottled, with a scatter of bright specks (glowing spores).
func _moss() -> void:
	var im := _images()
	for y in range(SIZE):
		for x in range(SIZE):
			var a := _tile(_noise, float(x), float(y), 0.02)
			var b := _tile(_noise, float(x) + 333.0, float(y) + 555.0, 0.08)
			var speck := smoothstep(0.86, 0.9, _tile(_noise, float(x) + 50.0, float(y) + 90.0, 0.2))
			var v := 0.34 + 0.3 * a + 0.12 * b
			v = lerpf(v, 1.0, speck * 0.8)
			im[0].set_pixel(x, y, Color(v * 0.95, v, v * 0.98))
			var hgt := a * 0.6 + b * 0.4
			im[1].set_pixel(x, y, Color(hgt, hgt, hgt))
	_save("moss", im[0], im[1], 5.0)
