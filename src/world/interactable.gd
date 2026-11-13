class_name Interactable
extends Node3D
## Something the player can use with the interact control (story 016): altars, Vessel bodies,
## signs. The game scene shows the prompt for the nearest one in reach and calls `interact`.
## Subclasses override `verb_key`, `can_interact` and `interact`.

const GROUP := "interactables"

## Horizontal reach in metres.
var radius: float = 1.6
## Translation key of the prompt verb ("UI_REST", "UI_POSSESS").
var verb_key: String = "UI_INTERACT"


func _ready() -> void:
	add_to_group(GROUP)


## May the player use it now?
func can_interact(_player: Player) -> bool:
	return true


## Use it. `game` is the game scene (state, saves, menus).
func interact(_game: Node) -> void:
	pass


## Is `player` within reach (same floor band)?
func in_reach(player: Player) -> bool:
	var d := player.global_position - global_position
	return absf(d.x) <= radius and absf(d.y) <= 1.6
