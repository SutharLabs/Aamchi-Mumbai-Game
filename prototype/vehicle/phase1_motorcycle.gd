extends "res://vehicle/phase1_two_wheeler.gd"
## Unbranded modern Indian commuter-motorcycle placeholder, front local -Z.


func _init() -> void:
	super()
	name = "Phase1Motorcycle"
	vehicle_label = "Motorcycle"
	exit_side_offset = 1.05
	follow_distance = 5.9
	max_forward_speed = 20.0
	max_reverse_speed = 2.0
	acceleration = 8.8
	brake_deceleration = 15.0
	coast_deceleration = 3.0
	turn_rate = 1.75
	steering_full_speed = 2.5
	high_speed_steering_factor = 0.36
	visual_steering_angle = 0.40
	wheel_radius = 0.31
	max_lean_radians = deg_to_rad(22.0)
	_build_collision(Vector3(0.74, 1.88, 2.05), Vector3(0.0, 0.44, 0.0))
	_build_placeholder()
	_build_rider(false)


func _build_placeholder() -> void:
	var paint: StandardMaterial3D = _material(Color(0.57, 0.075, 0.065))
	var dark: StandardMaterial3D = _material(Color(0.045, 0.055, 0.065))
	var engine: StandardMaterial3D = _material(Color(0.43, 0.46, 0.47))
	var tire: StandardMaterial3D = _material(Color(0.018, 0.023, 0.028))
	var lamp: StandardMaterial3D = _material(Color(1.0, 0.94, 0.76))
	lamp.emission_enabled = true
	lamp.emission = Color(0.9, 0.79, 0.47)
	lamp.emission_energy_multiplier = 0.5
	_brake_material = _material(Color(0.72, 0.025, 0.015))
	_brake_material.emission_enabled = true
	_brake_material.emission = Color(0.9, 0.02, 0.01)
	_visual_wheel(Vector3(0.0, -0.19, -0.618), tire, engine, true, 0.115)
	_visual_wheel(Vector3(0.0, -0.19, 0.618), tire, engine, false, 0.125)
	_visual_box("Engine", Vector3(0.32, 0.32, 0.37), Vector3(0.0, -0.015, 0.0), engine)
	_visual_box("Frame", Vector3(0.13, 0.12, 0.91), Vector3(0.0, 0.13, 0.10), dark)
	_visual_box("FuelTank", Vector3(0.35, 0.28, 0.44), Vector3(0.0, 0.29, -0.18), paint)
	_visual_box("Seat", Vector3(0.32, 0.13, 0.72), Vector3(0.0, 0.22, 0.34), dark)
	_visual_box("TailBody", Vector3(0.28, 0.17, 0.38), Vector3(0.0, 0.12, 0.67), paint)
	_visual_box("FrontMudguard", Vector3(0.18, 0.075, 0.53), Vector3(0.0, 0.16, -0.62), paint)
	_visual_box("RearMudguard", Vector3(0.18, 0.07, 0.39), Vector3(0.0, 0.14, 0.68), dark)
	_visual_box("Headlamp", Vector3(0.26, 0.22, 0.12), Vector3(0.0, 0.39, -0.70), lamp)
	_visual_box("Handlebar", Vector3(0.68, 0.045, 0.065), Vector3(0.0, 0.52, -0.57), dark)
	_visual_box("Instrument", Vector3(0.23, 0.09, 0.14), Vector3(0.0, 0.52, -0.48), dark)
	_visual_box("BrakeLamp", Vector3(0.22, 0.11, 0.05), Vector3(0.0, 0.19, 0.88), _brake_material)
	for side: float in [-1.0, 1.0]:
		_visual_box("Fork", Vector3(0.045, 0.51, 0.05), Vector3(side * 0.095, 0.02, -0.59), engine)
		_visual_box("Footpeg", Vector3(0.16, 0.045, 0.075), Vector3(side * 0.18, -0.18, 0.10), dark)
		_visual_box("RearShock", Vector3(0.055, 0.33, 0.055), Vector3(side * 0.13, -0.01, 0.56), engine)
		_visual_box("MirrorArm", Vector3(0.035, 0.15, 0.035), Vector3(side * 0.30, 0.59, -0.57), dark)
		_visual_box("Mirror", Vector3(0.13, 0.09, 0.045), Vector3(side * 0.30, 0.68, -0.57), engine)
	_visual_box("Exhaust", Vector3(0.10, 0.13, 0.70), Vector3(0.22, -0.16, 0.35), dark)
