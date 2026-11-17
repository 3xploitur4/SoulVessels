class_name VfxShapes
extends RefCounted
## Small procedural effect meshes (projectiles, waves, slashes). Placeholder art: each returns a
## fresh Node3D using cached materials, so swapping in final VFX changes only this file.
##
##     var knife := VfxShapes.knife(Color(0.7, 0.55, 1.0))


## A glowing ground wave (King's Judgment).
static func shockwave(color: Color) -> Node3D:
	# Story 051: a rolling crest of light and grit instead of a solid wedge. Soft additive blobs
	# rise to a crest at the leading edge (+x) and trail off behind it, with a hot core line.
	var root := Node3D.new()
	var tex := SpriteArt.blob()
	var crest := [[0.25, 0.55, 1.3, 1.0], [-0.1, 0.45, 1.1, 0.8], [-0.45, 0.32, 0.95, 0.6],
		[-0.8, 0.22, 0.8, 0.4], [-1.1, 0.14, 0.65, 0.25]]
	for c: Array in crest:
		var mi := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(float(c[2]), float(c[2]) * 1.15)
		mi.mesh = q
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_texture = tex
		mat.albedo_color = Color(color.r, color.g, color.b, 0.75 * float(c[3]))
		mat.disable_fog = true
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(float(c[0]), float(c[1]), 0.05)
		root.add_child(mi)
	var core := MeshInstance3D.new()
	var cq := QuadMesh.new()
	cq.size = Vector2(0.35, 1.1)
	core.mesh = cq
	var cm := StandardMaterial3D.new()
	cm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	cm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cm.albedo_texture = tex
	cm.albedo_color = color.lerp(Color.WHITE, 0.45)
	cm.disable_fog = true
	core.material_override = cm
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core.position = Vector3(0.3, 0.5, 0.08)
	root.add_child(core)
	return root


## A spectral throwing knife (Phantom Blades).
static func knife(color: Color) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.5, 0.06, 0.06)
	mi.mesh = b
	mi.material_override = ArenaMaterials.flat(color, 3.0)
	root.add_child(mi)
	return root


## An energy bolt (Watcher beam reflection, magic shots).
## `energy` is the glow; high values wash a colour out to white.
static func bolt(color: Color, radius: float, energy: float = 4.0) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 10
	s.rings = 5
	mi.mesh = s
	mi.material_override = ArenaMaterials.flat(color, energy)
	root.add_child(mi)
	return root


## A flat ring on the ground plane (Final Stand radius).
static func ring(color: Color, radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = radius - 0.12
	t.outer_radius = radius
	t.rings = 32
	t.ring_segments = 6
	mi.mesh = t
	mi.material_override = ArenaMaterials.flat(color, 3.0, true, true)
	return mi
