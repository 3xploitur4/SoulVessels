class_name GuardianBelow
extends Boss
## The Guardian Below (addendum boss table; bible boss 2): an iron colossus on the Sealed Rift's
## elevator. 8,000 HP, posture 900, phases at 65 % and 30 %.
## - Posture builds only on its fists in phases 1-2 and on its core in phase 3 (`posture_counts`).
##   Fists and core are separate targets (`GuardianZone`) that pass hits here; its body itself sits
##   out of reach. The core is armoured until phase 3, when it opens.
## - Phase 2 smashes the elevator chains: the arena tilts 15 degrees (the Boss base tilts every
##   SlideZone and the camera) and boulders roll down it every 6 s.
## - Phase 3: +40 % attack speed and radial shockwaves.
## Rewards: the Heart of the Guardian, Greater Soul Shards, and the Greatsword unlock flag.
## Numbers in data/balance/enemies/guardian_below.json.

var _zones: Array[GuardianZone] = []
var _rock_t: float = 0.0
## Boulders rolled so far (playtests read it).
var rocks_rolled: int = 0


func _init() -> void:
	enemy_id = "guardian_below"
	turn_delay_s = 0.6


## Does a hit on `zone` ("fist", "core" or "body") build posture in `phase`?
static func posture_counts(zone: String, at_phase: int) -> bool:
	match zone:
		"fist":
			return at_phase <= 1
		"core":
			return at_phase >= 2
	return false


func _ready() -> void:
	super._ready()
	for spec: Dictionary in data.get("zones", []):
		var z := GuardianZone.new()
		z.guardian = self
		z.zone = str(spec.get("zone", "fist"))
		var r: Array = spec.get("rect", [0, 0, 1, 1])
		z.offset = Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
		z.offset = Rect2(z.offset.position * size_scale, z.offset.size * size_scale)
		add_child(z)
		_zones.append(z)


func _hurt_size() -> Vector2:
	return Vector2(2.6, 4.2)


## Its body is out of reach: only the zones are hit (the hurt rect sits high above the arena).
func hurt_rect() -> Rect2:
	return Rect2(global_position.x - 0.1, global_position.y + 40.0, 0.2, 0.2)


## The core shows and takes hits in phase 3.
func core_open() -> bool:
	return phase >= 2


## A hit on one of its zones.
func zone_hit(p: DamagePacket, zone: String) -> DamagePacket.Result:
	if not is_alive():
		return DamagePacket.Result.IGNORED
	if zone == "core" and not core_open():
		GameEvents.hit_fx_requested.emit(global_position + Vector3(0.0, 2.8, 0.5), 0.0, false, true)
		Sfx.play("block")
		return DamagePacket.Result.SHIELDED
	if not posture_counts(zone, phase):
		p.posture = 0.0
	return receive_hit(p)


## Seconds between rolling boulders now (0: none).
func rock_interval() -> float:
	var ph: Dictionary = (data.get("phases", []) as Array)[phase]
	return float(ph.get("rocks_every_s", 0.0))


func _physics_process(delta: float) -> void:
	super(delta)
	var every := rock_interval()
	if every > 0.0 and is_alive():
		_rock_t += delta
		if _rock_t >= every:
			_rock_t = 0.0
			_roll_rock()


## A boulder breaks loose at the high end of the tilted elevator and rolls down it.
func _roll_rock() -> void:
	var rock: Dictionary = data.get("rock", {})
	var dir := -1.0
	for n in get_tree().get_nodes_in_group(SlideZone.GROUP):
		var z := n as SlideZone
		dir = signf(z.angle) if z.angle != 0.0 else dir
		var from_x := z.x_range.x + 0.8 if dir > 0.0 else z.x_range.y - 0.8
		var p := DamagePacket.new()
		p.attacker = self
		p.team = team
		p.atk = float(data.get("atk", 60.0))
		p.motion = float(rock.get("motion", 1.0))
		p.posture = float(rock.get("posture", 20.0))
		p.kind = DamagePacket.KIND_UNBLOCKABLE
		p.knockback = 3.0
		p.tags["attack"] = "rolling_rock"
		var speed := float(rock.get("speed_mps", 7.0))
		var vis := VfxShapes.bolt(Color(0.42, 0.38, 0.34), 0.7, 0.0)
		var proj := Projectile.spawn(get_parent(), world, p, Vector2(from_x, z.y_range.x + 0.7),
			Vector2(speed * dir, 0.0), Vector2(1.3, 1.3), vis)
		proj.target_team = CombatWorld.TEAM_PLAYER
		proj.max_distance = z.x_range.y - z.x_range.x
		proj.lifetime = proj.max_distance / speed + 0.2
		rocks_rolled += 1
		Sfx.play("guard_break")
		return


func _riposte_allowed() -> bool:
	return false
