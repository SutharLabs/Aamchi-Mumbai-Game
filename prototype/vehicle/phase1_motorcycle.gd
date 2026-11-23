extends "res://vehicle/phase1_two_wheeler.gd"
## Original contemporary commuter motorcycle, facing local -Z.
## Proportion reference: https://www.heromotocorp.com/en-in/motorcycles/splendor-plus.html


func _init() -> void:
	super()
	name = "Phase1Motorcycle"
	vehicle_label = "Motorcycle"
	chassis_mass = 205.0
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
	_build_body()
	_build_rider(Vector3(0, 0.365, 0.10), Vector3(0.23, -0.125, 0.135), false)


func _build_body() -> void:
	var paint := _finish(Color("9a4841"), 0.44, 0.18)
	var satin := _finish(Color("292d31"), 0.58, 0.16)
	var upholstery := _finish(Color("26282a"), 0.88)
	var alloy := _finish(Color("999da1"), 0.42, 0.27)
	var rubber := _finish(Color("202225"), 0.91)
	var mirror := _finish(Color("9aabaf"), 0.22, 0.45)
	var front := _visual_wheel(Vector3(0, -0.19, -0.618), rubber, alloy, true, 0.091)
	var rear := _visual_wheel(Vector3(0, -0.19, 0.618), rubber, alloy, false, 0.098)
	_fender(front, 0.335, 0.119, paint, 1.06)
	_fender(rear, 0.341, 0.131, satin, 1.09)

	_profile(lean_visual, "SculptedFuelTank", [
		Vector4(-0.429, 0.249, 0.063, 0.029), Vector4(-0.390, 0.276, 0.127, 0.088),
		Vector4(-0.293, 0.283, 0.168, 0.111), Vector4(-0.167, 0.272, 0.171, 0.106),
		Vector4(-0.057, 0.246, 0.138, 0.079), Vector4(0.031, 0.242, 0.095, 0.038),
	], paint, 0.82)
	_round_part(lean_visual, "FillCap", Vector3(0.039, 0.009, 0.040), Vector3(0, 0.387, -0.238), alloy)
	_profile(lean_visual, "SideCovers", [
		Vector4(-0.066, 0.058, 0.077, 0.043), Vector4(0.080, 0.086, 0.152, 0.079),
		Vector4(0.233, 0.126, 0.158, 0.069), Vector4(0.444, 0.153, 0.133, 0.043),
		Vector4(0.640, 0.150, 0.115, 0.041), Vector4(0.809, 0.115, 0.086, 0.041),
	], paint)
	_profile(lean_visual, "SteppedSaddle", [
		Vector4(-0.007, 0.249, 0.082, 0.024), Vector4(0.091, 0.249, 0.132, 0.038),
		Vector4(0.255, 0.247, 0.156, 0.044), Vector4(0.443, 0.260, 0.146, 0.041),
		Vector4(0.648, 0.259, 0.131, 0.036), Vector4(0.748, 0.244, 0.105, 0.019),
	], upholstery, 0.65)
	_build_running_gear(front, satin, alloy, rubber)
	_build_cockpit(paint, satin, alloy, rubber, mirror)
	_build_rear_lamps(satin, alloy)


func _build_running_gear(front: Node3D, satin: Material, alloy: Material, rubber: Material) -> void:
	_profile(lean_visual, "Crankcase", [
		Vector4(-0.263, -0.027, 0.075, 0.073), Vector4(-0.181, -0.048, 0.144, 0.104),
		Vector4(0.037, -0.068, 0.153, 0.097), Vector4(0.183, -0.050, 0.093, 0.068),
	], alloy)
	for i in range(6):
		var y := 0.007 + float(i) * 0.022
		var z := -0.090 - float(i) * 0.010
		_round_part(lean_visual, "CoolingFin", Vector3(0.100, 0.011, 0.103), Vector3(0, y, z), alloy)
	for side: float in [-1.0, 1.0]:
		var x := side * 0.082
		Geometry.bar(lean_visual, "FrameRail", Vector3(x, 0.265, -0.430), Vector3(x, -0.158, -0.190), 0.025, satin)
		Geometry.bar(lean_visual, "FrameCradle", Vector3(x, -0.158, -0.190), Vector3(x, -0.164, 0.258), 0.020, satin)
		Geometry.bar(lean_visual, "Swingarm", Vector3(side * 0.106, -0.078, 0.258), Vector3(side * 0.106, -0.190, 0.618), 0.025, satin)
		Geometry.bar(lean_visual, "Shock", Vector3(side * 0.112, 0.155, 0.427), Vector3(side * 0.112, -0.178, 0.595), 0.026, alloy)
		Geometry.bar(front, "ForkSlider", Vector3(x, 0, 0), Vector3(x, 0.307, 0.048), 0.024, satin)
		Geometry.bar(front, "ForkStanchion", Vector3(x, 0.254, 0.040), Vector3(x, 0.648, 0.119), 0.016, alloy)
		Geometry.bar(lean_visual, "Footrest", Vector3(side * 0.136, -0.219, 0.135), Vector3(side * 0.273, -0.219, 0.135), 0.020, rubber)
	Geometry.bar(lean_visual, "ExhaustHeader", Vector3(0.072, 0.015, -0.221), Vector3(0.197, -0.236, -0.035), 0.025, alloy)
	Geometry.bar(lean_visual, "ExhaustPipe", Vector3(0.197, -0.236, -0.035), Vector3(0.192, -0.189, 0.315), 0.026, satin)
	var muffler := _profile(lean_visual, "TaperedSilencer", [
		Vector4(0.246, -0.191, 0.029, 0.025), Vector4(0.356, -0.182, 0.046, 0.035),
		Vector4(0.719, -0.149, 0.044, 0.036), Vector4(0.844, -0.139, 0.031, 0.031),
	], satin)
	muffler.position.x = 0.192
	Geometry.bar(lean_visual, "ExhaustTrim", Vector3(0.237, -0.163, 0.390), Vector3(0.237, -0.139, 0.733), 0.011, alloy)


func _build_cockpit(paint: Material, satin: Material, alloy: Material, rubber: Material, mirror: Material) -> void:
	_cockpit.position = Vector3(0, 0.514, -0.511)
	_build_handlebars(0.311, alloy, rubber, mirror)
	_profile(_cockpit, "HeadlampShroud", [
		Vector4(-0.220, -0.126, 0.131, 0.074), Vector4(-0.183, -0.123, 0.143, 0.083),
		Vector4(-0.109, -0.123, 0.126, 0.071), Vector4(-0.024, -0.112, 0.086, 0.043),
	], paint, 0.62)
	var lamp := _lens(Color("ccc3a8"), 0.38)
	_profile(_cockpit, "BeveledHeadlamp", [
		Vector4(-0.238, -0.127, 0.096, 0.044), Vector4(-0.226, -0.126, 0.116, 0.058),
		Vector4(-0.208, -0.126, 0.117, 0.059),
	], lamp, 0.60)
	_profile(_cockpit, "GaugeHousing", [
		Vector4(-0.130, 0.008, 0.077, 0.030), Vector4(-0.086, 0.022, 0.094, 0.042),
		Vector4(0.086, 0.028, 0.070, 0.037),
	], satin)
	_round_part(_cockpit, "GaugeFace", Vector3(0.061, 0.012, 0.048), Vector3(0, 0.064, 0.001), mirror)


func _build_rear_lamps(satin: Material, alloy: Material) -> void:
	_brake_material = _lens(Color("a82621"), 0.35)
	_profile(lean_visual, "TailLens", [
		Vector4(0.779, 0.146, 0.100, 0.038), Vector4(0.836, 0.135, 0.103, 0.034),
		Vector4(0.871, 0.128, 0.082, 0.024),
	], _brake_material, 0.72)
	var indicators := _finish(Color("bd8135"), 0.44)
	for side: float in [-1.0, 1.0]:
		Geometry.bar(lean_visual, "IndicatorStem", Vector3(side * 0.098, 0.096, 0.774),
			Vector3(side * 0.170, 0.094, 0.777), 0.010, satin)
		_round_part(lean_visual, "RearIndicator", Vector3(0.027, 0.020, 0.035),
			Vector3(side * 0.167, 0.095, 0.777), indicators)
		Geometry.bar(lean_visual, "PassengerRail", Vector3(side * 0.133, 0.259, 0.545),
			Vector3(side * 0.128, 0.269, 0.748), 0.014, alloy)
	Geometry.bar(lean_visual, "PassengerGrip", Vector3(-0.128, 0.269, 0.748),
		Vector3(0.128, 0.269, 0.748), 0.014, alloy)
