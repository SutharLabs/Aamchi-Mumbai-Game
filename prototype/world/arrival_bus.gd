extends Node3D

const LENGTH := 9.0
const FRONT_STEP := Vector3(-1.18, 0.50, -2.72)

var _doors: Array[Node3D] = []
var _paint := _material("a72c26")
var _rubber := _material("20262a")
var _glass := _material("273c44", 0.27)
var _steel := _material("778084", 0.36)
var _trim := _material("dbd1bc")
var _lamp := _material("fff4cd")
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
	_box(Vector3(0, 0.52, -4.37), Vector3(2.32, 0.28, 0.31), _rubber)
	_box(Vector3(0, 0.52, 4.37), Vector3(2.32, 0.28, 0.31), _rubber)
	_box(Vector3(0, 1.95, -4.43), Vector3(2.11, 1.48, 0.10), _glass).rotation.x = -0.04
	_box(Vector3(0, 2.22, 4.32), Vector3(2.22, 0.90, 0.11), _glass)
	_box(Vector3(0, 1.95, -4.49), Vector3(0.045, 1.43, 0.03), _rubber)
	_box(Vector3(0, 1.21, -4.46), Vector3(0.98, 0.28, 0.08), _rubber)
	_box(Vector3(0, 2.90, -4.51), Vector3(1.87, 0.30, 0.04), _rubber)
	for side in [-1.0, 1.0]:
		_box(Vector3(side * 1.03, 1.02, -4.45), Vector3(0.31, 0.22, 0.14), _lamp)
		_box(Vector3(side * 1.10, 1.27, 4.34), Vector3(0.13, 0.42, 0.10), _brake)
		_box(Vector3(side * 1.36, 2.15, -4.00), Vector3(0.26, 0.40, 0.18), _rubber)
		for index in 6:
			var z := 3.07 - float(index) * 1.17
			if side < 0.0 and absf(z - FRONT_STEP.z) < 0.95:
				continue
			_box(Vector3(side * 1.258, 1.94, z), Vector3(0.06, 1.47, 1.08), _glass)
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
	_box(Vector3(-1.01, 0.44, FRONT_STEP.z), Vector3(0.56, 0.12, 1.15), _steel)
	var route := Label3D.new()
	route.text = "BANDRA"
	route.font_size = 76
	route.pixel_size = 0.0039
	route.outline_size = 1
	route.modulate = Color("ffc969")
	route.position = Vector3(0.0, 2.90, -4.54)
	route.rotation.y = PI
	add_child(route)


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


func _material(hex: String, roughness := 0.72) -> StandardMaterial3D:
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color(hex)
	surface.roughness = roughness
	return surface
