class_name GateLook
extends RefCounted
## How each gate looks (story 028, addendum gate table: every gate reads at a glance by shape
## and colour, never by colour alone). `dress` adds the look to a gate's collision body; the gate
## features (story 023) add behaviour and remove the body when it opens.
##
##   lock     an iron portcullis with a line of embers (arena doors)
##   ward     bars of golden light in a gold frame (Caelan's shield ward)
##   veil     a curtain of rising black mist with a violet rim (Nyra's shadow veil)
##   rune     a stone door with a dim rune circle (Seris, Zone 3)
##   masonry  cracked stonework with orange veins (Darius, Zone 4)
##   flood    dark water filling a stair (the way to Zone 3, sealed in M2)
##
##     GateLook.dress(body, "veil", rect)


## Add the visuals for gate `kind` under `body`, whose centre is the centre of `r` (room metres).
static func dress(body: Node3D, kind: String, r: Rect2) -> void:
	var w := r.size.x
	var h := r.size.y
	# The body may sit off the play plane; visuals are placed in play-plane space.
	var holder := Node3D.new()
	holder.name = "Look"
	holder.position.z = -body.position.z
	holder.set_meta("dynamic", true)
	body.add_child(holder)
	match kind:
		"lock":
			_bars(holder, w, h, "iron_dark", 0.07, 0.34)
			for y: float in [-h * 0.5 + 0.25, 0.0, h * 0.5 - 0.2]:
				_box(holder, Vector3(0.0, y, 0.0), Vector3(w + 0.3, 0.12, 0.2), "iron_dark")
			_box(holder, Vector3(0.0, h * 0.5 - 0.05, 0.12), Vector3(w + 0.1, 0.05, 0.03), "ember_glow")
		"ward":
			_bars(holder, w, h, "gold_light", 0.045, 0.3)
			for y: float in [-h * 0.5 + 0.08, h * 0.5 - 0.08]:
				_box(holder, Vector3(0.0, y, 0.0), Vector3(w + 0.5, 0.16, 0.4), "ward_gold")
			_glow(holder, Vector2(w + 1.6, h + 0.6), Color(1.0, 0.8, 0.35, 0.28), -0.2)
		"veil":
			var quad := MeshInstance3D.new()
			var mesh := QuadMesh.new()
			mesh.size = Vector2(w + 1.6, h + 0.2)
			quad.mesh = mesh
			var mat := ShaderMaterial.new()
			mat.shader = load("res://src/vfx/spatial_env_veil.gdshader") as Shader
			mat.set_shader_parameter("clouds", TexBank.get_tex("res://assets/art/textures/mist.png"))
			mat.set_shader_parameter("repeats_v", maxf(h / 4.0, 0.5))
			quad.material_override = mat
			quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			quad.position.z = 0.5
			holder.add_child(quad)
		"rune":
			_box(holder, Vector3(0.0, 0.0, -0.3), Vector3(w, h, 0.8), "door_stone")
			var ring := MeshInstance3D.new()
			var torus := TorusMesh.new()
			var radius := minf(w, h) * 0.42
			torus.inner_radius = radius * 0.86
			torus.outer_radius = radius
			torus.rings = 24
			torus.ring_segments = 6
			ring.mesh = torus
			ring.rotation_degrees.x = 90.0
			ring.position = Vector3(0.0, 0.0, 0.14)
			ring.material_override = ArenaMaterials.get_material("rune_glow")
			ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			holder.add_child(ring)
			# The sigil inside the circle: a triangle of thin bars.
			for i in range(3):
				var a := TAU * float(i) / 3.0 + PI * 0.5
				var b := a + TAU / 3.0
				var p0 := Vector2(cos(a), sin(a)) * radius * 0.8
				var p1 := Vector2(cos(b), sin(b)) * radius * 0.8
				var bar := _box(holder, Vector3((p0.x + p1.x) * 0.5, (p0.y + p1.y) * 0.5, 0.14),
					Vector3(p0.distance_to(p1), 0.05, 0.04), "rune_glow")
				bar.rotation.z = (p1 - p0).angle()
		"masonry":
			_box(holder, Vector3(0.0, 0.0, -0.3), Vector3(w, h, 0.9), "door_stone")
			var rng := RandomNumberGenerator.new()
			rng.seed = hash(r)
			# Orange veins: a few jagged cracks running up the face.
			for c in range(maxi(2, int(w * h / 1.5))):
				var p := Vector2(rng.randf_range(-w * 0.4, w * 0.4), -h * 0.45)
				for k in range(4):
					var q := p + Vector2(rng.randf_range(-0.35, 0.35), rng.randf_range(0.15, h * 0.3))
					q.x = clampf(q.x, -w * 0.48, w * 0.48)
					q.y = minf(q.y, h * 0.48)
					var seg := _box(holder, Vector3((p.x + q.x) * 0.5, (p.y + q.y) * 0.5, 0.17),
						Vector3(p.distance_to(q), 0.045, 0.03), "vein_orange")
					seg.rotation.z = (q - p).angle()
					p = q
		"flood":
			_box(holder, Vector3(0.0, 0.0, -0.4), Vector3(w, h, 1.6), "flood_water")
			_glow(holder, Vector2(w + 1.0, 0.8), Color(0.4, 0.95, 1.0, 0.3), h * 0.5)
		_:
			_box(holder, Vector3.ZERO, Vector3(w, h, 1.0), "slate")


## Evenly spaced vertical bars across the gate.
static func _bars(parent: Node3D, w: float, h: float, material: String, radius: float, spacing: float) -> void:
	var count := maxi(2, int(round(w / spacing)) + 1)
	for i in range(count):
		var x := -w * 0.5 + w * float(i) / float(count - 1)
		var bar := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = radius
		cyl.bottom_radius = radius
		cyl.height = h
		cyl.radial_segments = 6
		cyl.rings = 1
		bar.mesh = cyl
		bar.position = Vector3(x, 0.0, 0.0)
		bar.material_override = ArenaMaterials.get_material(material)
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(bar)


static func _box(parent: Node3D, pos: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = ArenaMaterials.get_material(material)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mesh)
	return mesh


## A soft additive glow behind or above a gate.
static func _glow(parent: Node3D, size: Vector2, color: Color, y: float) -> void:
	var q := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	q.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = SpriteArt.blob()
	mat.albedo_color = color
	q.material_override = mat
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.position = Vector3(0.0, y, 0.3)
	parent.add_child(q)
