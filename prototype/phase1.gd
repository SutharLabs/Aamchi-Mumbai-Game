extends Node3D

signal pause_requested

const World := preload("res://world/phase1_world.gd")
const Traffic := preload("res://world/ambient_traffic.gd")
const Vehicle := preload("res://vehicle/phase1_vehicle.gd")
const Car := preload("res://vehicle/phase1_car.gd")
const Rickshaw := preload("res://vehicle/phase1_rickshaw.gd")
const Motorcycle := preload("res://vehicle/phase1_motorcycle.gd")
const Scooter := preload("res://vehicle/phase1_scooter.gd")
const Fleet := preload("res://vehicle/ranwar_fleet.gd")
const Walker := preload("res://player.gd")
const Pedestrian := preload("res://character/practice_pedestrian.gd")
const Hud := preload("res://phase1_hud.gd")
const DeliveryRoute := preload("res://mission/ranwar_delivery_route.gd")
const MissionProgress := preload("res://mission/mission_progress.gd")
const Delivery := preload("res://mission/ranwar_delivery.gd")
const Career := preload("res://mission/ranwar_career.gd")
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
const FIRST_AID := Vector3(-13.4, 0.0, 5.0)
const MIRA_LEAD := "Mira: The parcel held receipts from the print shop. The same delivery name appears three times. I’ll ask Asha about tomorrow’s ledger."
const WITNESS_RANGE := 17.0
const CLAIMED_RETIRE_RANGE := 225.0

var world := World.new()
var traffic := Traffic.new()
var ambient_traffic_enabled := true
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
var delivery_progress: MissionProgress
var delivery: DeliveryRoute
var career: Career
var _mira: Pedestrian
var _parking_poses: Dictionary[Vehicle, Transform3D] = {}
var _vehicle_keys: Dictionary[Vehicle, bool] = {}
var _entered_vehicles: Dictionary[Vehicle, bool] = {}
var _claimed_traffic: Array[Vehicle] = []
var _loan_bike: Vehicle
var _first_arrival := false
var _claimed_check_time := 0.0
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
	if delivery_progress != null:
		if career == null:
			career = Career.new(delivery_progress)
		var saved := delivery_progress.load_snapshot()
		_first_arrival = (not career.arrival_seen and not delivery_progress.has_incompatible_save()
			and saved.get("state", String(Delivery.OFFER)) == String(Delivery.OFFER))
	world.spawn_at_arrival = _first_arrival
	world.name = "RanwarPracticeArea"
	add_child(world)
	player.name = "Walker"
	player.position = world.arrival_position() if _first_arrival else PLAYER_START
	if _first_arrival:
		_yaw = world.arrival_yaw()
		player.rotation.y = _yaw
		career.record_arrival()
	add_child(player)
	_mira = _add_pedestrian("Mira", "The open practice yard is just west of Hill Road.", 1.0, 0.08, Color("a4654d"))
	_add_pedestrian("Rafiq", "Nagrana Lane is easier on foot. Take Waroda Road if you're driving.", -1.0, 0.25, Color("50617b"), true)
	_add_practice_vehicle(car, "PracticeCar", CAR_START)
	_add_practice_vehicle(rickshaw, "PracticeRickshaw", RICKSHAW_START)
	_add_practice_vehicle(motorcycle, "PracticeMotorcycle", World.MOTORCYCLE_START)
	_add_practice_vehicle(scooter, "PracticeScooter", World.SCOOTER_START)
	if career != null:
		_populate_streets()
		traffic.civilian_limit = 3 if OS.has_feature("mobile") else 4
	traffic.name = "AmbientTraffic"
	add_child(traffic)
	traffic.child_entered_tree.connect(_watch_impact)
	if ambient_traffic_enabled:
		traffic.start(world.lane_graph.loop_for_road(TRAFFIC_ENTRY_ROAD), 26.0, camera)
	camera.fov = 68.0
	camera.far = 570.0
	add_child(camera)
	camera.make_current()
	if delivery_progress != null:
		delivery = DeliveryRoute.new()
		delivery.name = "RanwarParcelRun"
		add_child(delivery)
		delivery.setup(delivery_progress, world._gully)
		career.parcel_completed = delivery.flow.state == Delivery.COMPLETED
		_add_first_aid_sign()
		if _first_arrival:
			_show_message("First day in Mumbai. Take the loan bike and find work in Ranwar.", 5.0)
	hud.pause_enabled = startup_pause_enabled
	add_child(hud)
	var local_facilities := PackedVector3Array()
	for facility: Dictionary in world.facility_markers():
		if facility["playable"]:
			local_facilities.append(facility["position"])
	hud.set_map_geometry(world._roads, world._gully, local_facilities)
	hud.interact_pressed.connect(_request_interact)
	hud.jump_pressed.connect(player.request_jump)
	hud.reset_pressed.connect(_request_reset)
	hud.pause_pressed.connect(func() -> void: pause_requested.emit())
	hud.look_dragged.connect(_apply_look)
	_update_camera(0.0)
	if not hud.touch_enabled and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _add_practice_vehicle(vehicle: Vehicle, node_name: String, spawn: Vector3, with_key := true, yaw := 0.0) -> void:
	var pose := Transform3D(Basis(Vector3.UP, yaw), spawn)
	vehicle.name = node_name
	vehicle.position = spawn
	add_child(vehicle)
	vehicle.reset_to(pose)
	_parking_poses[vehicle] = pose
	_vehicle_keys[vehicle] = with_key
	_watch_impact(vehicle)


func _add_pedestrian(speaker: String, greeting: String, side: float, offset: float, shirt: Color, wears_overshirt: bool = false) -> Pedestrian:
	return _spawn_pedestrian(speaker, greeting, world.practice_pedestrian_path(side), offset, shirt, wears_overshirt)


func _spawn_pedestrian(speaker: String, greeting: String, path: PackedVector3Array,
		offset: float, shirt: Color, wears_overshirt: bool) -> Pedestrian:
	var pedestrian := Pedestrian.new()
	pedestrian.name = speaker
	pedestrian.display_name = speaker
	pedestrian.greeting = greeting
	pedestrian.path_start = path[0]
	pedestrian.path_end = path[1]
	pedestrian.start_fraction = offset
	pedestrian.shirt_color = shirt
	pedestrian.wears_overshirt = wears_overshirt
	add_child(pedestrian)
	pedestrians.append(pedestrian)
	return pedestrian


func _populate_streets() -> void:
	var arrival := world.arrival_position()
	var west := Vector3.FORWARD.rotated(Vector3.UP, world.arrival_yaw())
	var church_side := Vector3(west.z, 0.0, -west.x)
	_loan_bike = Fleet.create(&"commuter")
	var stops: Array[Vehicle] = [_loan_bike, Fleet.create(&"sedan"), Fleet.create(&"electric_scooter")]
	for index in stops.size():
		var spot := arrival + west * (13.0 + 7.0 * index) + church_side * 2.85
		spot.y = 0.55
		_add_practice_vehicle(stops[index], "StopVehicle%d" % index, spot, index == 0, world.arrival_yaw())
	var yard_kinds: Array[StringName] = [&"classic", &"roadster", &"scrambler", &"mpv", &"suv"]
	for index in yard_kinds.size():
		_add_practice_vehicle(Fleet.create(yard_kinds[index]), "YardVehicle%d" % index,
			Vector3(-47.0 + 7.3 * index, 0.55, 9.0), false)
	var names := ["Anjali", "Sameer", "Farah", "Nitin", "Leena", "Iqbal"]
	var colours := [Color("8b513c"), Color("587e77"), Color("6c536f"), Color("a5744f"), Color("809262"), Color("62788d")]
	for index in (4 if OS.has_feature("mobile") else names.size()):
		var across := -16.3 if index % 2 == 1 else 0.0
		var lane_offset := -0.36 if index % 3 == 1 else 0.36
		var start := arrival + west * 16.0 + church_side * (across + lane_offset)
		start.y = World.SIDEWALK_HEIGHT
		var end := start + west * 15.0
		var path := PackedVector3Array([end, start] if index % 3 == 1 else [start, end])
		_spawn_pedestrian(names[index], "The Hill Road job board is west of here.", path,
			0.15 + floorf(float(index) * 0.5) * 0.31, colours[index], index % 2 == 1)


func _add_lighting() -> void:
	var lighting := WorldEnvironment.new()
	lighting.environment = Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("698ca8")
	sky_material.sky_horizon_color = Color("c9d1c9")
	sky_material.ground_horizon_color = sky_material.sky_horizon_color
	sky_material.ground_bottom_color = Color("8a8578")
	sky_material.sun_angle_max = 13.0
	var sky := Sky.new()
	sky.sky_material = sky_material
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	lighting.environment.background_mode = Environment.BG_SKY
	lighting.environment.sky = sky
	lighting.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	lighting.environment.ambient_light_color = Color("c7d9e4")
	lighting.environment.ambient_light_energy = 0.58
	lighting.environment.ambient_light_sky_contribution = 0.0
	add_child(lighting)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-46.0, -36.0, 0.0)
	sun.light_color = Color("fff1d9")
	sun.light_energy = 1.08
	sun.shadow_enabled = not OS.has_feature("mobile")
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_split_1 = 0.20
	sun.directional_shadow_max_distance = 68.0
	sun.directional_shadow_fade_start = 0.82
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
	if not _resolve_recovery(delta) and (_interact_requested or Input.is_action_just_pressed(&"interact")):
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
	_retire_claimed_traffic(delta)
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
	elif player.can_interact():
		prompt = _special_interaction()
		if prompt.is_empty():
			var nearby := _nearby_interaction()
			if nearby is Pedestrian:
				prompt = "Talk to %s" % nearby.display_name
				if nearby == _mira and career != null and career.has_lead():
					prompt = "Ask Mira about the parcel"
			elif nearby is Vehicle:
				prompt = _entry_prompt(nearby)
		can_interact = not prompt.is_empty()
	if _message_time > 0.0:
		prompt = _message
		can_interact = false
	var objective := delivery.objective(_actor_position()) if delivery != null else ""
	if objective.is_empty() and _first_arrival and delivery.flow.state == Delivery.OFFER and delivery.target().is_finite():
		objective = "Find work at the Hill Road job board · %d m" % roundi(_actor_position().distance_to(delivery.target()))
	if objective.is_empty() and career != null and career.has_lead():
		objective = "Talk to Mira on Hill Road · %d m" % roundi(_actor_position().distance_to(_mira.global_position))
	var forward := -active_vehicle.global_basis.z if driving else -player.global_basis.z
	var condition := active_vehicle.condition_percent() if driving else -1
	hud.update_live_map(_actor_position(), forward, story_target())
	if career != null:
		hud.update_player_status(career.health, career.wanted, career.cash, condition)
	else:
		hud.update_player_status(-1.0, 0, -1, condition)
	hud.update_display(driving, speed, prompt, vehicle_label, can_interact, objective)


func story_target() -> Vector3:
	var destination := delivery.target() if delivery != null else Vector3.INF
	if not destination.is_finite() and career != null and career.has_lead():
		return _mira.global_position
	return destination


func session_status() -> String:
	if career == null:
		return ""
	var status := "₹%d  ·  Health %d%%" % [career.cash, ceili(career.health)]
	if career.wanted > 0:
		status += "  ·  Police alert %d" % career.wanted
	if career.lead_seen:
		status += "\nLead logged · Tomorrow’s ledger"
	return status


func _special_interaction() -> String:
	if delivery == null:
		return ""
	var job := delivery.prompt_for(player.global_position)
	if not job.is_empty():
		return job
	if _at_first_aid() and career.health < Career.MAX_HEALTH and career.wanted == 0:
		return "First aid · ₹%d" % Career.TREATMENT_PRICE
	return ""


func _at_first_aid() -> bool:
	return player.global_position.distance_squared_to(FIRST_AID) <= 2.2 * 2.2


func _add_first_aid_sign() -> void:
	var sign := Label3D.new()
	sign.name = "FirstAidSign"
	sign.text = "FIRST AID"
	sign.font_size = 48
	sign.pixel_size = 0.0035
	sign.modulate = Color("b8f2d0")
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = FIRST_AID + Vector3.UP * 1.45
	add_child(sign)


func _watch_impact(node: Node) -> void:
	if node is Vehicle:
		node.impacted.connect(_on_vehicle_impact)


func _on_vehicle_impact(vehicle: Vehicle, collider: Object, speed: float) -> void:
	if collider is Pedestrian or collider == player:
		var struck := collider as CharacterBody3D
		var approach := vehicle.impact_velocity.slide(Vector3.UP).normalized()
		var away := -vehicle.impact_normal.slide(Vector3.UP).normalized()
		var push := approach * 0.35 + away * 0.65
		if push.is_zero_approx():
			push = struck.global_position - vehicle.global_position
		collider.receive_vehicle_impact(push, speed)
	if career == null:
		return
	if vehicle == active_vehicle:
		if (collider is Pedestrian or (collider is Vehicle and collider.driver_active)) and career.report_collision():
			_show_message("Traffic collision reported · Police alert %d" % career.wanted, 3.0)
		if speed >= 7.0:
			career.damage(13.0 + (speed - 7.0) * 6.0)
	elif collider == player and not driving:
		career.damage(20.0 + (speed - 5.0) * 8.0)


func _resolve_recovery(delta: float) -> bool:
	var requested := _reset_requested or Input.is_action_just_pressed(&"recover")
	var fell := _actor_position().y < -8.0
	if career == null:
		if requested or fell:
			_reset_run()
		return requested or fell
	if career.health <= 0.0 or fell:
		_reset_run(&"clinic")
		return true
	if requested:
		_reset_run(&"detained" if career.wanted > 0 else &"")
		return true
	var previous_alert := career.wanted
	var patrol := traffic.police_vehicle()
	var seen := false
	var stopped_near := false
	if previous_alert > 0 and patrol != null:
		var actor := _actor_position()
		var distance_squared := actor.distance_squared_to(patrol.global_position)
		if distance_squared < 42.0 * 42.0:
			var sight := PhysicsRayQueryParameters3D.create(patrol.global_position + Vector3.UP,
				actor + Vector3.UP, 1)
			seen = get_world_3d().direct_space_state.intersect_ray(sight).is_empty()
			var speed := active_vehicle.get_speed_mps() if driving else player.get_real_velocity().length()
			stopped_near = seen and distance_squared < 8.0 * 8.0 and speed < 1.2
	if career.step(delta, seen, stopped_near):
		_reset_run(&"detained")
		return true
	traffic.set_police_alert(career.wanted, _actor_position())
	if previous_alert > 0 and career.wanted == 0:
		_show_message("Police alert cleared", 2.8)
	return false


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
	var candidates: Array[Vehicle] = []
	candidates.assign(_parking_poses.keys())
	candidates.append_array(_claimed_traffic)
	candidates.append_array(traffic.interaction_vehicles())
	for candidate: Vehicle in candidates:
		var distance := player.global_position.distance_squared_to(candidate.global_position)
		if distance < distance_limit and candidate.get_speed_mps() <= EXIT_SPEED:
			best = candidate
			distance_limit = distance
	return best


func _entry_prompt(vehicle: Vehicle) -> String:
	var label := vehicle.vehicle_label.to_lower()
	if _entered_vehicles.has(vehicle):
		return "Mount the %s" % label if vehicle.is_two_wheeler else "Get in the %s" % label
	return "Unlock the %s" % label if _vehicle_keys.get(vehicle, false) else "Steal the %s" % label


func _theft_seen(vehicle: Vehicle) -> bool:
	var near := vehicle.global_position + Vector3.UP * 0.6
	for pedestrian in pedestrians:
		if pedestrian.is_reacting() or pedestrian.global_position.distance_squared_to(near) > WITNESS_RANGE ** 2:
			continue
		var sight := PhysicsRayQueryParameters3D.create(pedestrian.global_position + Vector3.UP * 1.4, near, 1)
		if get_world_3d().direct_space_state.intersect_ray(sight).is_empty():
			return true
	return false


func _retire_claimed_traffic(delta: float) -> void:
	if _claimed_traffic.is_empty():
		return
	_claimed_check_time += delta
	if _claimed_check_time < 1.0:
		return
	_claimed_check_time = 0.0
	for index in range(_claimed_traffic.size() - 1, -1, -1):
		var vehicle := _claimed_traffic[index]
		if vehicle == active_vehicle:
			continue
		if vehicle.global_position.distance_squared_to(_actor_position()) > CLAIMED_RETIRE_RANGE ** 2 \
				and not camera.is_position_in_frustum(vehicle.global_position):
			_claimed_traffic.remove_at(index)
			_entered_vehicles.erase(vehicle)
			vehicle.queue_free()


func _nearby_interaction() -> PhysicsBody3D:
	var best: PhysicsBody3D = _nearby_vehicle()
	var distance_limit := TALK_RANGE * TALK_RANGE
	if best != null:
		distance_limit = minf(distance_limit, player.global_position.distance_squared_to(best.global_position))
	for pedestrian in pedestrians:
		if pedestrian.is_reacting():
			continue
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
	if not player.can_interact():
		return
	if delivery != null and not delivery.prompt_for(player.global_position).is_empty():
		var message := delivery.interact()
		career.parcel_completed = delivery.flow.state == Delivery.COMPLETED
		_show_message(message, 4.0)
		return
	if career != null and _at_first_aid() and career.health < Career.MAX_HEALTH and career.wanted == 0:
		var message := "First aid costs ₹%d." % Career.TREATMENT_PRICE
		if career.cash >= Career.TREATMENT_PRICE:
			message = "Treated · −₹%d" % Career.TREATMENT_PRICE if career.treat() else "Treatment could not be saved."
		_show_message(message, 3.0)
		return
	var target := _nearby_interaction()
	if target is Pedestrian:
		if target == _mira and career != null and career.has_lead():
			target.begin_conversation(player.global_position, 8.0)
			_show_message(MIRA_LEAD if career.record_lead() else "Mira’s lead could not be saved. Try again.", 8.0)
		else:
			target.begin_conversation(player.global_position, TALK_TIME)
			_show_message("%s: %s" % [target.display_name, target.greeting], TALK_TIME)
		return
	var vehicle := target as Vehicle
	if vehicle == null:
		return
	if not _can_reach(vehicle, Vector3.UP * 0.3):
		_show_message("Move closer to the vehicle from a clear side")
		return
	var first_entry := not _entered_vehicles.has(vehicle)
	var with_key: bool = _vehicle_keys.get(vehicle, false)
	var patrol := traffic.police_vehicle() == vehicle
	var occupied := traffic.take_for_player(vehicle)
	if occupied:
		_claimed_traffic.append(vehicle)
	_entered_vehicles[vehicle] = true
	player.set_on_foot(false)
	active_vehicle = vehicle
	active_vehicle.set_driver_active(true)
	_message_time = 0.0
	if first_entry:
		if with_key:
			_show_message("Unlocked with a loan key.")
		elif career != null and (occupied or _theft_seen(vehicle)):
			career.report_theft(patrol)
			_show_message("Theft reported · Police alert %d" % career.wanted, 3.0)
		else:
			_show_message("Vehicle taken.")


func _find_exit(vehicle: Vehicle) -> Vector3:
	var space := get_world_3d().direct_space_state
	for side: float in [vehicle.preferred_exit_side, -vehicle.preferred_exit_side]:
		var candidate := vehicle.global_position + vehicle.global_basis.x * (vehicle.exit_side_offset * side)
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


func abandon_delivery() -> void:
	if delivery != null:
		_show_message(delivery.abandon(), 4.0)


func _reset_run(reason: StringName = &"") -> void:
	active_vehicle = null
	for claimed in _claimed_traffic:
		claimed.queue_free()
	_claimed_traffic.clear()
	_entered_vehicles.clear()
	_first_arrival = false
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
	var message := delivery.on_recovery() if delivery != null else ""
	if career != null and reason != &"":
		var treatment := reason == &"clinic"
		var fee := career.charge(Career.CLINIC_FEE if treatment else Career.POLICE_FINE)
		career.respawn()
		var outcome := "Clinic recovery" if treatment else "Detained"
		if fee > 0:
			outcome += " · −₹%d" % fee
		elif fee < 0:
			outcome += " · Fee could not be saved"
		_show_message("%s. %s" % [outcome, message] if not message.is_empty() else outcome, 4.8)
	else:
		_show_message(message if not message.is_empty() else "Back at the starting point")


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
