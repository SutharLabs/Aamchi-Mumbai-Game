extends CharacterBody3D

signal impacted(vehicle: CharacterBody3D, collider: Object, closing_speed: float)
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
const MAX_CURB_RISE: float = 0.25
const STEP_PROBE_MARGIN: float = 0.006
const STEP_EDGE_CLEARANCE: float = 0.055
const WORLD_LAYER: int = 1
const PERSON_LAYER: int = 2
const DAMAGE_SPEED := 4.0
const REPORT_SPEED := 5.0
var wheel_radius: float = 0.32
var vehicle_label: String = "Vehicle"
var is_two_wheeler: bool = false
var exit_side_offset: float = 1.48
var preferred_exit_side: float = -1.0
var follow_distance: float = 6.9
var steering_full_speed: float = 3.0
var high_speed_steering_factor: float = 0.55
var visual_steering_angle: float = 0.42
var chassis_mass: float = 1100.0

var driver_active: bool = false
var impact_velocity := Vector3.ZERO
var impact_normal := Vector3.ZERO
var impact_position := Vector3.ZERO
var _damage := 0.0
var _impact_drift := Vector3.ZERO
var _throttle: float = 0.0
var _steering: float = 0.0
var _braking: bool = true
var _signed_speed: float = 0.0
var _home_transform: Transform3D = Transform3D.IDENTITY
var _front_wheels: Array[Node3D] = []
var _wheel_rolls: Array[Node3D] = []
var _wheel_angle: float = 0.0
var _brake_material: StandardMaterial3D
var _step_contact := KinematicCollision3D.new()


func _init() -> void:
	name = "Phase1Vehicle"
	# Physics layer bit values: world=1, people=2, vehicle=4.
	collision_layer = 4
	collision_mask = WORLD_LAYER | PERSON_LAYER | 4
	platform_floor_layers = WORLD_LAYER
	floor_snap_length = 0.28
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


func condition_percent() -> int:
	return roundi((1.0 - _damage) * 100.0)


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
	_impact_drift = Vector3.ZERO
	if _damage > 0.0:
		_damage = 0.0
		_restore_bodywork()
	_update_wheels(0.0)


func _physics_process(delta: float) -> void:
	if not global_position.is_finite() or global_position.y < FALL_RESET_Y:
		reset_to(_home_transform)
		return

	var throttle: float = _throttle if driver_active else 0.0
	var steering := clampf(_steering + _damage_steering_pull(), -1.0, 1.0) if driver_active else 0.0
	var braking: bool = _braking or not driver_active
	_update_longitudinal_speed(throttle, braking, delta)

	# Steering increases from rest and softens near top speed. Reversing reverses
	# the yaw response just as it does in a normal car. No stationary pivot turns.
	var steering_gain: float = clampf(absf(_signed_speed) / steering_full_speed, 0.0, 1.0)
	var speed_ratio: float = clampf(absf(_signed_speed) / max_forward_speed, 0.0, 1.0)
	var speed_softening: float = lerpf(1.0, high_speed_steering_factor, speed_ratio)
	var travel_sign: float = signf(_signed_speed)
	var grounded := is_on_floor()
	if grounded:
		rotate_y(-steering * turn_rate * (1.0 - 0.24 * _damage) * steering_gain * speed_softening * travel_sign * delta)

	var forward: Vector3 = -global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	_impact_drift = _impact_drift.move_toward(Vector3.ZERO, 7.5 * delta)
	var drift_at_start := _impact_drift
	var approach := forward * _signed_speed + drift_at_start
	velocity.x = approach.x
	velocity.z = approach.z
	if grounded:
		velocity.y = 0.0
	else:
		velocity.y = maxf(velocity.y - GRAVITY * delta, -TERMINAL_FALL_SPEED)

	if not grounded or not _try_step(velocity * delta):
		move_and_slide()
		if approach.length_squared() >= 0.01:
			_handle_slide_impacts(approach)
	# Consume the collision-adjusted speed so a frontal impact does not retain
	# an invisible high speed that instantly reappears after leaving the wall.
	_signed_speed = clampf((velocity - drift_at_start).dot(forward), -max_reverse_speed, max_forward_speed)
	_update_wheels(delta)
	if _brake_material != null:
		_brake_material.emission_energy_multiplier = 1.7 if braking else 0.3


func _handle_slide_impacts(approach: Vector3) -> void:
	var strongest: KinematicCollision3D
	var contact_index := 0
	var closing_speed := DAMAGE_SPEED
	for slide in get_slide_collision_count():
		var contact := get_slide_collision(slide)
		for index in contact.get_collision_count():
			var normal := contact.get_normal(index)
			if absf(normal.y) >= 0.60:
				continue
			var relative := approach - contact.get_collider_velocity(index)
			relative.y = 0.0
			var speed := -relative.dot(normal)
			if speed > closing_speed and approach.dot(normal) < -0.10:
				strongest = contact
				contact_index = index
				closing_speed = speed
	if strongest == null:
		return
	var collider := strongest.get_collider(contact_index) as CollisionObject3D
	var surface_normal := strongest.get_normal(contact_index)
	var point := strongest.get_position(contact_index)
	_emit_impact(approach, collider, closing_speed, point, surface_normal)
	if not is_instance_valid(collider) or (collider.collision_layer & PERSON_LAYER) != 0:
		return
	_record_chassis_damage(closing_speed, point, surface_normal)
	var away := Vector3(surface_normal.x, 0.0, surface_normal.z).normalized()
	if collider is CharacterBody3D and collider.has_method("_receive_vehicle_hit"):
		var fraction: float = collider._receive_vehicle_hit(closing_speed, point, -away, chassis_mass)
		_add_impact_drift(away * minf(closing_speed * fraction * 0.24, 2.2))
	elif closing_speed > 8.0:
		_add_impact_drift(away * minf((closing_speed - 8.0) * 0.15, 1.35))


func _receive_vehicle_hit(speed: float, point: Vector3, away: Vector3, other_mass: float) -> float:
	var other_share := other_mass / (other_mass + chassis_mass)
	_record_chassis_damage(speed * lerpf(0.56, 1.0, other_share), point, away)
	_add_impact_drift(away * minf(speed * other_share * 0.46, 3.2))
	return 1.0 - other_share


func _add_impact_drift(push: Vector3) -> void:
	_impact_drift = (_impact_drift + push).limit_length(3.2)


func _emit_impact(approach: Vector3, collider: Object, speed: float, point: Vector3, normal: Vector3) -> void:
	if speed < REPORT_SPEED or not impacted.has_connections():
		return
	impact_velocity = approach
	impact_normal = normal
	impact_position = point
	impacted.emit(self, collider, speed)


func _record_chassis_damage(speed: float, point: Vector3, normal: Vector3) -> void:
	if not is_finite(speed) or not point.is_finite() or not normal.is_finite() or speed <= DAMAGE_SPEED:
		return
	var severity := clampf((speed * speed - DAMAGE_SPEED * DAMAGE_SPEED) / 340.0, 0.0, 0.78)
	if severity < 0.012:
		return
	_damage = minf(_damage + severity * 0.76, 0.92)
	_damage_bodywork(severity, to_local(point), global_basis.inverse() * normal)


func _damage_bodywork(_severity: float, _point: Vector3, _normal: Vector3) -> void:
	pass


func _restore_bodywork() -> void:
	pass


func _damage_steering_pull() -> float:
	return 0.0


func _try_step(motion: Vector3) -> bool:
	if motion.length_squared() < 0.000001:
		return false
	var start := global_transform
	var direction := motion.normalized()
	# At crawl speed a single tick can be shorter than the collision margin.
	# Probe just past the lip so the downward sweep reaches the top face.
	var across_edge := motion + direction * STEP_EDGE_CLEARANCE
	if not test_move(start, across_edge, _step_contact, safe_margin):
		return false
	if _step_contact.get_travel().dot(direction) > motion.length() + safe_margin:
		return false
	var hit := _step_contact.get_collider() as CollisionObject3D
	var normal := _step_contact.get_normal()
	if hit != null and (hit.collision_layer & PERSON_LAYER) != 0 and direction.dot(normal) < -0.1:
		# Stop before a frontal contact. Sliding the chassis into a capsule can push it aside.
		var approach := Vector3(velocity.x, 0.0, velocity.z)
		var relative := approach - _step_contact.get_collider_velocity()
		relative.y = 0.0
		_emit_impact(approach, hit, -relative.dot(normal), _step_contact.get_position(), normal)
		velocity.x = 0.0
		velocity.z = 0.0
		return false
	var floor_dot := cos(floor_max_angle)
	if normal.y < -0.05 or normal.y >= floor_dot or not _is_static_world_contact():
		return false

	# Sweep the full chassis upward, over the curb and down to support. Each
	# segment checks overhead clearance and other collision layers as usual.
	var lift := Vector3.UP * MAX_CURB_RISE
	if test_move(start, lift, null, STEP_PROBE_MARGIN, true):
		return false
	var raised := start.translated(lift)
	if test_move(raised, across_edge, null, STEP_PROBE_MARGIN, true):
		return false
	var above_landing := raised.translated(across_edge)
	if not test_move(above_landing, -lift, _step_contact, safe_margin):
		return false
	if _step_contact.get_normal().y < floor_dot or not _is_static_world_contact():
		return false
	var landing := above_landing.translated(_step_contact.get_travel())
	var rise := landing.origin.y - start.origin.y
	if rise <= STEP_PROBE_MARGIN or rise > MAX_CURB_RISE:
		return false
	global_transform = landing
	return true


func _is_static_world_contact() -> bool:
	var surface := _step_contact.get_collider() as StaticBody3D
	return surface != null and (surface.collision_layer & WORLD_LAYER) != 0


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
		var drive_scale := 1.0 - _damage * 0.56
		_signed_speed = move_toward(_signed_speed, throttle * limit * drive_scale, acceleration * drive_scale * delta)


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
