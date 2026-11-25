extends RefCounted
## Skinned rest-pose hands for Omkar's existing wrist and forearm bones.

const WRIST := Vector3(0.665, 1.350, 0.003)
const SCANNED_HAND := preload("res://character/art/omkar_scan_hand.res") as ArrayMesh


class Section:
	var center: Vector3
	var radii: Vector2
	var forearm_weight: float

	func _init(point: Vector3, width: float, depth: float, forearm := 0.0) -> void:
		center = point
		radii = Vector2(width, depth)
		forearm_weight = forearm


static func add_scan(surface: SurfaceTool, side: float, hand_bone: int, forearm_bone: int,
		skin: Color) -> void:
	var arrays := SCANNED_HAND.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var fit: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var bones := PackedInt32Array([forearm_bone, hand_bone, 0, 0])
	for face in range(0, indices.size(), 3):
		for corner in range(3):
			var index := indices[face + (corner if side > 0.0 else 2 - corner)]
			var point := vertices[index] + WRIST
			point.x *= side
			var forearm := fit[index].x
			var seam := roundi(fit[index].y * 16.0) - 1
			if seam >= 0:
				# Recompute the shared wrist boundary exactly as the forearm tube does.
				var turn := TAU * posmod(seam if side > 0.0 else -seam, 10) / 10
				var depth := Vector3.UP.cross(Vector3(side, 0.0, 0.0))
				var radial := Vector3.UP * (0.027 * cos(turn)) + depth * (0.026 * sin(turn))
				point = Vector3(side * 0.666, 1.350, 0.002) + radial
				forearm = 1.0 - 0.56
			surface.set_bones(bones)
			surface.set_weights(PackedFloat32Array([forearm, 1.0 - forearm, 0.0, 0.0]))
			surface.set_uv(Vector2(0.90 + (point.x + point.z) * 0.06, 0.04 + point.y * 0.23))
			surface.set_color(skin)
			surface.add_vertex(point)


static func add(surface: SurfaceTool, side: float, hand_bone: int, forearm_bone: int,
		skin: Color) -> void:
	var bones := PackedInt32Array([hand_bone, forearm_bone, 0, 0])
	var palm: Array[Section] = [
		Section.new(Vector3(-0.019, 0.0, -0.001), 0.0, 0.0, 1.0),
		Section.new(Vector3.ZERO, 0.026, 0.026, 0.33),
		Section.new(Vector3(0.014, -0.001, -0.002), 0.022, 0.032, 0.12),
		Section.new(Vector3(0.032, -0.001, -0.004), 0.017, 0.038),
		Section.new(Vector3(0.046, -0.003, 0.0), 0.014, 0.036),
		Section.new(Vector3(0.057, -0.007, 0.0), 0.009, 0.030),
		Section.new(Vector3(0.061, -0.010, 0.002), 0.0, 0.0),
	]
	_loft(surface, palm, side, bones, skin, 10)

	# Thumb opposes the fingers. Its broad base sinks into the palm at the wrist side.
	var thumb: Array[Section] = [
		Section.new(Vector3(0.017, -0.006, -0.024), 0.0, 0.0),
		Section.new(Vector3(0.029, -0.010, -0.033), 0.013, 0.012),
		Section.new(Vector3(0.046, -0.017, -0.041), 0.011, 0.009),
		Section.new(Vector3(0.062, -0.027, -0.040), 0.009, 0.008),
		Section.new(Vector3(0.073, -0.030, -0.036), 0.007, 0.006),
		Section.new(Vector3(0.079, -0.030, -0.034), 0.0, 0.0),
	]
	_loft(surface, thumb, side, bones, skin, 8)

	# Finger lengths and knuckle positions follow the arc across a relaxed hand.
	_add_finger(surface, side, bones, skin, Vector3(0.046, -0.003, -0.026), 0.053, 0.009, -0.001)
	_add_finger(surface, side, bones, skin, Vector3(0.048, -0.002, -0.009), 0.056, 0.009, 0.0)
	_add_finger(surface, side, bones, skin, Vector3(0.047, -0.004, 0.009), 0.051, 0.0085, 0.002)
	_add_finger(surface, side, bones, skin, Vector3(0.043, -0.007, 0.025), 0.045, 0.007, 0.005)


static func _add_finger(surface: SurfaceTool, side: float, bones: PackedInt32Array, skin: Color,
		base: Vector3, length: float, radius: float, splay: float) -> void:
	var sections: Array[Section] = [
		Section.new(base, 0.0, 0.0),
		Section.new(base + Vector3(length * 0.19, -0.001, 0.0), radius * 1.14, radius),
		Section.new(base + Vector3(length * 0.42, -0.004, splay * 0.32), radius * 0.87, radius * 0.92),
		Section.new(base + Vector3(length * 0.63, -0.009, splay * 0.60), radius * 0.84, radius * 0.80),
		Section.new(base + Vector3(length * 0.85, -0.016, splay * 0.88), radius * 0.72, radius * 0.72),
		Section.new(base + Vector3(length, -0.020, splay), 0.0, 0.0),
	]
	_loft(surface, sections, side, bones, skin, 8)


static func _loft(surface: SurfaceTool, sections: Array[Section], side: float,
		bones: PackedInt32Array, skin: Color, sides: int) -> void:
	for row: int in range(sections.size() - 1):
		var start := sections[row]
		var end := sections[row + 1]
		for column: int in range(sides):
			var turn := TAU * float(column) / sides
			var next := TAU * float((column + 1) % sides) / sides
			if start.radii.x > 0.0:
				_emit(surface, start, turn, side, bones, skin)
				if side > 0.0:
					_emit(surface, start, next, side, bones, skin)
					_emit(surface, end, turn, side, bones, skin)
				else:
					_emit(surface, end, turn, side, bones, skin)
					_emit(surface, start, next, side, bones, skin)
			if end.radii.x > 0.0:
				_emit(surface, start, next, side, bones, skin)
				if side > 0.0:
					_emit(surface, end, next, side, bones, skin)
					_emit(surface, end, turn, side, bones, skin)
				else:
					_emit(surface, end, turn, side, bones, skin)
					_emit(surface, end, next, side, bones, skin)


static func _emit(surface: SurfaceTool, section: Section, turn: float, side: float,
		bones: PackedInt32Array, skin: Color) -> void:
	var across := cos(turn)
	var depth := -sin(turn)
	var point := WRIST + section.center + Vector3(0.0, section.radii.x * across, section.radii.y * depth)
	point.x *= side
	var palm_shade := maxf(0.0, -across) * smoothstep(0.010, 0.048, section.center.x)
	surface.set_bones(bones)
	surface.set_weights(PackedFloat32Array([1.0 - section.forearm_weight, section.forearm_weight, 0.0, 0.0]))
	surface.set_uv(Vector2(0.90 + (point.x + point.z) * 0.06, 0.04 + point.y * 0.23))
	surface.set_color(skin.darkened(0.08 * palm_shade))
	surface.add_vertex(point)
