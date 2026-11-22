extends SceneTree

const Scenario := preload("res://phase1.tscn")
var game: Node3D
var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = Scenario.instantiate()
	root.add_child(game)
	await _frames(30)
	_expect(game.player.is_on_floor(), "player settles on the starting street")
	_expect(not game.driving, "starts on foot")
	var hover_labels: int = game.world.find_children("*BayLabel", "Label3D", true, false).size()
	for actor: Node in [game.player, game.car, game.rickshaw, game.motorcycle, game.scooter] + game.pedestrians:
		for label: Label3D in actor.find_children("*", "Label3D", true, false):
			if label.is_visible_in_tree():
				hover_labels += 1
	_expect(hover_labels == 0, "actors and vehicle bays have no persistent hover labels")
	await _check_locomotion()
	await _check_pedestrians()
	await _tap(&"interact")
	_expect(not game.driving, "interaction out of reach is ignored")
	var start: Vector3 = game.player.position
	await _hold(&"move_forward", 124)
	_expect(game.player.position.z < start.z - 1.5, "keyboard movement approaches car")
	await _tap(&"interact")
	_expect(game.driving and not game.player.visible and game.car.driver_active, "enter transfers control once")
	_expect(not game.player.visual.animation_player.active, "walking animation pauses while driving")
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
	_expect(game.player.visual.animation_player.active and game.player.visual.animation_player.current_animation == &"idle", "exiting resumes on-foot idle")
	var exit_delta: Vector3 = game.player.position - game.car.position
	var side_axis: Vector3 = game.car.global_basis.x
	_expect(exit_delta.dot(side_axis) > 1.0, "second-side exit succeeds when first side is blocked")
	left.queue_free()
	await _tap(&"recover")
	_expect(not game.driving and absf(game.car.position.z) < 0.1 and absf(game.player.position.z - 5.0) < 0.1, "reset restores both actors")
	_check_route_clearance()
	await _check_ramp()
	await _check_street_curbs()
	await _check_yard_obstacles()
	await _check_rickshaw()
	_expect(game.motorcycle.rider.position.distance_to(game.scooter.rider.position) > 0.04, "motorcycle and scooter use distinct riding positions")
	await _check_two_wheeler(game.motorcycle, "motorcycle")
	await _check_two_wheeler(game.scooter, "scooter")
	if game.hud.touch_enabled:
		await _check_touch()
		await _check_touch_pedestrian()
		await _check_touch_rickshaw()
		await _check_touch_two_wheeler(game.motorcycle, "motorcycle")
		await _check_touch_two_wheeler(game.scooter, "scooter")
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
		# Presentation only: the assertions above still exercise the normal reset.
		game.player.global_position.x = (game.car.global_position.x + game.scooter.global_position.x) * 0.5
		game.player.global_position.z = maxf(game.car.global_position.z, game.scooter.global_position.z) + 8.5
		game._yaw = 0.0
		game._pitch = 0.32
		game._manual_look_time = 0.0
		await _frames(3)
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		_expect(screenshot.save_png("user://phase1-preview.png") == OK, "preview PNG saved")
		print("Preview: ", ProjectSettings.globalize_path("user://phase1-preview.png"))
	print("Phase 1 smoke: ", failures, " failures (", checks, " checks)")
	quit(0 if failures == 0 else 1)


func _check_locomotion() -> void:
	var animation: AnimationPlayer = game.player.visual.animation_player
	var skeleton: Skeleton3D = game.player.visual.skeleton
	_expect(animation.current_animation == &"idle" and animation.current_animation_position > 0.0, "captured idle plays at rest")
	var pedestrian: Node3D = game.pedestrians[0]
	var pedestrian_start := pedestrian.position
	var clear_pedestrian_paths := true
	var space := game.get_world_3d().direct_space_state
	var walking_mask: int = game.player.collision_mask
	game.player.collision_mask = 1 | 4
	for walker: Node3D in game.pedestrians:
		for point: Vector3 in [walker.path_start, walker.path_end]:
			var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP, point - Vector3.UP, 1)
			var support := space.intersect_ray(ray)
			if support.is_empty() or absf(support.position.y - point.y) > 0.02:
				clear_pedestrian_paths = false
		var start := Transform3D(Basis.IDENTITY, walker.path_start + Vector3.UP * 0.05)
		if game.player.test_move(start, walker.path_end - walker.path_start):
			clear_pedestrian_paths = false
	game.player.collision_mask = walking_mask
	_expect(clear_pedestrian_paths, "both pedestrian routes stay grounded and clear of obstacles")
	var thigh := skeleton.find_bone("LeftUpperLeg")
	Input.action_press(&"move_right")
	await _frames(20)
	var pose := skeleton.get_bone_pose_rotation(thigh)
	await _frames(16)
	_expect(animation.current_animation == &"walk" and absf(pose.dot(skeleton.get_bone_pose_rotation(thigh))) < 0.999, "captured walk moves the player's leg bones")
	_expect(pedestrian.position.distance_to(pedestrian_start) > 0.35 and pedestrian.animation_player.current_animation == &"walk", "Hill Road pedestrian walks using the shared captured clip")
	Input.action_press(&"run")
	await _frames(18)
	_expect(animation.current_animation == &"run" and game.player.get_real_velocity().length() > 1.8, "Shift selects the captured jog at movement speed")
	Input.action_release(&"run")
	Input.action_release(&"move_right")
	await _frames(22)
	_expect(animation.current_animation == &"idle", "locomotion returns to idle on release")
	await _tap(&"recover")


func _check_pedestrians() -> void:
	var pedestrian: CharacterBody3D = game.pedestrians[0]
	game.player.global_position = pedestrian.global_position + Vector3(1.50, 0.06, 0.0)
	game._message_time = 0.0
	await _frames(8)
	_expect(game.hud._prompt.text == "Talk to %s" % pedestrian.display_name, "walking near a pedestrian shows the Talk prompt")
	var obstacle := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(0.12, 1.0, 1.2)
	collider.shape = slab
	obstacle.add_child(collider)
	obstacle.position = game.player.global_position.lerp(pedestrian.global_position, 0.5) + Vector3.UP
	game.add_child(obstacle)
	await _frames(3)
	await _tap(&"interact")
	_expect(game._message_time <= 0.0, "a wall blocks talking through it")
	obstacle.queue_free()
	await _frames(3)
	await _tap(&"interact")
	_expect(game._message == "%s: %s" % [pedestrian.display_name, pedestrian.greeting], "interact starts the pedestrian's dialogue")
	var chatting_position := pedestrian.global_position
	await _frames(20)
	_expect(pedestrian.global_position.distance_to(chatting_position) < 0.04 and pedestrian.animation_player.current_animation == &"idle", "pedestrian pauses walking during the conversation")

	var contact := KinematicCollision3D.new()
	var walking_probe := Transform3D(Basis.IDENTITY, chatting_position + Vector3(1.5, 0.065, 0.0))
	_expect(game.player.test_move(walking_probe, Vector3.LEFT * 1.5, contact) and contact.get_collider() == pedestrian, "pedestrians block the walking player")
	game.player.set_on_foot(false)
	# Isolate the vehicle contact from curbs and buildings near the dialogue route.
	var yard_contact := Vector3(-20.0, 0.02, -18.0)
	var approach := Transform3D(Basis.IDENTITY, yard_contact + Vector3(0.0, 0.55, 5.5))
	pedestrian.global_position = yard_contact
	pedestrian.begin_conversation(approach.origin, 4.0)
	await _frames(6)
	for vehicle: Node3D in [game.car, game.rickshaw, game.motorcycle, game.scooter]:
		var blocked: bool = vehicle.test_move(approach, Vector3.FORWARD * 5.5, contact)
		_expect(blocked and contact.get_collider() == pedestrian, "%s collision detects pedestrians" % vehicle.vehicle_label)

	game.car.reset_to(approach)
	game.car.set_driver_active(true)
	await _frames(10)
	game.car.set_controls(0.22, 0.0, false)
	await _frames(155)
	_expect(game.car.global_position.z > yard_contact.z + 1.9 and game.car.global_position.z < yard_contact.z + 3.0 and game.car.get_speed_mps() < 0.2,
		"a moving car stops against the pedestrian without passing through")
	await _tap(&"recover")


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


func _check_street_curbs() -> void:
	var hill_road: PackedVector3Array = game.world._roads[0]
	var along := (hill_road[1] - hill_road[0]).normalized()
	var west := Vector3(along.z, 0.0, -along.x)
	var road_center := hill_road[0] + along * 35.0
	var heading := Basis(Vector3.UP, atan2(-west.x, -west.z))
	for vehicle: Node3D in [game.car, game.rickshaw, game.motorcycle, game.scooter]:
		var parking: Transform3D = vehicle.global_transform
		var approach := road_center + west * 3.3 + Vector3.UP * 0.55
		vehicle.reset_to(Transform3D(heading, approach))
		vehicle.set_driver_active(true)
		await _frames(10)
		var road_height: float = vehicle.global_position.y
		var peak_height := road_height
		vehicle.set_controls(0.24, 0.0, false)
		for tick in range(275):
			await physics_frame
			peak_height = maxf(peak_height, vehicle.global_position.y)
			if (vehicle.global_position - road_center).dot(west) > 12.0:
				break
		var crossed: bool = (vehicle.global_position - road_center).dot(west) > 12.0
		_expect(crossed and peak_height - road_height >= 0.11, "%s climbs the 14 cm Hill Road curb" % vehicle.vehicle_label)
		vehicle.set_controls(0.0, 0.0, true)
		await _frames(10)
		_expect(crossed and vehicle.is_on_floor() and absf(vehicle.global_position.y - road_height) < 0.06, "%s comes back down to ground level after crossing the sidewalk" % vehicle.vehicle_label)
		vehicle.set_driver_active(false)
		vehicle.reset_to(parking)
	await _tap(&"recover")


func _check_yard_obstacles() -> void:
	var curb: Node3D = game.world.get_node("CurbTest")
	var reverse_pose := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(curb.position.x - 3.5, 0.55, curb.position.z))
	game.car.reset_to(reverse_pose)
	game.car.set_driver_active(true)
	await _frames(10)
	var road_height: float = game.car.global_position.y
	var peak_height := road_height
	game.car.set_controls(-0.55, 0.0, false)
	for tick in range(190):
		await physics_frame
		peak_height = maxf(peak_height, game.car.global_position.y)
		if game.car.global_position.x > curb.position.x + 2.6:
			break
	_expect(game.car.global_position.x > curb.position.x + 2.6 and peak_height - road_height > 0.18, "car reverses over the taller 22 cm yard curb")

	var roof := StaticBody3D.new()
	var ceiling := CollisionShape3D.new()
	var roof_box := BoxShape3D.new()
	roof_box.size = Vector3(5.2, 0.24, 3.8)
	ceiling.shape = roof_box
	roof.position = Vector3(curb.position.x, 1.15, curb.position.z)
	roof.add_child(ceiling)
	game.add_child(roof)
	game.car.reset_to(reverse_pose)
	await _frames(10)
	game.car.set_controls(-0.55, 0.0, false)
	await _frames(135)
	_expect(game.car.global_position.x < curb.position.x - 1.7 and game.car.get_speed_mps() < 0.2, "car cannot step up under a low overhang")
	roof.queue_free()

	var wall: Node3D = game.world.get_node("ImpactWall")
	var wall_approach := Vector3(wall.position.x, 0.55, wall.position.z + 7.0)
	game.car.reset_to(Transform3D(Basis.IDENTITY, wall_approach))
	await _frames(10)
	game.car.set_controls(0.65, 0.0, false)
	await _frames(120)
	_expect(game.car.global_position.z > wall.position.z + 1.9 and game.car.get_speed_mps() < 0.2, "the solid yard wall still stops the car")
	await _tap(&"recover")


func _check_rickshaw() -> void:
	var parked: Vector3 = game.rickshaw.global_position
	var driver := game.rickshaw.get_node("SeatedDriver") as Node3D
	_expect(not driver.visible, "parked auto-rickshaw has an empty driver seat")
	var collision := KinematicCollision3D.new()
	var probe := Transform3D(Basis.IDENTITY, parked + Vector3(0.0, 0.07, 4.0))
	var hit_vehicle: bool = game.car.test_move(probe, Vector3(0.0, 0.0, -4.0), collision)
	_expect(hit_vehicle and collision.get_collider() == game.rickshaw, "parked vehicles collide with each other")
	game.player.global_position = Vector3(parked.x, 0.04, parked.z + 2.4)
	await _frames(6)
	await _tap(&"interact")
	_expect(game.active_vehicle == game.rickshaw and game.rickshaw.driver_active and not game.car.driver_active, "nearest auto-rickshaw takes control while the car stays parked")
	_expect(driver.is_visible_in_tree(), "entering the auto-rickshaw shows the seated driver")
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
	_expect(not driver.visible, "exiting the auto-rickshaw hides the seated driver")
	await _tap(&"recover")
	var centered: Vector2 = Vector2(game.rickshaw.position.x, game.rickshaw.position.z)
	_expect(centered.distance_to(Vector2(parked.x, parked.z)) < 0.1 and absf(game.car.position.z) < 0.1 and not game.driving, "reset parks the car and auto-rickshaw at their original bays")


func _check_two_wheeler(vehicle: Node3D, label: String) -> void:
	var parked: Vector3 = vehicle.global_position
	_expect(vehicle.is_two_wheeler and not vehicle.rider.visible, "parked %s has no visible rider" % label)
	var collision := KinematicCollision3D.new()
	var probe := Transform3D(Basis.IDENTITY, game.car.global_position + Vector3(0.0, 0.07, -4.0))
	var hits_parked_car: bool = vehicle.test_move(probe, Vector3(0.0, 0.0, 4.0), collision)
	_expect(hits_parked_car and collision.get_collider() == game.car and (vehicle.collision_layer & 4) != 0, "%s collision sweep detects another parked vehicle" % label)
	await _approach_vehicle(vehicle)
	await _tap(&"interact")
	_expect(game.active_vehicle == vehicle and vehicle.driver_active and not game.car.driver_active and not game.rickshaw.driver_active and game.motorcycle.driver_active != game.scooter.driver_active, "nearest %s takes exclusive driving control" % label)
	_expect(vehicle.rider.visible and not game.player.visible, "mounting %s shows its rider and hides the walker" % label)
	# Isolate handling from parked bays and the ramp. The world owns this yard;
	# derive the test pose from it instead of duplicating vehicle spawn constants.
	var yard: Node3D = game.world.get_node("RecoveryYard")
	var quiet_start := Vector3(yard.global_position.x + 10.0, parked.y, yard.global_position.z + 24.0)
	vehicle.reset_to(Transform3D(Basis.IDENTITY, quiet_start))
	await _frames(6)
	await _hold(&"move_forward", 90)
	_expect(vehicle.position.z < quiet_start.z - 3.0 and vehicle.get_speed_mps() > 2.0, "%s accelerates along the handling lane" % label)
	var heading: float = vehicle.rotation.y
	Input.action_press(&"move_forward")
	await _hold(&"move_right", 30)
	Input.action_release(&"move_forward")
	_expect(absf(angle_difference(heading, vehicle.rotation.y)) > 0.10, "%s steers while moving" % label)
	var lean: float = absf(vehicle.lean_visual.rotation.z)
	_expect(lean > 0.03 and lean <= deg_to_rad(23.0) and vehicle.global_basis.y.dot(Vector3.UP) > 0.999, "%s leans visually while its collision chassis stays upright" % label)
	await _tap(&"interact")
	_expect(game.active_vehicle == vehicle and vehicle.rider.visible, "moving %s cannot be dismounted" % label)
	await _hold(&"brake", 80)
	_expect(vehicle.get_speed_mps() < 0.20, "%s brakes to a halt" % label)
	await _tap(&"interact")
	_expect(not game.driving and game.player.visible and not vehicle.driver_active and not vehicle.rider.visible, "dismounting %s restores walking and removes its rider" % label)
	await _tap(&"recover")
	_expect(_at_parked_bay(vehicle, parked) and absf(vehicle.lean_visual.rotation.z) < 0.001, "%s reset restores its bay and clears lean" % label)
	await _approach_vehicle(vehicle)
	await _tap(&"interact")
	_expect(game.active_vehicle == vehicle and vehicle.rider.visible, "%s can be mounted again after recovery" % label)
	await _tap(&"recover")
	_expect(not game.driving and game.player.visible and not vehicle.driver_active and not vehicle.rider.visible and vehicle.get_speed_mps() < 0.01 and _at_parked_bay(vehicle, parked), "reset while mounted parks %s and clears rider/control state" % label)


func _approach_vehicle(vehicle: Node3D) -> void:
	var feet_height: float = game.player.global_position.y
	game.player.global_position = vehicle.global_position + vehicle.global_basis.z * 2.4
	game.player.global_position.y = feet_height
	game.player.velocity = Vector3.ZERO
	await _frames(6)


func _at_parked_bay(vehicle: Node3D, parked: Vector3) -> bool:
	return Vector2(vehicle.global_position.x, vehicle.global_position.z).distance_to(Vector2(parked.x, parked.z)) < 0.1


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


func _check_touch_pedestrian() -> void:
	var pedestrian: CharacterBody3D = game.pedestrians[0]
	game.player.global_position = pedestrian.global_position + Vector3(1.5, 0.06, 0.0)
	await _frames(7)
	var surface: Control = game.hud._touch_surface
	var interact_point: Vector2 = game.hud._button_rect(0).get_center()
	_touch(surface, 5, interact_point, true)
	_touch(surface, 5, interact_point, false)
	await _frames(3)
	_expect(not game.driving and game._message.begins_with("%s: " % pedestrian.display_name), "touch Interact talks to a nearby pedestrian")
	await _tap(&"recover")


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


func _check_touch_two_wheeler(vehicle: Node3D, label: String) -> void:
	var parked: Vector3 = vehicle.global_position
	await _approach_vehicle(vehicle)
	var surface: Control = game.hud._touch_surface
	var interact: Vector2 = game.hud._button_rect(0).get_center()
	_touch(surface, 7, interact, true)
	_touch(surface, 7, interact, false)
	await _frames(4)
	_expect(game.active_vehicle == vehicle and vehicle.rider.visible, "touch Interact mounts %s with a visible rider" % label)
	var stick: Vector2 = game.hud._stick_center() - Vector2(0, 52)
	_touch(surface, 8, stick, true)
	await _frames(50)
	_expect(vehicle.position.z < parked.z - 1.0 and vehicle.get_speed_mps() > 1.0, "touch stick accelerates %s" % label)
	var brake: Vector2 = game.hud._button_rect(1).get_center()
	_touch(surface, 9, brake, true)
	await _frames(70)
	_expect(game.hud.move_axis.y < -0.4 and vehicle.get_speed_mps() < 0.2, "second touch brakes %s while throttle remains held" % label)
	_touch(surface, 8, stick, false)
	_touch(surface, 9, brake, false)
	var reset_button: Vector2 = game.hud._button_rect(2).get_center()
	_touch(surface, 10, reset_button, true)
	_touch(surface, 10, reset_button, false)
	await _frames(4)
	_expect(not game.driving and not vehicle.rider.visible and _at_parked_bay(vehicle, parked), "touch reset parks %s and clears its rider" % label)


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
	checks += 1
	if condition:
		print("PASS ", description)
	else:
		failures += 1
		printerr("FAIL ", description)
