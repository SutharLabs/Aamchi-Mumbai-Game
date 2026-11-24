extends Node3D

const LENGTH := 9.0
const FRONT_STEP := Vector3(-1.18, 0.50, -2.72)
const NOSE_LIMIT := -4.53

var _doors: Array[Node3D] = []
var _paint := _material("a72c26")
var _rubber := _material("171e22")
var _glass := _material("2c4752", 0.23, 0.17)
var _steel := _material("778084", 0.36, 0.45)
var _trim := _material("dbd1bc")
var _lamp := _material("a4b3b5", 0.19, 0.30)
var _lamp_trim := _material("384952", 0.23, 0.55)
var _safety := _material("cb9a32", 0.48)
var _brake := _material("d7503a")
var _box_mesh := BoxMesh.new()


func _ready() -> void:
	_build_coach()
	set_door_open(0.0)


func set_door_open(amount: float) -> void:
	for index in _doors.size():
		var sign_z := -1.0 if index == 0 else 1.0
		_doors[index].position.z = FRONT_STEP.z + sign_z * (0.28 + 0.58 * amount)


func _build_coach() -> void:
	# Rounded plan section with a narrower, slightly inset nose and tail.
	_body_band(0.53, 1.20, 1.26, _paint, true)
	_body_band(2.67, 3.12, 1.26, _paint)
	_body_band(3.12, 3.20, 1.13, _trim)
	_box(Vector3(0, 0.53, 0), Vector3(2.26, 0.14, 8.54), _rubber)
	_box(Vector3(0, 0.52, -4.35), Vector3(2.19, 0.24, 0.28), _rubber)
	_box(Vector3(0, 0.52, 4.37), Vector3(2.32, 0.28, 0.31), _rubber)
	_build_front()
	_box(Vector3(0, 2.22, 4.32), Vector3(2.22, 0.90, 0.11), _glass)
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 1.10, 1.27, 4.34), Vector3(0.13, 0.42, 0.10), _brake)
		_box(Vector3(side * 1.286, 2.25, -4.05), Vector3(0.40, 0.07, 0.075), _rubber).rotation.z = -side * 0.20
		_box(Vector3(side * 1.42, 2.15, -4.05), Vector3(0.14, 0.35, 0.15), _rubber)
		_box(Vector3(side * 1.42, 2.15, -3.966), Vector3(0.11, 0.28, 0.015), _lamp_trim)
		for index in 6:
			var z := 3.07 - float(index) * 1.17
			if side < 0.0 and absf(z - FRONT_STEP.z) < 0.95:
				continue
			_box(Vector3(side * 1.255, 1.94, z), Vector3(0.045, 1.47, 1.17), _rubber)
			_box(Vector3(side * 1.279, 1.96, z), Vector3(0.019, 1.34, 1.08), _glass)
		for z in [-2.63, 2.55]:
			_wheel(Vector3(side * 1.16, 0.47, z), side)
	_box(Vector3(0.67, 3.23, -0.44), Vector3(0.83, 0.18, 2.85), _trim)
	_box(Vector3(-0.12, 3.23, 1.15), Vector3(0.74, 0.16, 1.44), _trim)
	for index in 2:
		var panel := Node3D.new()
		panel.position = Vector3(-1.258, 0.0, FRONT_STEP.z)
		add_child(panel)
		_doors.append(panel)
		_box(Vector3(0, 1.52, 0), Vector3(0.09, 1.97, 0.55), _rubber, panel)
		_box(Vector3(-0.052, 1.73, 0), Vector3(0.025, 1.42, 0.46), _glass, panel)
		_box(Vector3(-0.069, 1.23, 0), Vector3(0.018, 0.032, 0.42), _steel, panel)
	_box(Vector3(-1.01, 0.44, FRONT_STEP.z), Vector3(0.56, 0.12, 1.15), _steel)
	_box(Vector3(-1.26, 0.497, FRONT_STEP.z), Vector3(0.055, 0.019, 1.12), _safety)
	for offset in [-0.51, 0.51]:
		_box(Vector3(-1.08, 1.03, FRONT_STEP.z + offset), Vector3(0.041, 0.97, 0.041), _safety)


func _build_front() -> void:
	# The mask sits over the lower body skin and resolves the glass, seals and lamp modules as distinct surfaces.
	_front_panel(Vector3(0, 1.96, -4.499), Vector2(2.23, 1.61), 0.13, _rubber)
	_front_panel(Vector3(0, 1.98, -4.509), Vector2(2.10, 1.45), 0.105, _glass)
	_box(Vector3(0, 1.98, -4.52), Vector3(0.027, 1.43, 0.014), _rubber)
	_front_panel(Vector3(0, 1.165, -4.519), Vector2(1.77, 0.075), 0.027, _steel)
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 0.51, 1.36, -4.521), Vector3(0.018, 0.33, 0.017), _rubber).rotation.z = -0.70
		_box(Vector3(side * 0.37 + 0.11, 1.48, -4.524), Vector3(0.036, 0.55, 0.010), _rubber).rotation.z = -1.20
		_front_panel(Vector3(side * 0.82, 0.99, -4.512), Vector2(0.43, 0.27), 0.055, _rubber)
		_front_panel(Vector3(side * 0.82, 1.085, -4.523), Vector2(0.31, 0.028), 0.013, _lamp)
		for spacing in [-0.090, 0.090]:
			var center := Vector3(side * 0.82 + spacing, 0.958, -4.512)
			_front_disc(center, 0.066, _lamp_trim)
			_front_disc(center + Vector3.FORWARD * 0.008, 0.045, _lamp)
	_front_panel(Vector3(0, 0.60, -4.526), Vector2(2.17, 0.26), 0.085, _rubber)
	_front_panel(Vector3(0, 0.95, -4.516), Vector2(0.83, 0.16), 0.036, _rubber)
	for index in 3:
		_box(Vector3(0, 0.91 + float(index) * 0.039, -4.524), Vector3(0.68, 0.014, 0.012), _lamp_trim)
	_front_panel(Vector3(0, 0.69, NOSE_LIMIT), Vector2(0.30, 0.077), 0.012, _safety)
	_front_panel(Vector3(0, 2.90, -4.523), Vector2(1.91, 0.34), 0.066, _rubber)
	var route := Label3D.new()
	route.text = "BANDRA"
	route.font_size = 76
	route.pixel_size = 0.0039
	route.outline_size = 1
	route.modulate = Color("ffc969")
	route.position = Vector3(0.0, 2.90, -4.54)
	route.rotation.y = PI
	add_child(route)


func _front_panel(at: Vector3, size: Vector2, corner: float, material: StandardMaterial3D) -> void:
	var x := size.x * 0.5
	var y := size.y * 0.5
	var outline := PackedVector2Array([
		Vector2(-x + corner, -y), Vector2(-x, -y + corner), Vector2(-x, y - corner), Vector2(-x + corner, y),
		Vector2(x - corner, y), Vector2(x, y - corner), Vector2(x, -y + corner), Vector2(x - corner, -y),
	])
	var points := PackedVector3Array([at])
	for point: Vector2 in outline:
		var setback := 0.012 * pow(point.x / x, 2.0) * minf(size.x, 1.0) + point.y * 0.010
		points.append(Vector3(at.x + point.x, at.y + point.y, maxf(at.z + setback, NOSE_LIMIT)))
	points.append(points[1])
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.add_triangle_fan(points)
	surface.generate_normals()
	var part := MeshInstance3D.new()
	part.mesh = surface.commit()
	var two_sided := material.duplicate() as StandardMaterial3D
	two_sided.cull_mode = BaseMaterial3D.CULL_DISABLED
	part.material_override = two_sided
	add_child(part)


func _front_disc(at: Vector3, radius: float, material: StandardMaterial3D) -> void:
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.019
	disc.radial_segments = 14
	var part := MeshInstance3D.new()
	part.mesh = disc
	part.material_override = material
	part.position = at
	part.rotation.x = PI * 0.5
	add_child(part)


func _body_band(low: float, high: float, width: float, material: Material, step_open := false) -> void:
	var shape := PackedVector2Array([
		Vector2(-width * 0.83, -LENGTH * 0.5), Vector2(width * 0.83, -LENGTH * 0.5),
		Vector2(width, -LENGTH * 0.5 + 0.33), Vector2(width, LENGTH * 0.5 - 0.38),
		Vector2(width * 0.82, LENGTH * 0.5), Vector2(-width * 0.82, LENGTH * 0.5),
		Vector2(-width, LENGTH * 0.5 - 0.38), Vector2(-width, -LENGTH * 0.5 + 0.33)])
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in shape.size():
		var a := shape[index]
		var b := shape[(index + 1) % shape.size()]
		if step_open and index == 6:
			_band_face(mesh, a, Vector2(a.x, FRONT_STEP.z + 0.58), low, high)
			_band_face(mesh, Vector2(a.x, FRONT_STEP.z - 0.58), b, low, high)
		else:
			_band_face(mesh, a, b, low, high)
		if not step_open:
			mesh.add_triangle_fan(PackedVector3Array([
				Vector3(0.0, high, 0.0), Vector3(b.x, high, b.y), Vector3(a.x, high, a.y)]))
	mesh.generate_normals()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh.commit()
	# The band geometry also shows its undersides when viewed from the curb.
	var two_sided := material.duplicate() as StandardMaterial3D
	two_sided.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = two_sided
	add_child(instance)


func _band_face(mesh: SurfaceTool, a: Vector2, b: Vector2, low: float, high: float) -> void:
	mesh.add_triangle_fan(PackedVector3Array([
		Vector3(a.x, low, a.y), Vector3(a.x, high, a.y),
		Vector3(b.x, high, b.y), Vector3(b.x, low, b.y)]))


func _wheel(center: Vector3, side: float) -> void:
	for rim in [false, true]:
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.27 if rim else 0.47
		cylinder.bottom_radius = cylinder.top_radius
		cylinder.height = 0.08 if rim else 0.32
		cylinder.radial_segments = 16
		var instance := MeshInstance3D.new()
		instance.mesh = cylinder
		instance.material_override = _steel if rim else _rubber
		instance.position = center + Vector3(side * (0.17 if rim else 0.0), 0.0, 0.0)
		instance.rotation.z = PI * 0.5
		add_child(instance)


func _box(at: Vector3, dimensions: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = _box_mesh
	part.position = at
	part.scale = dimensions
	part.material_override = material
	(self if parent == null else parent).add_child(part)
	return part


func _material(hex: String, roughness := 0.72, metallic := 0.0) -> StandardMaterial3D:
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color(hex)
	surface.roughness = roughness
	surface.metallic = metallic
	return surface
