extends CharacterBody3D
## Shared lightweight Phase 1 arcade movement. Front is local -Z.
## Subclasses construct their original body/shape in their own _init().

@export_range(1.0, 35.0, 0.5) var max_forward_speed: float = 18.0
@export_range(1.0, 12.0, 0.5) var max_reverse_speed: float = 5.0
@export_range(1.0, 25.0, 0.5) var acceleration: float = 8.0
@export_range(1.0, 30.0, 0.5) var brake_deceleration: float = 16.0
@export_range(0.1, 12.0, 0.1) var coast_deceleration: float = 2.8
@export_range(0.2, 3.0, 0.05) var turn_rate: float = 1.45

const GRAVITY: float = 24.0
const TERMINAL_FALL_SPEED: float = 35.0
const FALL_RESET_Y: float = -25.0
var wheel_radius: float = 0.32
var vehicle_label: String = "Vehicle"
var exit_side_offset: float = 1.48
var follow_distance: float = 6.9
var steering_full_speed: float = 3.0
var high_speed_steering_factor: float = 0.55
var visual_steering_angle: float = 0.42

var driver_active: bool = false
var _throttle: float = 0.0
var _steering: float = 0.0
var _braking: bool = true
var _signed_speed: float = 0.0
var _home_transform: Transform3D = Transform3D.IDENTITY
var _front_wheels: Array[Node3D] = []
var _wheel_rolls: Array[Node3D] = []
var _wheel_angle: float = 0.0
var _brake_material: StandardMaterial3D


func _init() -> void:
	name = "Phase1Vehicle"
	# Physics layer bit values: world=1, walking player=2, vehicle=4.
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	floor_snap_length = 0.45
	floor_max_angle = deg_to_rad(34.0)
	floor_stop_on_slope = true
	safe_margin = 0.025
	max_slides = 4


func _ready() -> void:
	_home_transform = global_transform


func set_driver_active(active: bool) -> void:
	driver_active = active
	if not active:
		# Park immediately when handed back to the walking controller.
		_throttle = 0.0
		_steering = 0.0
		_braking = true
		_signed_speed = 0.0
		velocity.x = 0.0
		velocity.z = 0.0


func set_controls(throttle: float, steering: float, brake: bool) -> void:
	# Bounded programmatic input keeps bad controller values out of physics.
	_throttle = clampf(throttle, -1.0, 1.0) if is_finite(throttle) else 0.0
	_steering = clampf(steering, -1.0, 1.0) if is_finite(steering) else 0.0
	_braking = brake


func get_speed_mps() -> float:
	return Vector2(velocity.x, velocity.z).length()


func reset_to(pose: Transform3D) -> void:
	# The caller chooses a clear, grounded pose. Reject corrupt transforms and
	# retain only heading so resets cannot leave this upright arcade car tilted.
	if not pose.origin.is_finite():
		return
	if not pose.basis.x.is_finite() or not pose.basis.y.is_finite() or not pose.basis.z.is_finite():
		return
	var forward: Vector3 = -pose.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return
	forward = forward.normalized()
	var heading: float = atan2(-forward.x, -forward.z)
	var upright_pose := Transform3D(Basis(Vector3.UP, heading), pose.origin)
	if is_inside_tree():
		global_transform = upright_pose
		reset_physics_interpolation()
	else:
		transform = upright_pose
	_home_transform = upright_pose
	velocity = Vector3.ZERO
	_signed_speed = 0.0
	_throttle = 0.0
	_steering = 0.0
	_braking = true
	_wheel_angle = 0.0
	_update_wheels(0.0)


func _physics_process(delta: float) -> void:
	if not global_position.is_finite() or global_position.y < FALL_RESET_Y:
		reset_to(_home_transform)
		return

	var throttle: float = _throttle if driver_active else 0.0
	var steering: float = _steering if driver_active else 0.0
	var braking: bool = _braking or not driver_active
	_update_longitudinal_speed(throttle, braking, delta)

	# Steering increases from rest and softens near top speed. Reversing reverses
	# the yaw response just as it does in a normal car. No stationary pivot turns.
	var steering_gain: float = clampf(absf(_signed_speed) / steering_full_speed, 0.0, 1.0)
	var speed_ratio: float = clampf(absf(_signed_speed) / max_forward_speed, 0.0, 1.0)
	var speed_softening: float = lerpf(1.0, high_speed_steering_factor, speed_ratio)
	var travel_sign: float = signf(_signed_speed)
	if is_on_floor():
		rotate_y(-steering * turn_rate * steering_gain * speed_softening * travel_sign * delta)

	var forward: Vector3 = -global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	velocity.x = forward.x * _signed_speed
	velocity.z = forward.z * _signed_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y = maxf(velocity.y - GRAVITY * delta, -TERMINAL_FALL_SPEED)

	move_and_slide()
	# Consume the collision-adjusted speed so a frontal impact does not retain
	# an invisible high speed that instantly reappears after leaving the wall.
	_signed_speed = clampf(velocity.dot(forward), -max_reverse_speed, max_forward_speed)
	_update_wheels(delta)
	if _brake_material != null:
		_brake_material.emission_energy_multiplier = 1.7 if braking else 0.3


func _update_longitudinal_speed(throttle: float, braking: bool, delta: float) -> void:
	if braking:
		_signed_speed = move_toward(_signed_speed, 0.0, brake_deceleration * delta)
	elif absf(throttle) < 0.05:
		_signed_speed = move_toward(_signed_speed, 0.0, coast_deceleration * delta)
	elif _signed_speed * throttle < -0.1:
		# Opposite throttle brakes to a halt before changing direction.
		_signed_speed = move_toward(_signed_speed, 0.0, brake_deceleration * delta)
	else:
		var limit: float = max_forward_speed if throttle > 0.0 else max_reverse_speed
		_signed_speed = move_toward(_signed_speed, throttle * limit, acceleration * delta)


func _update_wheels(delta: float) -> void:
	_wheel_angle = wrapf(_wheel_angle - _signed_speed * delta / wheel_radius, -PI, PI)
	for wheel: Node3D in _wheel_rolls:
		wheel.rotation.x = _wheel_angle
	var visual_steering: float = _steering if driver_active else 0.0
	for wheel: Node3D in _front_wheels:
		wheel.rotation.y = -visual_steering * visual_steering_angle


func _build_collision(dimensions: Vector3, center: Vector3) -> void:
	var collider := CollisionShape3D.new()
	collider.name = "ChassisCollision"
	var box := BoxShape3D.new()
	box.size = dimensions
	collider.shape = box
	collider.position = center
	add_child(collider)


func _add_wheel_at(at: Vector3, tire_material: Material, hub_material: Material, front: bool, radius: float = 0.32, width: float = 0.22) -> Node3D:
	var steering_pivot := Node3D.new()
	steering_pivot.name = "FrontWheel" if front else "RearWheel"
	steering_pivot.position = at
	add_child(steering_pivot)
	if front:
		_front_wheels.append(steering_pivot)
	var roll := Node3D.new()
	steering_pivot.add_child(roll)
	_wheel_rolls.append(roll)
	var wheel := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = width
	cylinder.radial_segments = 12
	cylinder.rings = 1
	wheel.mesh = cylinder
	wheel.material_override = tire_material
	wheel.rotation.z = PI * 0.5
	roll.add_child(wheel)
	var hub := MeshInstance3D.new()
	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = radius * 0.5
	hub_mesh.bottom_radius = radius * 0.5
	hub_mesh.height = width + 0.015
	hub_mesh.radial_segments = 8
	hub_mesh.rings = 1
	hub.mesh = hub_mesh
	hub.material_override = hub_material
	hub.rotation.z = PI * 0.5
	roll.add_child(hub)
	return steering_pivot


func _add_box(part_name: String, size: Vector3, at: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.name = part_name
	var box := BoxMesh.new()
	box.size = size
	part.mesh = box
	part.position = at
	part.material_override = material
	add_child(part)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	return material
