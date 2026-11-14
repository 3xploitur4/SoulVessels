class_name DeathRules
extends RefCounted
## What dying costs (story 018, addendum "Death, saving"): carried Soul Essence stays behind as a
## Soul Echo where you fell; die again before touching it and the old echo is lost, unless the
## difficulty says echoes are never lost (Story), in which case the two merge. Shards, items and
## Affinity are never touched. Pure: the game scene moves the player and builds the echo node.
##
##     var result := DeathRules.on_death(state, "z1_05", Vector2(12, 2), lose_old_echo)
##     var got := DeathRules.recover(state)


## Apply a death in `room` at `pos` (last safe ground). Returns {"lost": n, "echo": n}.
## `lose_old_echo` is the difficulty's `echo_lost_on_second_death`.
static func on_death(state: GameState, room: String, pos: Vector2, lose_old_echo: bool) -> Dictionary:
	var carried := state.essence
	var lost := 0
	if not state.echo.is_empty():
		var old := int(state.echo.get("essence", 0))
		if lose_old_echo:
			lost = old
		else:
			carried += old
	state.essence = 0
	state.echo = {} if carried <= 0 else {"room": room, "x": pos.x, "y": pos.y, "essence": carried}
	state.deaths += 1
	state.reset_commons()
	return {"lost": lost, "echo": carried}


## Touching the echo: its Essence comes back. Returns the amount (0 when there is none).
static func recover(state: GameState) -> int:
	if state.echo.is_empty():
		return 0
	var amount := int(state.echo.get("essence", 0))
	state.essence += amount
	state.echo = {}
	return amount


## Where the player comes back: the rested altar, else the checkpoint. {"room", "x", "y"}.
static func respawn_point(state: GameState) -> Dictionary:
	if not state.rested_altar.is_empty():
		var cp := state.checkpoint
		if str(cp.get("room", "")) == str(state.rested_altar.get("room", "")):
			return cp.duplicate()
		return {"room": state.rested_altar["room"], "x": -1.0, "y": -1.0}
	return state.checkpoint.duplicate()
