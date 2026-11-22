extends "res://vehicle/phase1_vehicle.gd"
## Original open-sided Mumbai auto with separate body and fabric canopy.

const BodyMesh := preload("res://vehicle/vehicle_body_mesh.gd")
const DriverBody := preload("res://character/player_character.gd")
const WHEEL_WIDTH := 0.155
const DRIVER_SCALE := 0.84

var _driver := DriverBody.new()


func _init() -> void:
	super()
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
	_build_collision(Vector3(1.30, 1.65, 2.70), Vector3(0.0, 0.325, 0.0))
	_build_bodywork()
	_driver.name = "SeatedDriver"
	_driver.wears_dhotar = true
	_driver.scale = Vector3.ONE * DRIVER_SCALE
	_driver.position = Vector3(0.0, 0.245 - 0.90 * DRIVER_SCALE, -0.185)
	_driver.hide()
	add_child(_driver)


func _ready() -> void:
	super._ready()
	_pose_driver()


func set_driver_active(active: bool) -> void:
	super.set_driver_active(active)
	_driver.visible = active


func _pose_driver() -> void:
	var rig := _driver.skeleton
	rig.set_bone_pose_rotation(rig.find_bone("Spine"), Quaternion(Vector3.RIGHT, -0.28))
	rig.set_bone_pose_rotation(rig.find_bone("Chest"), Quaternion(Vector3.RIGHT, -0.08))
	rig.set_bone_pose_rotation(rig.find_bone("Neck"), Quaternion(Vector3.RIGHT, 0.21))
	for side: float in [-1.0, 1.0]:
		var label := "Left" if side < 0.0 else "Right"
		rig.set_bone_pose_rotation(rig.find_bone(label + "UpperLeg"), Quaternion(Vector3.RIGHT, deg_to_rad(86.0)))
		rig.set_bone_pose_rotation(rig.find_bone(label + "LowerLeg"), Quaternion(Vector3.RIGHT, deg_to_rad(-141.0)))
		rig.set_bone_pose_rotation(rig.find_bone(label + "Foot"), Quaternion(Vector3.RIGHT, deg_to_rad(55.0)))
		var arm_axis := Vector3(side, 0.0, 0.0)
		var grip := Vector3(side * 0.247, 0.373, -0.576)
		_point_driver_bone(label + "UpperArm", arm_axis, Vector3(side * 0.236, 0.440, -0.353))
		_point_driver_bone(label + "LowerArm", arm_axis, grip)
		_point_driver_bone(label + "Hand", arm_axis, grip + Vector3(0.0, -0.012, -0.028))


func _point_driver_bone(name: String, rest_axis: Vector3, target: Vector3) -> void:
	var rig := _driver.skeleton
	var index := rig.find_bone(name)
	var parent_pose := rig.get_bone_global_pose(rig.get_bone_parent(index))
	var bone_position := rig.get_bone_global_pose(index).origin
	var target_in_rig := _driver.transform.affine_inverse() * target
	var local_direction := parent_pose.basis.inverse() * (target_in_rig - bone_position).normalized()
	rig.set_bone_pose_rotation(index, Quaternion(rest_axis, local_direction))


func _build_bodywork() -> void:
	var paint := _material(Color("252b2d"))
	paint.roughness = 0.53
	var yellow := _material(Color("dda633"))
	yellow.roughness = 0.48
	var fabric := _material(Color("ad802a"))
	fabric.cull_mode = BaseMaterial3D.CULL_DISABLED
	var seat := _material(Color("514235"))
	var trim := _material(Color("535c5f"))
	trim.roughness = 0.46
	trim.cull_mode = BaseMaterial3D.CULL_DISABLED
	var tire := _material(Color("16191c"))
	var bar_material := _material(Color("242c2f"))
	var rim := _material(Color("8a9293"))
	rim.metallic = 0.18
	var rear_sections: Array[PackedVector3Array] = []
	for z: float in [-0.515, -0.35, 0.14, 0.57, 0.64, 0.72, 0.81, 0.94, 1.07, 1.15, 1.205, 1.265, 1.34]:
		var setback := smoothstep(1.16, 1.38, z)
		var width := lerpf(0.505, 0.635, smoothstep(-0.52, 0.49, z)) - setback * 0.08
		var wheel_offset := absf(z - 0.94)
		var bottom := -0.29
		if wheel_offset < 0.27:
			bottom = lerpf(bottom, 0.046, sqrt(1.0 - pow(wheel_offset / 0.27, 2.0)))
		var shoulder := lerpf(-0.06, 0.29, smoothstep(0.25, 1.13, z)) - setback * 0.047
		rear_sections.append(_body_ring(z, width, bottom, shoulder, 0.041))
	BodyMesh.loft(self, "ArchedRearBody", rear_sections, paint)
	BodyMesh.loft(self, "PressedFrontCowl", [
		_body_ring(-1.29, 0.205, -0.124, 0.130, 0.008),
		_body_ring(-1.211, 0.287, -0.119, 0.283, 0.019),
		_body_ring(-1.115, 0.390, -0.142, 0.404, 0.040),
		_body_ring(-0.925, 0.493, -0.210, 0.411, 0.043),
		_body_ring(-0.718, 0.517, -0.261, 0.337, 0.023),
		_body_ring(-0.552, 0.475, -0.262, 0.274, 0.022),
	], paint)
	BodyMesh.loft(self, "YellowScuttle", [
		_body_ring(-1.124, 0.386, 0.312, 0.388, 0.027),
		_body_ring(-1.030, 0.454, 0.313, 0.429, 0.031),
		_body_ring(-0.881, 0.498, 0.322, 0.432, 0.028),
		_body_ring(-0.757, 0.498, 0.330, 0.399, 0.022),
	], yellow)
	_build_cabin(yellow, fabric, seat, bar_material, trim)
	_build_lighting(bar_material, rim)
	for side: float in [-1.0, 1.0]:
		var wheel := _add_wheel_at(Vector3(side * 0.539, -0.25, 0.94), tire, rim, false, wheel_radius, WHEEL_WIDTH)
		BodyMesh.dress_wheel(wheel, wheel_radius, WHEEL_WIDTH, tire, rim, bar_material, 5)
	var front_wheel := _add_wheel_at(Vector3(0.0, -0.25, -1.05), tire, rim, true, wheel_radius, WHEEL_WIDTH)
	BodyMesh.dress_wheel(front_wheel, wheel_radius, WHEEL_WIDTH, tire, rim, bar_material, 5)
	_build_front_fender(front_wheel, paint)


func _body_ring(z: float, width: float, bottom: float, shoulder: float, crown: float) -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(-width * 0.82, bottom, z), Vector3(-width, bottom + 0.025, z),
		Vector3(-width, shoulder - 0.038, z), Vector3(-width * 0.94, shoulder, z),
		Vector3(-width * 0.68, shoulder + crown, z), Vector3(width * 0.68, shoulder + crown, z),
		Vector3(width * 0.94, shoulder, z), Vector3(width, shoulder - 0.038, z),
		Vector3(width, bottom + 0.025, z), Vector3(width * 0.82, bottom, z),
	])


func _build_cabin(yellow: Material, fabric: Material, seat: Material, bar_material: Material, trim: Material) -> void:
	var glazing := _material(Color("87a8ad"))
	glazing.albedo_color.a = 0.26
	glazing.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glazing.cull_mode = BaseMaterial3D.CULL_DISABLED
	glazing.roughness = 0.23
	var windscreen := PackedVector3Array([
		Vector3(-0.457, 0.449, -1.008), Vector3(-0.493, 0.978, -0.659),
		Vector3(-0.416, 1.025, -0.647), Vector3(0.416, 1.025, -0.647),
		Vector3(0.493, 0.978, -0.659), Vector3(0.457, 0.449, -1.008),
	])
	BodyMesh.faces(self, "SlopedWindscreen", [windscreen], glazing)
	for index in range(windscreen.size()):
		BodyMesh.bar(self, "GlazingSeal", windscreen[index], windscreen[(index + 1) % windscreen.size()], 0.020, bar_material)
	BodyMesh.loft(self, "FabricCanopy", [
		_canopy_ring(-0.715, 0.474, 1.017, 1.073),
		_canopy_ring(-0.627, 0.537, 1.012, 1.136),
		_canopy_ring(-0.418, 0.579, 1.000, 1.179),
		_canopy_ring(0.265, 0.600, 0.994, 1.183),
		_canopy_ring(0.933, 0.606, 0.980, 1.162),
		_canopy_ring(1.173, 0.596, 0.957, 1.133),
		_canopy_ring(1.265, 0.557, 0.950, 1.077),
	], fabric)
	BodyMesh.bar(self, "CanopyHeader", Vector3(-0.428, 1.003, -0.675), Vector3(0.428, 1.003, -0.675), 0.019, yellow)
	for side: float in [-1.0, 1.0]:
		BodyMesh.bar(self, "CurvedSideEdge", Vector3(side * 0.536, 0.993, -0.598), Vector3(side * 0.604, 0.979, 0.31), 0.017, yellow)
		BodyMesh.bar(self, "RearSideEdge", Vector3(side * 0.604, 0.979, 0.31), Vector3(side * 0.596, 0.945, 1.18), 0.017, yellow)
		BodyMesh.bar(self, "FrontCabPillar", Vector3(side * 0.490, 0.347, -0.929), Vector3(side * 0.510, 1.005, -0.650), 0.025, yellow)
		BodyMesh.bar(self, "CanopyRearPole", Vector3(side * 0.544, 0.220, 1.204), Vector3(side * 0.584, 0.974, 1.180), 0.024, bar_material)
		BodyMesh.bar(self, "PassengerGrabRail", Vector3(side * 0.486, 0.010, 0.21), Vector3(side * 0.558, 0.11, 0.77), 0.021, trim)
		BodyMesh.bar(self, "PassengerStep", Vector3(side * 0.502, -0.187, -0.11), Vector3(side * 0.565, -0.170, 0.54), 0.021, trim)
		BodyMesh.bar(self, "MirrorStalk", Vector3(side * 0.507, 0.650, -0.795), Vector3(side * 0.649, 0.737, -0.807), 0.012, trim)
		var shell := _oval("OvalAutoMirror", Vector3(side * 0.650, 0.762, -0.815), Vector3(0.110, 0.148, 0.052), bar_material)
		shell.rotation.y = side * 0.095
	_build_back_curtain(fabric, glazing, bar_material)
	_build_seats(seat, bar_material)
	BodyMesh.bar(self, "SteeringStem", Vector3(0.0, -0.032, -0.767), Vector3(0.0, 0.378, -0.555), 0.033, trim)
	BodyMesh.bar(self, "Handlebar", Vector3(-0.273, 0.367, -0.575), Vector3(0.273, 0.367, -0.575), 0.024, bar_material)
	BodyMesh.bar(self, "FrontBumper", Vector3(-0.342, -0.198, -1.233), Vector3(0.342, -0.198, -1.233), 0.029, trim)
	BodyMesh.bar(self, "RearBumper", Vector3(-0.524, -0.167, 1.340), Vector3(0.524, -0.167, 1.340), 0.027, trim)


func _canopy_ring(z: float, width: float, edge: float, crown: float) -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(-width, edge, z), Vector3(-width * 0.968, edge + 0.065, z),
		Vector3(-width * 0.72, crown - 0.024, z), Vector3(-width * 0.37, crown - 0.008, z),
		Vector3(0.0, crown, z), Vector3(width * 0.37, crown - 0.008, z),
		Vector3(width * 0.72, crown - 0.024, z), Vector3(width * 0.968, edge + 0.065, z),
		Vector3(width, edge, z),
	])


func _build_back_curtain(fabric: Material, glazing: Material, seam: Material) -> void:
	var zl := 1.259
	var zu := 1.231
	var low_left := Vector3(-0.360, 0.534, zl)
	var high_left := Vector3(-0.308, 0.866, zu)
	var low_right := Vector3(0.360, 0.534, zl)
	var high_right := Vector3(0.308, 0.866, zu)
	BodyMesh.faces(self, "ShapedRearCurtain", [
		PackedVector3Array([Vector3(-0.572, 0.285, 1.336), Vector3(-0.568, 0.968, zu), high_left, low_left]),
		PackedVector3Array([low_right, high_right, Vector3(0.568, 0.968, zu), Vector3(0.572, 0.285, 1.336)]),
		PackedVector3Array([high_left, Vector3(-0.568, 0.968, zu), Vector3(0.568, 0.968, zu), high_right]),
		PackedVector3Array([Vector3(-0.572, 0.285, 1.336), low_left, low_right, Vector3(0.572, 0.285, 1.336)]),
	], fabric)
	BodyMesh.faces(self, "RearCurtainGlazing", [PackedVector3Array([low_left, high_left, high_right, low_right])], glazing)
	var edge := [low_left, high_left, high_right, low_right]
	for index in range(edge.size()):
		BodyMesh.bar(self, "RearGlazingSeam", edge[index], edge[(index + 1) % edge.size()], 0.011, seam)


func _build_seats(seat: Material, bar_material: Material) -> void:
	BodyMesh.loft(self, "PassengerCushion", [
		_body_ring(0.44, 0.425, 0.106, 0.164, 0.020),
		_body_ring(0.514, 0.491, 0.098, 0.211, 0.021),
		_body_ring(0.787, 0.492, 0.127, 0.226, 0.022),
		_body_ring(0.880, 0.462, 0.153, 0.217, 0.020),
	], seat)
	BodyMesh.loft(self, "PassengerBackrest", [
		_body_ring(0.871, 0.429, 0.219, 0.393, 0.020),
		_body_ring(0.936, 0.474, 0.178, 0.581, 0.030),
		_body_ring(1.037, 0.467, 0.230, 0.604, 0.029),
		_body_ring(1.104, 0.422, 0.248, 0.533, 0.018),
	], seat)
	BodyMesh.loft(self, "DriverSaddle", [
		_body_ring(-0.441, 0.226, 0.052, 0.106, 0.008),
		_body_ring(-0.360, 0.265, 0.039, 0.146, 0.017),
		_body_ring(-0.144, 0.266, 0.048, 0.159, 0.022),
		_body_ring(-0.067, 0.218, 0.059, 0.134, 0.014),
	], seat)
	BodyMesh.loft(self, "DriverBackrest", [
		_body_ring(-0.145, 0.203, 0.147, 0.328, 0.011),
		_body_ring(-0.082, 0.229, 0.146, 0.407, 0.018),
		_body_ring(-0.024, 0.215, 0.172, 0.367, 0.012),
	], seat)
	for side: float in [-1.0, 1.0]:
		BodyMesh.bar(self, "SeatBracket", Vector3(side * 0.168, -0.252, -0.235), Vector3(side * 0.168, 0.082, -0.235), 0.026, bar_material)


func _build_lighting(trim: Material, rim: Material) -> void:
	var lamp := _material(Color("e7dfc6"))
	lamp.emission_enabled = true
	lamp.emission = Color("eee1af")
	lamp.emission_energy_multiplier = 0.6
	var turn_lens := _material(Color("be711e"))
	_brake_material = _material(Color("8b1420"))
	_brake_material.emission_enabled = true
	_brake_material.emission = Color("e10822")
	_brake_material.emission_energy_multiplier = 0.3
	_oval("RoundHeadlampBezel", Vector3(0.0, 0.203, -1.256), Vector3(0.286, 0.261, 0.109), trim)
	_oval("RoundHeadlamp", Vector3(0.0, 0.203, -1.305), Vector3(0.229, 0.202, 0.048), lamp)
	for side: float in [-1.0, 1.0]:
		_oval("FrontSignalLens", Vector3(side * 0.359, 0.278, -1.138), Vector3(0.128, 0.089, 0.059), turn_lens)
		_oval("RearTailLens", Vector3(side * 0.466, 0.139, 1.348), Vector3(0.151, 0.119, 0.035), _brake_material)
		_oval("RearSignalLens", Vector3(side * 0.462, 0.234, 1.327), Vector3(0.149, 0.081, 0.040), turn_lens)
	_add_box("RearPlate", Vector3(0.310, 0.077, 0.016), Vector3(0.0, 0.136, 1.349), rim)
	_add_box("FrontPlate", Vector3(0.237, 0.060, 0.012), Vector3(0.0, -0.122, -1.296), rim)
	for y: float in [0.025, 0.061, 0.097]:
		BodyMesh.bar(self, "EnginePanelLouvre", Vector3(-0.144, y, 1.349), Vector3(0.144, y, 1.349), 0.006, trim)


func _oval(label: String, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 16
	sphere.rings = 5
	var node := BodyMesh.part(self, label, sphere, material)
	node.position = at
	node.scale = size
	return node


func _build_front_fender(pivot: Node3D, paint: Material) -> void:
	var strips: Array[PackedVector3Array] = []
	for index in range(10):
		var start := -1.10 + float(index) * 0.22
		var end := start + 0.22
		var a := Vector3(0.0, cos(start) * 0.277, sin(start) * 0.277)
		var b := Vector3(0.0, cos(end) * 0.277, sin(end) * 0.277)
		strips.append(PackedVector3Array([a + Vector3.LEFT * 0.105, a + Vector3.RIGHT * 0.105, b + Vector3.RIGHT * 0.105, b + Vector3.LEFT * 0.105]))
	BodyMesh.faces(pivot, "SteeringFrontMudguard", strips, paint)
