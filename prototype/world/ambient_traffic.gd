extends Node3D
## The pilot, nearby civilian cars, and a separate patrol follow the directed lane loop.

const Vehicle := preload("res://vehicle/phase1_vehicle.gd")
const Car := preload("res://vehicle/phase1_car.gd")
const CarDriver := preload("res://vehicle/phase1_car_driver.gd")
const Fleet := preload("res://vehicle/ranwar_fleet.gd")
const CRUISE_SPEED := 5.5
const CORNER_SPEED := 2.6
const STEERING_LOOK_AHEAD := 3.6
const STANDOFF := 1.15
const SPAWN_HEIGHT := 0.55
const SPAWN_NEAR := 85.0
const SPAWN_FAR := 180.0
const DESPAWN_DISTANCE := 225.0
const SPAWN_SPACING := 30.0
const VISIBILITY_MARGIN := 3.0
const POPULATION_INTERVAL := 0.5
const STUCK_TIME := 8.0
const MAX_CIVILIAN_LIMIT := 4
const LOCAL_MODELS: Array[StringName] = [&"sedan", &"suv", &"mpv"]
const PATROL_SPAWN_OFFSETS: Array[float] = [38.0, 56.0, 78.0]
const PATROL_MIN_DISTANCE := 24.0
const PATROL_MAX_DISTANCE := 125.0
const PATROL_SPAWN_SPACING := 14.0
const PATROL_RETIRE_DISTANCE := 35.0
const PATROL_APPROACH_DISTANCE := 13.0
const PATROL_APPROACH_SPEED := 3.0


class Driver:
	var car: Car
	var occupant: CarDriver
	var segment: int
	var idle_seconds := 0.0


@export_range(1, 4) var civilian_limit := 2
var _drivers: Array[Driver] = []
var _pilot: Driver
var _camera: Camera3D
var _route := PackedVector3Array()
var _spawn_segment := 0
var _spawn_pose := Transform3D.IDENTITY
var _spawn_shape := BoxShape3D.new()
var _reset_tick := -1
var _population_clock := 0.0
var _local_serial := 0
var _patrol: Driver
var _alert_level := 0
var _alert_target := Vector3.ZERO


func start(route: PackedVector3Array, spawn_distance: float, observer: Camera3D) -> void:
	if not _route.is_empty() or not is_finite(spawn_distance) or route.size() < 4 or not route[0].is_equal_approx(route[-1]):
		return
	for index in range(route.size() - 1):
		if not route[index].is_finite() or route[index].distance_squared_to(route[index + 1]) < 0.0001:
			return
	_route = route
	_camera = observer
	_spawn_shape.size = Car.CHASSIS_SIZE
	_place_start(maxf(0.0, spawn_distance))
	_add_pilot(_spawn_pose, _spawn_segment)


func _place_start(distance: float) -> void:
	while _spawn_segment < _route.size() - 2:
		var span := _route[_spawn_segment].distance_to(_route[_spawn_segment + 1])
		if distance < span:
			break
		distance -= span
		_spawn_segment += 1
	_spawn_pose = _lane_pose(_spawn_segment, distance)


func _lane_pose(segment: int, distance: float) -> Transform3D:
	var start_point := _route[segment]
	var lane_delta := _route[segment + 1] - start_point
	var forward := lane_delta.normalized()
	var position_on_lane := start_point + forward * minf(distance, lane_delta.length())
	var heading := atan2(-forward.x, -forward.z)
	return Transform3D(Basis(Vector3.UP, heading), position_on_lane + Vector3.UP * SPAWN_HEIGHT)


func _add_pilot(pose: Transform3D, segment: int) -> void:
	_pilot = _create_car(Car.new(), pose, segment, "TrafficCar", Color("bd8a55"))
	_drivers.push_front(_pilot)


func _add_local(pose: Transform3D, segment: int) -> void:
	var model := &"hatch"
	if civilian_limit > 2:
		model = LOCAL_MODELS[_local_serial % LOCAL_MODELS.size()]
	_local_serial += 1
	var car_name := "LocalTrafficCar%d" % _local_serial if has_node("LocalTrafficCar") else "LocalTrafficCar"
	var car := Fleet.create(model) as Car
	_drivers.append(_create_car(car, pose, segment, car_name, Color("789a82")))


func _create_car(car: Car, pose: Transform3D, segment: int, car_name: String, shirt: Color, patrol: bool = false) -> Driver:
	var driver := Driver.new()
	driver.car = car
	driver.car.name = car_name
	driver.car.reset_to(pose)
	driver.car.set_driver_active(true)
	driver.occupant = CarDriver.new()
	driver.occupant.shirt_color = shirt
	driver.occupant.wears_overshirt = patrol
	driver.car.add_child(driver.occupant)
	driver.segment = segment
	add_child(driver.car)
	return driver


func set_police_alert(level: int, target_position: Vector3) -> void:
	if target_position.is_finite():
		_alert_target = target_position
	_alert_level = clampi(level, 0, 2)


func police_vehicle() -> Car:
	return _patrol.car if _patrol != null else null


func interaction_vehicles() -> Array[Vehicle]:
	var vehicles: Array[Vehicle] = []
	for driver: Driver in _drivers:
		vehicles.append(driver.car)
	if _patrol != null:
		vehicles.append(_patrol.car)
	return vehicles


func take_for_player(vehicle: Vehicle) -> bool:
	if _patrol != null and _patrol.car == vehicle:
		_release_driver(_patrol)
		_patrol = null
		return true
	for driver: Driver in _drivers:
		if driver.car == vehicle:
			if driver == _pilot:
				_pilot = null
			_release_driver(driver)
			_drivers.erase(driver)
			return true
	return false


func _release_driver(driver: Driver) -> void:
	# Keep the vehicle and damage state available to the player after removing its AI.
	driver.occupant.hide()
	driver.car.set_driver_active(false)
	driver.car.name = "ClaimedTraffic%d" % driver.car.get_instance_id()


func reset() -> void:
	_alert_level = 0
	_remove_patrol()
	# Wait for the player's reset pose to reach the physics server.
	_reset_tick = Engine.get_physics_frames() + 1


func _pose_clear(pose: Transform3D, excluded: Array[RID]) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _spawn_shape
	query.transform = Transform3D(pose.basis, pose * Car.CHASSIS_CENTER)
	query.collision_mask = Vehicle.WORLD_LAYER | Vehicle.PERSON_LAYER | 4
	query.exclude = excluded
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _physics_process(delta: float) -> void:
	if _route.is_empty():
		return
	if _reset_tick >= 0 and Engine.get_physics_frames() >= _reset_tick:
		_reset_tick = -1
		if _pilot != null and _pose_clear(_spawn_pose, [_pilot.car.get_rid()]):
			_pilot.segment = _spawn_segment
			_pilot.car.reset_to(_spawn_pose)
	_population_clock += delta
	if _population_clock >= POPULATION_INTERVAL:
		_population_clock = 0.0
		_refresh_local_traffic()
		_refresh_patrol()
	for driver in _drivers:
		driver.idle_seconds = driver.idle_seconds + delta if driver.car.get_speed_mps() < 0.1 else 0.0
		_drive(driver, delta)
	if _patrol != null:
		var cruise := CRUISE_SPEED + 2.5 * _alert_level
		if _alert_level > 0 and _patrol.car.global_position.distance_squared_to(_alert_target) < PATROL_APPROACH_DISTANCE ** 2:
			cruise = PATROL_APPROACH_SPEED
		_drive(_patrol, delta, cruise)


func _refresh_local_traffic() -> void:
	if not is_instance_valid(_camera) or not _camera.is_inside_tree():
		return
	var observer := _camera.global_position
	var frustum := _camera.get_frustum()
	for local: Driver in _drivers.duplicate():
		if local == _pilot:
			continue
		var distance_squared := observer.distance_squared_to(local.car.global_position)
		var distant := distance_squared > DESPAWN_DISTANCE * DESPAWN_DISTANCE
		var stuck_away := local.idle_seconds >= STUCK_TIME and distance_squared > SPAWN_NEAR * SPAWN_NEAR
		if (distant or stuck_away) and _outside_view(local.car.global_position, frustum):
			_drivers.erase(local)
			local.car.queue_free()
	if _drivers.size() >= clampi(civilian_limit, 1, MAX_CIVILIAN_LIMIT):
		return
	if _pilot == null and _spawn_clear(_spawn_pose, observer, frustum):
		_add_pilot(_spawn_pose, _spawn_segment)
		return
	for segment in range(_route.size() - 1):
		var span := _route[segment].distance_to(_route[segment + 1])
		if span < 12.0:
			continue
		for fraction: float in [0.5, 0.25, 0.75]:
			var candidate := _lane_pose(segment, span * fraction)
			if _spawn_clear(candidate, observer, frustum):
				if _pilot == null:
					_add_pilot(candidate, segment)
				else:
					_add_local(candidate, segment)
				return


func _spawn_clear(candidate: Transform3D, observer: Vector3, frustum: Array[Plane]) -> bool:
	var distance_squared := observer.distance_squared_to(candidate.origin)
	return distance_squared >= SPAWN_NEAR * SPAWN_NEAR and distance_squared <= SPAWN_FAR * SPAWN_FAR \
		and _outside_view(candidate.origin, frustum) and _spaced_from_traffic(candidate.origin, SPAWN_SPACING) \
		and _pose_clear(candidate, [])


func _spaced_from_traffic(position_on_road: Vector3, spacing: float) -> bool:
	var spacing_squared := spacing * spacing
	for driver: Driver in _drivers:
		if driver.car.global_position.distance_squared_to(position_on_road) < spacing_squared:
			return false
	return _patrol == null or _patrol.car.global_position.distance_squared_to(position_on_road) >= spacing_squared


func _refresh_patrol() -> void:
	if not is_instance_valid(_camera) or not _camera.is_inside_tree():
		return
	var frustum := _camera.get_frustum()
	if _patrol != null:
		var position_on_road := _patrol.car.global_position
		if _alert_level == 0 and _outside_view(position_on_road, frustum) \
				and position_on_road.distance_squared_to(_camera.global_position) > PATROL_RETIRE_DISTANCE ** 2:
			_remove_patrol()
		return
	if _alert_level == 0:
		return

	# Follow the existing directed circuit toward the nearest point to the player.
	var closest_segment := 0
	var closest_offset := 0.0
	var closest_distance := INF
	for segment in range(_route.size() - 1):
		var point := Geometry3D.get_closest_point_to_segment(_alert_target, _route[segment], _route[segment + 1])
		var distance := point.distance_squared_to(_alert_target)
		if distance < closest_distance:
			closest_segment = segment
			closest_offset = point.distance_to(_route[segment])
			closest_distance = distance

	for behind: float in PATROL_SPAWN_OFFSETS:
		var segment := closest_segment
		var offset := closest_offset - behind
		# Walk back no more than one circuit, even on a short route.
		for step in range(_route.size() - 1):
			if offset >= 0.0:
				break
			segment = posmod(segment - 1, _route.size() - 1)
			offset += _route[segment].distance_to(_route[segment + 1])
		if offset < 0.0:
			continue
		var spawn := _lane_pose(segment, offset)
		var distance_squared := spawn.origin.distance_squared_to(_alert_target)
		if distance_squared >= PATROL_MIN_DISTANCE ** 2 and distance_squared <= PATROL_MAX_DISTANCE ** 2 \
				and _outside_view(spawn.origin, frustum) and _spaced_from_traffic(spawn.origin, PATROL_SPAWN_SPACING) \
				and _pose_clear(spawn, []):
			_patrol = _create_car(Car.new(true), spawn, segment, "PatrolCar", Color("8296a8"), true)
			return


func _remove_patrol() -> void:
	if _patrol == null:
		return
	_patrol.car.queue_free()
	_patrol = null


func _outside_view(position: Vector3, frustum: Array[Plane]) -> bool:
	# Reject positions near the frame boundary as well as centers inside the view.
	for plane in frustum:
		if plane.distance_to(position) > VISIBILITY_MARGIN:
			return true
	return false


func _drive(driver: Driver, delta: float, cruise_speed: float = CRUISE_SPEED) -> void:
	var car := driver.car
	var position_on_road := car.global_position
	position_on_road.y = 0.0
	var closest := _closest_on_lane(driver, position_on_road)
	var target := _point_ahead(driver.segment, closest)
	var offset := target - position_on_road
	var desired_yaw := atan2(-offset.x, -offset.z)
	var yaw_error := angle_difference(car.global_rotation.y, desired_yaw)
	var steering := -clampf(yaw_error / 0.52, -1.0, 1.0)
	var speed := car.get_speed_mps()
	var stopping_distance := speed * speed / (2.0 * car.brake_deceleration)
	var sweep := -car.global_basis.z * (STANDOFF + stopping_distance + speed * delta * 2.0)
	if car.test_move(car.global_transform, sweep):
		car.set_controls(0.0, steering, true)
		return
	var target_speed := lerpf(cruise_speed, CORNER_SPEED, smoothstep(0.14, 0.62, absf(yaw_error)))
	car.set_controls(target_speed / car.max_forward_speed, steering, speed > target_speed + 0.38)


func _closest_on_lane(driver: Driver, position_on_road: Vector3) -> Vector3:
	var closest := Geometry3D.get_closest_point_to_segment(position_on_road, _route[driver.segment], _route[driver.segment + 1])
	var closest_error := position_on_road.distance_squared_to(closest)
	var ahead := STEERING_LOOK_AHEAD * 1.5 - closest.distance_to(_route[driver.segment + 1])
	var next_segment := driver.segment
	# Search a short stretch ahead for a tight turn's closely spaced lane points.
	for step in range(_route.size() - 2):
		if ahead <= 0.0:
			break
		next_segment = (next_segment + 1) % (_route.size() - 1)
		var start_point := _route[next_segment]
		var end_point := _route[next_segment + 1]
		var candidate := Geometry3D.get_closest_point_to_segment(position_on_road, start_point, start_point.move_toward(end_point, ahead))
		var error := position_on_road.distance_squared_to(candidate)
		if error + 0.0125 < closest_error or (step == 0 and position_on_road.distance_squared_to(start_point) < 0.09):
			closest = candidate
			closest_error = error
			driver.segment = next_segment
		ahead -= start_point.distance_to(end_point)
	return closest


func _point_ahead(segment: int, from: Vector3) -> Vector3:
	var remaining := STEERING_LOOK_AHEAD
	for step in range(_route.size() - 1):
		var next_point := _route[(segment + step) % (_route.size() - 1) + 1]
		var length := from.distance_to(next_point)
		if length >= remaining:
			return from.move_toward(next_point, remaining)
		remaining -= length
		from = next_point
	return from
