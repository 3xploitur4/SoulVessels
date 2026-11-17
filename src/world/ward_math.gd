class_name WardMath
extends RefCounted
## The shield ward statue fires a steady horizontal beam; when Caelan blocks it facing the statue,
## his shield throws it back toward the statue's side and upward at a fixed angle; if that
## reflected ray crosses the receiver crystal, the crystal charges. All positions are room metres
## (x right, y up).

## Returns the reflected unit direction, back along x and upward by `angle_deg`.
static func reflect_dir(beam_dir_x: float, angle_deg: float) -> Vector2:
	var rad: float = deg_to_rad(angle_deg)
	return Vector2(-beam_dir_x * cos(rad), sin(rad))


## Returns the first blocker face along the horizontal beam, or the beam's maximum endpoint.
static func beam_end_x(origin: Vector2, beam_dir_x: float, max_length: float, blockers: Array[Rect2]) -> float:
	var end_x: float = origin.x + beam_dir_x * max_length
	var nearest_x: float = end_x
	var found: bool = false
	for rect: Rect2 in blockers:
		if origin.y < rect.position.y or origin.y > rect.end.y:
			continue
		var face_x: float = rect.end.x if beam_dir_x < 0.0 else rect.position.x
		if beam_dir_x < 0.0:
			if face_x > origin.x or face_x < end_x:
				continue
			if not found or face_x > nearest_x:
				nearest_x = face_x
				found = true
		else:
			if face_x < origin.x or face_x > end_x:
				continue
			if not found or face_x < nearest_x:
				nearest_x = face_x
				found = true
	return nearest_x


## Returns whether the normalized ray segment crosses `rect`.
static func ray_hits(origin: Vector2, dir: Vector2, length: float, rect: Rect2) -> bool:
	return CombatWorld.segment_hits_rect(origin, origin + dir.normalized() * length, rect)


## Story 032: a bolt with velocity `v` off a two-sided mirror whose normal points at `angle_deg`
## (0 = facing right, so the mirror stands upright; 90 = lying flat). Same speed, mirrored angle.
static func mirror_reflect(v: Vector2, angle_deg: float) -> Vector2:
	var n := Vector2.from_angle(deg_to_rad(angle_deg))
	return v - 2.0 * v.dot(n) * n
