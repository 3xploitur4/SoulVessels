class_name RiftPortal
extends SealedGate
## The rift the Abyssal Leviathan's fall tears open (story 049; addendum Narrative 6). Hidden until
## the save flag (default "rift_open") is set, which can happen while the player stands in the
## room; then the tear shows and "Enter" carries the player to the awakening room.
##
## Room JSON: "rift": {"pos": [x, y], "flag": "rift_open", "to": "z4_14", "at": [x, y]}

## Save flag that opens the rift.
var flag: String = "rift_open"
## Room it leads to, and the arrival point there (room metres).
var to_room: String = ""
var arrive: Vector2 = Vector2.INF
var state: GameState
var manager: RoomManager


## Build the rift for a room that has one. Registered as a room feature.
static func build_for(m: RoomManager, room: RoomData, gs: GameState) -> void:
	var def: Variant = room.raw.get("rift")
	if not def is Dictionary:
		return
	var d := def as Dictionary
	var r := RiftPortal.new()
	r.name = "Rift"
	r.kind = "rift"
	r.state = gs
	r.manager = m
	r.flag = str(d.get("flag", "rift_open"))
	r.to_room = str(d.get("to", ""))
	var at: Array = d.get("at", [])
	if at.size() == 2:
		r.arrive = Vector2(float(at[0]), float(at[1]))
	m.features_root.add_child(r)
	var pos: Array = d.get("pos", [0, 0])
	r.global_position = Vector3(float(pos[0]), float(pos[1]), 0.0)


func _ready() -> void:
	super._ready()
	verb_key = "UI_ENTER"
	visible = is_open()


## Is the rift torn open yet?
func is_open() -> bool:
	return state != null and state.flag(flag)


func can_interact(_player: Player) -> bool:
	return is_open() and to_room != ""


func interact(_game: Node) -> void:
	if manager != null and can_interact(null):
		Sfx.play("vanish")
		manager.travel(to_room, "", arrive)


func _physics_process(_delta: float) -> void:
	if not visible and is_open():
		visible = true
		GameEvents.ultimate_fx_requested.emit("cataclysm_fused", global_position + Vector3(0, 1.3, 0), 1.5)
