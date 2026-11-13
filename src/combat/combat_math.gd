class_name CombatMath
extends RefCounted
## Pure combat formulas from the addendum ("Damage formula", "Elements and status effects",
## "Posture"). No state, no nodes: everything here is unit-tested in
## `tests/unit/combat/combat_math_test.gd`. Callers pass the multipliers they resolved from
## `Balance`; nothing here reads a file.
##
##     var dmg := CombatMath.damage(40.0, 1.0, 30.0)            # 30.77
##     var mult := CombatMath.element_multiplier("frost", ["frost"], [], 1.5, 0.5)  # 1.5


## Damage = ATK x MotionValue x 100 / (100 + DEF) x Crit x Element x Backstab.
static func damage(atk: float, motion_value: float, def: float, crit: float = 1.0,
		element: float = 1.0, backstab: float = 1.0) -> float:
	return atk * motion_value * 100.0 / (100.0 + maxf(def, 0.0)) * crit * element * backstab


## 1.5x on a weakness, 0.5x on a resisted element, 1.0 otherwise (the numbers come from
## combat.json `damage.weakness_multiplier` / `damage.resist_multiplier`).
static func element_multiplier(element: String, weaknesses: Array, resists: Array,
		weakness_mult: float, resist_mult: float) -> float:
	if element.is_empty():
		return 1.0
	if weaknesses.has(element):
		return weakness_mult
	if resists.has(element):
		return resist_mult
	return 1.0


## Side-view backstab: the attacker stands on the side the target is not facing.
## `target_facing` is +1 (looks right) or -1 (looks left). Equal x is never a backstab.
static func is_backstab(attacker_x: float, target_x: float, target_facing: int) -> bool:
	var side := signf(attacker_x - target_x)
	return side != 0.0 and int(side) == -target_facing


## Whether an attack from `attacker_x` hits the frontal arc of a shield-bearer at `target_x`
## facing `target_facing`. In a side view the arc degenerates to "in front"; `arc_deg` under 180
## means a shield, 360 means no gap. Kept as a function so a 3D flank rule can replace it.
static func hits_frontal_arc(attacker_x: float, target_x: float, target_facing: int,
		arc_deg: float) -> bool:
	if arc_deg >= 360.0:
		return true
	var side := signf(attacker_x - target_x)
	return side == 0.0 or int(side) == target_facing


## Damage after a shield that blocks `block_fraction` of frontal hits.
static func shielded_damage(raw: float, frontal: bool, shield_up: bool, block_fraction: float) -> float:
	if frontal and shield_up:
		return raw * (1.0 - block_fraction)
	return raw


## Crit roll with an injected RNG so tests are deterministic.
static func roll_crit(chance: float, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < chance


## Posture dealt by a hit: base posture x attacker multiplier x element stagger bonus.
static func posture_damage(base: float, attacker_multiplier: float, stagger_bonus: float = 1.0) -> float:
	return base * attacker_multiplier * stagger_bonus


## Whether a block started at `block_start_s` parries a hit landing at `hit_s`: the block began
## within `window_s` before the impact (inclusive) and not after it.
static func is_perfect_parry(block_start_s: float, hit_s: float, window_s: float) -> bool:
	var lead := hit_s - block_start_s
	# A hair of tolerance so an exact-window block (0.18 s before a hit at 1.0 s) still counts;
	# float subtraction otherwise lands at 0.18000000000000005.
	return lead >= 0.0 and lead <= window_s + 0.0001


## Whether a dodge that started at `dodge_start_s` is a perfect dodge against a hit at `hit_s`:
## the hit lands inside the i-frames and within `perfect_window_s` of the dodge start + i-frame start.
static func is_perfect_dodge(dodge_start_s: float, hit_s: float, iframe_start_s: float,
		iframe_s: float, perfect_window_s: float) -> bool:
	var iframes_begin := dodge_start_s + iframe_start_s
	var in_iframes := hit_s >= iframes_begin and hit_s <= iframes_begin + iframe_s
	return in_iframes and (hit_s - iframes_begin) <= perfect_window_s


## Last Survivor style scaling: +`per_step` per `step_fraction` of HP missing, capped.
static func missing_hp_bonus(current_hp: float, max_hp: float, per_step: float, step_fraction: float,
		cap: float) -> float:
	if max_hp <= 0.0:
		return 0.0
	var missing := clampf(1.0 - current_hp / max_hp, 0.0, 1.0)
	return minf(floorf(missing / step_fraction) * per_step, cap)
