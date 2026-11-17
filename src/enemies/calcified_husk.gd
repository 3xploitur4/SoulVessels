class_name CalcifiedHusk
extends EnemyBase
## Calcified Husk (bible section 5, addendum enemy table): a fungal ambusher disguised as a
## statue. It stands as stone, with no aggro and no music change, until the player comes within
## `wake_range_m` or hits it. Then: a 1.0 s spore puff (crimson X, unblockable) that root-snares
## whoever it catches, or a parryable claw up close. Weak to Ember, resists Venom (data).
##
##     var h := CalcifiedHusk.new()   # spawned by EnemyFactory from the room grid ("h")

## Tint of the statue disguise (multiplied into the painting).
const STONE_TINT := Color(0.55, 0.57, 0.6)

## True while it still pretends to be a statue.
var dormant: bool = true


func _init() -> void:
	enemy_id = "calcified_husk"


func _ready() -> void:
	super()
	_set_stone(true)


func _hurt_size() -> Vector2:
	return Vector2(1.0, 2.0)


## Stone-coloured and still while dormant; its own colours once awake.
func _set_stone(on: bool) -> void:
	var sv := visual as EnemySpriteVisual
	if sv != null and sv.body != null:
		sv.body.set_tint(STONE_TINT if on else Color.WHITE)


func wake() -> void:
	if not dormant:
		return
	dormant = false
	_set_stone(false)
	Sfx.play("spore")
	visual.flash(Color(0.7, 1.0, 0.5), 0.3)


func receive_hit(p: DamagePacket) -> DamagePacket.Result:
	wake()
	return super(p)


func _idle_tick(player: Node3D, delta: float) -> void:
	_halt(delta)
	if player == null:
		return
	if dormant:
		var near := absf(player.global_position.x - global_position.x) <= float(data.get("wake_range_m", 3.5)) \
			and absf(player.global_position.y - global_position.y) <= 2.5
		if not near:
			return
		wake()
	super(player, delta)


## The spore puff carries the snare tag; the player applies it if the hit lands.
func _make_packet(attack: Dictionary) -> DamagePacket:
	var p := super(attack)
	if bool(attack.get("snare", false)):
		p.tags["snare"] = true
	return p


func _make_attack_hit(attack: Dictionary) -> ActionHit:
	if not bool(attack.get("snare", false)):
		return super(attack)
	# A low cloud rolling out in front, waist high.
	var reach := float(attack.get("range_m", 3.0))
	return ActionHit.new(0.0, float(attack.get("active_s", 0.4)) + 0.01,
		Vector2(reach * 0.5 + 0.2, 0.7), Vector2(reach, 1.4), _make_packet(attack))


func _begin_attack() -> void:
	super()
	if bool(current_attack.get("snare", false)):
		Sfx.play("spore")
		GameEvents.hit_fx_requested.emit(global_position + Vector3(float(facing) * 1.4, 0.8, 0.3), 0.0, false, true)
