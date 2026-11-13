class_name Hud
extends CanvasLayer
## In-game HUD (story 011), drawn in code in the corners so the centre 60 % stays clear
## (addendum "UI"). Top-left: soul HP, flask pips, Soul Gauge in 3 segments. Top-right: the
## 3-Vessel swap wheel (stamina ring, swap cooldown arc, Sync-Guard-ready glow), tappable in
## touch mode. Over enemies: HP and posture bars for elites, HP for hurt commons, and the
## Riposte prompt over a staggered enemy in reach. Always visible, gamepad or touch.
##
##     var hud := Hud.new()
##     hud.player = player; hud.world = world; hud.camera = camera
##     add_child(hud)

const COL_HP := Color(0.78, 0.16, 0.2)
const COL_HP_BACK := Color(0.12, 0.05, 0.06, 0.85)
const COL_GAUGE := Color(0.44, 0.83, 0.91)
const COL_GAUGE_FULL := Color(0.75, 0.95, 1.0)
const COL_STAMINA := Color(0.55, 0.85, 0.35)
const COL_POSTURE := Color(0.95, 0.75, 0.25)
const COL_FRAME := Color(0.85, 0.82, 0.75, 0.9)
const COL_PANEL := Color(0.02, 0.03, 0.05, 0.55)
const VESSEL_COLORS := {
	"caelan": Color(0.18, 0.37, 0.82), "nyra": Color(0.42, 0.27, 0.62),
	"seris": Color(0.85, 0.82, 0.7), "darius": Color(0.85, 0.45, 0.17), "ilyr": Color(0.9, 0.9, 0.95),
}

var player: Player
## The run's save state (Essence counter); null in the sandbox.
var state: GameState
var world: CombatWorld
var camera: Camera3D

var _canvas: Control
var _font: Font
var _wheel_centres: Array[Vector2] = []
var _wheel_radius: float = 46.0
var _scratch: Array[Node3D] = []


func _ready() -> void:
	layer = 5
	_font = ThemeDB.fallback_font
	_canvas = Control.new()
	_canvas.name = "HudCanvas"
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_hud)
	add_child(_canvas)


func _process(_delta: float) -> void:
	_canvas.queue_redraw()


## Tap on a wheel portrait swaps to that Vessel (touch mode).
func _input(event: InputEvent) -> void:
	if player == null:
		return
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		var pos := (event as InputEventScreenTouch).position
		pos = _canvas.get_global_transform_with_canvas().affine_inverse() * pos
		for i in range(_wheel_centres.size()):
			if pos.distance_to(_wheel_centres[i]) <= _wheel_radius:
				if i != player.loadout.active_index:
					player.try_swap(i)
				get_viewport().set_input_as_handled()
				return


## Screen rect inside the safe area (notch, gesture bar), in canvas coordinates.
func safe_rect() -> Rect2:
	var size := _canvas.size
	var margin := Vector2(28.0, 22.0)
	var safe := DisplayServer.get_display_safe_area()
	var win := DisplayServer.window_get_size()
	if OS.has_feature("mobile") and win.x > 0 and win.y > 0:
		var sx := size.x / float(win.x)
		var sy := size.y / float(win.y)
		var left := float(safe.position.x) * sx
		var top := float(safe.position.y) * sy
		var right := (float(win.x) - float(safe.end.x)) * sx
		var bottom := (float(win.y) - float(safe.end.y)) * sy
		return Rect2(Vector2(left, top) + margin, size - Vector2(left + right, top + bottom) - margin * 2.0)
	return Rect2(margin, size - margin * 2.0)


func _draw_hud() -> void:
	if player == null:
		return
	var r := safe_rect()
	_draw_vitals(r.position)
	_draw_wheel(Vector2(r.end.x, r.position.y))
	_draw_enemy_bars()
	if player.state == "dead":
		var msg := tr("UI_SOUL_LOST")
		var w := _font.get_string_size(msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 48).x
		_canvas.draw_string_outline(_font, Vector2(_canvas.size.x * 0.5 - w * 0.5, _canvas.size.y * 0.4), msg,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 48, 8, Color.BLACK)
		_canvas.draw_string(_font, Vector2(_canvas.size.x * 0.5 - w * 0.5, _canvas.size.y * 0.4), msg,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(0.9, 0.85, 0.8))


func _draw_vitals(origin: Vector2) -> void:
	var hp_w := 420.0
	_canvas.draw_rect(Rect2(origin - Vector2(10, 8), Vector2(hp_w + 20, 112)), COL_PANEL)
	# HP bar.
	var hp_rect := Rect2(origin, Vector2(hp_w, 24))
	_canvas.draw_rect(hp_rect, COL_HP_BACK)
	_canvas.draw_rect(Rect2(origin, Vector2(hp_w * player.health.ratio(), 24)), COL_HP)
	_canvas.draw_rect(hp_rect, COL_FRAME, false, 2.0)
	var hp_text := "%d / %d" % [int(ceilf(player.health.current)), int(player.health.max_value)]
	_canvas.draw_string(_font, origin + Vector2(10, 19), hp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 1, 1, 0.9))
	# Flask pips: small vials.
	for i in range(player.flask_max()):
		var p := origin + Vector2(hp_w - 70.0 + 24.0 * float(i), 32.0)
		var full := i < player.flask_charges
		_draw_vial(p, full)
	# Soul Gauge: three segments.
	var seg_w := 120.0
	var gap := 8.0
	var gy := origin.y + 62.0
	for i in range(3):
		var seg := Rect2(Vector2(origin.x + float(i) * (seg_w + gap), gy), Vector2(seg_w, 16))
		var fill := clampf((player.gauge.value - float(i) * player.gauge.bar_size) / player.gauge.bar_size, 0.0, 1.0)
		_canvas.draw_rect(seg, Color(0.05, 0.1, 0.12, 0.9))
		_canvas.draw_rect(Rect2(seg.position, Vector2(seg_w * fill, 16)), COL_GAUGE_FULL if fill >= 1.0 else COL_GAUGE)
		_canvas.draw_rect(seg, COL_FRAME, false, 1.5)
	_canvas.draw_string(_font, Vector2(origin.x, gy + 38), tr("HUD_SOUL_GAUGE"), HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
		Color(0.75, 0.9, 0.95, 0.85))
	if state != null:
		# Soul Essence: a small soul-light diamond and the carried amount.
		var ep := Vector2(origin.x + 3.0 * (seg_w + gap) + 6.0, gy + 8.0)
		var d := PackedVector2Array([ep + Vector2(0, -9), ep + Vector2(7, 0), ep + Vector2(0, 9), ep + Vector2(-7, 0)])
		_canvas.draw_colored_polygon(d, COL_GAUGE_FULL)
		_canvas.draw_string(_font, ep + Vector2(14, 8), str(state.essence), HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
			Color(0.85, 0.95, 1.0))


func _draw_vial(p: Vector2, full: bool) -> void:
	var body := PackedVector2Array([p + Vector2(-7, 4), p + Vector2(7, 4), p + Vector2(9, 22), p + Vector2(-9, 22)])
	_canvas.draw_colored_polygon(body, Color(0.4, 0.85, 0.95, 0.95) if full else Color(0.15, 0.18, 0.2, 0.8))
	_canvas.draw_rect(Rect2(p + Vector2(-4, -2), Vector2(8, 6)), COL_FRAME)


func _draw_wheel(top_right: Vector2) -> void:
	var lo := player.loadout
	_wheel_centres.clear()
	var centre := top_right + Vector2(-150.0, 90.0)
	_canvas.draw_circle(centre, 118.0, COL_PANEL)
	var n := lo.size()
	for i in range(n):
		var ang := -PI * 0.5 + TAU * float(i - lo.active_index) / float(maxi(n, 1))
		var active := i == lo.active_index
		var radius := 0.0 if active else 72.0
		var pos := centre + Vector2(cos(ang), sin(ang)) * radius
		if active:
			pos = centre
		var rr := 50.0 if active else 34.0
		_wheel_centres.append(pos)
		var slot := lo.slots[i]
		var col: Color = VESSEL_COLORS.get(slot.id, Color.GRAY)
		# Sync Guard ready glow.
		var guard_ready := slot.affinity >= int(Balance.combat_f("sync_guard.min_affinity")) \
			and slot.sync_guard_left <= 0.0 and player.gauge.has_bars(1)
		if guard_ready:
			_canvas.draw_circle(pos, rr + 9.0, Color(0.6, 0.95, 1.0, 0.25 + 0.15 * sin(Time.get_ticks_msec() / 200.0)))
		_canvas.draw_circle(pos, rr, col.darkened(0.45))
		_draw_portrait(pos, rr * 0.8, slot.id, col)
		# Stamina ring.
		_canvas.draw_arc(pos, rr + 3.0, -PI * 0.5, -PI * 0.5 + TAU * slot.stamina.ratio(), 48,
			Color(0.9, 0.4, 0.3) if slot.stamina.is_exhausted() else COL_STAMINA, 5.0)
		if active:
			_canvas.draw_arc(pos, rr - 4.0, 0.0, TAU, 48, COL_FRAME, 2.0)
	# Swap cooldown sweep around the whole wheel.
	if lo.swap_cooldown_left > 0.0:
		var k := lo.swap_cooldown_left / maxf(lo.swap_cooldown_s, 0.01)
		_canvas.draw_arc(centre, 112.0, -PI * 0.5, -PI * 0.5 + TAU * k, 64, Color(1, 1, 1, 0.6), 4.0)
	_wheel_radius = 44.0


## A tiny emblem per Vessel: shield for Caelan, crossed blades for Nyra, a gem for the rest.
func _draw_portrait(c: Vector2, s: float, id: String, col: Color) -> void:
	var light := col.lightened(0.45)
	match id:
		"caelan":
			var pts := PackedVector2Array([c + Vector2(-0.55, -0.6) * s, c + Vector2(0.55, -0.6) * s,
				c + Vector2(0.5, 0.1) * s, c + Vector2(0.0, 0.7) * s, c + Vector2(-0.5, 0.1) * s])
			_canvas.draw_colored_polygon(pts, light)
			_canvas.draw_line(c + Vector2(0, -0.45) * s, c + Vector2(0, 0.45) * s, col.darkened(0.3), 3.0)
		"nyra":
			_canvas.draw_line(c + Vector2(-0.6, 0.6) * s, c + Vector2(0.6, -0.6) * s, light, 5.0)
			_canvas.draw_line(c + Vector2(0.6, 0.6) * s, c + Vector2(-0.6, -0.6) * s, light, 5.0)
		_:
			var pts := PackedVector2Array([c + Vector2(0, -0.6) * s, c + Vector2(0.5, 0) * s,
				c + Vector2(0, 0.6) * s, c + Vector2(-0.5, 0) * s])
			_canvas.draw_colored_polygon(pts, light)


func _draw_enemy_bars() -> void:
	if world == null or camera == null:
		return
	_scratch.clear()
	world.members_of(CombatWorld.TEAM_ENEMY, _scratch)
	for e in _scratch:
		var enemy := e as EnemyBase
		if enemy == null:
			continue
		var head := enemy.global_position + Vector3(0.0, enemy.hurt_rect().size.y + enemy._hurt_offset_y() + 0.35, 0.0)
		if camera.is_position_behind(head):
			continue
		var sp := camera.unproject_position(head)
		var elite := enemy.tier == "elite"
		var w := 150.0 if elite else 80.0
		var hurt := enemy.health.current < enemy.health.max_value
		if elite or hurt:
			var hp_r := Rect2(sp - Vector2(w * 0.5, 0), Vector2(w, 8))
			_canvas.draw_rect(hp_r, COL_HP_BACK)
			_canvas.draw_rect(Rect2(hp_r.position, Vector2(w * enemy.health.ratio(), 8)), COL_HP)
		if elite or enemy.posture.value > 0.0:
			var pr := Rect2(sp + Vector2(-w * 0.5, 12), Vector2(w, 6))
			_canvas.draw_rect(pr, Color(0.1, 0.08, 0.02, 0.8))
			# Posture fills from both ends to the middle, souls-like.
			var half := w * 0.5 * enemy.posture.ratio()
			_canvas.draw_rect(Rect2(pr.position + Vector2(w * 0.5 - half, 0), Vector2(half * 2.0, 6)), COL_POSTURE)
		if enemy.posture.is_staggered() and absf(enemy.global_position.x - player.global_position.x) < 3.5:
			var label := tr("UI_RIPOSTE")
			var tw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x
			var at := sp + Vector2(-tw * 0.5, -18)
			_canvas.draw_string_outline(_font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 6, Color.BLACK)
			_canvas.draw_string(_font, at, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color(1.0, 0.85, 0.35))
