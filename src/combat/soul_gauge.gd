class_name SoulGauge
extends RefCounted
## The shared Soul Gauge (addendum "Soul Gauge"): 300 max = 3 bars of 100. Gains come from the
## events in combat.json `soul_gauge.*`; it drains 1/s once the player has been out of combat for
## `out_of_combat_delay_s`. Sync Guard spends 1 bar, a Sync Ultimate 2.
##
##     gauge.gain("per_perfect_parry")      # +10
##     if gauge.spend_bars(2): _ultimate()

signal changed(value: float, maximum: float, bars: int)

var max_value: float = 300.0
var bar_size: float = 100.0
var value: float = 0.0
var drain_per_s: float = 1.0
var out_of_combat_delay_s: float = 6.0

var _gains: Dictionary = {}
var _since_combat: float = 999.0
var _damage_remainder: float = 0.0


static func from_balance() -> SoulGauge:
	var g := SoulGauge.new()
	var cfg: Variant = Balance.combat("soul_gauge")
	if cfg is Dictionary:
		var d: Dictionary = cfg
		g._gains = d
		g.max_value = float(d.get("max", 300.0))
		g.bar_size = float(d.get("bar", 100.0))
		g.drain_per_s = float(d.get("drain_per_s_out_of_combat", 1.0))
		g.out_of_combat_delay_s = float(d.get("out_of_combat_delay_s", 6.0))
	return g


## Gain the amount named by a combat.json key ("per_hit", "per_kill", ...). Unknown keys add 0.
func gain(event_key: String) -> void:
	add(float(_gains.get(event_key, 0.0)))


## +1 per 10 damage taken, carrying the remainder between hits.
func gain_from_damage_taken(damage: float) -> void:
	var per_10: float = float(_gains.get("per_10_damage_taken", 1.0))
	_damage_remainder += damage
	var steps := floorf(_damage_remainder / 10.0)
	_damage_remainder -= steps * 10.0
	add(steps * per_10)


func add(amount: float) -> void:
	if amount == 0.0:
		return
	value = clampf(value + amount, 0.0, max_value)
	changed.emit(value, max_value, bars())


func bars() -> int:
	return int(floorf(value / bar_size + 0.0001))


func has_bars(count: int) -> bool:
	return bars() >= count


## Spend whole bars. Returns false and spends nothing when there are not enough.
func spend_bars(count: int) -> bool:
	if not has_bars(count):
		return false
	add(-bar_size * count)
	return true


## Call when anything counts as combat (an enemy has aggro, a hit lands).
func mark_combat() -> void:
	_since_combat = 0.0


func in_combat() -> bool:
	return _since_combat < out_of_combat_delay_s


func tick(delta: float) -> void:
	_since_combat += delta
	var drain_time := minf(delta, _since_combat - out_of_combat_delay_s)
	if drain_time > 0.0 and value > 0.0:
		add(-drain_per_s * drain_time)
