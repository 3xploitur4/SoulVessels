class_name EnemyFactory
extends RefCounted
## Builds an enemy node from its data id (story 015). One place maps ids to classes, so rooms,
## the sandbox and the bridge spawn the same way.
##
##     var e := EnemyFactory.create("echo_crawler")


## A new enemy for `enemy_id`, or null (with an error) for an unknown id.
static func create(enemy_id: String) -> EnemyBase:
	match enemy_id:
		"echo_crawler":
			return EchoCrawler.new()
		"subterranean_watcher":
			return SubterraneanWatcher.new()
		"branded_warden":
			return BrandedWarden.new()
		"calcified_husk":
			return CalcifiedHusk.new()
		"fungal_stalker":
			return FungalStalker.new()
	push_error("EnemyFactory: unknown enemy %s" % enemy_id)
	return null


## Height above the spawn cell's floor where the enemy's origin goes (hovering enemies).
static func spawn_height(enemy_id: String) -> float:
	return float(Balance.enemy(enemy_id).get("hover_height_m", 0.0)) + 0.05
