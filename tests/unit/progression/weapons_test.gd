extends TestCase
## Story 050: second weapons (Greatsword, Venom Blades, Floating Focus, Improvised Heavy) and the
## Affinity 5 signature passives (Sworn Shield, Ghost Step, Spellweave, Unkillable): unlocks,
## switching, the save, the data patches, and each kit hook.

class Dummy extends Node3D:
	var team: int = CombatWorld.TEAM_ENEMY
	var packets: Array[DamagePacket] = []

	func hurt_rect() -> Rect2:
		return Rect2(2.0, 0.0, 1.0, 2.0)

	func receive_hit(p: DamagePacket) -> DamagePacket.Result:
		packets.append(p)
		return DamagePacket.Result.HIT

	func is_alive() -> bool:
		return true


var w: Weapons
var gs: GameState


func before_each() -> void:
	w = Weapons.from_data()
	gs = GameState.new_game("normal")


## A player whose Vessels carry `gs`'s weapons, with every Vessel at Affinity `aff`.
func _player(ids: Array[String], aff: int = 0) -> Player:
	var holder := add_node(Node3D.new()) as Node3D
	var world := CombatWorld.new()
	add_node(world)
	var p := Player.new()
	p.world = world
	p.fx_parent = holder
	p.vessel_ids = ids
	var levels := {}
	for v in ids:
		levels[v] = aff
	p.affinity_levels = levels
	p.data_patcher = func(vid: String, d: Dictionary) -> Dictionary: return w.patched(d, gs, vid, aff)
	add_node(p)
	return p


func test_every_vessel_has_a_second_weapon_and_a_signature() -> void:
	for v: String in ["caelan", "nyra", "seris", "darius"]:
		assert_false(w.second(v).is_empty(), v + " has a second weapon")
		assert_true(w.signatures.has(v), v + " has a signature passive")
		assert_eq(int(w.signatures[v].get("level", 0)), 5)


func test_unlocks_come_from_the_guardian_the_schematic_the_rune_and_the_cores() -> void:
	for v: String in ["caelan", "nyra", "seris", "darius"]:
		assert_false(w.unlocked(gs, v), v + " starts locked")
	gs.set_flag("unlock_greatsword")
	gs.add_item("weapon_schematic", 1)
	gs.add_item("deep_realm_rune", 1)
	gs.add_item("polished_basalt_core", 1)
	for v: String in ["caelan", "nyra", "seris", "darius"]:
		assert_true(w.unlocked(gs, v), v + " unlocked")


func test_an_item_unlock_is_remembered_after_the_item_is_spent() -> void:
	gs.add_item("polished_basalt_core", 1)
	assert_eq(w.refresh(gs), ["improvised_heavy"] as Array[String])
	gs.inventory.erase("polished_basalt_core")
	assert_true(w.unlocked(gs, "darius"))


func test_switching_weapons_and_the_save() -> void:
	assert_false(w.equip(gs, "caelan", "greatsword"), "locked")
	gs.set_flag("unlock_greatsword")
	assert_false(w.equip(gs, "caelan", "venom_blades"), "not Caelan's")
	assert_true(w.equip(gs, "caelan", "greatsword"))
	assert_eq(w.equipped(gs, "caelan"), "greatsword")
	var back := GameState.from_dict(gs.to_dict())
	assert_eq(w.equipped(back, "caelan"), "greatsword", "kept in the save")
	assert_true(w.equip(gs, "caelan", ""))
	assert_eq(w.equipped(gs, "caelan"), "")
	assert_eq(GameState.from_dict({}).weapons.size(), 0, "an old save has the first weapons")


func test_the_greatsword_drops_the_shield_and_hits_posture_harder() -> void:
	var base := Balance.vessel("caelan")
	gs.set_flag("unlock_greatsword")
	w.equip(gs, "caelan", "greatsword")
	var out := w.patched(base, gs, "caelan", 0)
	assert_almost(float(out["stats"]["posture_multiplier"]), float(base["stats"]["posture_multiplier"]) * 1.5, 0.001)
	assert_false(bool(out["weapon"]["shield"]))
	assert_true(float(out["passive"]["blocking_damage_taken_multiplier"]) > float(base["passive"]["blocking_damage_taken_multiplier"]),
		"the blade parries, but blocks less than the shield")


func test_signatures_apply_only_from_affinity_five() -> void:
	var base := Balance.vessel("darius")
	assert_false(w.patched(base, gs, "darius", 4).get("sync_guard", {}).has("cooldown_s"))
	assert_eq(float(w.patched(base, gs, "darius", 5)["sync_guard"]["cooldown_s"]), 45.0, "Unkillable")


func test_venom_blades_carry_venom() -> void:
	gs.add_item("weapon_schematic", 1)
	w.equip(gs, "nyra", "venom_blades")
	var p := _player(["nyra"] as Array[String])
	var a := p.loadout.active().kit.primary_action(p, 0)
	var packet: DamagePacket = a.hits[0].packet
	assert_eq(packet.element, "venom")
	assert_true(packet.element_buildup > 0.0)


func test_the_improvised_heavy_lands_a_random_element() -> void:
	gs.add_item("polished_basalt_core", 1)
	w.equip(gs, "darius", "improvised_heavy")
	var p := _player(["darius"] as Array[String])
	var seen := {}
	for i in range(24):
		var a := p.loadout.active().kit.primary_action(p, i % 3)
		seen[(a.hits[0].packet as DamagePacket).element] = true
	for el: String in seen:
		assert_true(["ember", "frost", "venom", "aether"].has(el), "an element: " + el)
	assert_true(seen.size() >= 2, "more than one element over 24 blows")


func test_the_floating_focus_casts_at_full_speed() -> void:
	var p0 := _player(["seris"] as Array[String])
	assert_almost(p0.loadout.active().kit.primary_action(p0, 0).steer, 0.4, 0.001, "the staff slows the cast")
	gs.add_item("deep_realm_rune", 1)
	w.equip(gs, "seris", "floating_focus")
	var p := _player(["seris"] as Array[String])
	assert_almost(p.loadout.active().kit.primary_action(p, 0).steer, 1.0, 0.001)


func test_spellweave_every_third_bolt_copies_the_last_spell() -> void:
	var p := _player(["seris"] as Array[String], 5)
	var kit := p.loadout.active().kit as SerisKit
	kit.last_spell = {"element": "frost", "buildup": 60.0}
	var els: Array[String] = []
	for i in range(3):
		els.append(kit.fire_bolt(p, 0).packet.element)
	assert_eq(els, ["aether", "aether", "frost"] as Array[String])
	var p4 := _player(["seris"] as Array[String], 4)
	var k4 := p4.loadout.active().kit as SerisKit
	k4.last_spell = {"element": "frost", "buildup": 60.0}
	for i in range(3):
		assert_eq(k4.fire_bolt(p4, 0).packet.element, "aether", "not before Affinity 5")


func test_ghost_step_readies_shadowstep_after_a_backstab_kill() -> void:
	var p := _player(["nyra"] as Array[String], 5)
	var slot := p.loadout.active()
	slot.start_cooldown("shadowstep", 6.0)
	var hit := p.make_packet(1.0, 5.0)
	hit.was_backstab = true
	hit.result = DamagePacket.Result.HIT
	slot.kit.on_primary_landed(p, null, hit)
	assert_false(slot.cooldown_ready("shadowstep"), "a backstab that does not kill")
	hit.result = DamagePacket.Result.KILLED
	slot.kit.on_primary_landed(p, null, hit)
	assert_true(slot.cooldown_ready("shadowstep"))


func test_sworn_shield_sends_magic_back() -> void:
	var caster := add_node(Dummy.new()) as Dummy
	var orb := DamagePacket.new()
	orb.kind = DamagePacket.KIND_MAGIC
	orb.atk = 40.0
	orb.motion = 1.0
	orb.attacker = caster
	var p4 := _player(["caelan"] as Array[String], 4)
	p4.loadout.active().kit.on_perfect_parry(p4, caster, orb)
	assert_eq(caster.packets.size(), 0, "not before Affinity 5")
	var p := _player(["caelan"] as Array[String], 5)
	p.loadout.active().kit.on_perfect_parry(p, caster, orb)
	assert_eq(caster.packets.size(), 1)
	assert_eq(caster.packets[0].team, CombatWorld.TEAM_PLAYER)
	var melee := DamagePacket.new()
	melee.attacker = caster
	p.loadout.active().kit.on_perfect_parry(p, caster, melee)
	assert_eq(caster.packets.size(), 1, "a sword is not sent back")
