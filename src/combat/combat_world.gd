class_name CombatWorld
extends Node
## Registry of everything that can be hit, and the overlap queries attacks use (decision D-011).
## Hits are rectangles in the X/Y play plane, not Area3D overlaps: the game is side-on with z
## locked, so a rect test is exact, deterministic, frame-order independent and runs headless in
## unit tests. Combatants register on `_ready` and leave on `_exit_tree`.
##
## A combatant is any Node3D with:
##   var team: int                         # TEAM_PLAYER or TEAM_ENEMY
##   func hurt_rect() -> Rect2             # world X/Y
##   func receive_hit(p: DamagePacket) -> DamagePacket.Result
##   func is_alive() -> bool
##
##     var hits: Array[Node3D] = []
##     world.query_rect(Rect2(x, y, 2, 1.5), CombatWorld.TEAM_ENEMY, hits)

const TEAM_PLAYER := 0
const TEAM_ENEMY := 1

## The player body, for enemies to target. Set by whoever spawns the player.
var player: Node3D

var _members: Array[Node3D] = []


func register(c: Node3D) -> void:
	if not _members.has(c):
		_members.append(c)


func unregister(c: Node3D) -> void:
	_members.erase(c)


## Living members of `team` whose hurt rect overlaps `rect`, appended to `out` (not cleared).
func query_rect(rect: Rect2, team: int, out: Array[Node3D]) -> void:
	for c in _members:
		if not is_instance_valid(c):
			continue
		if int(c.get("team")) != team or not bool(c.call("is_alive")):
			continue
		var r: Rect2 = c.call("hurt_rect")
		if r.intersects(rect, true):
			out.append(c)


## Living members of `team` within `radius` of `point` (rect centre distance), into `out`.
func query_radius(point: Vector2, radius: float, team: int, out: Array[Node3D]) -> void:
	for c in _members:
		if not is_instance_valid(c):
			continue
		if int(c.get("team")) != team or not bool(c.call("is_alive")):
			continue
		var r: Rect2 = c.call("hurt_rect")
		var closest := Vector2(clampf(point.x, r.position.x, r.end.x), clampf(point.y, r.position.y, r.end.y))
		if closest.distance_to(point) <= radius:
			out.append(c)


## The living member of `team` nearest to `point` within `max_range`, or null.
func nearest(point: Vector2, team: int, max_range: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_range
	for c in _members:
		if not is_instance_valid(c):
			continue
		if int(c.get("team")) != team or not bool(c.call("is_alive")):
			continue
		var r: Rect2 = c.call("hurt_rect")
		var d := r.get_center().distance_to(point)
		if d <= best_d:
			best_d = d
			best = c
	return best


## Every living member of `team`, into `out`.
func members_of(team: int, out: Array[Node3D]) -> void:
	for c in _members:
		if is_instance_valid(c) and int(c.get("team")) == team and bool(c.call("is_alive")):
			out.append(c)


## Does the segment a-b cross the rect? (Watcher beam.)
static func segment_hits_rect(a: Vector2, b: Vector2, rect: Rect2) -> bool:
	if rect.has_point(a) or rect.has_point(b):
		return true
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y)]
	for i in range(4):
		var c1: Vector2 = corners[i]
		var c2: Vector2 = corners[(i + 1) % 4]
		if Geometry2D.segment_intersects_segment(a, b, c1, c2) != null:
			return true
	return false
