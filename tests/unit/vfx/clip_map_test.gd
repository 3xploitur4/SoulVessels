extends TestCase
## Story 039: a Vessel with its own clip for an action plays it (Seris's bolt cast, Frost Binding,
## swim); others fall back to the shared clips.


func test_seris_casts_bolts_with_her_own_clip() -> void:
	var clips := RigBody.load_def("seris").get("clips", {}) as Dictionary
	assert_eq(VesselSpriteVisual.clip_for_rig("primary_0", clips), "bolt")
	assert_eq(VesselSpriteVisual.clip_for_rig("frost_binding", clips), "frost")
	assert_eq(VesselSpriteVisual.clip_for_rig("swim", clips), "swim")


func test_caelan_keeps_the_shared_clips() -> void:
	var clips := RigBody.load_def("caelan").get("clips", {}) as Dictionary
	assert_eq(VesselSpriteVisual.clip_for_rig("primary_2", clips), "attack_2")
	assert_eq(VesselSpriteVisual.clip_for_rig("swim", clips), "fall", "no swim clip: falls back")
