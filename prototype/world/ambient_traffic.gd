extends Node3D
## A loop-following pilot and one nearby car use the same arcade chassis.

const Car := preload("res://vehicle/phase1_car.gd")
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


class Driver:
	var car: Car
	var segment: int
	var idle_seconds := 0.0


var _drivers: Array[Driver] = []
var _camera: Camera3D
var _route := PackedVector3Array()
var _spawn_segment := 0
var _spawn_pose := Transform3D.IDENTITY
var _reset_tick := -1
var _population_clock := 0.0


func start(route: PackedVector3Array, spawn_distance: float, observer: Camera3D) -> void:
	if not _drivers.is_empty() or route.size() < 4 or not route[0].is_equal_approx(route[-1]):
		return
	for index in range(route.size() - 1):
		if not route[index].is_finite() or route[index].distance_squared_to(route[index + 1]) < 0.0001:
			return
	_route = route
	_camera = observer
	_place_start(maxf(0.0, spawn_distance))
	_add_car(_spawn_pose, _spawn_segment, "TrafficCar")


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


func _add_car(pose: Transform3D, segment: int, car_name: String) -> void:
	var driver := Driver.new()
	driver.car = Car.new()
	driver.car.name = car_name
	driver.car.reset_to(pose)
	driver.car.set_driver_active(true)
	driver.segment = segment
	_drivers.append(driver)
	add_child(driver.car)


func reset() -> void:
	# Wait for the player's reset pose to reach the physics server.
	_reset_tick = Engine.get_physics_frames() + 1


func _pose_clear(pose: Transform3D, excluded: Array[RID]) -> bool:
	var car := _drivers[0].car
	var chassis := car.get_node("ChassisCollision") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = chassis.shape
	query.transform = pose * chassis.transform
	query.collision_mask = car.collision_mask
	query.exclude = excluded
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _physics_process(delta: float) -> void:
	if _drivers.is_empty():
		return
	if _reset_tick >= 0 and Engine.get_physics_frames() >= _reset_tick:
		_reset_tick = -1
		var pilot := _drivers[0]
		if _pose_clear(_spawn_pose, [pilot.car.get_rid()]):
			pilot.segment = _spawn_segment
			pilot.car.reset_to(_spawn_pose)
	_population_clock += delta
	if _population_clock >= POPULATION_INTERVAL:
		_population_clock = 0.0
		_refresh_local_traffic()
	for driver in _drivers:
		driver.idle_seconds = driver.idle_seconds + delta if driver.car.get_speed_mps() < 0.1 else 0.0
		_drive(driver, delta)


func _refresh_local_traffic() -> void:
	if not is_instance_valid(_camera) or not _camera.is_inside_tree():
		return
	var observer := _camera.global_position
	var frustum := _camera.get_frustum()
	if _drivers.size() == 2:
		var local := _drivers[1]
		var distance_squared := observer.distance_squared_to(local.car.global_position)
		var distant := distance_squared > DESPAWN_DISTANCE * DESPAWN_DISTANCE
		var stuck_away := local.idle_seconds >= STUCK_TIME and distance_squared > SPAWN_NEAR * SPAWN_NEAR
		if (distant or stuck_away) and _outside_view(local.car.global_position, frustum):
			_drivers.pop_back()
			local.car.queue_free()
		return
	var pilot_position := _drivers[0].car.global_position
	for segment in range(_route.size() - 1):
		var span := _route[segment].distance_to(_route[segment + 1])
		if span < 12.0:
			continue
		var candidate := _lane_pose(segment, span * 0.5)
		if _spawn_clear(candidate, observer, pilot_position, frustum):
			_add_car(candidate, segment, "LocalTrafficCar")
			return


func _spawn_clear(candidate: Transform3D, observer: Vector3, pilot_position: Vector3, frustum: Array[Plane]) -> bool:
	var distance_squared := observer.distance_squared_to(candidate.origin)
	return distance_squared >= SPAWN_NEAR * SPAWN_NEAR and distance_squared <= SPAWN_FAR * SPAWN_FAR \
		and pilot_position.distance_squared_to(candidate.origin) >= SPAWN_SPACING * SPAWN_SPACING \
		and _outside_view(candidate.origin, frustum) and _pose_clear(candidate, [])


func _outside_view(position: Vector3, frustum: Array[Plane]) -> bool:
	# Reject positions near the frame boundary as well as centers inside the view.
	for plane in frustum:
		if plane.distance_to(position) > VISIBILITY_MARGIN:
			return true
	return false


func _drive(driver: Driver, delta: float) -> void:
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
	var target_speed := lerpf(CRUISE_SPEED, CORNER_SPEED, smoothstep(0.14, 0.62, absf(yaw_error)))
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
