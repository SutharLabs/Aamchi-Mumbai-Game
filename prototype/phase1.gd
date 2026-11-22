extends Node3D

const World := preload("res://world/phase1_world.gd")
const Car := preload("res://vehicle/phase1_car.gd")
const Walker := preload("res://player.gd")
const Hud := preload("res://phase1_hud.gd")
const PLAYER_START := Vector3(0.0, 0.5, 5.0)
const CAR_START := Vector3(0.0, 0.55, 0.0)
const ENTER_RANGE := 3.2
const EXIT_SPEED := 0.65

var world := World.new()
var player := Walker.new()
var car := Car.new()
var camera := Camera3D.new()
var hud := Hud.new()
var driving := false
var _yaw := 0.0
var _pitch := 0.32
var _manual_look_time := 0.0
var _interact_requested := false
var _reset_requested := false
var _message := ""
var _message_time := 0.0


func _ready() -> void:
	_install_inputs()
	_add_lighting()
	world.name = "RanwarPracticeArea"
	add_child(world)
	player.name = "Walker"
	player.position = PLAYER_START
	add_child(player)
	car.name = "PracticeCar"
	car.position = CAR_START
	add_child(car)
	car.reset_to(Transform3D(Basis.IDENTITY, CAR_START))
	camera.fov = 68.0
	camera.far = 570.0
	add_child(camera)
	camera.make_current()
	add_child(hud)
	hud.interact_pressed.connect(_request_interact)
	hud.reset_pressed.connect(_request_reset)
	hud.look_dragged.connect(_apply_look)
	_update_camera(0.0)
	if not hud.touch_enabled and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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


func _install_inputs() -> void:
	_bind_keys(&"move_left", [KEY_A, KEY_LEFT])
	_bind_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_bind_keys(&"move_forward", [KEY_W, KEY_UP])
	_bind_keys(&"move_back", [KEY_S, KEY_DOWN])
	_bind_keys(&"interact", [KEY_E])
	_bind_keys(&"brake", [KEY_SPACE])
	_bind_keys(&"recover", [KEY_R])


func _bind_keys(action: StringName, keys: Array[int]) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key as Key
		InputMap.action_add_event(action, event)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
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
		car.set_controls(-intent.y, intent.x, Input.is_action_pressed(&"brake") or hud.brake_held)
	else:
		player.direction = Basis(Vector3.UP, _yaw) * Vector3(intent.x, 0.0, intent.y)
	_update_camera(delta)
	_message_time = maxf(0.0, _message_time - delta)
	var prompt := "Walk up to the amber car"
	if driving:
		prompt = "Stop before getting out" if car.get_speed_mps() > EXIT_SPEED else "Get out"
	elif _near_car():
		prompt = "Get in"
	if _message_time > 0.0:
		prompt = _message
	hud.update_display(driving, car.get_speed_mps(), prompt)


func _request_interact() -> void:
	_interact_requested = true


func _request_reset() -> void:
	_reset_requested = true


func _apply_look(motion: Vector2) -> void:
	_yaw = wrapf(_yaw - motion.x * 0.0031, -PI, PI)
	_pitch = clampf(_pitch + motion.y * 0.0027, 0.10, 1.00)
	_manual_look_time = 1.5


func _actor_position() -> Vector3:
	return car.global_position if driving else player.global_position


func _near_car() -> bool:
	return player.global_position.distance_to(car.global_position) < ENTER_RANGE


func _try_interact() -> void:
	if driving:
		if car.get_speed_mps() > EXIT_SPEED:
			_show_message("Stop the car before getting out")
			return
		var exit_pose := _find_exit()
		if not exit_pose.is_finite():
			_show_message("Both sides are blocked. Move the car and try again.")
			return
		player.global_position = exit_pose
		player.rotation.y = car.rotation.y
		player.set_on_foot(true)
		car.set_driver_active(false)
		driving = false
		_message_time = 0.0
		return
	if not _near_car() or car.get_speed_mps() > EXIT_SPEED:
		return
	var reach := PhysicsRayQueryParameters3D.create(
		player.global_position + Vector3.UP, car.global_position + Vector3.UP * 0.3, 1)
	if not get_world_3d().direct_space_state.intersect_ray(reach).is_empty():
		_show_message("Approach the car from the street")
		return
	player.set_on_foot(false)
	car.set_driver_active(true)
	driving = true
	_message_time = 0.0


func _find_exit() -> Vector3:
	var space := get_world_3d().direct_space_state
	for side in [-1.0, 1.0]:
		var candidate := car.global_position + car.global_basis.x * (1.48 * float(side))
		var ray := PhysicsRayQueryParameters3D.create(candidate + Vector3.UP * 1.1, candidate - Vector3.UP * 1.0, 1)
		var ground := space.intersect_ray(ray)
		if ground.is_empty():
			continue
		var normal: Vector3 = ground.normal
		var surface: Vector3 = ground.position
		if normal.y < 0.72 or absf(surface.y - car.global_position.y) > 0.80:
			continue
		var feet := surface + Vector3.UP * 0.055
		var clearance := PhysicsShapeQueryParameters3D.new()
		clearance.shape = player.body_shape
		clearance.transform = Transform3D(Basis.IDENTITY, feet + Vector3.UP * Walker.BODY_HEIGHT * 0.5)
		clearance.collision_mask = 1 | 4
		if space.intersect_shape(clearance, 1).is_empty():
			return feet
	return Vector3.INF


func _show_message(message: String) -> void:
	_message = message
	_message_time = 2.3


func _reset_run() -> void:
	driving = false
	car.set_driver_active(false)
	car.reset_to(Transform3D(Basis.IDENTITY, CAR_START))
	player.global_position = PLAYER_START
	player.rotation = Vector3.ZERO
	player.set_on_foot(true)
	_yaw = 0.0
	_pitch = 0.32
	_manual_look_time = 0.0
	_show_message("Back at the starting point")


func _update_camera(delta: float) -> void:
	_manual_look_time = maxf(0.0, _manual_look_time - delta)
	if driving and _manual_look_time <= 0.0:
		_yaw = lerp_angle(_yaw, car.rotation.y, minf(delta * 4.5, 1.0))
	var target := _actor_position() + Vector3.UP * (1.10 if driving else 1.30)
	var distance := 6.9 if driving else 4.8
	var offset := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch))
	var desired := target + offset * distance
	var query := PhysicsRayQueryParameters3D.create(target, desired, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var point: Vector3 = hit.position
		desired = target + offset * maxf(0.18, target.distance_to(point) - 0.24)
	camera.global_position = desired
	camera.look_at(target)
