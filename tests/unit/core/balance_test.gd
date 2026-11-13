extends TestCase
## Story 004: the Balance autoload reads the addendum numbers from data/balance/*.json.


func test_combat_values_match_the_addendum() -> void:
	assert_eq(Balance.combat("soul_hp_base"), 300.0)
	assert_eq(Balance.combat("stamina.dodge_cost"), 20.0)
	assert_eq(Balance.combat("stamina.air_dash_cost"), 25.0)
	assert_eq(Balance.combat("parry.window_s"), 0.18)
	assert_eq(Balance.combat("posture.stagger_s"), 2.5)
	assert_eq(Balance.combat("swap.cooldown_s"), 1.5)
	assert_eq(Balance.combat("soul_gauge.max"), 300.0)
	assert_eq(Balance.combat("sync_guard.cooldown_s"), 90.0)


func test_vessel_tables_match_the_addendum() -> void:
	var caelan := Balance.vessel("caelan")
	assert_eq(caelan["stats"]["atk"], 40.0)
	assert_eq(caelan["stats"]["def"], 30.0)
	assert_eq(caelan["stats"]["move_speed"], 6.0)
	assert_eq((caelan["primary"]["hits"] as Array).size(), 4, "4-hit longsword combo")
	assert_eq(caelan["ability_2"]["cooldown_s"], 6.0)
	var nyra := Balance.vessel("nyra")
	assert_eq(nyra["stats"]["crit_chance"], 0.2)
	assert_eq(nyra["stats"]["backstab_multiplier"], 2.5)
	assert_eq((nyra["primary"]["hits"] as Array).size(), 6, "6-hit dagger flurry")
	assert_eq(nyra["ability_1"]["distance_m"], 6.0)
	assert_eq(Balance.vessel_ids(), ["caelan", "darius", "ilyr", "nyra", "seris"])


func test_enemy_tables_match_the_addendum() -> void:
	assert_eq(Balance.enemy("echo_crawler")["hp"], 90.0)
	assert_eq(Balance.enemy("echo_crawler")["attacks"][0]["telegraph_s"], 0.6)
	assert_eq(Balance.enemy("subterranean_watcher")["hp"], 120.0)
	assert_eq(Balance.enemy("subterranean_watcher")["attacks"][0]["telegraph_s"], 1.2)
	assert_eq(Balance.enemy("branded_warden")["hp"], 900.0)
	assert_eq(Balance.enemy("branded_warden")["posture"], 220.0)
	assert_eq(Balance.enemy("branded_warden")["shield"]["block_fraction"], 0.8)


func test_missing_keys_return_null_not_zero() -> void:
	assert_null(Balance.combat("stamina.no_such_key"))
	assert_eq(Balance.vessel("nobody"), {})
	assert_eq(Balance.enemy("nobody"), {})


func test_get_and_set_value_by_dotted_path() -> void:
	assert_eq(Balance.get_value("combat.stamina.dodge_cost"), 20.0)
	assert_eq(Balance.get_value("vessel.caelan.stats.atk"), 40.0)
	assert_eq(Balance.get_value("enemy.branded_warden.attacks.0.range_m"), 3.5)
	assert_true(Balance.set_value("combat.stamina.dodge_cost", 25.0))
	assert_eq(Balance.get_value("combat.stamina.dodge_cost"), 25.0)
	assert_false(Balance.set_value("combat.stamina.invented", 1.0), "no new keys at run time")
	Balance.reload()
	assert_eq(Balance.get_value("combat.stamina.dodge_cost"), 20.0, "reload restores the file value")
