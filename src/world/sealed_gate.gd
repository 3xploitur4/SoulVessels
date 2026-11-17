class_name SealedGate
extends Interactable
## A gate that a later Vessel opens (story 023, addendum gate table): the light-rune door (Seris,
## Zone 3), cracked masonry (Darius, Zone 4), the flooded stair (Zone 3, sealed in M2) and the
## rift scar (Ilyr, Chapter II). Examining it shows a hint line that names no Vessel, so the
## player learns to remember the place. The rift scar also draws its shimmering tear.
##
##     var g := SealedGate.new()
##     g.kind = "rune"
##     features_root.add_child(g)

## "rune", "masonry", "flood" or "rift".
var kind: String = "rune"

var _tear: MeshInstance3D
var _t: float = 0.0


func _ready() -> void:
	super._ready()
	radius = 2.2
	verb_key = "UI_EXAMINE"
	if kind == "rift":
		_build_tear()


func interact(game: Node) -> void:
	var prompts: Prompts = game.get("prompts")
	prompts.subtitle("", tr("SEALED_" + kind.to_upper()), Color(0.8, 0.82, 0.9))


func _build_tear() -> void:
	_tear = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.7, 2.6)
	_tear.mesh = q
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SpriteArt.blob()
	mat.albedo_color = Color(0.85, 0.95, 1.0, 0.85)
	_tear.material_override = mat
	_tear.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_tear.position = Vector3(0.0, 1.3, -0.3)
	_tear.rotation_degrees.z = 12.0
	add_child(_tear)
	var halo := MeshInstance3D.new()
	var hq := QuadMesh.new()
	hq.size = Vector2(2.6, 3.6)
	halo.mesh = hq
	var hm := mat.duplicate() as StandardMaterial3D
	hm.albedo_color = Color(0.45, 0.6, 1.0, 0.25)
	halo.material_override = hm
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = Vector3(0.0, 1.3, -0.35)
	add_child(halo)


func _process(delta: float) -> void:
	_t += delta
	if _tear != null:
		_tear.scale = Vector3(1.0 + 0.25 * sin(_t * 7.0) * sin(_t * 2.3), 1.0 + 0.05 * sin(_t * 3.0), 1.0)
