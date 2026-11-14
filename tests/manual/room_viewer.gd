extends Node3D
## Story 015 tool: load rooms and screenshot them (the room atlas).
##
##   godot --path . --windowed --resolution 1280x720 res://tests/manual/room_viewer.tscn -- \
##       --rooms z1_01,z1_02 --out production/qa/evidence/atlas [--at entry|centre] [--draws]
## With no --rooms, every room. Each room is shot with the player at its first exit's arrival
## (or the start marker), plus a second shot panned to the room centre for wide rooms.

var world: CombatWorld
var player: Player
var camera: SideCamera
var rooms: RoomManager


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var ids := WorldData.room_ids()
	var i := args.find("--rooms")
	if i >= 0 and i + 1 < args.size():
		ids.assign(args[i + 1].split(","))
	var out := "production/qa/evidence/atlas"
	i = args.find("--out")
	if i >= 0 and i + 1 < args.size():
		out = args[i + 1]
	world = CombatWorld.new()
	add_child(world)
	player = Player.new()
	player.world = world
	player.vessel_ids = ["caelan"]
	add_child(player)
	player.input_enabled = false
	camera = SideCamera.new()
	camera.target = player
	add_child(camera)
	add_child(Vignette.new())
	rooms = RoomManager.new()
	rooms.world = world
	rooms.player = player
	rooms.camera = camera
	rooms.state = GameState.new_game()
	add_child(rooms)
	var abs_out := ProjectSettings.globalize_path("res://").path_join(out)
	DirAccess.make_dir_recursive_absolute(abs_out)
	for id in ids:
		var t0 := Time.get_ticks_usec()
		rooms.enter(id)
		var build_ms := float(Time.get_ticks_usec() - t0) / 1000.0
		var r := rooms.data
		var shots: Array[Vector2] = []
		var first := ""
		for d: String in r.exits.keys():
			first = d
			break
		shots.append(r.markers.get("start", r.exits[first]["arrive"] if first != "" else r.size() * 0.5))
		if r.cols > 26 or r.rows > 14:
			shots.append(Vector2(r.cols * 0.5, r.rows * 0.5))
		for k in range(shots.size()):
			player.teleport(shots[k].x, shots[k].y)
			rooms.kill_all() if k > 0 else null
			camera.snap()
			for f in range(8):
				await get_tree().process_frame
			camera.snap()
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var path := abs_out.path_join("%s_%d.png" % [id, k])
			img.save_png(path)
		var draws := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		print("ROOM %s size=%dx%d build_ms=%.1f draws=%d enemies=%d" % [id, r.cols, r.rows, build_ms, draws, rooms.enemies().size()])
	get_tree().quit()
