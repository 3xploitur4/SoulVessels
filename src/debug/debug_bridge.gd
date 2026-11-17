class_name DebugBridge
extends Node
## Command handler behind the playtest bridge (story 013). The kit's `Bridge` node speaks
## newline JSON over 127.0.0.1:9177 (or BRIDGE_PORT) and calls `run_command` here. Enabled in
## debug builds or with `--bridge`. Drive it with `tools/mcp/bridge_client.py` or the kit's MCP
## server.
##
## Commands:
##   ping                          -> {"pong": true}
##   get_state                     -> player, enemies, music, fps, wave
##   get_value {key}               -> a Balance value by dotted path ("combat.stamina.dodge_cost")
##   set_value {key, value}        -> live tuning (memory only)
##   sim_input {action, seconds}   -> hold an input action for `seconds` (0 = one tap)
##   press {action} / release {action}
##   axis {x, y}                   -> set the touch-joystick axis (bots steer with it)
##   touch {x, y, pressed, index} / drag {x, y, index}  -> real screen-touch events (window pixels)
##   joypad {button}               -> a real gamepad button press + release
##   screenshot {path}             -> PNG of the next frame, path relative to the project root
##   window_size {size}            -> get or set [w, h]
##   spawn {enemy_id, x}           -> spawn an enemy
##   kill_all                      -> clear enemies (and stop waves)
##   set_vessel {id}               -> free swap to a Vessel in the loadout
##   swap {index}                  -> normal swap (cooldown + Resonance Strike)
##   teleport {x, y}
##   gauge {value}                 -> set the Soul Gauge
##   heal                          -> full HP
##   set_hp {hp} / set_stamina {value}
##   music_state {state}           -> force a music state ("" = automatic)
##   wait {seconds}                -> real-time wait (frames keep running)
##   rng_sample {n, reseed}        -> sample the global RNG (determinism checks)
##   quit

var sandbox: Node


func run_command(cmd: String, args: Dictionary) -> Variant:
	# Host-specific commands (the game scene's runs, rooms and menus): `bridge_<cmd>(args)`.
	if sandbox.has_method("bridge_" + cmd):
		return await sandbox.call("bridge_" + cmd, args)
	var player: Player = sandbox.get("player")
	if player == null and cmd not in ["ping", "get_state", "get_value", "set_value", "screenshot", "window_size", "debug_overlay",
			"wait", "rng_sample", "quit", "press", "release", "touch", "drag", "joypad", "sim_input"]:
		return {"error": "no player (title screen?)"}
	match cmd:
		"ping":
			return {"pong": true, "frame": Engine.get_physics_frames()}
		"get_state":
			return _state()
		"get_value":
			return {"key": args.get("key", ""), "value": Balance.get_value(str(args.get("key", "")))}
		"set_value":
			var ok := Balance.set_value(str(args.get("key", "")), args.get("value"))
			return {"ok": ok} if ok else {"error": "unknown key %s" % args.get("key", "")}
		"sim_input":
			var action := str(args.get("action", ""))
			if not InputMap.has_action(action):
				return {"error": "unknown action %s" % action}
			Input.action_press(action)
			var seconds := float(args.get("seconds", 0.0))
			if seconds > 0.0:
				await get_tree().create_timer(seconds, true, false, true).timeout
			else:
				await get_tree().physics_frame
				await get_tree().physics_frame
			Input.action_release(action)
			await get_tree().physics_frame
			return {"action": action, "seconds": seconds}
		"press":
			Input.action_press(str(args.get("action", "")))
			return {"ok": true}
		"release":
			Input.action_release(str(args.get("action", "")))
			return {"ok": true}
		"touch":
			# A real screen touch through the input pipeline (touch UI, device switching).
			var t := InputEventScreenTouch.new()
			t.index = int(args.get("index", 0))
			t.position = Vector2(float(args.get("x", 0.0)), float(args.get("y", 0.0)))
			t.pressed = bool(args.get("pressed", true))
			Input.parse_input_event(t)
			await get_tree().process_frame
			return {"ok": true}
		"drag":
			var d := InputEventScreenDrag.new()
			d.index = int(args.get("index", 0))
			d.position = Vector2(float(args.get("x", 0.0)), float(args.get("y", 0.0)))
			Input.parse_input_event(d)
			await get_tree().process_frame
			return {"ok": true}
		"joypad":
			# A real gamepad button press and release (hides the touch UI).
			var j := InputEventJoypadButton.new()
			j.button_index = int(args.get("button", JOY_BUTTON_A)) as JoyButton
			j.pressed = true
			Input.parse_input_event(j)
			await get_tree().process_frame
			j = j.duplicate() as InputEventJoypadButton
			j.pressed = false
			Input.parse_input_event(j)
			await get_tree().process_frame
			return {"device": (sandbox.get("input_router") as InputRouter).device}
		"axis":
			var router: InputRouter = sandbox.get("input_router")
			router.touch_axis = Vector2(float(args.get("x", 0.0)), float(args.get("y", 0.0)))
			return {"axis": [router.touch_axis.x, router.touch_axis.y]}
		"screenshot":
			return await _screenshot(str(args.get("path", "shots/screenshot.png")))
		"window_size":
			var size: Variant = args.get("size")
			if size is Array and (size as Array).size() == 2:
				DisplayServer.window_set_size(Vector2i(int(size[0]), int(size[1])))
				await get_tree().process_frame
			var s := DisplayServer.window_get_size()
			return {"size": [s.x, s.y]}
		"spawn":
			var e: EnemyBase = sandbox.call("spawn", str(args.get("enemy_id", "echo_crawler")), float(args.get("x", 5.0)))
			return {"error": "unknown enemy"} if e == null else {"name": e.name, "x": e.global_position.x}
		"kill_all":
			sandbox.set("waves_enabled", false)
			sandbox.call("kill_all")
			await get_tree().process_frame
			return {"ok": true}
		"set_vessel":
			var idx := player.loadout.index_of(str(args.get("id", "")))
			if idx < 0:
				return {"error": "vessel not in loadout"}
			player.try_swap(idx, true)
			return {"vessel": player.loadout.active().id}
		"swap":
			return {"swapped": player.try_swap(int(args.get("index", 1))), "vessel": player.loadout.active().id}
		"teleport":
			player.teleport(float(args.get("x", 0.0)), float(args.get("y", 0.2)))
			return {"ok": true}
		"gauge":
			player.gauge.value = 0.0
			player.gauge.add(float(args.get("value", 300.0)))
			return {"gauge": player.gauge.value}
		"heal":
			player.health.reset()
			return {"hp": player.health.current}
		"set_hp":
			player.health.current = clampf(float(args.get("hp", 1.0)), 1.0, player.health.max_value)
			GameEvents.player_hp_changed.emit(player.health.current, player.health.max_value)
			return {"hp": player.health.current}
		"kill_player":
			player.kill()
			return {"dead": not player.is_alive()}
		"water":
			# Pour a pool into the current room, or move an existing one's surface (story 031).
			var rm: RoomManager = sandbox.get("rooms")
			if rm == null:
				return {"error": "no rooms"}
			var wid := str(args.get("id", "debug_pool"))
			var w := rm.water(wid)
			if w == null:
				w = Water.new()
				w.name = "Water_" + wid
				var xs: Array = args.get("x", [4, 12])
				w.setup(wid, Vector2(float(xs[0]), float(xs[1])), float(args.get("floor", 0.0)),
					float(args.get("level", 1.0)))
				rm.features_root.add_child(w)
			elif args.has("to"):
				w.rise_to(float(args.get("to")), float(args.get("seconds", 0.0)))
			return {"id": wid, "level": w.level, "patches": w.patches.size()}
		"mirror":
			# Stand a mirror-shield in the current room (story 032 playtests).
			var rmm: RoomManager = sandbox.get("rooms")
			var m := MirrorShield.new()
			m.name = "DebugMirror"
			m.player = player
			m.angle = float(args.get("angle", 135.0))
			rmm.features_root.add_child(m)
			m.global_position = Vector3(float(args.get("x", 5.0)), float(args.get("y", 1.0)), 0.0)
			return {"angle": m.angle}
		"runes":
			var rmr: RoomManager = sandbox.get("rooms")
			var pz := rmr.features_root.get_node_or_null("RunePuzzle") as RunePuzzle
			if pz == null:
				return {"error": "no rune puzzle here"}
			return {"lit": pz.sequence.lit_count(), "size": pz.sequence.size(), "solved": pz.sequence.solved,
				"door": rmr.builder.gate_active(pz.door_kind)}
		"boss":
			# Set the boss's health to a fraction and strike it once, so a playtest can walk its phases.
			for e: EnemyBase in sandbox.call("enemies"):
				if e is Boss:
					var bb := e as Boss
					bb.boundary_source = func(_a: float) -> float: return -1.0
					if args.has("fraction"):
						bb.health.current = maxf(bb.health.max_value * float(args["fraction"]), 1.0)
						var hit := DamagePacket.new()
						hit.atk = float(args.get("strike", 50.0))
						hit.source_x = bb.global_position.x - 2.0
						bb.receive_hit(hit)
					return {"phase": bb.phase, "hp": bb.health.current, "transition": bb.in_transition(),
						"state": bb.state, "attack": str(bb.current_attack.get("id", "")),
						"rocks": int(bb.get("rocks_rolled")) if bb.get("rocks_rolled") != null else 0}
			return {"error": "no boss"}
		"essence":
			var gst: GameState = sandbox.get("state")
			if gst == null:
				return {"error": "no game state"}
			gst.essence = int(args.get("value", gst.essence))
			return {"essence": gst.essence}
		"dark":
			# Darken the current room (story 043 playtests); lamps: [[x, y], ...].
			var rmd: RoomManager = sandbox.get("rooms")
			if rmd.darkness == null:
				rmd.darkness = Darkness.new()
				rmd.darkness.player = player
				rmd.features_root.add_child(rmd.darkness)
			for xy: Array in args.get("lamps", []):
				rmd.darkness.lamps.append(Vector3(float(xy[0]), float(xy[1]), 0.0))
			rmd.darkness.fade(1.0 if bool(args.get("on", true)) else 0.0, 0.0)
			return {"dark": rmd.darkness.amount, "lamps": rmd.darkness.lamps.size()}
		"slide":
			var rms: RoomManager = sandbox.get("rooms")
			var z := SlideZone.new()
			var xs: Array = args.get("x", [4, 16])
			var ys: Array = args.get("y", [1.5, 3.0])
			z.setup(Vector2(float(xs[0]), float(xs[1])), Vector2(float(ys[0]), float(ys[1])), float(args.get("angle", 15.0)))
			rms.features_root.add_child(z)
			return {"angle": z.angle}
		"root_player":
			player.snare.apply()
			return {"rooted": player.snare.is_active()}
		"set_affinity":
			var vid := str(args.get("id", player.loadout.active().id))
			player.set_affinity(vid, int(args.get("level", 3)))
			return {"vessel": vid, "level": int(args.get("level", 3))}
		"set_stamina":
			player.loadout.active().stamina.value = float(args.get("value", 100.0))
			return {"stamina": player.loadout.active().stamina.value}
		"music_state":
			MusicDirector.force_state(str(args.get("state", "")))
			return {"state": MusicDirector.state, "pending": MusicDirector.pending_state}
		"wait":
			await get_tree().create_timer(float(args.get("seconds", 1.0)), true, false, true).timeout
			return {"frame": Engine.get_physics_frames()}
		"rng_sample":
			if bool(args.get("reseed", false)):
				seed(12345)
			var out: Array[float] = []
			for i in range(int(args.get("n", 4))):
				out.append(randf())
			return {"values": out}
		"debug_overlay":
			var dh: Node = sandbox.get("debug_hud")
			if dh != null:
				(dh as CanvasLayer).visible = bool(args.get("on", false))
			return {"ok": true}
		"quit":
			get_tree().quit.call_deferred()
			return {"ok": true}
	return {"error": "unknown command %s" % cmd}


func _state() -> Dictionary:
	var player: Player = sandbox.get("player")
	if player == null:
		return {"frame": Engine.get_physics_frames(), "fps": Engine.get_frames_per_second(), "player": null,
			"title": sandbox.get("title") != null, "music": {"state": MusicDirector.state, "zone": MusicDirector.zone}}
	var list: Array = []
	for e: EnemyBase in sandbox.call("enemies"):
		list.append(e.snapshot())
	var debug_hud: DebugHud = sandbox.get("debug_hud")
	return {
		"frame": Engine.get_physics_frames(),
		"fps": Engine.get_frames_per_second(),
		"player": player.snapshot(),
		"enemies": list,
		"music": {"zone": MusicDirector.zone, "state": MusicDirector.state, "pending": MusicDirector.pending_state,
			"vessel": MusicDirector.vessel, "t": snappedf(MusicDirector.song_time(), 0.01),
			"playing": MusicDirector.is_playing(), "history": MusicDirector.history,
			"drift": snappedf(MusicDirector.clock_drift(), 0.001),
			"stems": {"bed": MusicDirector.stem_db("bed"), "pulse": MusicDirector.stem_db("pulse"),
				"combat": MusicDirector.stem_db("combat"), "elite": MusicDirector.stem_db("elite"),
				"lead_caelan": MusicDirector.stem_db("lead_caelan"), "lead_nyra": MusicDirector.stem_db("lead_nyra")}},
		"wave": sandbox.get("wave_index"),
		"touch_visible": (sandbox.get("touch") as CanvasLayer).visible if sandbox.get("touch") != null else false,
		"sfx": Sfx.play_counts,
		"debug": debug_hud.text() if debug_hud != null else "",
	}


func _screenshot(path: String) -> Dictionary:
	var full := path if path.is_absolute_path() else ProjectSettings.globalize_path("res://").path_join(path)
	DirAccess.make_dir_recursive_absolute(full.get_base_dir())
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(full)
	if err != OK:
		return {"error": "save failed %d" % err}
	return {"path": full, "size": [img.get_width(), img.get_height()]}
