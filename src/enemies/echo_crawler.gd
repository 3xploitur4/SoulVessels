class_name EchoCrawler
extends EnemyBase
## Echo Crawler (addendum enemy table): a swarming slate arachnid. 0.6 s green spine-sac flare
## with the crimson X cue, then an unblockable 4 m lunge. Takes +50 % from AoE. Flinches on hit.


func _init() -> void:
	enemy_id = "echo_crawler"


func _hurt_size() -> Vector2:
	return Vector2(1.5, 0.95)


func _attack_tick(_player: Node3D, _delta: float) -> void:
	var dist := float(current_attack.get("lunge_distance_m", 4.0))
	var active := maxf(float(current_attack.get("active_s", 0.25)), 0.01)
	velocity.x = float(facing) * dist / active


func _make_attack_hit(attack: Dictionary) -> ActionHit:
	# The lunge hits with the body: a rect hugging the crawler's front, carried along by the lunge.
	return ActionHit.new(0.0, float(attack.get("active_s", 0.25)) + 0.01, Vector2(0.7, 0.5),
		Vector2(1.2, 0.9), _make_packet(attack))
