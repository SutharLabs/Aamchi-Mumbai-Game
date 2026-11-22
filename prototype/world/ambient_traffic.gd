extends Node3D
## One route-following hatchback using the shared arcade chassis and solid layers.

const Car := preload("res://vehicle/phase1_car.gd")
const CRUISE_SPEED := 5.5
const CORNER_SPEED := 2.6
const STEERING_LOOK_AHEAD := 3.6
const STANDOFF := 1.15
const SPAWN_HEIGHT := 0.55

var _car: Car
var _route := PackedVector3Array()
var _segment := 0
var _spawn_segment := 0
var _spawn_pose := Transform3D.IDENTITY
var _reset_tick := -1


func start(route: PackedVector3Array, spawn_distance: float) -> void:
	if _car != null or route.size() < 4 or not route[0].is_equal_approx(route[-1]):
		return
	for index in range(route.size() - 1):
		if not route[index].is_finite() or route[index].distance_squared_to(route[index + 1]) < 0.0001:
			return
	_route = route
	_place_start(maxf(0.0, spawn_distance))
	_car = Car.new()
	_car.name = "TrafficCar"
	_car.reset_to(_spawn_pose)
	_car.set_driver_active(true)
	add_child(_car)


func _place_start(distance: float) -> void:
	var last_segment := _route.size() - 2
	while _spawn_segment < last_segment:
		var span := _route[_spawn_segment].distance_to(_route[_spawn_segment + 1])
		if distance < span:
			break
		distance -= span
		_spawn_segment += 1
	_segment = _spawn_segment
	var start_point := _route[_segment]
	var lane_delta := _route[_segment + 1] - start_point
	var forward := lane_delta.normalized()
	var position_on_lane := start_point + forward * minf(distance, lane_delta.length())
	var heading := atan2(-forward.x, -forward.z)
	_spawn_pose = Transform3D(Basis(Vector3.UP, heading), position_on_lane + Vector3.UP * SPAWN_HEIGHT)


func reset() -> void:
	# Let the other actors' new reset poses reach the physics server first.
	_reset_tick = Engine.get_physics_frames() + 1


func _reset_if_clear() -> void:
	var chassis := _car.get_node("ChassisCollision") as CollisionShape3D
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = chassis.shape
	query.transform = _spawn_pose * chassis.transform
	query.collision_mask = _car.collision_mask
	query.exclude = [_car.get_rid()]
	if not _car.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
		return
	_segment = _spawn_segment
	_car.reset_to(_spawn_pose)


func _physics_process(delta: float) -> void:
	if _car == null:
		return
	if _reset_tick >= 0 and Engine.get_physics_frames() >= _reset_tick:
		_reset_tick = -1
		_reset_if_clear()
	var position_on_road := _car.global_position
	position_on_road.y = 0.0
	var closest := _closest_on_lane(position_on_road)
	var target := _point_ahead(closest)
	var offset := target - position_on_road
	var desired_yaw := atan2(-offset.x, -offset.z)
	var yaw_error := angle_difference(_car.global_rotation.y, desired_yaw)
	var steering := -clampf(yaw_error / 0.52, -1.0, 1.0)
	var speed := _car.get_speed_mps()
	var stopping_distance := speed * speed / (2.0 * _car.brake_deceleration)
	var sweep := -_car.global_basis.z * (STANDOFF + stopping_distance + speed * delta * 2.0)
	if _car.test_move(_car.global_transform, sweep):
		_car.set_controls(0.0, steering, true)
		return
	var target_speed := lerpf(CRUISE_SPEED, CORNER_SPEED, smoothstep(0.14, 0.62, absf(yaw_error)))
	_car.set_controls(target_speed / _car.max_forward_speed, steering, speed > target_speed + 0.38)


func _closest_on_lane(position_on_road: Vector3) -> Vector3:
	var closest := Geometry3D.get_closest_point_to_segment(position_on_road, _route[_segment], _route[_segment + 1])
	var closest_error := position_on_road.distance_squared_to(closest)
	var ahead := STEERING_LOOK_AHEAD * 1.5 - closest.distance_to(_route[_segment + 1])
	var next_segment := _segment
	# Search a short stretch ahead for a tight turn's closely spaced lane points.
	# This keeps the cursor on its chosen route even when another lane is nearby.
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
			_segment = next_segment
		ahead -= start_point.distance_to(end_point)
	return closest


func _point_ahead(from: Vector3) -> Vector3:
	var remaining := STEERING_LOOK_AHEAD
	for step in range(_route.size() - 1):
		var next_point := _route[(_segment + step) % (_route.size() - 1) + 1]
		var length := from.distance_to(next_point)
		if length >= remaining:
			return from.move_toward(next_point, remaining)
		remaining -= length
		from = next_point
	return from
