extends TestCase
## Story 057 (D-068): the combo moves (air chain, dash slash, rising cut) and the horizontal arcs.


func _player(vessel: String) -> Player:
	var p := Player.new()
	p.vessel_ids = [vessel] as Array[String]
	add_node(p)
	return p


func test_a_swordsman_has_an_air_chain_a_dash_slash_and_a_rising_cut() -> void:
	var p := _player("caelan")
	var kit := p.loadout.active().kit
	assert_eq(kit.special_count("air"), 2)
	var air := kit.special_action(p, "air", 0)
	assert_eq(air.id, "slash_air_0")
	assert_lt(air.gravity_scale, 0.55, "an air cut holds you up a little")
	assert_eq(kit.special_action(p, "air", 3).id, "slash_air_1", "the air chain wraps")
	var dash := kit.special_action(p, "dash")
	assert_eq(dash.id, "slash_dash")
	var up := kit.special_action(p, "up")
	assert_eq(up.id, "slash_up")
	var hit: ActionHit = up.hits[0]
	assert_gt(hit.offset.y, 1.8, "the rising cut reaches above the head")


func test_a_caster_keeps_her_bolts() -> void:
	var p := _player("seris")
	var kit := p.loadout.active().kit
	assert_eq(kit.special_count("air"), 0)
	assert_true(kit.special_action(p, "air") == null)
	assert_true(kit.special_action(p, "dash") == null)


func test_the_hammer_keeps_its_armour_on_its_combo_moves() -> void:
	var p := _player("darius")
	assert_true(p.loadout.active().kit.special_action(p, "dash").hyper_armor)


func test_ground_cuts_are_flat_and_the_finisher_goes_all_the_way_round() -> void:
	var first: Array = VesselSpriteVisual.swing(0, "", false)
	assert_lt(float(first[4]), 0.5, "a horizontal cut is a flat sweep")
	var back: Array = VesselSpriteVisual.swing(1, "", false)
	assert_true(float(back[1]) < float(back[2]), "the backhand sweeps the other way")
	var spin: Array = VesselSpriteVisual.swing(3, "", false)
	assert_gt(absf(float(spin[2]) - float(spin[1])), 359.0, "the finisher spins")
	var up: Array = VesselSpriteVisual.swing(-1, "up", false)
	assert_almost(float(up[4]), 1.0, 0.001, "the rising cut is a round vertical arc")
