extends RefCounted
## Visual frontage for the fictional Hill Road tenant. The mapped building owns its collider.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const SIGNS := preload("res://world/textures/hill_road_tea_room_signs.png")
const STONE := Color("ada392")
const GREEN := Color("3a5047")
const STEEL := Color("5b6862")
const GALVANIZED := Color("878c81")
const CREAM := Color("d7ccad")


static func add_to(body: Node3D, frame: Transform3D, material: Material, span: float, height: float,
		paint: Color) -> void:
	var mesh := ArrayMesh.new()
	var structural := _surface()
	var glass := _surface()
	_ground_floor(structural, glass, frame, span, height, paint)
	_upper_storeys(structural, glass, frame, span, height)
	_canopy(structural, frame)
	_commit(structural, mesh, material)
	var glazing := StandardMaterial3D.new()
	glazing.resource_name = "TeaRoomShadedGlazing"
	glazing.vertex_color_use_as_albedo = true
	glazing.roughness = 0.32
	_commit(glass, mesh, glazing)

	var lettering := _surface()
	_sign(lettering, frame, Vector3(0, 3.13, -0.388), Vector2(6.47, 0.76), Rect2(9, 10, 1006, 128))
	_sign(lettering, frame, Vector3(-1.55, 1.51, -0.334), Vector2(0.46, 0.51), Rect2(9, 163, 236, 260))
	_sign(lettering, frame, Vector3(1.99, 1.01, -0.351), Vector2(0.69, 0.28), Rect2(273, 163, 292, 120))
	var ink := StandardMaterial3D.new()
	ink.resource_name = "TeaRoomOriginalLettering"
	ink.albedo_texture = SIGNS
	ink.roughness = 0.79
	ink.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ink.texture_repeat = false
	_commit(lettering, mesh, ink)

	var visual := MeshInstance3D.new()
	visual.name = "HillRoadTeaRoomFrontage"
	visual.mesh = mesh
	body.add_child(visual)


static func _ground_floor(surface: SurfaceTool, glass: SurfaceTool, frame: Transform3D, span: float,
		height: float, paint: Color) -> void:
	# Keep the existing 2.14 m opening clear. Returns sit outside the wall thickness.
	for side: float in [-1.0, 1.0]:
		_piece(surface, frame, Vector3(side * 1.175, 1.315, -0.16), Vector3(0.145, 2.60, 0.27), GREEN)
		_piece(surface, frame, Vector3(side * 1.16, 1.29, -0.308), Vector3(0.050, 2.53, 0.030), GREEN.lightened(0.11))
		_piece(surface, frame, Vector3(side * 3.39, 1.32, -0.167), Vector3(0.22, 2.64, 0.23), STONE, Surfaces.PLASTER)
		_piece(surface, frame, Vector3(side * 3.39, 0.27, -0.191), Vector3(0.25, 0.51, 0.26), STONE.darkened(0.18),
			Surfaces.CONCRETE)
		var run := span * 0.5 - 1.23
		_piece(surface, frame, Vector3(side * (1.23 + run * 0.5), 0.23, -0.11), Vector3(run, 0.46, 0.13),
			STONE.darkened(0.15), Surfaces.CONCRETE)
	_piece(surface, frame, Vector3(0, 2.70, -0.16), Vector3(2.43, 0.15, 0.26), GREEN)
	_piece(surface, frame, Vector3(0, 3.13, -0.25), Vector3(6.58, 0.84, 0.26), GREEN.darkened(0.15))
	_piece(surface, frame, Vector3(0, 3.57, -0.23), Vector3(6.73, 0.08, 0.31), STONE, Surfaces.CONCRETE)
	for x: float in [-3.18, 3.18]:
		_piece(surface, frame, Vector3(x, 3.56, -0.395), Vector3(0.037, 0.037, 0.020), GALVANIZED)

	_display_box(surface, glass, frame, -2.29, 1.43, 1.88, 1.80, true)
	_display_box(surface, glass, frame, 2.29, 1.43, 1.88, 1.80, true)
	_piece(surface, frame, Vector3(-1.55, 1.51, -0.291), Vector3(0.51, 0.56, 0.080), GREEN.darkened(0.14))
	_piece(surface, frame, Vector3(1.99, 1.01, -0.316), Vector3(0.75, 0.33, 0.066), GREEN.darkened(0.15))
	_piece(surface, frame, Vector3(2.62, 0.62, -0.225), Vector3(1.11, 0.075, 0.255), CREAM, Surfaces.CONCRETE)
	_closed_shutter(surface, frame, 5.13)
	_display_box(surface, glass, frame, -5.45, 1.61, 1.65, 1.23, false)

	var pipe_x := -4.06
	_piece(surface, frame, Vector3(pipe_x, height * 0.5, -0.096), Vector3(0.29, height - 0.34, 0.027),
		paint.darkened(0.052), Surfaces.PLASTER)
	_pipe(surface, frame, Vector3(pipe_x, 0.27, -0.202), Vector3(pipe_x, height - 0.20, -0.202), 0.041, STEEL)
	_pipe(surface, frame, Vector3(pipe_x, 0.29, -0.202), Vector3(pipe_x, 0.19, -0.346), 0.041, STEEL)
	for collar_y: float in [1.0, 2.78, 5.8, 8.81]:
		if collar_y < height - 0.2:
			_pipe(surface, frame, Vector3(pipe_x, collar_y - 0.035, -0.202),
				Vector3(pipe_x, collar_y + 0.035, -0.202), 0.051, STEEL.lightened(0.16))
			_piece(surface, frame, Vector3(pipe_x, collar_y, -0.124), Vector3(0.19, 0.040, 0.10), STEEL)


static func _closed_shutter(surface: SurfaceTool, frame: Transform3D, x: float) -> void:
	_piece(surface, frame, Vector3(x, 1.30, -0.115), Vector3(2.32, 2.53, 0.12), STEEL.darkened(0.25))
	for side: float in [-1.0, 1.0]:
		_piece(surface, frame, Vector3(x + side * 1.083, 1.25, -0.258), Vector3(0.105, 2.40, 0.25), STEEL)
		_piece(surface, frame, Vector3(x + side * 1.11, 1.25, -0.392), Vector3(0.028, 2.40, 0.018), GALVANIZED)
	# Alternating fold widths read as rolled steel at street-camera distance.
	for slat in 21:
		var y := 0.17 + float(slat) * 0.102
		var color := GALVANIZED.darkened(0.08 + float((slat * 3) % 5) * 0.009)
		_quad(surface, frame, x, 2.05, y, y + 0.061, -0.289, -0.304, color)
		_quad(surface, frame, x, 2.05, y + 0.061, y + 0.097, -0.304, -0.286, color.darkened(0.26))
	_piece(surface, frame, Vector3(x, 0.143, -0.305), Vector3(2.10, 0.08, 0.050), STEEL)
	_piece(surface, frame, Vector3(x, 2.454, -0.268), Vector3(2.40, 0.28, 0.30), STEEL)
	_piece(surface, frame, Vector3(x, 2.311, -0.316), Vector3(2.39, 0.043, 0.229), GALVANIZED)
	_piece(surface, frame, Vector3(x + 0.33, 0.38, -0.339), Vector3(0.15, 0.05, 0.06), STEEL.darkened(0.21))


static func _display_box(surface: SurfaceTool, glass: SurfaceTool, frame: Transform3D, x: float,
		y: float, width: float, height: float, storefront: bool) -> void:
	var frame_color := GREEN if storefront else CREAM.darkened(0.11)
	var lip := 0.088 if storefront else 0.064
	var outer_z := -0.28 if storefront else -0.227
	var inset_z := -0.112 if storefront else -0.100
	var bottom := y - height * 0.5
	var top := y + height * 0.5
	for side: float in [-1.0, 1.0]:
		_piece(surface, frame, Vector3(x + side * (width - lip) * 0.5, y, lerpf(outer_z, inset_z, 0.43)),
			Vector3(lip, height, absf(outer_z - inset_z) + 0.045), frame_color)
		_piece(surface, frame, Vector3(x, y + side * (height - lip) * 0.5, lerpf(outer_z, inset_z, 0.43)),
			Vector3(width - 2.0 * lip, lip, absf(outer_z - inset_z) + 0.045), frame_color)
	_piece(surface, frame, Vector3(x, bottom - 0.021, outer_z + 0.027), Vector3(width + 0.18, 0.078, 0.39),
		STONE, Surfaces.CONCRETE)
	_piece(surface, frame, Vector3(x, y, outer_z + 0.037), Vector3(lip * 0.60, height - lip, 0.060), frame_color)
	_piece(surface, frame, Vector3(x, y + height * 0.19, outer_z + 0.040),
		Vector3(width - lip, lip * 0.56, 0.058), frame_color)
	var fill := Color("35433d") if storefront else Color("3b4b4a")
	_quad(glass, frame, x, width - lip * 1.5, bottom + lip * 0.75, top - lip * 0.75, inset_z, inset_z, fill)


static func _upper_storeys(surface: SurfaceTool, glass: SurfaceTool, frame: Transform3D, span: float,
		height: float) -> void:
	var bay_count := maxi(1, floori(span / 3.05))
	for storey in range(1, floori(height / 3.05)):
		var floor_y := float(storey) * 3.05
		_piece(surface, frame, Vector3(0, floor_y + 0.62, -0.103), Vector3(span - 0.16, 0.11, 0.16),
			STONE, Surfaces.CONCRETE)
		for bay in bay_count:
			var x := span * ((float(bay) + 0.5) / bay_count - 0.5)
			_display_box(surface, glass, frame, x, floor_y + 1.58, 1.62, 1.48, false)
			if (bay + storey * 2) % 4 == 0:
				var vent := Vector3(x + 0.58, floor_y + 0.72, -0.336)
				_piece(surface, frame, vent, Vector3(0.62, 0.39, 0.29), STEEL.lightened(0.23))
				for slot in 4:
					_piece(surface, frame, vent + Vector3(0.04, -0.11 + slot * 0.064, -0.151),
						Vector3(0.44, 0.026, 0.020), STEEL.darkened(0.31))


static func _canopy(surface: SurfaceTool, frame: Transform3D) -> void:
	var slope := Basis(Vector3.RIGHT, -0.135)
	_piece(surface, frame, Vector3(0, 2.759, -0.734), Vector3(6.64, 0.059, 1.07), STEEL.darkened(0.09),
		Surfaces.PLAIN, slope)
	for rib in 27:
		var center := Vector3(-3.25 + 0.25 * float(rib), 2.796, -0.734)
		_piece(surface, frame, center, Vector3(0.036, 0.030, 1.08), GALVANIZED.darkened(0.16),
			Surfaces.PLAIN, slope)
	_piece(surface, frame, Vector3(0, 2.635, -1.250), Vector3(6.71, 0.089, 0.067), GREEN.darkened(0.21))
	_piece(surface, frame, Vector3(0, 2.683, -1.287), Vector3(6.71, 0.020, 0.017), GALVANIZED)
	for x: float in [-3.17, -1.47, 1.47, 3.17]:
		_rod(surface, frame, Vector3(x, 2.38, -0.158), Vector3(x, 2.638, -1.04), 0.031, STEEL)
		_piece(surface, frame, Vector3(x, 2.451, -0.123), Vector3(0.085, 0.20, 0.045), STEEL)
	_piece(surface, frame, Vector3(0, 2.674, -0.651), Vector3(1.18, 0.044, 0.19), GREEN.darkened(0.14))
	_piece(surface, frame, Vector3(0, 2.647, -0.651), Vector3(1.10, 0.018, 0.14), CREAM)


static func _surface() -> SurfaceTool:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	return surface


static func _commit(surface: SurfaceTool, mesh: ArrayMesh, material: Material) -> void:
	surface.set_material(material)
	surface.generate_normals()
	surface.index()
	surface.commit(mesh)


static func _piece(surface: SurfaceTool, frame: Transform3D, center: Vector3, size: Vector3, color: Color,
		finish: int = Surfaces.PLAIN, basis: Basis = Basis.IDENTITY) -> void:
	Surfaces.add_box(surface, frame * center, size, color, finish, frame.basis * basis)


static func _quad(surface: SurfaceTool, frame: Transform3D, x: float, width: float, bottom: float,
		top: float, bottom_z: float, top_z: float, tint: Color) -> void:
	var a := frame * Vector3(x - width * 0.5, bottom, bottom_z)
	var b := frame * Vector3(x + width * 0.5, bottom, bottom_z)
	var c := frame * Vector3(x + width * 0.5, top, top_z)
	var d := frame * Vector3(x - width * 0.5, top, top_z)
	Surfaces.add_triangle(surface, a, b, c, tint, Surfaces.PLAIN)
	Surfaces.add_triangle(surface, a, c, d, tint, Surfaces.PLAIN)


static func _rod(surface: SurfaceTool, frame: Transform3D, a: Vector3, b: Vector3, width: float,
		color: Color) -> void:
	var axis := (b - a).normalized()
	var cross := Vector3.RIGHT.cross(axis)
	_piece(surface, frame, (a + b) * 0.5, Vector3(width, a.distance_to(b), width), color,
		Surfaces.PLAIN, Basis(Vector3.RIGHT, axis, cross))


static func _pipe(surface: SurfaceTool, frame: Transform3D, a: Vector3, b: Vector3, radius: float,
		color: Color) -> void:
	var v := Vector3.RIGHT.cross((b - a).normalized())
	for side in 8:
		var t1 := float(side) * TAU / 8.0
		var t2 := float(side + 1) * TAU / 8.0
		var p := radius * (cos(t1) * Vector3.RIGHT + sin(t1) * v)
		var q := radius * (cos(t2) * Vector3.RIGHT + sin(t2) * v)
		Surfaces.add_triangle(surface, frame * (a + p), frame * (b + q), frame * (b + p), color, Surfaces.PLAIN)
		Surfaces.add_triangle(surface, frame * (a + p), frame * (a + q), frame * (b + q), color, Surfaces.PLAIN)


static func _sign(surface: SurfaceTool, frame: Transform3D, center: Vector3, size: Vector2, atlas: Rect2) -> void:
	var texel := Vector2(1.0 / 1024.0, 1.0 / 512.0)
	var uv_start := atlas.position * texel
	var uv_end := atlas.end * texel
	var half := size * 0.5
	var corners := PackedVector3Array([Vector3(half.x, half.y, 0.0), Vector3(-half.x, half.y, 0.0),
		Vector3(-half.x, -half.y, 0.0), Vector3(half.x, -half.y, 0.0)])
	var coordinates := PackedVector2Array([uv_start, Vector2(uv_end.x, uv_start.y), uv_end,
		Vector2(uv_start.x, uv_end.y)])
	for index: int in [0, 1, 2, 0, 2, 3]:
		surface.set_uv(coordinates[index])
		surface.add_vertex(frame * (center + corners[index]))
