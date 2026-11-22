extends "res://vehicle/phase1_vehicle.gd"
## Original primitive car body; movement is shared with the other arcade vehicles.

func _init() -> void:
	name = "Phase1Car"
	vehicle_label = "Car"
	exit_side_offset = 1.48
	follow_distance = 6.9
	_build_collision(Vector3(1.64, 0.92, 3.8), Vector3(0.0, -0.04, 0.0))
	_build_placeholder()


func _build_placeholder() -> void:
	# Original primitives: intentionally not an approved real-model asset.
	var paint: StandardMaterial3D = _material(Color(0.055, 0.075, 0.09))
	var roof: StandardMaterial3D = _material(Color(0.98, 0.66, 0.08))
	var windows: StandardMaterial3D = _material(Color(0.13, 0.28, 0.34))
	var trim: StandardMaterial3D = _material(Color(0.55, 0.59, 0.61))
	var tire: StandardMaterial3D = _material(Color(0.025, 0.03, 0.035))
	var lamps: StandardMaterial3D = _material(Color(1.0, 0.95, 0.72))
	lamps.emission_enabled = true
	lamps.emission = Color(0.95, 0.84, 0.50)
	lamps.emission_energy_multiplier = 0.7
	_brake_material = _material(Color(0.72, 0.045, 0.025))
	_brake_material.emission_enabled = true
	_brake_material.emission = Color(0.9, 0.02, 0.01)
	_brake_material.emission_energy_multiplier = 0.3

	_add_box("Body", Vector3(1.58, 0.57, 3.48), Vector3(0.0, 0.05, 0.0), paint)
	_add_box("Cabin", Vector3(1.35, 0.56, 1.68), Vector3(0.0, 0.61, 0.25), roof)
	_add_box("Bonnet", Vector3(1.53, 0.12, 1.10), Vector3(0.0, 0.38, -1.14), paint)
	_add_box("Windshield", Vector3(1.20, 0.36, 0.035), Vector3(0.0, 0.64, -0.608), windows)
	_add_box("RearGlass", Vector3(1.19, 0.34, 0.035), Vector3(0.0, 0.64, 1.108), windows)
	_add_box("Roof", Vector3(1.39, 0.065, 1.72), Vector3(0.0, 0.92, 0.25), roof)
	_add_box("FrontBumper", Vector3(1.65, 0.13, 0.15), Vector3(0.0, -0.07, -1.80), trim)
	_add_box("RearBumper", Vector3(1.65, 0.13, 0.15), Vector3(0.0, -0.07, 1.80), trim)
	for side: float in [-1.0, 1.0]:
		_add_box("SideGlass", Vector3(0.035, 0.34, 1.32), Vector3(side * 0.688, 0.65, 0.25), windows)
		_add_box("DoorPillar", Vector3(0.045, 0.43, 0.075), Vector3(side * 0.71, 0.64, 0.20), roof)
		_add_box("Headlamp", Vector3(0.36, 0.18, 0.035), Vector3(side * 0.52, 0.14, -1.758), lamps)
		_add_box("Taillamp", Vector3(0.28, 0.16, 0.035), Vector3(side * 0.57, 0.15, 1.758), _brake_material)
		_add_wheel_at(Vector3(side * 0.81, -0.18, -1.14), tire, trim, true)
		_add_wheel_at(Vector3(side * 0.81, -0.18, 1.14), tire, trim, false)
