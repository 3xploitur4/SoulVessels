class_name MeshMerger
extends RefCounted
## Merge a node's static decorative meshes into one mesh per material and shadow setting
## (stories 005 and 015: draw calls). A mesh casts shadows when it has the meta `cast_shadow`
## true, or, without the meta, when it sits near the play plane (|z| < 3): a column at z = -6
## throws its shadow behind the floor, where nobody sees it, and would cost a shadow draw anyway.
## Meshes with the meta `dynamic` are left alone (gates that open, bodies that move).
##
##     MeshMerger.merge(room_root)


static func merge(root: Node3D) -> int:
	var groups: Dictionary = {}
	var originals: Array[MeshInstance3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.mesh == null or mi.material_override == null or _is_dynamic(mi, root):
			continue
		var casts := absf(mi.global_position.z) < 3.0
		if mi.has_meta("cast_shadow"):
			casts = bool(mi.get_meta("cast_shadow"))
		var key := "%d_%s" % [mi.material_override.get_instance_id(), casts]
		if not groups.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[key] = {"st": st, "mat": mi.material_override, "casts": casts}
		var g: Dictionary = groups[key]
		var xform := root.global_transform.affine_inverse() * mi.global_transform
		(g["st"] as SurfaceTool).append_from(mi.mesh, 0, xform)
		originals.append(mi)
	for key: String in groups.keys():
		var g: Dictionary = groups[key]
		var merged := MeshInstance3D.new()
		merged.name = "Merged_%s" % key
		merged.mesh = (g["st"] as SurfaceTool).commit()
		merged.material_override = g["mat"]
		merged.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if g["casts"] \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(merged)
	for mi in originals:
		mi.get_parent().remove_child(mi)
		mi.queue_free()
	return groups.size()


static func _is_dynamic(mi: Node, root: Node) -> bool:
	var n: Node = mi
	while n != null and n != root:
		if n.has_meta("dynamic"):
			return true
		n = n.get_parent()
	return false
