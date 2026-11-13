class_name VfxShapes
extends RefCounted
## Small procedural effect meshes (projectiles, waves, slashes). Placeholder art: each returns a
## fresh Node3D using cached materials, so swapping in final VFX changes only this file.
##
##     var knife := VfxShapes.knife(Color(0.7, 0.55, 1.0))


## A glowing ground wave (King's Judgment).
static func shockwave(color: Color) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.9, 1.2, 0.9)
	prism.left_to_right = 1.0
	mi.mesh = prism
	mi.material_override = ArenaMaterials.flat(color, 3.5)
	mi.position.y = 0.0
	root.add_child(mi)
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
static func bolt(color: Color, radius: float) -> Node3D:
	var root := Node3D.new()
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 10
	s.rings = 5
	mi.mesh = s
	mi.material_override = ArenaMaterials.flat(color, 4.0)
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
