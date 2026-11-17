class_name RunePuzzle
extends Node3D
## A light-rune door and its runes (story 032, addendum "Light-rune puzzles"). Each rune is a dark
## stone circle; an Arcane Bolt that touches an unlit rune is spent and lights it (a lit rune
## lets bolts through, so runes in one line light nearest first). The rule (`RuneSequence`)
## decides: lit, wrong (all go dark), or solved, which opens the room's door gate for good and
## records it in the save. An optional mural shows the order for a sequence.
##
## Room JSON:
##     "runes": {"id": "z3_05_door", "kind": "sequence", "door": "rune",
##               "runes": [[x, y], ...], "mural": [x, y]}
##     "mirrors": [{"pos": [x, y], "angle": 135}]
## Rune positions are their centres in room metres; a bolt flies 0.95 m above the feet that fired it.

## Emitted on every rune result ("lit", "wrong", "solved"), for tutorials and tests.
signal rune_result(index: int, result: String)

const RUNE_SIZE := 0.9
const STONE := Color(0.3, 0.31, 0.34)
const DARK_GLYPH := Color(0.14, 0.15, 0.19)
const GLOW := Color(0.55, 0.85, 1.0)
const WRONG_FLASH := Color(1.0, 0.35, 0.3)

var manager: RoomManager
var state: GameState
var puzzle_id: String = ""
var door_kind: String = "rune"
var positions: Array[Vector2] = []
var sequence: RuneSequence

var _discs: Array[Node3D] = []
var _flash_left: float = 0.0


## Build the room's rune puzzle and mirrors, if it has any. Registered as a room feature.
static func build_for(m: RoomManager, room: RoomData, game_state: GameState) -> void:
	var def: Variant = room.raw.get("runes")
	if def is Dictionary:
		var d := def as Dictionary
		var p := RunePuzzle.new()
		p.name = "RunePuzzle"
		p.manager = m
		p.state = game_state
		p.puzzle_id = str(d.get("id", room.id + "_runes"))
		p.door_kind = str(d.get("door", "rune"))
		for xy: Array in d.get("runes", []):
			p.positions.append(Vector2(float(xy[0]), float(xy[1])))
		p.sequence = RuneSequence.new(str(d.get("kind", "all")), p.positions.size())
		m.features_root.add_child(p)
		var mural: Variant = d.get("mural")
		if mural is Array and p.sequence.kind == "sequence":
			p._build_mural(Vector2(float(mural[0]), float(mural[1])))
	var i := 0
	for md: Dictionary in room.raw.get("mirrors", []):
		var at: Array = md.get("pos", [0, 0])
		var mirror := MirrorShield.new()
		mirror.name = "Mirror%d" % i
		mirror.player = m.player as Player
		mirror.angle = float(md.get("angle", 45.0))
		m.features_root.add_child(mirror)
		mirror.global_position = Vector3(float(at[0]), float(at[1]), 0.0)
		i += 1


func _ready() -> void:
	for pos in positions:
		var rune := RunePuzzle.make_rune_look(RUNE_SIZE)
		add_child(rune)
		rune.global_position = Vector3(pos.x, pos.y, 0.35)
		_discs.append(rune)
	if state != null and state.opened_gates.has(puzzle_id):
		sequence.restore_solved()
		_open_quietly.call_deferred()
	_paint()


func _physics_process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left = maxf(_flash_left - delta, 0.0)
		if _flash_left == 0.0:
			_paint()
	if sequence.solved:
		return
	for n in get_tree().get_nodes_in_group(SerisKit.BOLT_GROUP):
		var bolt := n as Projectile
		if bolt == null or bolt.is_queued_for_deletion():
			continue
		var b := Rect2(Vector2(bolt.global_position.x, bolt.global_position.y) - bolt.size * 0.5, bolt.size)
		for i in range(positions.size()):
			if sequence.is_lit(i):
				continue
			var r := Rect2(positions[i] - Vector2.ONE * RUNE_SIZE * 0.5, Vector2.ONE * RUNE_SIZE)
			if r.intersects(b):
				bolt.queue_free()
				_on_rune(i)
				break


## Light rune `index` as if a bolt touched it (the bridge and tests use this too).
func light(index: int) -> String:
	return _on_rune(index)


func _on_rune(i: int) -> String:
	var result := sequence.light(i)
	match result:
		RuneSequence.LIT:
			Sfx.play("rune_lit")
		RuneSequence.WRONG:
			Sfx.play("rune_wrong")
			_flash_left = 0.5
		RuneSequence.SOLVED:
			Sfx.play("rune_lit")
			_open()
	_paint()
	rune_result.emit(i, result)
	return result


func _open() -> void:
	_open_quietly()
	if state != null:
		GameState.add_unique(state.opened_gates, puzzle_id)
	Sfx.play("gate_open")
	GameEvents.camera_shake_requested.emit(0.2)


## Remove the door and its "examine" hint (the sealed-gate sign from story 023).
func _open_quietly() -> void:
	if manager == null:
		return
	if manager.builder != null:
		manager.builder.open_gate(door_kind)
	if manager.features_root != null:
		for n in manager.features_root.get_children():
			if n is SealedGate and (n as SealedGate).kind == door_kind:
				n.queue_free()


func _paint() -> void:
	for i in range(_discs.size()):
		var col := GLOW if sequence.is_lit(i) else DARK_GLYPH
		var energy := 2.2 if sequence.is_lit(i) else 0.0
		if _flash_left > 0.0:
			col = WRONG_FLASH
			energy = 2.0
		var mat := ArenaMaterials.flat(col, energy)
		for g in _discs[i].get_children():
			if g.has_meta("glyph"):
				(g as MeshInstance3D).material_override = mat


## A carved rune: a round stone face, a raised outer ring and a three-stroke sigil with a centre
## diamond. Children tagged "glyph" are the parts that light. Faces the camera (+z).
static func make_rune_look(size: float) -> Node3D:
	var root := Node3D.new()
	var stone := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = size * 0.5
	cyl.bottom_radius = size * 0.52
	cyl.height = 0.1
	cyl.radial_segments = 24
	stone.mesh = cyl
	stone.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	stone.material_override = ArenaMaterials.flat(STONE)
	root.add_child(stone)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = size * 0.38
	torus.outer_radius = size * 0.46
	torus.rings = 24
	ring.mesh = torus
	ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	ring.position.z = 0.06
	ring.set_meta("glyph", true)
	root.add_child(ring)
	for k in range(3):
		var stroke := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.045, size * 0.5, 0.03)
		stroke.mesh = box
		var a := deg_to_rad(90.0 + 120.0 * k)
		stroke.position = Vector3(cos(a) * size * 0.14, sin(a) * size * 0.14, 0.07)
		stroke.rotation_degrees = Vector3(0.0, 0.0, 120.0 * k + 90.0)
		stroke.set_meta("glyph", true)
		root.add_child(stroke)
	var gem := MeshInstance3D.new()
	var dbox := BoxMesh.new()
	dbox.size = Vector3(0.09, 0.09, 0.04)
	gem.mesh = dbox
	gem.rotation_degrees = Vector3(0.0, 0.0, 45.0)
	gem.position.z = 0.08
	gem.set_meta("glyph", true)
	root.add_child(gem)
	return root


## A stone tablet showing the runes' layout in miniature, each marked with its place in the order.
func _build_mural(at: Vector2) -> void:
	var frame := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(2.5, 1.9, 0.1)
	frame.mesh = fb
	frame.material_override = ArenaMaterials.flat(Color(0.6, 0.48, 0.24), 0.25)
	add_child(frame)
	frame.global_position = Vector3(at.x, at.y, -0.66)
	var plate := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.3, 1.7, 0.12)
	plate.mesh = box
	plate.material_override = ArenaMaterials.flat(Color(0.33, 0.31, 0.29))
	add_child(plate)
	plate.global_position = Vector3(at.x, at.y, -0.6)
	var lo := positions[0]
	var hi := positions[0]
	for p in positions:
		lo = lo.min(p)
		hi = hi.max(p)
	var span := (hi - lo).max(Vector2.ONE)
	for i in range(positions.size()):
		var k := (positions[i] - lo) / span - Vector2(0.5, 0.5)
		var spot := Vector3(at.x + k.x * 1.5, at.y + k.y * 0.9, -0.52)
		var mini := RunePuzzle.make_rune_look(0.42)
		add_child(mini)
		mini.global_position = spot
		for g in mini.get_children():
			if g.has_meta("glyph"):
				(g as MeshInstance3D).material_override = ArenaMaterials.flat(Color(0.75, 0.62, 0.35), 0.4)
		var mark := Label3D.new()
		mark.text = str(i + 1)
		mark.font_size = 56
		mark.outline_size = 10
		mark.modulate = Color(0.95, 0.85, 0.6)
		mark.pixel_size = 0.004
		add_child(mark)
		mark.global_position = spot + Vector3(0.0, -0.32, 0.05)
