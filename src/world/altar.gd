class_name Altar
extends Interactable
## A Soul Altar (story 017, addendum "Soul Altars"): a marble pedestal with a soul flame, dim
## until first lit. Using it rests the player (full heal, flasks, ordinary enemies return, save)
## and opens the altar menu; the game scene does all of that in `rest_at_altar`.
##
##     var a := Altar.new()
##     a.altar_id = "altar_z1_a"; a.name_key = "ALTAR_Z1_A"; a.lit = state.lit_altars.has(a.altar_id)
##     features_root.add_child(a)

var altar_id: String = ""
var name_key: String = ""
var lit: bool = false

var _flame: MeshInstance3D
var _halo: MeshInstance3D
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
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.4, 0.35, 1.0)
	base.mesh = bm
	base.position = Vector3(0, 0.175, -0.6)
	base.material_override = ArenaMaterials.get_material("altar_stone")
	add_child(base)
	var pillar := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.38
	cm.bottom_radius = 0.3
	cm.height = 0.9
	cm.radial_segments = 10
	pillar.mesh = cm
	pillar.position = Vector3(0, 0.8, -0.6)
	pillar.material_override = ArenaMaterials.get_material("altar_stone")
	add_child(pillar)
	var bowl := MeshInstance3D.new()
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = 0.62
	bowl_mesh.bottom_radius = 0.3
	bowl_mesh.height = 0.25
	bowl_mesh.radial_segments = 14
	bowl.mesh = bowl_mesh
	bowl.position = Vector3(0, 1.37, -0.6)
	bowl.material_override = ArenaMaterials.get_material("marble")
	add_child(bowl)
	_flame = MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.22
	fm.height = 0.7
	_flame.mesh = fm
	_flame.position = Vector3(0, 1.75, -0.6)
	_flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_flame)
	_halo = MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.5
	hm.height = 1.0
	_halo.mesh = hm
	_halo.position = _flame.position
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_halo)
	_apply_look()


func _apply_look() -> void:
	if _flame == null:
		return
	if lit:
		_flame.material_override = ArenaMaterials.flat(Color(0.7, 0.92, 1.0), 4.0, true)
		_halo.material_override = ArenaMaterials.flat(Color(0.95, 0.8, 0.4, 0.25), 2.0, true, true)
	else:
		_flame.material_override = ArenaMaterials.flat(Color(0.3, 0.32, 0.38), 0.4, true)
		_halo.material_override = ArenaMaterials.flat(Color(0.3, 0.3, 0.4, 0.08), 0.2, true, true)


func _process(delta: float) -> void:
	_t += delta
	if _flame != null:
		var k := 1.0 + (0.12 if lit else 0.04) * sin(_t * 7.0)
		_flame.scale = Vector3(1.0, k, 1.0)
		_halo.scale = Vector3.ONE * (1.0 + 0.06 * sin(_t * 3.0))
