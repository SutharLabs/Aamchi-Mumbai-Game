extends RefCounted
## Small original bodywork meshes built in metres, with forward along -Z.


static func loft(parent: Node3D, label: String, sections: Array, material: Material, closed: bool = true) -> MeshInstance3D:
	# Rings advance along +Z and are clockwise in X/Y, starting at the lower left.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for section in range(sections.size() - 1):
		var start: PackedVector3Array = sections[section]
		var next: PackedVector3Array = sections[section + 1]
		for index in range(start.size()):
			var adjacent := (index + 1) % start.size()
			_triangle(surface, start[index], start[adjacent], next[adjacent])
			_triangle(surface, start[index], next[adjacent], next[index])
	if closed:
		var front: PackedVector3Array = sections.front().duplicate()
		front.reverse()
		_polygon(surface, front)
		_polygon(surface, sections.back())
	surface.generate_normals()
	surface.index()
	return part(parent, label, surface.commit(), material)


static func faces(parent: Node3D, label: String, polygons: Array, material: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for polygon: PackedVector3Array in polygons:
		_polygon(surface, polygon)
	surface.generate_normals()
	return part(parent, label, surface.commit(), material)


static func part(parent: Node3D, label: String, mesh: Mesh, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	return node


static func bar(parent: Node3D, label: String, from: Vector3, to: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = from.distance_to(to)
	cylinder.radial_segments = 8
	cylinder.rings = 1
	var node := part(parent, label, cylinder, material)
	node.position = (from + to) * 0.5
	node.quaternion = Quaternion(Vector3.UP, (to - from).normalized())
	return node


static func dress_wheel(pivot: Node3D, radius: float, width: float, tire: Material, steel: Material, inset: Material, spokes: int = 5) -> void:
	var roll: Node3D = pivot.get_child(0)
	var old_tire: MeshInstance3D = roll.get_child(0)
	var old_hub: MeshInstance3D = roll.get_child(1)
	# Tire shoulders, sidewalls and beads become a single smooth mesh.
	var tire_profile := PackedVector2Array([
		Vector2(-0.44, 0.68), Vector2(-0.51, 0.87), Vector2(-0.42, 0.96),
		Vector2(-0.27, 1.0), Vector2(0.27, 1.0), Vector2(0.42, 0.96),
		Vector2(0.51, 0.87), Vector2(0.44, 0.68),
	])
	old_tire.mesh = _revolve(tire_profile, width, radius)
	old_tire.material_override = tire
	old_tire.rotation = Vector3.ZERO
	var rim_profile := PackedVector2Array([
		Vector2(-0.43, 0.61), Vector2(-0.46, 0.70), Vector2(-0.37, 0.73),
		Vector2(0.37, 0.73), Vector2(0.46, 0.70), Vector2(0.43, 0.61),
	])
	old_hub.mesh = _revolve(rim_profile, width, radius)
	old_hub.material_override = steel
	old_hub.rotation = Vector3.ZERO
	var hub := CylinderMesh.new()
	hub.top_radius = radius * 0.19
	hub.bottom_radius = radius * 0.19
	hub.height = width * 0.89
	hub.radial_segments = 12
	hub.rings = 1
	part(roll, "WheelCentre", hub, inset).rotation.z = PI * 0.5
	var spoke_faces: Array[PackedVector3Array] = []
	for side: float in [-1.0, 1.0]:
		for spoke in range(spokes):
			var angle := TAU * float(spoke) / float(spokes)
			var x := side * width * 0.43
			var polygon := PackedVector3Array([
				_wheel_point(x, radius * 0.16, angle - 0.22),
				_wheel_point(x, radius * 0.64, angle - 0.08),
				_wheel_point(x, radius * 0.64, angle + 0.09),
				_wheel_point(x, radius * 0.16, angle + 0.24),
			])
			if side > 0.0:
				polygon.reverse()
			spoke_faces.append(polygon)
	faces(roll, "WheelSpokes", spoke_faces, steel)


static func _revolve(profile: PackedVector2Array, width: float, radius: float) -> ArrayMesh:
	const SIDES := 20
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for band in range(profile.size()):
		var first := profile[band]
		var next := profile[(band + 1) % profile.size()]
		for side in range(SIDES):
			var angle := TAU * float(side) / float(SIDES)
			var later := TAU * float((side + 1) % SIDES) / float(SIDES)
			var a := _wheel_point(first.x * width, first.y * radius, angle)
			var b := _wheel_point(next.x * width, next.y * radius, angle)
			var c := _wheel_point(next.x * width, next.y * radius, later)
			var d := _wheel_point(first.x * width, first.y * radius, later)
			_triangle(surface, a, b, c)
			_triangle(surface, a, c, d)
	surface.generate_normals()
	surface.index()
	return surface.commit()


static func _wheel_point(x: float, radius: float, angle: float) -> Vector3:
	return Vector3(x, cos(angle) * radius, sin(angle) * radius)


static func _polygon(surface: SurfaceTool, polygon: PackedVector3Array) -> void:
	for vertex in range(1, polygon.size() - 1):
		_triangle(surface, polygon[0], polygon[vertex], polygon[vertex + 1])


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
