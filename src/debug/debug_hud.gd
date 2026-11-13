class_name DebugHud
extends CanvasLayer
## Debug overlay (story 013), toggled by `debug_hud` (F3). FPS, frame time, draw calls,
## primitives, pipeline compilations (the hitch monitor from the cheat sheet), memory, and live
## combat numbers: player state, Vessel, stamina, posture, gauge, enemies, music state.
## Visible by default in debug builds.

var sandbox: Node

var _label: Label
var _panel: ColorRect
var _accum: float = 0.0


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	_panel.color = Color(0, 0, 0, 0.5)
	_panel.position = Vector2(560, 12)
	_panel.size = Vector2(560, 210)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)
	_label = Label.new()
	_label.position = Vector2(572, 18)
	_label.add_theme_font_size_override("font_size", 15)
	_label.add_theme_color_override("font_color", Color(0.85, 1.0, 0.85))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	visible = OS.is_debug_build()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_hud"):
		visible = not visible


func _process(delta: float) -> void:
	_accum += delta
	if not visible or _accum < 0.2:
		return
	_accum = 0.0
	_label.text = text()


## The overlay text (also returned by the bridge's get_state as `debug`).
func text() -> String:
	var lines: PackedStringArray = []
	lines.append("%s %d  |  %.2f ms  |  draws %d  prims %d" % [tr("DEBUG_FPS"),
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)])
	lines.append("pipelines mesh %d surf %d draw %d  |  mem %.0f MB  vram %.0f MB" % [
		Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_MESH),
		Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_SURFACE),
		Performance.get_monitor(Performance.PIPELINE_COMPILATIONS_DRAW),
		Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0])
	var player: Player = sandbox.get("player") if sandbox != null else null
	if player != null:
		var s := player.snapshot()
		lines.append("player %s  x %.1f y %.1f  vessel %s  hp %.0f/%.0f" % [s["state"], s["x"], s["y"],
			s["vessel"], s["hp"], s["hp_max"]])
		lines.append("stamina %.0f%s  posture %.0f  gauge %.0f (%d bars)  swap cd %.2f  inv %s" % [s["stamina"],
			" EXHAUSTED" if s["exhausted"] else "", s["posture"], s["gauge"], s["bars"], s["swap_cd"], s["invulnerable"]])
	if sandbox != null and sandbox.has_method("enemies"):
		var list: Array = sandbox.call("enemies")
		var parts: PackedStringArray = []
		for e: EnemyBase in list:
			parts.append("%s:%s %.0f/%.0f p%.0f" % [e.enemy_id.get_slice("_", 0), e.state, e.health.current,
				e.health.max_value, e.posture.value])
		lines.append("enemies %d  %s" % [list.size(), ", ".join(parts)])
	lines.append("music %s%s  t %.1f  wave %s" % [MusicDirector.state,
		(" -> " + MusicDirector.pending_state) if MusicDirector.pending_state != "" else "",
		MusicDirector.song_time(), str(sandbox.get("wave_index")) if sandbox != null else "-"])
	return "\n".join(lines)
