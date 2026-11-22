extends "res://vehicle/phase1_vehicle.gd"
## Original Indian-market tall hatch. Forward is local -Z.

const BodyMesh := preload("res://vehicle/vehicle_body_mesh.gd")
const AXLE := 1.215
const WHEEL_WIDTH := 0.19
const FRONT_SEAT_OFFSET := 0.35
const STEERING_POSE := Transform3D(Basis(Vector3.RIGHT, 1.25), Vector3(FRONT_SEAT_OFFSET, 0.64, -0.48))


func _init(patrol: bool = false) -> void:
	super()
	name = "Phase1Car"
	vehicle_label = "Car"
	exit_side_offset = 1.48
	preferred_exit_side = 1.0
	follow_distance = 6.9
	_build_collision(Vector3(1.64, 0.92, 3.8), Vector3(0.0, -0.04, 0.0))
	_build_bodywork(patrol)


func _build_bodywork(patrol: bool) -> void:
	var paint := _material(Color("d7e1e3") if patrol else Color("233741"))
	paint.roughness = 0.36
	paint.metallic = 0.12
	var roof := _material(Color("273858") if patrol else Color("cc9b3e"))
	roof.roughness = 0.41
	var glass := _material(Color("63879745"))
	glass.roughness = 0.22
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var trim := _material(Color("23282c"))
	var satin := _material(Color("7c888b"))
	satin.metallic = 0.24
	satin.roughness = 0.42
	var tire := _material(Color("171b1f"))
	var black := _material(Color("161b1d"))
	var section_rings: Array[PackedVector3Array] = []
	for z: float in [-1.84, -1.79, -1.68, -1.55, -1.51, -1.44, -1.36, -1.215, -1.07,
			-0.99, -0.92, -0.88, -0.68, 0.1, 0.68, 0.88, 0.92, 0.99, 1.07, 1.215,
			1.36, 1.44, 1.51, 1.55, 1.68, 1.79, 1.84]:
		var end_taper := smoothstep(1.47, 1.86, absf(z))
		var width := lerpf(0.818, 0.635, end_taper)
		var rocker := lerpf(-0.32, -0.21, end_taper)
		var wheel_offset := absf(absf(z) - AXLE)
		# The skin follows the round wheel opening before it wraps under the sill.
		if wheel_offset < 0.35:
			var arch := sqrt(1.0 - pow(wheel_offset / 0.35, 2.0))
			rocker = lerpf(rocker, 0.184, arch)
		var shoulder := 0.36 + 0.073 * smoothstep(-1.53, -0.85, z)
		shoulder -= end_taper * (0.19 if z < 0.0 else 0.10)
		section_rings.append(_body_ring(z, width, rocker, shoulder))
	BodyMesh.loft(self, "WheelArchedBody", section_rings, paint)
	_build_cabin(roof, glass, trim)
	_build_cabin_interior()
	_build_fascias(trim, satin)
	if patrol:
		_build_patrol_details(trim)
	for side: float in [-1.0, 1.0]:
		_build_door_details(side, paint, trim, satin)
		for axle: float in [-AXLE, AXLE]:
			var wheel := _add_wheel_at(Vector3(side * 0.769, -0.18, axle), tire, satin, axle < 0.0, wheel_radius, WHEEL_WIDTH)
			BodyMesh.dress_wheel(wheel, wheel_radius, WHEEL_WIDTH, tire, satin, black, 6)


func _build_patrol_details(trim: Material) -> void:
	var stripe := _material(Color("283e67"))
	for side: float in [-1.0, 1.0]:
		_add_box("PatrolStripe", Vector3(0.026, 0.094, 1.17), Vector3(side * 0.816, 0.28, -0.03), stripe)
	_add_box("PatrolLightbase", Vector3(0.72, 0.050, 0.19), Vector3(0.0, 1.126, 0.13), trim)
	for side: float in [-1.0, 1.0]:
		var lens := _material(Color("e48842") if side < 0.0 else Color("4269b5"))
		lens.emission_enabled = true
		lens.emission = lens.albedo_color
		lens.emission_energy_multiplier = 0.35
		_add_box("PatrolRoofLens", Vector3(0.32, 0.069, 0.16), Vector3(side * 0.168, 1.176, 0.13), lens)


func _body_ring(z: float, width: float, bottom: float, shoulder: float) -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(-width + 0.065, bottom, z), Vector3(-width, bottom + 0.025, z),
		Vector3(-width, shoulder - 0.060, z), Vector3(-width + 0.029, shoulder, z),
		Vector3(-width * 0.71, shoulder + 0.042, z), Vector3(width * 0.71, shoulder + 0.042, z),
		Vector3(width - 0.029, shoulder, z), Vector3(width, shoulder - 0.060, z),
		Vector3(width, bottom + 0.025, z), Vector3(width - 0.065, bottom, z),
	])


func _build_cabin(roof: Material, glass: Material, trim: Material) -> void:
	var windscreen_low := Vector3(0.731, 0.447, -0.968)
	var windscreen_top := Vector3(0.590, 1.010, -0.493)
	var hatch_low := Vector3(0.732, 0.450, 1.565)
	var hatch_top := Vector3(0.609, 0.991, 1.230)
	var left := Vector3(-1.0, 1.0, 1.0)
	var panes: Array[PackedVector3Array] = [
		PackedVector3Array([windscreen_low, windscreen_top, windscreen_top * left, windscreen_low * left]),
		PackedVector3Array([hatch_low * left, hatch_top * left, hatch_top, hatch_low]),
	]
	for side: float in [-1.0, 1.0]:
		var mirror := Vector3(side, 1.0, 1.0)
		var side_pane := PackedVector3Array([windscreen_low * mirror, windscreen_top * mirror, hatch_top * mirror, hatch_low * mirror])
		if side > 0.0:
			side_pane.reverse()
		panes.append(side_pane)
		BodyMesh.bar(self, "WindscreenPillar", windscreen_low * mirror, windscreen_top * mirror, 0.038, roof)
		BodyMesh.bar(self, "HatchPillar", hatch_low * mirror, hatch_top * mirror, 0.044, roof)
		BodyMesh.bar(self, "WindowSill", windscreen_low * mirror, hatch_low * mirror, 0.023, trim)
		var b_low := Vector3(side * 0.737, 0.447, 0.28)
		var b_top := Vector3(side * 0.604, 1.006, 0.19)
		BodyMesh.bar(self, "BColumn", b_low, b_top, 0.026, trim)
		BodyMesh.bar(self, "HatchQuarterColumn", Vector3(side * 0.735, 0.451, 1.140), Vector3(side * 0.611, 1.013, 1.035), 0.024, trim)
	BodyMesh.faces(self, "ShapedCabinGlazing", panes, glass)
	BodyMesh.loft(self, "CrownedRoof", [
		_roof_ring(-0.575, 0.557, 0.979, 1.011),
		_roof_ring(-0.472, 0.622, 0.998, 1.089),
		_roof_ring(-0.230, 0.646, 1.025, 1.128),
		_roof_ring(0.64, 0.641, 1.023, 1.135),
		_roof_ring(1.090, 0.635, 1.001, 1.113),
		_roof_ring(1.277, 0.613, 0.988, 1.051),
		_roof_ring(1.334, 0.572, 0.970, 1.008),
	], roof)
	BodyMesh.bar(self, "RearWiper", Vector3(-0.23, 0.539, 1.527), Vector3(0.204, 0.627, 1.475), 0.010, trim)


func _build_cabin_interior() -> void:
	# Local +X is the driver's right when facing forward along -Z.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var block := BoxMesh.new()
	block.size = Vector3(1.18, 0.15, 0.26)
	surface.append_from(block, 0, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.48, -0.75)))
	for side: float in [-1.0, 1.0]:
		var seat_x := side * FRONT_SEAT_OFFSET
		block.size = Vector3(0.43, 0.11, 0.42)
		surface.append_from(block, 0, Transform3D(Basis.IDENTITY, Vector3(seat_x, 0.45, 0.08)))
		block.size = Vector3(0.43, 0.38, 0.11)
		surface.append_from(block, 0, Transform3D(Basis(Vector3.RIGHT, 0.13), Vector3(seat_x, 0.63, 0.25)))
		block.size = Vector3(0.25, 0.12, 0.10)
		surface.append_from(block, 0, Transform3D(Basis.IDENTITY, Vector3(seat_x, 0.86, 0.28)))

	block.size = Vector3(0.08, 0.095, 0.22)
	surface.append_from(block, 0, Transform3D(Basis.IDENTITY, Vector3(FRONT_SEAT_OFFSET, 0.585, -0.579)))
	var wheel := TorusMesh.new()
	wheel.inner_radius = 0.134
	wheel.outer_radius = 0.170
	wheel.rings = 12
	wheel.ring_segments = 6
	surface.append_from(wheel, 0, STEERING_POSE)
	block.size = Vector3(0.28, 0.035, 0.032)
	surface.append_from(block, 0, STEERING_POSE)
	BodyMesh.part(self, "RightHandDriveInterior", surface.commit(), _material(Color("514943")))


func _roof_ring(z: float, half_width: float, bottom: float, crown: float) -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(-half_width, bottom, z), Vector3(-half_width, lerpf(bottom, crown, 0.40), z),
		Vector3(-half_width * 0.78, crown - 0.010, z), Vector3(0.0, crown, z),
		Vector3(half_width * 0.78, crown - 0.010, z), Vector3(half_width, lerpf(bottom, crown, 0.40), z),
		Vector3(half_width, bottom, z),
	])


func _build_fascias(trim: StandardMaterial3D, satin: Material) -> void:
	var lamp := _material(Color("e7e2ca"))
	lamp.cull_mode = BaseMaterial3D.CULL_DISABLED
	lamp.emission_enabled = true
	lamp.emission = Color("dfcc9a")
	lamp.emission_energy_multiplier = 0.7
	_brake_material = _material(Color("a41424"))
	_brake_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_brake_material.emission_enabled = true
	_brake_material.emission = Color("e10822")
	_brake_material.emission_energy_multiplier = 0.3
	trim.cull_mode = BaseMaterial3D.CULL_DISABLED
	var front_lamps: Array[PackedVector3Array] = []
	var rear_lamps: Array[PackedVector3Array] = []
	for side: float in [-1.0, 1.0]:
		var mirror := Vector3(side, 1.0, 1.0)
		front_lamps.append(PackedVector3Array([
			Vector3(0.374, 0.076, -1.853) * mirror, Vector3(0.366, 0.146, -1.853) * mirror,
			Vector3(0.526, 0.157, -1.853) * mirror, Vector3(0.603, 0.161, -1.853) * mirror,
			Vector3(0.620, 0.127, -1.853) * mirror, Vector3(0.593, 0.089, -1.853) * mirror,
		]))
		rear_lamps.append(PackedVector3Array([
			Vector3(0.490, 0.106, 1.851) * mirror, Vector3(0.585, 0.099, 1.851) * mirror,
			Vector3(0.617, 0.141, 1.851) * mirror, Vector3(0.605, 0.281, 1.851) * mirror,
			Vector3(0.534, 0.286, 1.851) * mirror, Vector3(0.494, 0.229, 1.851) * mirror,
		]))
	BodyMesh.faces(self, "SweptHeadlightLenses", front_lamps, lamp)
	BodyMesh.faces(self, "VerticalTailLenses", rear_lamps, _brake_material)
	BodyMesh.faces(self, "BumperInserts", [
		PackedVector3Array([Vector3(-0.455, -0.165, -1.849), Vector3(-0.475, -0.092, -1.849), Vector3(0.475, -0.092, -1.849), Vector3(0.455, -0.165, -1.849)]),
		PackedVector3Array([Vector3(-0.350, 0.013, -1.851), Vector3(-0.359, 0.120, -1.851), Vector3(0.359, 0.120, -1.851), Vector3(0.350, 0.013, -1.851)]),
		PackedVector3Array([Vector3(0.505, -0.123, 1.849), Vector3(0.559, -0.065, 1.849), Vector3(-0.559, -0.065, 1.849), Vector3(-0.505, -0.123, 1.849)]),
	], trim)
	for y: float in [0.036, 0.068, 0.10]:
		BodyMesh.bar(self, "GrilleSlat", Vector3(-0.339, y, -1.857), Vector3(0.339, y, -1.857), 0.006, satin)
	_add_box("FrontPlate", Vector3(0.36, 0.086, 0.016), Vector3(0.0, -0.104, -1.856), satin)
	_add_box("RearPlate", Vector3(0.37, 0.090, 0.019), Vector3(0.0, 0.015, 1.850), satin)
	BodyMesh.bar(self, "HatchPull", Vector3(-0.106, 0.215, 1.851), Vector3(0.106, 0.215, 1.851), 0.017, trim)


func _build_door_details(side: float, paint: Material, trim: Material, satin: Material) -> void:
	var x := side * 0.823
	for z: float in [-0.637, 0.28, 0.875]:
		BodyMesh.bar(self, "DoorShutLine", Vector3(x, -0.143, z), Vector3(x, 0.320, z + 0.028), 0.0038, trim)
	BodyMesh.bar(self, "SillShutLine", Vector3(x, -0.143, -0.637), Vector3(x, -0.143, 0.875), 0.004, trim)
	for z: float in [0.042, 0.627]:
		BodyMesh.bar(self, "DoorPull", Vector3(x, 0.333, z), Vector3(x, 0.333, z + 0.110), 0.013, satin)
	BodyMesh.bar(self, "MirrorStalk", Vector3(side * 0.728, 0.469, -0.725), Vector3(side * 0.855, 0.504, -0.745), 0.034, trim)
	var mirror := SphereMesh.new()
	mirror.radius = 0.5
	mirror.height = 1.0
	mirror.radial_segments = 10
	mirror.rings = 4
	var housing := BodyMesh.part(self, "OvalMirrorHousing", mirror, paint)
	housing.position = Vector3(side * 0.863, 0.520, -0.766)
	housing.scale = Vector3(0.17, 0.108, 0.13)
