extends "res://vehicle/phase1_two_wheeler.gd"
## Original contemporary step-through scooter, facing local -Z.
## Proportion reference: https://www.suzukimotorcycle.co.in/product-details/all-new-access-125-bluetooth-enabled/features


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
	_build_body()
	_build_rider(Vector3(0, 0.396, 0.155), Vector3(0.141, -0.136, -0.267), true)


func _build_body() -> void:
	var paint := _finish(Color("456e84"), 0.38, 0.16)
	var plastic := _finish(Color("303538"), 0.67)
	var saddle := _finish(Color("514138"), 0.89)
	var alloy := _finish(Color("a6a7a2"), 0.45, 0.26)
	var rubber := _finish(Color("202225"), 0.90)
	var glass := _finish(Color("98acb2"), 0.25, 0.40)
	var front := _visual_wheel(Vector3(0, -0.255, -0.63), rubber, alloy, true, 0.108)
	var rear := _visual_wheel(Vector3(0, -0.255, 0.63), rubber, alloy, false, 0.114)
	_fender(front, 0.269, 0.147, paint, 1.30)
	_fender(rear, 0.268, 0.143, plastic, 1.02)

	_profile(lean_visual, "TaperedSideFairing", [
		Vector4(-0.124, -0.055, 0.153, 0.099), Vector4(-0.028, 0.000, 0.183, 0.179),
		Vector4(0.129, 0.016, 0.228, 0.214), Vector4(0.338, 0.021, 0.250, 0.224),
		Vector4(0.569, 0.028, 0.241, 0.220), Vector4(0.748, 0.050, 0.198, 0.170),
		Vector4(0.856, 0.072, 0.118, 0.099), Vector4(0.906, 0.082, 0.076, 0.048),
	], paint, 0.81)
	_profile(lean_visual, "PaddedSaddle", [
		Vector4(-0.044, 0.182, 0.122, 0.023), Vector4(0.036, 0.230, 0.163, 0.051),
		Vector4(0.214, 0.245, 0.191, 0.075), Vector4(0.404, 0.265, 0.200, 0.067),
		Vector4(0.629, 0.257, 0.182, 0.056), Vector4(0.748, 0.224, 0.121, 0.033),
	], saddle, 0.67)
	_profile(lean_visual, "TaperedFloorboard", [
		Vector4(-0.637, -0.190, 0.116, 0.034), Vector4(-0.510, -0.235, 0.179, 0.039),
		Vector4(-0.377, -0.243, 0.221, 0.035), Vector4(-0.083, -0.241, 0.228, 0.033),
		Vector4(0.088, -0.205, 0.186, 0.062), Vector4(0.153, -0.151, 0.141, 0.066),
	], plastic, 0.49)
	_build_front_apron(front, paint, plastic, alloy)
	_build_cockpit(paint, plastic, alloy, rubber, glass)
	_build_rear_trim(plastic, alloy)


func _build_front_apron(front: Node3D, paint: Material, plastic: Material, alloy: Material) -> void:
	# The apron loft is rotated upright. Its section centres follow the fork rake.
	var apron := _profile(lean_visual, "RoundedApron", [
		Vector4(-0.218, 0.484, 0.155, 0.089), Vector4(-0.111, 0.506, 0.201, 0.105),
		Vector4(0.048, 0.507, 0.232, 0.109), Vector4(0.211, 0.505, 0.224, 0.100),
		Vector4(0.372, 0.508, 0.178, 0.085), Vector4(0.498, 0.486, 0.110, 0.063),
	], paint, 0.69)
	apron.rotation.x = -PI * 0.5
	var inside := _profile(lean_visual, "InnerLegShield", [
		Vector4(-0.211, 0.404, 0.124, 0.038), Vector4(-0.099, 0.422, 0.173, 0.049),
		Vector4(0.116, 0.421, 0.177, 0.040), Vector4(0.324, 0.430, 0.139, 0.036),
		Vector4(0.480, 0.451, 0.093, 0.030),
	], plastic, 0.58)
	inside.rotation.x = -PI * 0.5
	Geometry.bar(front, "SuspensionCover", Vector3(-0.086, 0.001, 0),
		Vector3(-0.086, 0.197, 0.040), 0.025, alloy)
	var indicators := _lens(Color("b9823e"), 0.22)
	for side: float in [-1.0, 1.0]:
		var lamp := _profile(lean_visual, "ApronIndicator", [
			Vector4(-0.609, 0.162, 0.015, 0.022), Vector4(-0.596, 0.168, 0.032, 0.041),
			Vector4(-0.570, 0.167, 0.037, 0.038),
		], indicators)
		lamp.position.x = side * 0.148


func _build_cockpit(paint: Material, plastic: Material, alloy: Material, rubber: Material, glass: Material) -> void:
	_cockpit.position = Vector3(0, 0.558, -0.454)
	_build_handlebars(0.310, alloy, rubber, glass, 0.123)
	_profile(_cockpit, "HeadlampCowl", [
		Vector4(-0.227, -0.007, 0.138, 0.085), Vector4(-0.163, -0.017, 0.183, 0.095),
		Vector4(-0.056, -0.015, 0.197, 0.093), Vector4(0.048, 0.014, 0.143, 0.052),
		Vector4(0.103, 0.008, 0.092, 0.043),
	], paint, 0.68)
	_profile(_cockpit, "HeadlampBezel", [
		Vector4(-0.245, -0.021, 0.108, 0.052), Vector4(-0.225, -0.019, 0.139, 0.065),
		Vector4(-0.205, -0.018, 0.148, 0.068),
	], alloy, 0.70)
	var lamp := _lens(Color("d9dbc8"), 0.43)
	_profile(_cockpit, "ShapedHeadlampLens", [
		Vector4(-0.250, -0.024, 0.082, 0.041), Vector4(-0.241, -0.023, 0.112, 0.045),
		Vector4(-0.227, -0.022, 0.124, 0.052),
	], lamp, 0.65)
	_round_part(_cockpit, "InstrumentSurround", Vector3(0.108, 0.021, 0.078), Vector3(0, 0.073, -0.071), plastic)
	_round_part(_cockpit, "InstrumentFace", Vector3(0.076, 0.012, 0.057), Vector3(0, 0.092, -0.064), glass)


func _build_rear_trim(plastic: Material, alloy: Material) -> void:
	_brake_material = _lens(Color("a92828"), 0.35)
	_profile(lean_visual, "WraparoundRearLamp", [
		Vector4(0.782, 0.112, 0.155, 0.041), Vector4(0.836, 0.104, 0.144, 0.047),
		Vector4(0.883, 0.093, 0.109, 0.037), Vector4(0.919, 0.085, 0.075, 0.022),
	], _brake_material, 0.71)
	var transmission := _profile(lean_visual, "TransmissionCover", [
		Vector4(0.167, -0.181, 0.034, 0.054), Vector4(0.249, -0.179, 0.066, 0.076),
		Vector4(0.427, -0.223, 0.051, 0.062), Vector4(0.567, -0.233, 0.059, 0.073),
		Vector4(0.678, -0.225, 0.038, 0.063),
	], alloy)
	transmission.position.x = -0.119
	Geometry.bar(lean_visual, "Silencer", Vector3(0.156, -0.254, 0.400), Vector3(0.156, -0.212, 0.793), 0.044, plastic)
	Geometry.bar(lean_visual, "RearGrabRail", Vector3(-0.168, 0.281, 0.741), Vector3(0.168, 0.281, 0.741), 0.015, alloy)
	for side: float in [-1.0, 1.0]:
		Geometry.bar(lean_visual, "GrabRailSupport", Vector3(side * 0.184, 0.245, 0.508),
			Vector3(side * 0.168, 0.281, 0.741), 0.015, alloy)
