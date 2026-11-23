extends "res://vehicle/phase1_vehicle.gd"
## Original compact Indian-market car variants. Forward is local -Z.

const BodyMesh := preload("res://vehicle/vehicle_body_mesh.gd")
const AXLE := 1.215
const WHEEL_WIDTH := 0.19
const FRONT_SEAT_OFFSET := 0.35
const STEERING_POSE := Transform3D(Basis(Vector3.RIGHT, 1.25), Vector3(FRONT_SEAT_OFFSET, 0.64, -0.48))
const CHASSIS_SIZE := Vector3(1.64, 0.92, 3.8)
const CHASSIS_CENTER := Vector3(0.0, -0.04, 0.0)
enum BodyStyle { HATCH, SEDAN, SUV, MPV }
enum DamageZone { FRONT, REAR, LEFT, RIGHT }
const BODY_STYLES := {
	BodyStyle.HATCH: {"label": "Car", "paint": Color("233741"), "roof": Color("cc9b3e"), "mass": 1100.0},
	BodyStyle.SEDAN: {"label": "Compact Sedan", "paint": Color("7b8a91"), "roof": Color("7b8a91"), "mass": 1150.0},
	BodyStyle.SUV: {"label": "Compact SUV", "paint": Color("8c5142"), "roof": Color("232b32"), "mass": 1350.0},
	BodyStyle.MPV: {"label": "Family MPV", "paint": Color("c3b395"), "roof": Color("c3b395"), "mass": 1320.0},
}

var _panel_damage := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _panel_centers := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
var _broken_lamps := PackedByteArray([0, 0, 0, 0])
var _shell: MeshInstance3D
var _shell_rings: Array[PackedVector3Array] = []
var _stock_meshes: Dictionary[MeshInstance3D, Mesh] = {}
var _moving_trim: Dictionary[MeshInstance3D, Vector3] = {}
var _face_panels: Dictionary[MeshInstance3D, Array] = {}
var _front_lenses: MeshInstance3D
var _rear_lenses: MeshInstance3D
var _scrapes: MeshInstance3D
var _chassis: CollisionShape3D
var _body_style: BodyStyle


func _init(patrol: bool = false, body_style: BodyStyle = BodyStyle.HATCH) -> void:
	super()
	name = "Phase1Car"
	_body_style = body_style
	var style: Dictionary = BODY_STYLES[body_style]
	vehicle_label = style.label
	chassis_mass = style.mass
	exit_side_offset = 1.48
	preferred_exit_side = 1.0
	follow_distance = 6.9
	_build_collision(CHASSIS_SIZE, CHASSIS_CENTER)
	_chassis = get_node("ChassisCollision")
	_build_bodywork(patrol)


func _build_bodywork(patrol: bool) -> void:
	var style: Dictionary = BODY_STYLES[_body_style]
	var paint := _material(Color("d7e1e3") if patrol else style.paint)
	paint.roughness = 0.36
	paint.metallic = 0.12
	var roof := _material(Color("273858") if patrol else style.roof)
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
		_shell_rings.append(_body_ring(z, width, rocker, shoulder))
	_shell = BodyMesh.loft(self, "WheelArchedBody", _shell_rings, paint)
	_stock_meshes[_shell] = _shell.mesh
	_build_cabin(roof, glass, trim)
	_build_cabin_interior()
	_build_fascias(trim, satin)
	if _body_style == BodyStyle.SUV:
		_build_suv_cladding(trim, satin)
	if patrol:
		_build_patrol_details(trim)
	for side: float in [-1.0, 1.0]:
		var first_trim := get_child_count()
		_build_door_details(side, paint, trim, satin)
		_track_trim(first_trim)
		for axle: float in [-AXLE, AXLE]:
			var wheel := _add_wheel_at(Vector3(side * 0.769, -0.18, axle), tire, satin, axle < 0.0, wheel_radius, WHEEL_WIDTH)
			BodyMesh.dress_wheel(wheel, wheel_radius, WHEEL_WIDTH, tire, satin, black, 6)
	var scrape_material := _material(Color("9da7ad"))
	scrape_material.metallic = 0.30
	scrape_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_scrapes = BodyMesh.part(self, "ImpactScuffs", null, scrape_material)
	_scrapes.hide()


func _build_patrol_details(trim: Material) -> void:
	var stripe := _material(Color("283e67"))
	for side: float in [-1.0, 1.0]:
		var stripe_start := get_child_count()
		_add_box("PatrolStripe", Vector3(0.026, 0.094, 1.17), Vector3(side * 0.816, 0.28, -0.03), stripe)
		_track_trim(stripe_start)
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
	if _body_style != BodyStyle.HATCH:
		_build_variant_cabin(roof, glass, trim)
		return
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


func _build_variant_cabin(roof: Material, glass: Material, trim: Material) -> void:
	# Each profile describes the windscreen, roof crown, rear glass and rear deck.
	var front_low := Vector3(0.733, 0.455, -0.95)
	var front_top := Vector3(0.565, 0.985, -0.42)
	var rear_top := Vector3(0.574, 0.971, 0.56)
	var rear_low := Vector3(0.698, 0.468, 1.24)
	var crown := 1.064
	match _body_style:
		BodyStyle.SUV:
			front_low = Vector3(0.742, 0.455, -0.99)
			front_top = Vector3(0.616, 1.081, -0.51)
			rear_top = Vector3(0.607, 1.058, 1.02)
			rear_low = Vector3(0.726, 0.447, 1.53)
			crown = 1.162
		BodyStyle.MPV:
			front_low = Vector3(0.748, 0.448, -1.20)
			front_top = Vector3(0.626, 1.116, -0.45)
			rear_top = Vector3(0.615, 1.107, 1.30)
			rear_low = Vector3(0.641, 0.430, 1.64)
			crown = 1.207
	var left := Vector3(-1.0, 1.0, 1.0)
	var panes: Array[PackedVector3Array] = [
		PackedVector3Array([front_low, front_top, front_top * left, front_low * left]),
		PackedVector3Array([rear_low * left, rear_top * left, rear_top, rear_low]),
	]
	for side: float in [-1.0, 1.0]:
		var mirror := Vector3(side, 1.0, 1.0)
		var pane := PackedVector3Array([front_low * mirror, front_top * mirror, rear_top * mirror, rear_low * mirror])
		if side > 0.0:
			pane.reverse()
		panes.append(pane)
		BodyMesh.bar(self, "RakedWindscreenPillar", front_low * mirror, front_top * mirror, 0.038, roof)
		BodyMesh.bar(self, "RearGlassPillar", rear_low * mirror, rear_top * mirror, 0.051, roof)
		BodyMesh.bar(self, "CabinBeltline", front_low * mirror, rear_low * mirror, 0.024, trim)
		BodyMesh.bar(self, "CentrePillar", Vector3(0.729, 0.453, 0.26) * mirror,
			front_top.lerp(rear_top, 0.53) * mirror, 0.026, trim)
		if _body_style == BodyStyle.MPV:
			BodyMesh.bar(self, "RearQuarterPillar", rear_low.lerp(front_low, 0.24) * mirror,
				rear_top.lerp(front_top, 0.28) * mirror, 0.026, trim)
	BodyMesh.faces(self, "ShapedCabinGlazing", panes, glass)
	BodyMesh.loft(self, "CrownedRoof", [
		_roof_ring(front_top.z - 0.04, front_top.x - 0.015, front_top.y - 0.015, front_top.y + 0.03),
		_roof_ring(front_top.z + 0.13, front_top.x + 0.027, front_top.y + 0.008, crown - 0.015),
		_roof_ring(lerpf(front_top.z, rear_top.z, 0.53), rear_top.x + 0.035, rear_top.y + 0.012, crown),
		_roof_ring(rear_top.z - 0.12, rear_top.x + 0.026, rear_top.y + 0.004, crown - 0.013),
		_roof_ring(rear_top.z + 0.05, rear_top.x - 0.012, rear_top.y - 0.015, rear_top.y + 0.025),
	], roof)


func _build_suv_cladding(trim: Material, satin: Material) -> void:
	var first_trim := get_child_count()
	for side: float in [-1.0, 1.0]:
		var x := side * 0.818
		BodyMesh.bar(self, "RaisedSillCladding", Vector3(x, -0.207, -0.83), Vector3(x, -0.207, 0.83), 0.030, trim)
		BodyMesh.bar(self, "RaisedRoofRail", Vector3(side * 0.43, 1.191, -0.35), Vector3(side * 0.43, 1.18, 0.94), 0.020, satin)
	BodyMesh.bar(self, "LowerSkidTrim", Vector3(-0.43, -0.171, -1.856), Vector3(0.43, -0.171, -1.856), 0.019, satin)
	_track_trim(first_trim)


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
	_front_lenses = _track_panel("SweptHeadlightLenses", front_lamps, lamp)
	_rear_lenses = _track_panel("VerticalTailLenses", rear_lamps, _brake_material)
	_track_panel("BumperInserts", [
		PackedVector3Array([Vector3(-0.455, -0.165, -1.849), Vector3(-0.475, -0.092, -1.849), Vector3(0.475, -0.092, -1.849), Vector3(0.455, -0.165, -1.849)]),
		PackedVector3Array([Vector3(-0.350, 0.013, -1.851), Vector3(-0.359, 0.120, -1.851), Vector3(0.359, 0.120, -1.851), Vector3(0.350, 0.013, -1.851)]),
		PackedVector3Array([Vector3(0.505, -0.123, 1.849), Vector3(0.559, -0.065, 1.849), Vector3(-0.559, -0.065, 1.849), Vector3(-0.505, -0.123, 1.849)]),
	], trim)
	var first_trim := get_child_count()
	for y: float in [0.036, 0.068, 0.10]:
		BodyMesh.bar(self, "GrilleSlat", Vector3(-0.339, y, -1.857), Vector3(0.339, y, -1.857), 0.006, satin)
	_add_box("FrontPlate", Vector3(0.36, 0.086, 0.016), Vector3(0.0, -0.104, -1.856), satin)
	_add_box("RearPlate", Vector3(0.37, 0.090, 0.019), Vector3(0.0, 0.015, 1.850), satin)
	BodyMesh.bar(self, "HatchPull", Vector3(-0.106, 0.215, 1.851), Vector3(0.106, 0.215, 1.851), 0.017, trim)
	_track_trim(first_trim)


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


func _track_trim(first: int) -> void:
	for index in range(first, get_child_count()):
		var node := get_child(index) as MeshInstance3D
		_moving_trim[node] = node.position


func _track_panel(label: String, polygons: Array, material: Material) -> MeshInstance3D:
	var node := BodyMesh.faces(self, label, polygons, material)
	_stock_meshes[node] = node.mesh
	_face_panels[node] = polygons
	return node


func _damage_bodywork(severity: float, point: Vector3, normal: Vector3) -> void:
	var zone: DamageZone
	if absf(normal.z) >= absf(normal.x):
		zone = DamageZone.FRONT if normal.z >= 0.0 else DamageZone.REAR
	else:
		zone = DamageZone.LEFT if normal.x >= 0.0 else DamageZone.RIGHT
	var previous := _panel_damage[zone]
	var updated := minf(1.0, previous + severity * 1.7)
	if is_equal_approx(updated, previous):
		return
	var location := clampf(point.x, -0.56, 0.56) if zone < DamageZone.LEFT else clampf(point.z, -1.12, 1.12)
	_panel_centers[zone] = lerpf(_panel_centers[zone], location, (updated - previous) / updated)
	_panel_damage[zone] = updated
	if zone < DamageZone.LEFT and updated >= 0.46:
		_broken_lamps[zone * 2 + (1 if location > 0.0 else 0)] = 1
	_rebuild_damaged_panels()
	_update_crumpled_collision()


func _damage_steering_pull() -> float:
	return (_panel_damage[DamageZone.RIGHT] - _panel_damage[DamageZone.LEFT]) * 0.14


func _restore_bodywork() -> void:
	_panel_damage.fill(0.0)
	_panel_centers.fill(0.0)
	_broken_lamps.fill(0)
	for panel: MeshInstance3D in _stock_meshes:
		panel.mesh = _stock_meshes[panel]
		panel.show()
	for trim: MeshInstance3D in _moving_trim:
		trim.position = _moving_trim[trim]
	_scrapes.hide()
	_scrapes.mesh = null
	_update_crumpled_collision()


func _update_crumpled_collision() -> void:
	var front := _panel_damage[DamageZone.FRONT] * 0.24
	var rear := _panel_damage[DamageZone.REAR] * 0.24
	var shape := _chassis.shape as BoxShape3D
	shape.size = CHASSIS_SIZE - Vector3(0.0, 0.0, front + rear)
	_chassis.position = CHASSIS_CENTER + Vector3(0.0, 0.0, (front - rear) * 0.5)


func _rebuild_damaged_panels() -> void:
	var shaped_rings: Array[PackedVector3Array] = []
	for index in _shell_rings.size():
		var ring := _shell_rings[index]
		shaped_rings.append(_crumple_polygon(ring))
		if index + 1 == _shell_rings.size():
			break
		# Sample the curved dent between the wide straight-door sections.
		var next := _shell_rings[index + 1]
		var intervals := ceili((next[0].z - ring[0].z) / 0.16)
		for step in range(1, intervals):
			var middle := PackedVector3Array()
			for vertex in ring.size():
				middle.append(ring[vertex].lerp(next[vertex], float(step) / intervals))
			shaped_rings.append(_crumple_polygon(middle))
	_shell.mesh = BodyMesh.loft_mesh(shaped_rings)
	for panel: MeshInstance3D in _face_panels:
		var shaped_faces: Array[PackedVector3Array] = []
		var faces: Array = _face_panels[panel]
		for index in faces.size():
			if (panel == _front_lenses and _broken_lamps[index] != 0) or (
					panel == _rear_lenses and _broken_lamps[2 + index] != 0):
				continue
			shaped_faces.append(_crumple_polygon(faces[index]))
		panel.visible = not shaped_faces.is_empty()
		if panel.visible:
			panel.mesh = BodyMesh.faces_mesh(shaped_faces)
	for trim: MeshInstance3D in _moving_trim:
		trim.position = _crumple(_moving_trim[trim])
	_rebuild_scuffs()


func _crumple_polygon(points: PackedVector3Array) -> PackedVector3Array:
	var result := points.duplicate()
	for index in result.size():
		result[index] = _crumple(result[index])
	return result


func _crumple(point: Vector3) -> Vector3:
	var result := point
	for edge in [DamageZone.FRONT, DamageZone.REAR]:
		if _panel_damage[edge] <= 0.0:
			continue
		var direction := -1.0 if edge == DamageZone.FRONT else 1.0
		var depth := smoothstep(0.98, 1.86, point.z * direction)
		var across := 1.0 - 0.56 * smoothstep(0.02, 1.25, absf(point.x - _panel_centers[edge]))
		var strength := depth * across * _panel_damage[edge]
		result.z -= direction * strength * 0.45
		var buckle := 1.0 - smoothstep(0.0, 0.41, absf(point.z * direction - 1.56))
		result.y += strength * lerpf(-0.035, 0.21 * buckle, smoothstep(-0.15, 0.24, point.y))
	var side := DamageZone.LEFT if point.x < 0.0 else DamageZone.RIGHT
	var taper := 1.0 - smoothstep(0.15, 1.32, absf(point.z - _panel_centers[side]))
	var shoulder := smoothstep(0.30, 0.82, absf(point.x)) * (1.0 - smoothstep(0.26, 0.58, point.y))
	result.x -= signf(point.x) * taper * shoulder * _panel_damage[side] * 0.28
	return result


func _rebuild_scuffs() -> void:
	var scars: Array[PackedVector3Array] = []
	for zone in _panel_damage.size():
		var amount := _panel_damage[zone]
		if amount < 0.12:
			continue
		for line in 3:
			var shift := float(line)
			var height := 0.193 + shift * 0.018
			var width := (0.07 + amount * 0.39) * (1.0 - shift * 0.19)
			var center := _panel_centers[zone]
			var cut: PackedVector3Array
			if zone < DamageZone.LEFT:
				var z := -1.866 if zone == DamageZone.FRONT else 1.866
				center = clampf(center, -0.53 + width, 0.53 - width)
				cut = PackedVector3Array([Vector3(center - width, height - 0.025, z),
					Vector3(center + width, height + 0.008, z), Vector3(center + width * 0.76, height + 0.016, z)])
			else:
				var x := -0.829 if zone == DamageZone.LEFT else 0.829
				center = clampf(center, -1.33 + width, 1.33 - width)
				cut = PackedVector3Array([Vector3(x, height - 0.008, center - width),
					Vector3(x, height + 0.021, center + width), Vector3(x, height + 0.029, center + width * 0.80)])
			scars.append(_crumple_polygon(cut))
	_scrapes.visible = not scars.is_empty()
	if _scrapes.visible:
		_scrapes.mesh = BodyMesh.faces_mesh(scars)
