extends SceneTree
## Render a cut-out rig in its clips to one sheet (story 029): every clip in a row of frames,
## so a pose can be judged without playing the game.
##
##   godot --path . -s tools/art/rig_preview.gd -- caelan [frames_per_clip] [clip,clip,...]
##
## Writes `builds/art/rig_<id>_poses.png`. Needs a window (not --headless): it renders.

const CELL := 360
const PAD_M := 0.35

var _id: String
var _frames: int = 5
var _bodies: Array[RigBody] = []
var _times: Array[float] = []
var _clips: Array[String] = []
var _wait: int = 0
var _vp: SubViewport


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_id = args[0] if args.size() > 0 else "caelan"
	if args.size() > 1:
		_frames = int(args[1])
	var probe := SpriteBody.create(_id) as RigBody
	if probe == null:
		push_error("rig_preview: %s has no rig" % _id)
		quit(1)
		return
	var names: Array = probe.clips.keys()
	if args.size() > 2:
		names = Array(args[2].split(","))
	probe.free()
	var cols := _frames
	var rows := names.size()
	_vp = SubViewport.new()
	_vp.size = Vector2i(CELL * cols, CELL * rows)
	_vp.transparent_bg = false
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.17, 0.2)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.85)
	env.environment = e
	_vp.add_child(env)
	var h := probe_height()
	var cell_m := h * (1.0 + PAD_M)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = cell_m * rows
	cam.position = Vector3(cell_m * cols * 0.5, -cell_m * rows * 0.5, 10.0)
	_vp.add_child(cam)
	for r in range(rows):
		var clip := str(names[r])
		for c in range(cols):
			var b := SpriteBody.create(_id) as RigBody
			_vp.add_child(b)
			b.position = Vector3(cell_m * (c + 0.5), -cell_m * (r + 0.5) - h * 0.5, 0.0)
			_bodies.append(b)
			_times.append(float(c) / float(maxi(cols - 1, 1)))
			_clips.append(clip)
	print("rig_preview: %s rows = %s" % [_id, ", ".join(names)])


func probe_height() -> float:
	var b := SpriteBody.create(_id)
	var h := b.height_m
	b.free()
	return h


func _process(_delta: float) -> bool:
	# Pose every body directly at its time (no blending), then grab a frame.
	for i in range(_bodies.size()):
		_bodies[i].pose_now(_clips[i], _times[i])
	_wait += 1
	if _wait < 4:
		return false
	var img := _vp.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/art"))
	img.save_png(ProjectSettings.globalize_path("res://builds/art/rig_%s_poses.png" % _id))
	print("rig_preview: rows %s" % ", ".join(_clips.slice(0, _clips.size(), _frames)))
	print("rig_preview: wrote builds/art/rig_%s_poses.png" % _id)
	return true
