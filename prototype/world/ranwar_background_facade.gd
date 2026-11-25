extends RefCounted
## Small street and return faces for the remaining authored building masses.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const WIDTH := 12.0
const DEPTH := 13.0
const GLASS := Color("526061")


static func create(height: float, paint: Color, material: Material, street_side: Vector3,
		seed_value: int, street_already_detailed: bool) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	Surfaces.add_box(surface, Vector3.UP * height * 0.5, Vector3(WIDTH, height, DEPTH), paint, Surfaces.PLASTER)
	Surfaces.add_box(surface, Vector3.UP * (height + 0.13), Vector3(WIDTH + 0.42, 0.26, DEPTH + 0.42),
		paint.darkened(0.24), Surfaces.CONCRETE)
	var roof_side := -1.0 if seed_value % 2 == 0 else 1.0
	Surfaces.add_box(surface, Vector3(roof_side * 2.8, height + 0.70, -1.8), Vector3(2.45, 0.88, 2.50),
		paint.darkened(0.15), Surfaces.PLASTER)
	for edge: float in [-1.0, 1.0]:
		Surfaces.add_box(surface, Vector3(0, height + 0.30, edge * 6.36), Vector3(12.1, 0.60, 0.19),
			paint.darkened(0.27), Surfaces.CONCRETE)
		Surfaces.add_box(surface, Vector3(edge * 5.92, height + 0.30, 0), Vector3(0.18, 0.60, 12.62),
			paint.darkened(0.27), Surfaces.CONCRETE)
	for outward: Vector3 in [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var faces_street := outward.dot(street_side) > 0.9
		if faces_street and street_already_detailed:
			continue
		var along := Vector3.UP.cross(outward)
		var axes := Basis(along, Vector3.UP, outward)
		var span := DEPTH if absf(outward.x) > 0.5 else WIDTH
		var inset := WIDTH * 0.5 if absf(outward.x) > 0.5 else DEPTH * 0.5
		_add_face(surface, outward * inset, axes, span, height, paint, seed_value, faces_street)
	surface.generate_normals()
	surface.index()
	var arrays := surface.commit_to_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for index in vertices.size():
		vertices[index] -= Vector3.UP * height * 0.5
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	return mesh


static func _add_face(surface: SurfaceTool, origin: Vector3, axes: Basis, span: float, height: float,
		paint: Color, seed_value: int, faces_street: bool) -> void:
	var window_trim := paint.lerp(Color("c9c0a8"), 0.57)
	var levels := maxi(1, floori(height / 2.65))
	var bays := 3 + (seed_value % 2)
	var spacing := (span - 1.30) / bays
	var style := seed_value % 3
	Surfaces.add_box(surface, origin + axes * Vector3(0.0, 0.34, 0.03), Vector3(span, 0.68, 0.10),
		paint.darkened(0.29), Surfaces.CONCRETE, axes)
	for pipe_side: float in [-1.0, 1.0]:
		var column := pipe_side * (span * 0.5 - 0.33)
		Surfaces.add_box(surface, origin + axes * Vector3(column, height * 0.5, 0.055),
			Vector3(0.16, height - 0.35, 0.16), paint.darkened(0.33), Surfaces.PLAIN, axes)
		for level in range(1, levels):
			Surfaces.add_box(surface, origin + axes * Vector3(column, level * 2.65, 0.070),
				Vector3(0.21, 0.08, 0.20), window_trim.darkened(0.32), Surfaces.PLAIN, axes)
	if faces_street:
		var porch_width := 2.30 + float(seed_value % 3) * 0.60
		Surfaces.add_box(surface, origin + axes * Vector3(0.0, 2.46, 0.38), Vector3(porch_width, 0.12, 0.82),
			paint.darkened(0.38), Surfaces.CONCRETE, axes)
	for level in range(1 if faces_street else 0, levels):
		if level > 0 and style == 0:
			Surfaces.add_box(surface, origin + axes * Vector3(0.0, level * 2.65 + 0.26, 0.05),
				Vector3(span - 0.32, 0.15, 0.18), paint.darkened(0.21), Surfaces.CONCRETE, axes)
		for bay in bays:
			var x := (float(bay) + 0.5) * spacing - (span - 1.30) * 0.5
			var center := Vector3(x, 1.55 + float(level) * 2.65, 0.018)
			var shade := float((seed_value + level * 5 + bay * 3) % 7) * 0.045
			_panel(surface, origin, axes, center, Vector2(1.43, 1.46), window_trim)
			_panel(surface, origin, axes, center + Vector3(0.0, 0.0, 0.018), Vector2(1.24, 1.25), GLASS.darkened(shade))
			_panel(surface, origin, axes, center + Vector3(0.0, 0.0, 0.022), Vector2(0.054, 1.25), window_trim)
			_panel(surface, origin, axes, center + Vector3(0.0, -0.10, 0.025), Vector2(1.24, 0.04), window_trim)
			if style == 1 or (style == 0 and bay % 2 == 0):
				Surfaces.add_box(surface, origin + axes * (center + Vector3(0, 0.86, 0.22)),
					Vector3(1.88, 0.095, 0.51), window_trim.darkened(0.19), Surfaces.CONCRETE, axes)
			if level > 0 and style == 2 and (bay + level) % 2 == 0:
				_add_balcony(surface, origin + axes * Vector3(x, level * 2.65 + 0.40, 0), axes, window_trim)
			if faces_street:
				Surfaces.add_box(surface, origin + axes * (center + Vector3(0.0, -0.70, 0.082)),
					Vector3(1.55, 0.095, 0.23), window_trim.darkened(0.17), Surfaces.CONCRETE, axes)
	if faces_street:
		_panel(surface, origin, axes, Vector3(0.0, 1.19, 0.025), Vector2(1.66, 2.38), paint.darkened(0.49))


static func _add_balcony(surface: SurfaceTool, origin: Vector3, axes: Basis, trim: Color) -> void:
	Surfaces.add_box(surface, origin + axes * Vector3(0, 0, 0.38), Vector3(2.08, 0.14, 0.83),
		trim.darkened(0.18), Surfaces.CONCRETE, axes)
	var railing := trim.darkened(0.59)
	for y: float in [0.39, 0.87]:
		Surfaces.add_box(surface, origin + axes * Vector3(0, y, 0.75), Vector3(1.97, 0.048, 0.044),
			railing, Surfaces.PLAIN, axes)
	for post in 6:
		Surfaces.add_box(surface, origin + axes * Vector3(-0.96 + 0.384 * post, 0.46, 0.75),
			Vector3(0.037, 0.86, 0.036), railing, Surfaces.PLAIN, axes)


static func _panel(surface: SurfaceTool, origin: Vector3, axes: Basis, center: Vector3,
		size: Vector2, tint: Color) -> void:
	var point := origin + axes * center
	var x := axes.x * size.x * 0.5
	var y := axes.y * size.y * 0.5
	Surfaces.add_triangle(surface, point - x - y, point + x + y, point + x - y, tint, Surfaces.PLAIN)
	Surfaces.add_triangle(surface, point - x - y, point - x + y, point + x + y, tint, Surfaces.PLAIN)
