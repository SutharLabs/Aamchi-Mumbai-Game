extends SceneTree

const Phase := preload("res://phase1.tscn")
const Daylight := preload("res://world/district_daylight.gd")

var _failures := 0
var _checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := Phase.instantiate()
	root.add_child(game)
	await _frames(12)
	var controller := game.get_node_or_null("DistrictDaylight") as Daylight
	_expect(controller != null, "the gameplay scene instantiates the district clock")
	if controller == null:
		quit(1)
		return
	var player: CharacterBody3D = game.player
	var animation: AnimationPlayer = player.visual.animation_player
	var start := player.global_position

	_key(KEY_D, true)
	await _frames(20)
	_expect(animation.current_animation == &"walk", "keyboard movement begins with the captured walk")
	_key(KEY_SHIFT, true)
	await _frames(20)
	var thigh: int = player.visual.skeleton.find_bone("LeftUpperLeg")
	var pose: Quaternion = player.visual.skeleton.get_bone_pose_rotation(thigh)
	await _frames(7)
	_expect(animation.current_animation == &"run" and player.get_real_velocity().length() > 2.7
		and absf(pose.dot(player.visual.skeleton.get_bone_pose_rotation(thigh))) < 0.999,
		"holding Shift plays a moving run cycle at the faster pace")
	await _capture("run-daylight-running.png")
	_key(KEY_SHIFT, false)
	_key(KEY_D, false)
	await _frames(18)
	_expect(animation.current_animation == &"idle", "releasing keyboard movement returns to idle")

	player.global_position = start
	_axis(1.0)
	_joy(JOY_BUTTON_X, true)
	await _frames(20)
	_expect(animation.current_animation == &"run" and player.get_real_velocity().length() > 2.7,
		"the default gamepad run binding plays the captured cycle")
	_axis(0.0)
	_joy(JOY_BUTTON_X, false)
	await _frames(16)

	if game.hud.touch_enabled:
		player.global_position = start
		var surface: Control = game.hud._touch_surface
		var center: Vector2 = game.hud._stick_center()
		_touch(surface, center + Vector2(36.0, 0.0), true)
		await _frames(20)
		_expect(not game.hud.run_held and animation.current_animation == &"walk",
			"the inner touch stick selects walking")
		_drag(surface, center + Vector2(70.0, 0.0))
		await _frames(20)
		_expect(game.hud.run_held and animation.current_animation == &"run",
			"dragging the touch stick to the edge selects the captured run")
		_drag(surface, center + Vector2(58.0, 0.0))
		await _frames(2)
		_expect(game.hud.run_held, "touch sprint stays engaged within its release band")
		_drag(surface, center + Vector2(40.0, 0.0))
		await _frames(16)
		_expect(not game.hud.run_held and animation.current_animation == &"walk",
			"dragging back inside the release band returns to walking")
		_touch(surface, center, false)
		await _frames(16)
		_expect(not game.hud.run_held and animation.current_animation == &"idle",
			"releasing the touch stick clears run input")

	var pedestrian: CharacterBody3D = game.pedestrians[0]
	pedestrian.hurry_for(1.0)
	await _frames(16)
	_expect(pedestrian.animation_player.current_animation == &"run",
		"a pedestrian can briefly use the shared run animation")
	await _frames(60)
	_expect(pedestrian.animation_player.current_animation == &"walk",
		"the pedestrian returns to the ordinary walking pace")

	controller.minutes_per_second = 0.0
	controller.set_time_minutes(720.0)
	var day := controller._sky_material.sky_top_color
	_expect(controller.clock_label() == "12:00" and controller._sun.light_energy > 0.95
		and controller._night_fill.light_energy < 0.01, "midday uses a sun and a daylight sky")
	controller.set_time_minutes(1080.0)
	_expect(controller._sky_material.sky_horizon_color.r > controller._sky_material.sky_horizon_color.b,
		"sunset uses a warm horizon")
	await _capture("run-daylight-dusk.png")
	controller.set_time_minutes(0.0)
	_expect(controller._sky_material.sky_top_color != day and controller._sun.light_energy < 0.01
		and controller._night_fill.light_energy > 0.20 and not controller._sun.shadow_enabled,
		"midnight has a dark sky and shadowless navigation fill")
	await _capture("run-daylight-night.png")
	controller.set_time_minutes(1439.9)
	controller.minutes_per_second = 60.0
	await _frames(4)
	_expect(controller.clock_label().begins_with("00:"), "the district clock advances and wraps after midnight")
	paused = true
	var frozen := controller.clock_label()
	await _frames(4)
	_expect(controller.clock_label() == frozen, "pausing the scene also pauses district time")
	paused = false
	print("%d passed, %d failed." % [_checks - _failures, _failures])
	quit(1 if _failures > 0 else 0)


func _key(keycode: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = keycode as Key
	event.pressed = pressed
	Input.parse_input_event(event)


func _joy(button: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)


func _axis(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)


func _touch(surface: Control, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 3
	event.position = surface.get_global_transform_with_canvas() * point
	event.pressed = pressed
	root.push_input(event, true)


func _drag(surface: Control, point: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = 3
	event.position = surface.get_global_transform_with_canvas() * point
	root.push_input(event, true)


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless" or "--capture" not in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_expect(image.save_png("user://" + filename) == OK, "capture " + filename)


func _frames(ticks: int) -> void:
	for tick in range(ticks):
		await physics_frame


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if condition:
		print("PASS ", description)
	else:
		_failures += 1
		printerr("FAIL ", description)
