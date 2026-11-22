extends Node3D

signal pause_requested

const World := preload("res://world/phase1_world.gd")
const Traffic := preload("res://world/ambient_traffic.gd")
const Vehicle := preload("res://vehicle/phase1_vehicle.gd")
const Car := preload("res://vehicle/phase1_car.gd")
const Rickshaw := preload("res://vehicle/phase1_rickshaw.gd")
const Motorcycle := preload("res://vehicle/phase1_motorcycle.gd")
const Scooter := preload("res://vehicle/phase1_scooter.gd")
const Walker := preload("res://player.gd")
const Pedestrian := preload("res://character/practice_pedestrian.gd")
const Hud := preload("res://phase1_hud.gd")
const PLAYER_START := World.PLAYER_START
const CAR_START := World.VEHICLE_START
const RICKSHAW_START := World.RICKSHAW_START
const ENTER_RANGE := 3.2
const TALK_RANGE := 2.35
const TALK_TIME := 4.8
const EXIT_SPEED := 0.65
const STREET_SOLIDS := 1 | 2 | 4
const GAMEPAD_LOOK_SPEED := 680.0
const TRAFFIC_ENTRY_ROAD := 3 # West Waroda Road.

var world := World.new()
var traffic := Traffic.new()
var player := Walker.new()
var car := Car.new()
var rickshaw := Rickshaw.new()
var motorcycle := Motorcycle.new()
var scooter := Scooter.new()
var camera := Camera3D.new()
var hud := Hud.new()
var pedestrians: Array[Pedestrian] = []
var active_vehicle: Vehicle
var startup_pause_enabled := false
var look_sensitivity := 1.0
var _parking_poses: Dictionary[Vehicle, Transform3D] = {}
var driving: bool:
	get:
		return active_vehicle != null
var _yaw := 0.0
var _pitch := 0.32
var _camera_target_height := 0.0
var _manual_look_time := 0.0
var _interact_requested := false
var _reset_requested := false
var _message := ""
var _message_time := 0.0


func _ready() -> void:
	_add_lighting()
	world.name = "RanwarPracticeArea"
	add_child(world)
	player.name = "Walker"
	player.position = PLAYER_START
	add_child(player)
	_add_pedestrian("Mira", "The open practice yard is just west of Hill Road.", 1.0, 0.08, Color("a4654d"))
	_add_pedestrian("Rafiq", "Nagrana Lane is easier on foot. Take Waroda Road if you're driving.", -1.0, 0.25, Color("50617b"))
	_add_practice_vehicle(car, "PracticeCar", CAR_START)
	_add_practice_vehicle(rickshaw, "PracticeRickshaw", RICKSHAW_START)
	_add_practice_vehicle(motorcycle, "PracticeMotorcycle", World.MOTORCYCLE_START)
	_add_practice_vehicle(scooter, "PracticeScooter", World.SCOOTER_START)
	traffic.name = "AmbientTraffic"
	add_child(traffic)
	traffic.start(world.lane_graph.loop_for_road(TRAFFIC_ENTRY_ROAD), 26.0)
	camera.fov = 68.0
	camera.far = 570.0
	add_child(camera)
	camera.make_current()
	hud.pause_enabled = startup_pause_enabled
	add_child(hud)
	hud.interact_pressed.connect(_request_interact)
	hud.reset_pressed.connect(_request_reset)
	hud.pause_pressed.connect(func() -> void: pause_requested.emit())
	hud.look_dragged.connect(_apply_look)
	_update_camera(0.0)
	if not hud.touch_enabled and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _add_practice_vehicle(vehicle: Vehicle, node_name: String, spawn: Vector3) -> void:
	var pose := Transform3D(Basis.IDENTITY, spawn)
	vehicle.name = node_name
	vehicle.position = spawn
	add_child(vehicle)
	vehicle.reset_to(pose)
	_parking_poses[vehicle] = pose


func _add_pedestrian(speaker: String, greeting: String, side: float, offset: float, shirt: Color) -> void:
	var path := world.practice_pedestrian_path(side)
	var pedestrian := Pedestrian.new()
	pedestrian.name = speaker
	pedestrian.display_name = speaker
	pedestrian.greeting = greeting
	pedestrian.path_start = path[0]
	pedestrian.path_end = path[1]
	pedestrian.start_fraction = offset
	pedestrian.shirt_color = shirt
	add_child(pedestrian)
	pedestrians.append(pedestrian)


func _add_lighting() -> void:
	var lighting := WorldEnvironment.new()
	lighting.environment = Environment.new()
	lighting.environment.background_mode = Environment.BG_COLOR
	lighting.environment.background_color = Color("a6bdc5")
	lighting.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lighting.environment.ambient_light_color = Color("dce9ed")
	lighting.environment.ambient_light_energy = 0.76
	add_child(lighting)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-54.0, -27.0, 0.0)
	sun.light_color = Color("fff1d9")
	sun.light_energy = 0.81
	add_child(sun)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		hud.set_gamepad_input(true)
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.35:
		hud.set_gamepad_input(true)
	elif (event is InputEventKey and event.pressed) or event is InputEventMouse:
		hud.set_gamepad_input(false)
	if not startup_pause_enabled and event.is_action_pressed(&"ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif not hud.touch_enabled:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_apply_look(event.relative)


func _physics_process(delta: float) -> void:
	if _reset_requested or Input.is_action_just_pressed(&"recover") or _actor_position().y < -8.0:
		_reset_run()
	elif _interact_requested or Input.is_action_just_pressed(&"interact"):
		_try_interact()
	_reset_requested = false
	_interact_requested = false
	var intent := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if hud.move_axis.length_squared() > intent.length_squared():
		intent = hud.move_axis
	if driving:
		active_vehicle.set_controls(-intent.y, intent.x, Input.is_action_pressed(&"brake") or hud.brake_held)
	else:
		player.direction = Basis(Vector3.UP, _yaw) * Vector3(intent.x, 0.0, intent.y)
		player.running = Input.is_action_pressed(&"run")
	var look := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	if look != Vector2.ZERO:
		_apply_look(look * GAMEPAD_LOOK_SPEED * delta)
	_update_camera(delta)
	_message_time = maxf(0.0, _message_time - delta)
	var prompt := ""
	var speed := 0.0
	var vehicle_label := ""
	var can_interact := false
	if driving:
		speed = active_vehicle.get_speed_mps()
		vehicle_label = active_vehicle.vehicle_label
		if speed <= EXIT_SPEED:
			prompt = "Dismount" if active_vehicle.is_two_wheeler else "Get out"
			can_interact = true
	else:
		var nearby := _nearby_interaction()
		if nearby is Pedestrian:
			prompt = "Talk to %s" % nearby.display_name
			can_interact = true
		elif nearby is Vehicle:
			var entry_label := "Mount" if nearby.is_two_wheeler else "Get in"
			prompt = "%s the %s" % [entry_label, nearby.vehicle_label.to_lower()]
			can_interact = true
	if _message_time > 0.0:
		prompt = _message
		can_interact = false
	hud.update_display(driving, speed, prompt, vehicle_label, can_interact)


func _request_interact() -> void:
	_interact_requested = true


func _request_reset() -> void:
	_reset_requested = true


func _apply_look(motion: Vector2) -> void:
	_yaw = wrapf(_yaw - motion.x * 0.0031 * look_sensitivity, -PI, PI)
	_pitch = clampf(_pitch + motion.y * 0.0027 * look_sensitivity, 0.10, 1.00)
	_manual_look_time = 1.5


func _actor_position() -> Vector3:
	return active_vehicle.global_position if driving else player.global_position


func _nearby_vehicle() -> Vehicle:
	var best: Vehicle
	var distance_limit := ENTER_RANGE * ENTER_RANGE
	for candidate: Vehicle in _parking_poses:
		var distance := player.global_position.distance_squared_to(candidate.global_position)
		if distance < distance_limit and candidate.get_speed_mps() <= EXIT_SPEED:
			best = candidate
			distance_limit = distance
	return best


func _nearby_interaction() -> PhysicsBody3D:
	var best: PhysicsBody3D = _nearby_vehicle()
	var distance_limit := TALK_RANGE * TALK_RANGE
	if best != null:
		distance_limit = minf(distance_limit, player.global_position.distance_squared_to(best.global_position))
	for pedestrian in pedestrians:
		var distance := player.global_position.distance_squared_to(pedestrian.global_position)
		if distance < distance_limit and _can_reach(pedestrian, Vector3.UP):
			best = pedestrian
			distance_limit = distance
	return best


func _can_reach(target: PhysicsBody3D, offset: Vector3) -> bool:
	var reach := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3.UP, target.global_position + offset, STREET_SOLIDS)
	reach.exclude = [player.get_rid(), target.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(reach).is_empty()


func _try_interact() -> void:
	if driving:
		if active_vehicle.get_speed_mps() > EXIT_SPEED:
			_show_message("Stop before dismounting" if active_vehicle.is_two_wheeler else "Stop before getting out")
			return
		var exit_pose := _find_exit(active_vehicle)
		if not exit_pose.is_finite():
			_show_message("Both sides are blocked. Repark and try again.")
			return
		player.global_position = exit_pose
		player.rotation.y = active_vehicle.rotation.y
		player.set_on_foot(true)
		active_vehicle.set_driver_active(false)
		active_vehicle = null
		_message_time = 0.0
		return
	var target := _nearby_interaction()
	if target is Pedestrian:
		target.begin_conversation(player.global_position, TALK_TIME)
		_show_message("%s: %s" % [target.display_name, target.greeting], TALK_TIME)
		return
	var vehicle := target as Vehicle
	if vehicle == null:
		return
	if not _can_reach(vehicle, Vector3.UP * 0.3):
		_show_message("Move closer to the vehicle from a clear side")
		return
	player.set_on_foot(false)
	active_vehicle = vehicle
	active_vehicle.set_driver_active(true)
	_message_time = 0.0


func _find_exit(vehicle: Vehicle) -> Vector3:
	var space := get_world_3d().direct_space_state
	for side in [-1.0, 1.0]:
		var candidate := vehicle.global_position + vehicle.global_basis.x * (vehicle.exit_side_offset * float(side))
		var ray := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 1.1, candidate - Vector3.UP * 1.0, 1)
		var ground := space.intersect_ray(ray)
		if ground.is_empty():
			continue
		var normal: Vector3 = ground.normal
		var surface: Vector3 = ground.position
		if normal.y < 0.72 or absf(surface.y - vehicle.global_position.y) > 0.80:
			continue
		var feet := surface + Vector3.UP * 0.055
		var clearance := PhysicsShapeQueryParameters3D.new()
		clearance.shape = player.body_shape
		clearance.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * Walker.BODY_HEIGHT * 0.5)
		clearance.collision_mask = STREET_SOLIDS
		if space.intersect_shape(clearance, 1).is_empty():
			return feet
	return Vector3.INF


func _show_message(message: String, duration := 2.3) -> void:
	_message = message
	_message_time = duration


func _reset_run() -> void:
	active_vehicle = null
	for vehicle: Vehicle in _parking_poses:
		vehicle.set_driver_active(false)
		vehicle.reset_to(_parking_poses[vehicle])
	for pedestrian in pedestrians:
		pedestrian.reset_to_path()
	player.global_position = PLAYER_START
	player.rotation = Vector3.ZERO
	player.set_on_foot(true)
	_yaw = 0.0
	_pitch = 0.32
	_manual_look_time = 0.0
	traffic.reset()
	_show_message("Back at the starting point")


func _update_camera(delta: float) -> void:
	_manual_look_time = maxf(0.0, _manual_look_time - delta)
	if driving and _manual_look_time <= 0.0:
		_yaw = lerp_angle(_yaw, active_vehicle.rotation.y, minf(delta * 4.5, 1.0))
	var target := _actor_position() + Vector3.UP * (1.10 if driving else 1.30)
	if driving:
		_camera_target_height = lerpf(_camera_target_height, target.y, 1.0 - exp(-delta * 12.0))
	else:
		_camera_target_height = target.y
	var focus := Vector3(target.x, _camera_target_height, target.z)
	var distance := active_vehicle.follow_distance if driving else 4.8
	var offset := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))
	var desired := focus + offset * distance
	var query := PhysicsRayQueryParameters3D.create(target, desired, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var point: Vector3 = hit.position
		desired = target + (desired - target).normalized() * maxf(0.18, target.distance_to(point) - 0.24)
	camera.global_position = desired
	camera.look_at(focus)
