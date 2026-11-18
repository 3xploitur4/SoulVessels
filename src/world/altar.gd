class_name Altar
extends Interactable
## A Soul Altar (story 017, addendum "Soul Altars"; look from story 028): three worn stone steps,
## a pillar and a wide basin holding a soul flame. Cold, the basin shows only a grey ember; lit,
## a blue-white flame with a gold halo and rising sparks. Using it rests the player (full heal,
## flasks, ordinary enemies return, save) and opens the altar menu; the game scene does that in
## `rest_at_altar`.
##
##     var a := Altar.new()
##     a.altar_id = "altar_z1_a"; a.name_key = "ALTAR_Z1_A"; a.lit = state.lit_altars.has(a.altar_id)
##     features_root.add_child(a)

## Depth of the altar behind the play plane.
const Z := -0.9

var altar_id: String = ""
var name_key: String = ""
var lit: bool = false

var _core: MeshInstance3D
var _mid: MeshInstance3D
var _halo: MeshInstance3D
var _sparks: CPUParticles3D
## The painted altar (story 053), dimmed while cold.
var _painting: MeshInstance3D
## Flame height: the painting's basin, or the built basin's.
var _flame_y: float = 2.1
var _t: float = 0.0


func _ready() -> void:
	super._ready()
	radius = 1.8
	_update_verb()
	_build()


func set_lit(on: bool) -> void:
	lit = on
	_update_verb()
	_apply_look()


func interact(game: Node) -> void:
	game.call("rest_at_altar", self)


func _update_verb() -> void:
	verb_key = "UI_REST" if lit else "UI_KINDLE"


func _build() -> void:
	if PropArt.has("altar"):
		# Story 053: the painted altar, 3 m tall; its basin sits at about two thirds of the height.
		var h := 3.0
		_painting = PropArt.quad("altar", Vector2(h * PropArt.aspect("altar"), h))
		_painting.position = Vector3(0.0, 0.0, Z)
		add_child(_painting)
		_flame_y = 2.35
	else:
		# Three steps, each narrower than the one below.
		for i in range(3):
			var w := 2.6 - 0.55 * float(i)
			_box(Vector3(0.0, 0.11 + 0.22 * float(i), Z), Vector3(w, 0.22, 1.5 - 0.25 * float(i)), "altar_ashlar")
		_cyl(Vector3(0.0, 1.05, Z), 0.24, 0.3, 0.8, "altar_ashlar")
		_cyl(Vector3(0.0, 1.5, Z), 0.34, 0.24, 0.12, "altar_basin")
		_cyl(Vector3(0.0, 1.66, Z), 0.78, 0.34, 0.24, "altar_basin")
		for x: float in [-0.62, 0.62]:
			_cyl(Vector3(x, 0.78, Z + 0.35), 0.06, 0.07, 0.24, "altar_basin")
	_halo = _blob(Vector2(2.6, 2.6), Vector3(0.0, _flame_y + 0.05, Z - 0.1))
	_mid = _blob(Vector2(0.9, 1.5), Vector3(0.0, _flame_y + 0.1, Z + 0.02))
	_core = _blob(Vector2(0.42, 0.95), Vector3(0.0, _flame_y, Z + 0.04))
	_sparks = CPUParticles3D.new()
	_sparks.amount = 12
	_sparks.lifetime = 1.8
	_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_sparks.emission_sphere_radius = 0.25
	_sparks.direction = Vector3(0.0, 1.0, 0.0)
	_sparks.spread = 18.0
	_sparks.gravity = Vector3(0.0, 0.4, 0.0)
	_sparks.initial_velocity_min = 0.5
	_sparks.initial_velocity_max = 1.1
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SpriteArt.blob()
	mat.albedo_color = Color(0.7, 0.95, 1.0, 0.9)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = mat
	_sparks.mesh = q
	_sparks.position = Vector3(0.0, _flame_y - 0.2, Z)
	_sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sparks)
	_apply_look()


func _apply_look() -> void:
	if _core == null:
		return
	_color(_core, Color(0.92, 1.0, 1.0, 0.95) if lit else Color(0.45, 0.5, 0.6, 0.35))
	_color(_mid, Color(0.35, 0.8, 1.0, 0.6) if lit else Color(0.3, 0.35, 0.5, 0.0))
	_color(_halo, Color(1.0, 0.8, 0.4, 0.3) if lit else Color(0.4, 0.45, 0.6, 0.06))
	_sparks.emitting = lit
	if _painting != null:
		# Cold, the painting is dim and grey; kindled, it shows its own colours.
		var mat := _painting.material_override as StandardMaterial3D
		mat.albedo_color = Color(0.85, 0.85, 0.85) if lit else Color(0.36, 0.38, 0.44)
	if not lit:
		_core.scale = Vector3(0.6, 0.35, 1.0)
		_core.position.y = _flame_y - 0.25


func _process(delta: float) -> void:
	_t += delta
	if _core == null or not lit:
		return
	var f := 1.0 + 0.1 * sin(_t * 9.0) * sin(_t * 3.1)
	_core.scale = Vector3(1.0 + 0.06 * sin(_t * 13.0), f, 1.0)
	_core.position.y = _flame_y + 0.03 * sin(_t * 7.0)
	_mid.scale = Vector3(1.0, 1.0 + 0.14 * sin(_t * 5.0 + 1.0), 1.0)
	_halo.scale = Vector3.ONE * (1.0 + 0.05 * sin(_t * 2.2))


func _box(pos: Vector3, size: Vector3, material: String) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.position = pos
	m.material_override = ArenaMaterials.get_material(material)
	add_child(m)


func _cyl(pos: Vector3, top: float, bottom: float, height: float, material: String) -> void:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = height
	c.radial_segments = 12
	c.rings = 1
	m.mesh = c
	m.position = pos
	m.material_override = ArenaMaterials.get_material(material)
	add_child(m)


## A soft additive glow quad (the flame is three of these).
func _blob(size: Vector2, pos: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	m.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SpriteArt.blob()
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = pos
	add_child(m)
	return m


func _color(m: MeshInstance3D, c: Color) -> void:
	(m.material_override as StandardMaterial3D).albedo_color = c
