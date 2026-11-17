class_name RootPrison
extends Interactable
## Nyra bound in the mycelium roots (story 025; addendum zone table "Nyra in room 8, freed from
## roots", Narrative 2). The roots are something to hit: they register with the combat world as a
## target, and each blow cuts one of them (`root_prison.hits` in combat.json). Once all are cut
## Nyra slumps free and the prompt reads "Free"; the game scene binds her (`Game.free_vessel`).
## A Vessel already freed (story flag `freed_<vessel>`) is never built again.
##
##     var r := RootPrison.new()
##     r.vessel = "nyra"; r.world = combat_world
##     features_root.add_child(r)

signal roots_cut(left: int)

## Vessel bound here.
var vessel: String = ""
var world: CombatWorld
## Combat-world team: the roots are hit by the player's attacks.
var team: int = CombatWorld.TEAM_ENEMY
var hits_left: int = 3
## "roots" (Nyra, Zone 2), "crystal" (Seris, Zone 3: she sealed herself in ice) or "rubble"
## (Darius, Zone 4: pinned under fallen basalt, story 049).
var look: String = "roots"

var _cfg: Dictionary = {}
var _body: SpriteBody
var _roots: Array[Node3D] = []
var _shake: float = 0.0
var _t: float = 0.0


func _ready() -> void:
	super._ready()
	verb_key = "UI_FREE"
	radius = 1.8
	_cfg = Balance.combat("root_prison")
	hits_left = int(_cfg.get("hits", 3))
	_body = SpriteBody.create(vessel)
	if _body != null:
		add_child(_body)
		_body.set_tint({"roots": Color(0.62, 0.7, 0.66), "rubble": Color(0.78, 0.7, 0.62)}.get(look, Color(0.7, 0.85, 1.0)))
	_build_roots()
	if world != null:
		world.register(self)


func _exit_tree() -> void:
	if world != null:
		world.unregister(self)


func hurt_rect() -> Rect2:
	var size: Array = _cfg.get("hurt_size_m", [1.4, 2.2])
	return Rect2(global_position.x - float(size[0]) * 0.5, global_position.y, float(size[0]), float(size[1]))


func is_alive() -> bool:
	return hits_left > 0


func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	if hits_left <= 0 or p.team == team:
		return DamagePacket.Result.IGNORED
	hits_left -= 1
	_shake = 0.25
	if hits_left < _roots.size():
		_roots[hits_left].visible = false
	GameEvents.hit_fx_requested.emit(global_position + Vector3(0.0, 1.1, 0.4), 0.0, false, false)
	Sfx.play("hit")
	if hits_left == 0 and world != null:
		world.unregister(self)
	roots_cut.emit(hits_left)
	p.result = DamagePacket.Result.KILLED if hits_left == 0 else DamagePacket.Result.HIT
	return p.result


## Free only once every root is cut.
func can_interact(_player: Player) -> bool:
	return hits_left <= 0


func interact(game: Node) -> void:
	game.call("free_vessel", vessel, self)


func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(_shake - delta, 0.0)
	position.x += sin(_t * 90.0) * _shake * 0.02
	if _body == null:
		return
	if _body is RigBody:
		(_body as RigBody).play("rooted" if hits_left > 0 else "kneel" if (_body as RigBody).clips.has("kneel") else "hurt")
	_body.glow = 0.1 + (0.1 * sin(_t * 2.0) if hits_left > 0 else 0.25)
	_body.tick(delta)


## Thick glowing roots wound around the body (or shards of crystal); one goes per blow.
func _build_roots() -> void:
	if look == "crystal":
		_build_crystal()
		return
	if look == "rubble":
		_build_rubble()
		return
	var mat := ArenaMaterials.get_material("z2_ledge")
	for i in range(hits_left):
		var m := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.09
		c.bottom_radius = 0.14
		c.height = 2.4
		c.radial_segments = 8
		m.mesh = c
		m.material_override = mat
		m.position = Vector3(-0.45 + 0.45 * float(i), 1.0, 0.25)
		m.rotation_degrees.z = -35.0 + 35.0 * float(i)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		_roots.append(m)


## Story 038: tall shards of pale crystal standing around her; one breaks per blow.
func _build_crystal() -> void:
	var mat := ArenaMaterials.flat(Color(0.72, 0.9, 1.0, 0.55), 1.2, false, true)
	var shards := [[-0.55, 2.4, -8.0], [0.0, 2.9, 2.0], [0.55, 2.3, 9.0]]
	for i in range(hits_left):
		var s: Array = shards[i % shards.size()]
		var m := MeshInstance3D.new()
		var p := PrismMesh.new()
		p.size = Vector3(0.7, float(s[1]), 0.7)
		m.mesh = p
		m.material_override = mat
		m.position = Vector3(float(s[0]), float(s[1]) * 0.5, 0.3)
		m.rotation_degrees = Vector3(0.0, 45.0, float(s[2]))
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)
		_roots.append(m)


## Story 049: slabs of cracked basalt fallen across him (the zone's own textured stone), split by
## thin glowing seams; one slab breaks per blow.
func _build_rubble() -> void:
	var mat := ArenaMaterials.get_material("z4_ledge")
	var seam := ArenaMaterials.get_material("masonry")
	var slabs := [[-0.55, 0.45, 22.0, 1.6, 0.5], [0.5, 0.75, -16.0, 1.8, 0.45], [0.0, 1.25, 7.0, 2.1, 0.55]]
	for i in range(hits_left):
		var s: Array = slabs[i % slabs.size()]
		var slab := Node3D.new()
		slab.position = Vector3(float(s[0]), float(s[1]), 0.35)
		slab.rotation_degrees = Vector3(0.0, 10.0 * float(i) - 8.0, float(s[2]))
		# Two halves of one broken slab with an ember seam between them.
		var half_w := float(s[3]) * 0.5 - 0.04
		for side in [-1.0, 1.0]:
			var m := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(half_w, float(s[4]), 0.8)
			m.mesh = b
			m.material_override = mat
			m.position = Vector3(side * (half_w * 0.5 + 0.04), side * 0.03, 0.0)
			m.rotation_degrees.z = side * 2.5
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			slab.add_child(m)
		var crack := MeshInstance3D.new()
		var cb := BoxMesh.new()
		cb.size = Vector3(0.07, float(s[4]) * 0.9, 0.82)
		crack.mesh = cb
		crack.material_override = seam
		crack.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		slab.add_child(crack)
		add_child(slab)
		_roots.append(slab)
