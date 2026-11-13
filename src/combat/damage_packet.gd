class_name DamagePacket
extends RefCounted
## One hit, as the attacker describes it. The receiver resolves the final number with its own
## DEF, weaknesses, shield and state (`CombatMath.damage`). Built by `PlayerAction` hits, enemy
## attacks and projectiles; copied per target with `duplicate_packet()` so per-target flags
## (backstab, crit) never leak between targets.
##
##     var p := DamagePacket.new()
##     p.attacker = self; p.atk = 40.0; p.motion = 1.2; p.posture = 16.0
##     p.kind = DamagePacket.KIND_PARRYABLE
##     target.receive_hit(p)

## A plain hit: blockable, not parryable as a telegraphed attack.
const KIND_NORMAL := "normal"
## Gold: a block that starts inside the parry window turns it into a perfect parry.
const KIND_PARRYABLE := "parryable"
## Crimson: ignores block; dodge or jump.
const KIND_UNBLOCKABLE := "unblockable"
## Violet: magic. Only a shield that can reflect it (Caelan vs the Watcher beam) blocks it.
const KIND_MAGIC := "magic"

## What `receive_hit` reports back.
enum Result { IGNORED, HIT, KILLED, BLOCKED, PARRIED, DODGED, SHIELDED, REFLECTED, GUARD_BROKEN }

var attacker: Node
var team: int = 0
var atk: float = 0.0
var motion: float = 1.0
var posture: float = 0.0
var element: String = "physical"
var element_buildup: float = 0.0
var kind: String = KIND_NORMAL
var knockback: float = 0.0
## World x of the attacker (or the projectile) when the hit lands; decides front, back, block side.
var source_x: float = 0.0
var crit_chance: float = 0.0
var crit_multiplier: float = 1.5
var backstab_multiplier: float = 1.3
var force_crit: bool = false
var force_backstab: bool = false
## Area hits take Echo Crawler's +50 % (`aoe_multiplier` in its data).
var aoe: bool = false
## Heavy hits fill the player's hidden posture when blocked.
var heavy: bool = false
## A parry of this hit sends it back (Watcher beam vs Caelan).
var can_reflect: bool = false
## Breaks shields (Darius's Crushing Blow).
var breaks_shield: bool = false
## Primary-attack hits can riposte a staggered enemy.
var is_primary: bool = false
## The source of a Resonance Strike (Soul Gauge +8 on connect).
var is_resonance: bool = false
## Free-form extras (ability id, echo bonus flags).
var tags: Dictionary = {}

## Filled in by the receiver for the attacker to read.
var result: Result = Result.IGNORED
var dealt: float = 0.0
var was_crit: bool = false
var was_backstab: bool = false
var was_riposte: bool = false


## A fresh copy with the same attack data and cleared results.
func duplicate_packet() -> DamagePacket:
	var p := DamagePacket.new()
	p.attacker = attacker
	p.team = team
	p.atk = atk
	p.motion = motion
	p.posture = posture
	p.element = element
	p.element_buildup = element_buildup
	p.kind = kind
	p.knockback = knockback
	p.source_x = source_x
	p.crit_chance = crit_chance
	p.crit_multiplier = crit_multiplier
	p.backstab_multiplier = backstab_multiplier
	p.force_crit = force_crit
	p.force_backstab = force_backstab
	p.aoe = aoe
	p.heavy = heavy
	p.can_reflect = can_reflect
	p.breaks_shield = breaks_shield
	p.is_primary = is_primary
	p.is_resonance = is_resonance
	p.tags = tags.duplicate()
	return p
