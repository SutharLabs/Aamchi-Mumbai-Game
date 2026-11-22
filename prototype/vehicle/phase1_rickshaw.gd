extends "res://vehicle/phase1_vehicle.gd"
## Generic contemporary Mumbai auto study, built from original primitives.
## Reference proportions are interpreted for gameplay; this is not an OEM replica.


func _init() -> void:
	name = "Phase1Rickshaw"
	vehicle_label = "Auto-rickshaw"
	exit_side_offset = 1.30
	follow_distance = 6.2
	max_forward_speed = 13.0
	max_reverse_speed = 3.5
	acceleration = 5.8
	brake_deceleration = 12.0
	coast_deceleration = 3.3
	turn_rate = 2.0
	steering_full_speed = 2.3
	high_speed_steering_factor = 0.40
	visual_steering_angle = 0.54
	wheel_radius = 0.25
	# The bottom matches the car's -0.50 m local datum. Whole-cabin collision
	# includes the canopy, unlike a thin chassis-only auto model.
	_build_collision(Vector3(1.30, 1.65, 2.70), Vector3(0.0, 0.325, 0.0))
	_build_placeholder()


func _build_placeholder() -> void:
	var body: StandardMaterial3D = _material(Color(0.045, 0.055, 0.065))
	var canopy: StandardMaterial3D = _material(Color(0.97, 0.66, 0.065))
	var window: StandardMaterial3D = _material(Color(0.14, 0.31, 0.35))
	var seat: StandardMaterial3D = _material(Color(0.11, 0.095, 0.075))
	var tire: StandardMaterial3D = _material(Color(0.025, 0.028, 0.032))
	var trim: StandardMaterial3D = _material(Color(0.52, 0.55, 0.57))
	var lamp: StandardMaterial3D = _material(Color(1.0, 0.94, 0.72))
	lamp.emission_enabled = true
	lamp.emission = Color(0.93, 0.82, 0.46)
	lamp.emission_energy_multiplier = 0.6
	_brake_material = _material(Color(0.74, 0.04, 0.025))
	_brake_material.emission_enabled = true
	_brake_material.emission = Color(0.9, 0.02, 0.01)
	_brake_material.emission_energy_multiplier = 0.3

	_add_box("Floorboard", Vector3(1.14, 0.14, 1.98), Vector3(0.0, -0.22, 0.23), body)
	_add_box("RearEngineBody", Vector3(1.24, 0.62, 0.24), Vector3(0.0, 0.04, 1.18), body)
	_add_box("RearBench", Vector3(1.00, 0.16, 0.48), Vector3(0.0, 0.20, 0.69), seat)
	_add_box("RearBackrest", Vector3(1.00, 0.43, 0.12), Vector3(0.0, 0.47, 0.96), seat)
	_add_box("DriverSeat", Vector3(0.52, 0.15, 0.42), Vector3(0.0, 0.07, -0.34), seat)
	_add_box("DriverBackrest", Vector3(0.52, 0.40, 0.11), Vector3(0.0, 0.31, -0.09), seat)

	# Open sides are deliberately readable from the driving camera: low rails,
	# narrow posts and a separate roof, with no solid side-window slabs.
	for side: float in [-1.0, 1.0]:
		_add_box("LowSidePanel", Vector3(0.10, 0.31, 1.38), Vector3(side * 0.57, -0.005, 0.47), body)
		_add_box("RearCanopyPost", Vector3(0.065, 0.99, 0.07), Vector3(side * 0.57, 0.55, 1.10), body)
		_add_box("WindshieldPost", Vector3(0.065, 0.72, 0.065), Vector3(side * 0.52, 0.66, -0.66), canopy)
		_add_box("MirrorArm", Vector3(0.14, 0.04, 0.04), Vector3(side * 0.62, 0.66, -0.66), body)
		_add_box("Mirror", Vector3(0.075, 0.13, 0.055), Vector3(side * 0.69, 0.70, -0.66), trim)
		_add_box("RearLamp", Vector3(0.15, 0.17, 0.035), Vector3(side * 0.46, 0.04, 1.315), _brake_material)
		_add_wheel_at(Vector3(side * 0.55, -0.25, 0.95), tire, trim, false, wheel_radius, 0.18)

	_add_box("FrontNose", Vector3(1.02, 0.42, 0.34), Vector3(0.0, 0.025, -0.92), body)
	_add_box("FrontApron", Vector3(0.73, 0.19, 0.30), Vector3(0.0, -0.21, -1.08), body)
	_add_box("Windshield", Vector3(0.98, 0.53, 0.045), Vector3(0.0, 0.68, -0.685), window)
	_add_box("WindshieldHeader", Vector3(1.10, 0.10, 0.12), Vector3(0.0, 1.00, -0.64), canopy)
	_add_box("Handlebar", Vector3(0.55, 0.045, 0.055), Vector3(0.0, 0.33, -0.50), body)
	_add_box("Headlamp", Vector3(0.35, 0.17, 0.045), Vector3(0.0, 0.04, -1.115), lamp)
	_add_box("FrontBumper", Vector3(1.02, 0.08, 0.09), Vector3(0.0, -0.21, -1.27), trim)
	_add_box("CanopyRoof", Vector3(1.26, 0.15, 1.93), Vector3(0.0, 1.075, 0.27), canopy)
	_add_box("RearCanopy", Vector3(1.22, 0.52, 0.07), Vector3(0.0, 0.80, 1.19), body)
	_add_box("RearWindow", Vector3(0.72, 0.25, 0.035), Vector3(0.0, 0.84, 1.238), window)
	_add_wheel_at(Vector3(0.0, -0.25, -1.05), tire, trim, true, wheel_radius, 0.18)
