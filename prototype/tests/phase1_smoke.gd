extends SceneTree

const Scenario := preload("res://phase1.tscn")
var game: Node3D
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = Scenario.instantiate()
	root.add_child(game)
	await _frames(30)
	_expect(game.player.is_on_floor(), "player settles on the starting street")
	_expect(not game.driving, "starts on foot")
	await _tap(&"interact")
	_expect(not game.driving, "interaction out of reach is ignored")
	var start: Vector3 = game.player.position
	await _hold(&"move_forward", 54)
	_expect(game.player.position.z < start.z - 1.5, "keyboard movement approaches car")
	await _tap(&"interact")
	_expect(game.driving and not game.player.visible and game.car.driver_active, "enter transfers control once")
	var parked: Vector3 = game.car.position
	await _hold(&"move_forward", 90)
	_expect(game.car.position.z < parked.z - 4.0 and game.car.get_speed_mps() > 2.0, "car accelerates forward")
	await _tap(&"interact")
	_expect(game.driving, "exit is refused while moving")
	await _hold(&"brake", 76)
	_expect(game.car.get_speed_mps() < 0.20, "brake stops the car")
	var stopped: Vector3 = game.car.position
	await _hold(&"move_back", 30)
	_expect(game.car.position.z > stopped.z + 0.45, "car reverses after stopping")
	await _hold(&"brake", 35)
	var left := _block_exit(-1.0)
	var right := _block_exit(1.0)
	await _frames(3)
	await _tap(&"interact")
	_expect(game.driving, "occupied exit spaces keep the player in the car")
	right.queue_free()
	await _frames(3)
	await _tap(&"interact")
	_expect(not game.driving and game.player.visible and not game.car.driver_active, "exit transfers back to walking")
	var exit_delta: Vector3 = game.player.position - game.car.position
	var side_axis: Vector3 = game.car.global_basis.x
	_expect(exit_delta.dot(side_axis) > 1.0, "second-side exit succeeds when first side is blocked")
	left.queue_free()
	await _tap(&"recover")
	_expect(not game.driving and absf(game.car.position.z) < 0.1 and absf(game.player.position.z - 5.0) < 0.1, "reset restores both actors")
	_check_route_clearance()
	await _check_ramp()
	await _check_rickshaw()
	if game.hud.touch_enabled:
		await _check_touch()
		await _check_touch_rickshaw()
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		_expect(screenshot.save_png("user://phase1-preview.png") == OK, "preview PNG saved")
		print("Preview: ", ProjectSettings.globalize_path("user://phase1-preview.png"))
	print("Phase 1 smoke: ", failures, " failures")
	quit(0 if failures == 0 else 1)


func _check_route_clearance() -> void:
	var road_clear := true
	for points: PackedVector3Array in game.world._roads:
		for index in range(points.size() - 1):
			var segment := points[index + 1] - points[index]
			var heading := atan2(-segment.x, -segment.z)
			var pose := Transform3D(Basis(Vector3.UP, heading), points[index] + Vector3.UP * 0.57)
			if game.car.test_move(pose, segment):
				road_clear = false
	_expect(road_clear, "car shape clears all 21 road centerline segments")
	var path: PackedVector3Array = game.world._gully
	var footway_clear := true
	for index in range(path.size() - 1):
		var pose := Transform3D(Basis.IDENTITY, path[index] + Vector3.UP * 0.05)
		if game.player.test_move(pose, path[index + 1] - path[index]):
			footway_clear = false
	_expect(footway_clear, "walker shape clears all four footway segments")


func _check_ramp() -> void:
	game.car.reset_to(Transform3D(Basis.IDENTITY, Vector3(-31, 0.55, -20)))
	game.car.set_driver_active(true)
	game.player.set_on_foot(false)
	game.active_vehicle = game.car
	await _hold(&"move_forward", 160)
	_expect(game.car.position.y > 1.35 and game.car.position.z < -43.0, "car climbs the handling ramp to the deck")
	await _tap(&"recover")


func _check_rickshaw() -> void:
	var parked: Vector3 = game.rickshaw.global_position
	var collision := KinematicCollision3D.new()
	var probe := Transform3D(Basis.IDENTITY, parked + Vector3(0.0, 0.07, 4.0))
	var hit_vehicle: bool = game.car.test_move(probe, Vector3(0.0, 0.0, -4.0), collision)
	_expect(hit_vehicle and collision.get_collider() == game.rickshaw, "parked vehicles collide with each other")
	game.player.global_position = Vector3(parked.x, 0.04, parked.z + 2.4)
	await _frames(6)
	await _tap(&"interact")
	_expect(game.active_vehicle == game.rickshaw and game.rickshaw.driver_active and not game.car.driver_active, "nearest auto-rickshaw takes control while the car stays parked")
	await _hold(&"move_forward", 72)
	_expect(game.rickshaw.position.z < parked.z - 2.5 and game.rickshaw.get_speed_mps() > 1.8, "auto-rickshaw accelerates")
	var heading: float = game.rickshaw.rotation.y
	Input.action_press(&"move_forward")
	await _hold(&"move_right", 18)
	Input.action_release(&"move_forward")
	_expect(absf(angle_difference(heading, game.rickshaw.rotation.y)) > 0.12 and game.rickshaw.global_basis.y.dot(Vector3.UP) > 0.99, "auto-rickshaw turns and remains upright")
	await _tap(&"interact")
	_expect(game.active_vehicle == game.rickshaw, "moving auto-rickshaw cannot be exited")
	await _hold(&"brake", 70)
	_expect(game.rickshaw.get_speed_mps() < 0.2, "auto-rickshaw brakes to a halt")
	await _tap(&"interact")
	_expect(not game.driving and game.player.visible, "stopped auto-rickshaw can be exited")
	await _tap(&"recover")
	var centered: Vector2 = Vector2(game.rickshaw.position.x, game.rickshaw.position.z)
	_expect(centered.distance_to(Vector2(parked.x, parked.z)) < 0.1 and absf(game.car.position.z) < 0.1 and not game.driving, "reset parks both vehicles at their original bays")


func _check_touch() -> void:
	var camera_start: Vector3 = game.camera.position
	var stick: Vector2 = game.hud._stick_center()
	var look_point := Vector2(790.0, 420.0)
	var surface: Control = game.hud._touch_surface
	_touch(surface, 0, stick - Vector2(0, 48), true)
	_touch(surface, 1, look_point, true)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = look_point + Vector2(35, 0)
	drag.relative = Vector2(35, 0)
	root.push_input(drag, true)
	await _frames(8)
	_expect(game.hud.move_axis.y < -0.4 and game.camera.position.distance_to(camera_start) > 0.12, "separate touch IDs can move and look together")
	_touch(surface, 1, look_point, false)
	_expect(game.hud.move_axis.y < -0.4, "lifting look finger leaves movement active")
	_touch(surface, 0, stick - Vector2(0, 48), false)
	_expect(game.hud.move_axis == Vector2.ZERO, "lifting move finger stops touch input")
	var reset_button: Rect2 = game.hud._button_rect(2)
	_touch(surface, 2, reset_button.get_center(), true)
	_touch(surface, 2, reset_button.get_center(), false)
	await _frames(4)
	_expect(absf(game.player.position.z - 5.0) < 0.1, "touch reset runs through the HUD signal")


func _check_touch_rickshaw() -> void:
	var parked: Vector3 = game.rickshaw.global_position
	game.player.global_position = Vector3(parked.x, 0.04, parked.z + 2.4)
	await _frames(6)
	var surface: Control = game.hud._touch_surface
	var interact: Vector2 = game.hud._button_rect(0).get_center()
	_touch(surface, 3, interact, true)
	_touch(surface, 3, interact, false)
	await _frames(4)
	_expect(game.active_vehicle == game.rickshaw, "touch Interact selects the auto-rickshaw")
	var stick: Vector2 = game.hud._stick_center() - Vector2(0, 52)
	_touch(surface, 4, stick, true)
	await _frames(58)
	_expect(game.rickshaw.position.z < parked.z - 1.0, "touch stick drives the auto-rickshaw")
	var brake: Vector2 = game.hud._button_rect(1).get_center()
	_touch(surface, 5, brake, true)
	await _frames(65)
	_expect(game.hud.move_axis.y < -0.4 and game.rickshaw.get_speed_mps() < 0.2, "second touch brakes while throttle is held")
	_touch(surface, 4, stick, false)
	_touch(surface, 5, brake, false)
	var reset_button: Vector2 = game.hud._button_rect(2).get_center()
	_touch(surface, 6, reset_button, true)
	_touch(surface, 6, reset_button, false)
	await _frames(4)
	_expect(not game.driving and absf(game.rickshaw.position.z) < 0.1, "touch reset returns the auto-rickshaw to its bay")


func _touch(surface: Control, index: int, point: Vector2, pressed: bool) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = index
	touch.position = surface.get_global_transform_with_canvas() * point
	touch.pressed = pressed
	root.push_input(touch, true)


func _block_exit(side: float) -> StaticBody3D:
	var box := StaticBody3D.new()
	box.position = game.car.global_position + game.car.global_basis.x * (1.48 * side) + Vector3.UP * 0.54
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.85, 2.0, 0.85)
	collision.shape = shape
	box.add_child(collision)
	game.add_child(box)
	return box


func _hold(action: StringName, ticks: int) -> void:
	Input.action_press(action)
	await _frames(ticks)
	Input.action_release(action)
	await _frames(2)


func _tap(action: StringName) -> void:
	await _hold(action, 1)


func _frames(ticks: int) -> void:
	for tick in range(ticks):
		await physics_frame


func _expect(condition: bool, description: String) -> void:
	if condition:
		print("PASS ", description)
	else:
		failures += 1
		printerr("FAIL ", description)
