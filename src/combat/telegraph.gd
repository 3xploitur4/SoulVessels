class_name Telegraph
extends Node3D
## The standard attack cue (story 007): colour + shape + sound, always together. Shows the
## kind's icon above the attacker, pulses it toward the strike, flashes the attacker's body, plays
## the cue sound and announces it on `GameEvents.telegraph_fired`. Colours and sounds come from
## combat.json `telegraph`, so a colour-blind palette is a data change.
##
##     telegraph.show_cue(DamagePacket.KIND_PARRYABLE, 0.8)
##     telegraph.hide_cue()

## Emitted when a cue starts, for the owner's own tell (spine sacs, eye charge).
signal cue_started(kind: String, duration: float)

var height: float = 2.4
var kind: String = ""

var _sprite: Sprite3D
var _left: float = 0.0
var _duration: float = 0.0


func _ready() -> void:
	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.pixel_size = 0.006
	_sprite.no_depth_test = true
	_sprite.shaded = false
	_sprite.render_priority = 10
	_sprite.visible = false
	add_child(_sprite)
	position.y = height
	# Build all three textures now so the first cue in combat never stalls.
	for k in ["parryable", "unblockable", "magic"]:
		TelegraphIcons.texture(k)


## Start a cue of `cue_kind` lasting `duration` seconds (the time until the hit lands).
func show_cue(cue_kind: String, duration: float) -> void:
	kind = cue_kind
	_left = duration
	_duration = maxf(duration, 0.01)
	var spec: Dictionary = Balance.combat("telegraph.%s" % cue_kind) if Balance.combat("telegraph.%s" % cue_kind) is Dictionary else {}
	_sprite.texture = TelegraphIcons.texture(cue_kind)
	_sprite.modulate = Color(str(spec.get("color", "#ffffff")))
	_sprite.visible = true
	_sprite.scale = Vector3.ONE * 0.6
	var sfx := str(spec.get("sfx", ""))
	if not sfx.is_empty():
		Sfx.play(sfx)
	cue_started.emit(cue_kind, duration)
	GameEvents.telegraph_fired.emit(cue_kind, get_parent())


func hide_cue() -> void:
	_left = 0.0
	if _sprite != null:
		_sprite.visible = false


func is_showing() -> bool:
	return _sprite != null and _sprite.visible


func _process(delta: float) -> void:
	if not _sprite.visible:
		return
	_left -= delta
	var t := 1.0 - clampf(_left / _duration, 0.0, 1.0)
	# Grows toward the strike and blinks faster in the last third.
	var pulse := 0.6 + 0.5 * t
	if t > 0.66:
		pulse += 0.12 * sin(t * 60.0)
	_sprite.scale = Vector3.ONE * pulse
	if _left <= -0.15:
		hide_cue()
