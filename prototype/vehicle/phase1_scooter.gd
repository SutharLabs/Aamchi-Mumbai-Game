extends "res://vehicle/phase1_two_wheeler.gd"
## Unbranded modern Indian step-through scooter placeholder, front local -Z.


func _init() -> void:
	super()
	name = "Phase1Scooter"
	vehicle_label = "Scooter"
	exit_side_offset = 1.0
	follow_distance = 5.6
	max_forward_speed = 14.0
	max_reverse_speed = 1.8
	acceleration = 6.8
	brake_deceleration = 13.0
	coast_deceleration = 3.2
	turn_rate = 2.05
	steering_full_speed = 2.1
	high_speed_steering_factor = 0.40
	visual_steering_angle = 0.48
	wheel_radius = 0.245
	max_lean_radians = deg_to_rad(16.0)
	_build_collision(Vector3(0.70, 1.90, 1.90), Vector3(0.0, 0.45, 0.0))
	_build_placeholder()
	_build_rider(true)


func _build_placeholder() -> void:
	var paint: StandardMaterial3D = _material(Color(0.12, 0.36, 0.55))
	var dark: StandardMaterial3D = _material(Color(0.045, 0.055, 0.065))
	var trim: StandardMaterial3D = _material(Color(0.55, 0.59, 0.62))
	var tire: StandardMaterial3D = _material(Color(0.018, 0.023, 0.028))
	var lamp: StandardMaterial3D = _material(Color(1.0, 0.96, 0.80))
	lamp.emission_enabled = true
	lamp.emission = Color(0.89, 0.83, 0.58)
	lamp.emission_energy_multiplier = 0.5
	_brake_material = _material(Color(0.74, 0.03, 0.015))
	_brake_material.emission_enabled = true
	_brake_material.emission = Color(0.9, 0.02, 0.01)
	_visual_wheel(Vector3(0.0, -0.255, -0.63), tire, trim, true, 0.13)
	_visual_wheel(Vector3(0.0, -0.255, 0.63), tire, trim, false, 0.14)
	_visual_box("RearBody", Vector3(0.48, 0.39, 0.80), Vector3(0.0, -0.035, 0.42), paint)
	_visual_box("Seat", Vector3(0.39, 0.13, 0.72), Vector3(0.0, 0.235, 0.24), dark)
	_visual_box("Floorboard", Vector3(0.47, 0.085, 0.68), Vector3(0.0, -0.255, -0.18), dark)
	_visual_box("LegShield", Vector3(0.49, 0.64, 0.17), Vector3(0.0, 0.12, -0.55), paint)
	_visual_box("FrontStem", Vector3(0.18, 0.21, 0.17), Vector3(0.0, 0.48, -0.55), paint)
	_visual_box("FrontMudguard", Vector3(0.20, 0.08, 0.47), Vector3(0.0, 0.04, -0.63), paint)
	_visual_box("HandlebarCowl", Vector3(0.49, 0.18, 0.22), Vector3(0.0, 0.56, -0.56), paint)
	_visual_box("Headlamp", Vector3(0.30, 0.12, 0.04), Vector3(0.0, 0.56, -0.685), lamp)
	_visual_box("Handlebar", Vector3(0.65, 0.05, 0.065), Vector3(0.0, 0.57, -0.52), dark)
	_visual_box("TailLamp", Vector3(0.29, 0.15, 0.04), Vector3(0.0, 0.09, 0.84), _brake_material)
	_visual_box("GrabRail", Vector3(0.40, 0.055, 0.08), Vector3(0.0, 0.30, 0.67), trim)
	for side: float in [-1.0, 1.0]:
		_visual_box("RearSidePanel", Vector3(0.055, 0.28, 0.69), Vector3(side * 0.24, -0.015, 0.42), paint)
		_visual_box("MirrorArm", Vector3(0.03, 0.20, 0.03), Vector3(side * 0.285, 0.68, -0.52), dark)
		_visual_box("Mirror", Vector3(0.12, 0.095, 0.045), Vector3(side * 0.285, 0.80, -0.52), trim)
