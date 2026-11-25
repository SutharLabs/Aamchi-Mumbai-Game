extends RefCounted
## Small original bodywork meshes built in metres, with forward along -Z.

const REGISTRATION_GLYPHS := {
	"M": [Vector4(0, 0, 0, 1), Vector4(0, 1, 0.5, 0.52), Vector4(0.5, 0.52, 1, 1), Vector4(1, 1, 1, 0)],
	"H": [Vector4(0, 0, 0, 1), Vector4(0, 0.5, 1, 0.5), Vector4(1, 0, 1, 1)],
	"0": [Vector4(0, 0, 0, 1), Vector4(0, 1, 1, 1), Vector4(1, 1, 1, 0), Vector4(1, 0, 0, 0)],
	"2": [Vector4(0, 1, 1, 1), Vector4(1, 1, 1, 0.63), Vector4(1, 0.63, 0, 0.12),
		Vector4(0, 0.12, 0, 0), Vector4(0, 0, 1, 0)],
	"R": [Vector4(0, 0, 0, 1), Vector4(0, 1, 1, 1), Vector4(1, 1, 1, 0.53),
		Vector4(1, 0.53, 0, 0.53), Vector4(0.35, 0.53, 1, 0)],
	"X": [Vector4(0, 0, 1, 1), Vector4(0, 1, 1, 0)],
}


static func loft(parent: Node3D, label: String, sections: Array, material: Material, closed: bool = true) -> MeshInstance3D:
	return part(parent, label, loft_mesh(sections, closed), material)


static func loft_mesh(sections: Array, closed: bool = true) -> ArrayMesh:
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
	return surface.commit()


static func faces(parent: Node3D, label: String, polygons: Array, material: Material) -> MeshInstance3D:
	return part(parent, label, faces_mesh(polygons), material)


static func faces_mesh(polygons: Array) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	for polygon: PackedVector3Array in polygons:
		_polygon(surface, polygon)
	surface.generate_normals()
	return surface.commit()


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


static func detail_boxes(parent: Node3D, label: String, boxes: Array[Array], material: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var block := BoxMesh.new()
	for box: Array in boxes:
		block.size = box[1]
		surface.append_from(block, 0, Transform3D(Basis.IDENTITY, box[0]))
	return part(parent, label, surface.commit(), material)


static func registration_text(parent: Node3D, center: Vector3, front: bool, two_lines: bool,
		ink: Material) -> MeshInstance3D:
	# Use flat, original strokes to keep recurring plate geometry small in traffic.
	var rows := PackedStringArray(["MH 02", "RX 0000"] if two_lines else ["MH 02 RX 0000"])
	var glyph_size := Vector2(0.0105, 0.017) if two_lines else Vector2(0.015, 0.033)
	var advance := glyph_size.x * 1.32
	var half_stroke := 0.00086 if two_lines else 0.00143
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_normal(Vector3.BACK)
	for row_index in rows.size():
		var row := rows[row_index]
		var x := -((row.length() - 1) * advance + glyph_size.x) * 0.5
		var y := -glyph_size.y * 0.5 + (0.5 * (rows.size() - 1) - row_index) * glyph_size.y * 1.36
		for glyph_index in row.length():
			var origin := Vector2(x + glyph_index * advance, y)
			for stroke: Vector4 in REGISTRATION_GLYPHS.get(row[glyph_index], []):
				var start := origin + Vector2(stroke.x, stroke.y) * glyph_size
				var end := origin + Vector2(stroke.z, stroke.w) * glyph_size
				var direction := (end - start).normalized()
				var edge := Vector2(-direction.y, direction.x) * half_stroke
				start -= direction * half_stroke
				end += direction * half_stroke
				_polygon(surface, PackedVector3Array([
					Vector3(start.x - edge.x, start.y - edge.y, 0), Vector3(start.x + edge.x, start.y + edge.y, 0),
					Vector3(end.x + edge.x, end.y + edge.y, 0), Vector3(end.x - edge.x, end.y - edge.y, 0),
				]))
	surface.index()
	var label := part(parent, "FictionalMumbaiRegistration", surface.commit(), ink)
	label.position = center
	if front:
		label.rotation.y = PI
	return label


static func spring(parent: Node3D, label: String, bottom: Vector3, top: Vector3,
		coil_radius: float, wire_radius: float, material: Material) -> void:
	const STEPS := 40
	const COILS := 5.0
	const SIDES := 5
	var axis := (top - bottom).normalized()
	var across := axis.cross(Vector3.FORWARD).normalized()
	var around := axis.cross(across)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous := PackedVector3Array()
	for index in range(STEPS + 1):
		var progress := float(index) / STEPS
		var angle := progress * TAU * COILS
		var radial := across * cos(angle) + around * sin(angle)
		var center := bottom.lerp(top, progress) + radial * coil_radius
		var ring := PackedVector3Array()
		for side in SIDES:
			var section := TAU * float(side) / SIDES
			ring.append(center + (radial * cos(section) + axis * sin(section)) * wire_radius)
		if not previous.is_empty():
			for side in SIDES:
				var next := (side + 1) % SIDES
				_triangle(surface, previous[side], ring[side], ring[next])
				_triangle(surface, previous[side], ring[next], previous[next])
		previous = ring
	surface.generate_normals()
	surface.index()
	part(parent, label, surface.commit(), material)


static func dress_wheel(pivot: Node3D, radius: float, width: float, tire: Material, steel: Material, inset: Material, spokes: int = 5) -> void:
	var roll: Node3D = pivot.get_child(0)
	var old_tire: MeshInstance3D = roll.get_child(0)
	var old_hub: MeshInstance3D = roll.get_child(1)
	# Tire shoulders, sidewalls and beads become a single smooth mesh.
	var tire_profile := PackedVector2Array([
		Vector2(-0.44, 0.68), Vector2(-0.51, 0.85), Vector2(-0.47, 0.94),
		Vector2(-0.34, 0.984), Vector2(-0.18, 1.0), Vector2(0.18, 1.0),
		Vector2(0.34, 0.984), Vector2(0.47, 0.94), Vector2(0.51, 0.85), Vector2(0.44, 0.68),
	])
	old_tire.mesh = _revolve(tire_profile, width, radius, 28)
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
	var cap := CylinderMesh.new()
	cap.top_radius = radius * 0.101
	cap.bottom_radius = radius * 0.121
	cap.height = width * 0.06
	cap.radial_segments = 12
	cap.rings = 0
	var nuts: Array[Array] = []
	for side: float in [-1.0, 1.0]:
		var cover := part(roll, "HubCap", cap, steel)
		cover.position.x = side * width * 0.456
		cover.rotation.z = -side * PI * 0.5
		for lug in range(4):
			var angle := TAU * float(lug) / 4.0 + PI * 0.25
			nuts.append([_wheel_point(side * width * 0.461, radius * 0.163, angle),
				Vector3(width * 0.052, radius * 0.047, radius * 0.047)])
	detail_boxes(roll, "HubFasteners", nuts, steel)


static func brake_rotor(wheel: Node3D, radius: float, width: float, steel: Material, housing: Material) -> void:
	# The disc spins with the wheel. The caliper stays attached to the upright.
	var roll: Node3D = wheel.get_child(0)
	var disc := _revolve(PackedVector2Array([
		Vector2(-0.18, 0.22), Vector2(-0.18, 0.52), Vector2(-0.14, 0.56),
		Vector2(-0.04, 0.56), Vector2(0.0, 0.52), Vector2(0.0, 0.22),
	]), width, radius, 22)
	var rotor := part(roll, "BrakeDisc", disc, steel)
	rotor.position.x = width * 0.27
	detail_boxes(wheel, "BrakeCaliper", [[Vector3(width * 0.44, radius * 0.34, -radius * 0.39),
		Vector3(width * 0.36, radius * 0.28, radius * 0.20)]], housing)
	bar(wheel, "BrakeHoseGuide", Vector3(width * 0.52, radius * 0.47, -radius * 0.35),
		Vector3(width * 0.68, radius * 0.77, -radius * 0.12), radius * 0.016, housing)


static func brake_drum(wheel: Node3D, radius: float, width: float, alloy: Material, housing: Material) -> void:
	var roll: Node3D = wheel.get_child(0)
	var drum := CylinderMesh.new()
	drum.top_radius = radius * 0.31
	drum.bottom_radius = radius * 0.35
	drum.height = width * 0.64
	drum.radial_segments = 16
	drum.rings = 0
	var casing := part(roll, "DrumBrakeCasing", drum, alloy)
	casing.position.x = width * 0.11
	casing.rotation.z = -PI * 0.5
	bar(wheel, "DrumBrakeActuator", Vector3(width * 0.53, radius * 0.12, 0.0),
		Vector3(width * 0.57, radius * 0.47, -radius * 0.08), radius * 0.024, housing)


static func _revolve(profile: PackedVector2Array, width: float, radius: float, sides: int = 20) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for band in range(profile.size()):
		var first := profile[band]
		var next := profile[(band + 1) % profile.size()]
		for side in sides:
			var angle := TAU * float(side) / float(sides)
			var later := TAU * float((side + 1) % sides) / float(sides)
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
