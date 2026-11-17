class_name PossessionBody
extends Interactable
## A fallen Vessel's body the wisp can enter (story 024; addendum Narrative 1: the Intruder
## enters Caelan, who died guarding a sealed door). It kneels lifeless and dim, with a faint
## pulse of soul-light; while the player is the bare wisp the prompt reads "Possess". The game
## scene does the binding (`Game.possess`), then this body is removed. A body already taken
## (story flag `possessed_<vessel>`) is never built again.
##
##     var b := PossessionBody.new()
##     b.vessel = "caelan"
##     features_root.add_child(b)

## Vessel id this body belongs to.
var vessel: String = ""

var _body: SpriteBody
var _t: float = 0.0


func _ready() -> void:
	super._ready()
	verb_key = "UI_POSSESS"
	radius = 1.8
	_body = SpriteBody.create(vessel)
	if _body != null:
		add_child(_body)
		_body.set_tint(Color(0.55, 0.58, 0.68))
		if _body is RigBody:
			(_body as RigBody).pose_now("kneel" if (_body as RigBody).clips.has("kneel") else "dead", 0.0)


## Only the bare wisp can take a body.
func can_interact(player: Player) -> bool:
	return player.is_wisp()


func interact(game: Node) -> void:
	game.call("possess", vessel, self)


func _process(delta: float) -> void:
	if _body == null:
		return
	_t += delta
	# A slow heartbeat of soul-light: the body is empty but not gone.
	_body.glow = 0.12 + 0.12 * sin(_t * 2.2)
	if _body is RigBody:
		(_body as RigBody).play("kneel" if (_body as RigBody).clips.has("kneel") else "dead")
	_body.tick(delta)
