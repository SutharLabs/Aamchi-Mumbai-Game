extends RefCounted
## Visual-only Bandra frontage details using the existing batched finish material.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const STOREY_HEIGHT := 3.05
const TOWER_HEIGHT := 24.0
const REVEAL := Color("40464a")
const WINDOW_COLORS: Array[Color] = [Color("526c73"), Color("667e80"), Color("3e575e"), Color("776e62")]
const STONE := Color("b3ab96")
const METAL := Color("545b58")


static func add_face(surface: SurfaceTool, start: Vector3, end: Vector3, height: float, paint: Color,
		seed: int, first_storey := 0, wall_depth := 0.0) -> void:
	var span := start.distance_to(end)
	if span < 0.45:
		return
	var tangent := (end - start) / span
	var frame := Transform3D(Basis(tangent, Vector3.UP, tangent.cross(Vector3.UP)), start)
	FacadeFace.new(surface, frame, span, height, paint, seed, wall_depth).draw(first_storey)


static func add_roof(surface: SurfaceTool, polygon: PackedVector2Array, height: float, paint: Color) -> void:
	if height < TOWER_HEIGHT:
		return
	var midpoint := Vector2.ZERO
	for point: Vector2 in polygon:
		midpoint += point
	midpoint /= polygon.size()
	# Find roof space around the vertex mean before placing the visual service bulkhead.
	for offset: Vector2 in [Vector2(-1.8, -1.45), Vector2(1.8, -1.45), Vector2(1.8, 1.45), Vector2(-1.8, 1.45)]:
		if not Geometry2D.is_point_in_polygon(midpoint + offset, polygon):
			return
	var center := Vector3(midpoint.x, height, midpoint.y)
	Surfaces.add_box(surface, center + Vector3.UP * 1.07, Vector3(3.55, 2.14, 2.82), paint.lightened(0.10), Surfaces.PLASTER)
	Surfaces.add_box(surface, center + Vector3.UP * 2.17, Vector3(3.68, 0.16, 2.95), STONE, Surfaces.CONCRETE)
	Surfaces.add_box(surface, center + Vector3(-1.24, 2.48, 0.25), Vector3(0.58, 0.48, 0.74), METAL)


class FacadeFace:
	var _surface: SurfaceTool
	var _frame: Transform3D
	var _span: float
	var _height: float
	var _paint: Color
	var _seed: int
	var _depth: float
	var _trim: Color
	var _tower: bool

	func _init(surface: SurfaceTool, frame: Transform3D, span: float, height: float, paint: Color,
			seed: int, depth: float) -> void:
		_surface = surface
		_frame = frame
		_span = span
		_height = height
		_paint = paint
		_seed = seed
		_depth = depth
		_trim = paint.lerp(STONE, 0.58).lightened(0.22)
		_tower = height >= TOWER_HEIGHT

	func draw(first_storey: int) -> void:
		var storeys := maxi(1, floori(_height / STOREY_HEIGHT + 0.001))
		var edge := minf(0.20, _span * 0.12)
		if first_storey == 0:
			_projection(Rect2(edge, 0.08, _span - edge * 2.0, 0.51), 0.022, 0.10,
				_paint.darkened(0.27), Surfaces.CONCRETE)
		var crown_height := 0.44 if _tower else 0.16
		_projection(Rect2(edge, _height - crown_height, _span - edge * 2.0, crown_height + 0.06),
			0.013, 0.22, _trim, Surfaces.CONCRETE)
		if _span < 2.25:
			return

		var bays := maxi(1, floori(_span / STOREY_HEIGHT))
		var bay_width := _span / bays
		var style := posmod(_seed, 3)
		if _tower and _span > 5.0:
			_tower_structure(edge, style)
		for level in range(first_storey, storeys):
			var floor_y := float(level) * STOREY_HEIGHT
			for bay in bays:
				var center := (float(bay) + 0.5) * bay_width
				if _tower and level >= 2 and _span > 5.5 and (bay + style) % 3 != 2:
					_balcony(center, floor_y, bay_width, level, bay, style)
				else:
					_window(center, floor_y, bay_width, level, bay)

	func _tower_structure(edge: float, style: int) -> void:
		_panel(Rect2(edge, 0.02, _span - edge * 2.0, 5.85), 0.009,
			_paint.lerp(Color("716d65"), 0.42), Surfaces.CONCRETE)
		_projection(Rect2(edge, 5.88, _span - edge * 2.0, 0.30), 0.01, 0.35, _trim, Surfaces.CONCRETE)
		_projection(Rect2(edge, _height - 0.34, _span - edge * 2.0, 0.36), 0.24, 0.39, _trim, Surfaces.CONCRETE)
		if style == 0:
			for position in [_span * 0.09, _span * 0.91]:
				_projection(Rect2(float(position) - 0.18, 6.11, 0.36, _height - 6.49),
					0.03, 0.52, _trim, Surfaces.PLASTER)
		else:
			var position := _span * (0.74 if style == 2 else 0.34)
			var rib := 0.60 if style == 2 else 0.46
			_projection(Rect2(position - rib * 0.5, 6.22, rib, _height - 6.57),
				0.03, 0.53, _paint.lerp(Color("6c5c44"), 0.51), Surfaces.PLASTER)
		var vents := maxi(1, floori(_span / 3.6))
		for vent in vents:
			var center := (float(vent) + 0.5) * _span / vents
			_panel(Rect2(center - 0.62, 5.18, 1.24, 0.29), 0.013, METAL)
			_panel(Rect2(center - 0.57, 5.32, 1.14, 0.07), 0.017, _trim.darkened(0.12))

	func _balcony(center: float, floor_y: float, bay_width: float, level: int, bay: int, style: int) -> void:
		var width := bay_width * (0.83 if style == 0 else 0.77)
		var left := center - width * 0.5
		var projection := 0.78 if style == 0 else 0.65
		_panel(Rect2(left, floor_y + 0.38, width, 2.34), 0.016, REVEAL)
		var glazing := WINDOW_COLORS[posmod(_seed + level * 7 + bay * 3, WINDOW_COLORS.size())]
		_panel(Rect2(left + 0.10, floor_y + 0.61, width - 0.20, 1.92), 0.021, glazing)
		_panel(Rect2(center - 0.033, floor_y + 0.68, 0.066, 1.79), 0.025, METAL)
		_projection(Rect2(left - 0.055, floor_y + 0.39, width + 0.11, 0.20),
			0.012, projection, _trim, Surfaces.CONCRETE)
		_projection(Rect2(left, floor_y + 0.59, width, 0.58),
			projection - 0.10, projection - 0.015, glazing.darkened(0.17))
		_panel(Rect2(left, floor_y + 1.14, width, 0.052), projection - 0.009, _trim)
		_panel(Rect2(center - 0.027, floor_y + 0.61, 0.054, 0.52), projection - 0.007, METAL)

	func _window(center: float, floor_y: float, bay_width: float, level: int, bay: int) -> void:
		var width := bay_width * 0.69
		var left := center - width * 0.5
		var glazing := WINDOW_COLORS[posmod(_seed + level * 5 + bay * 3, WINDOW_COLORS.size())]
		_panel(Rect2(left, floor_y + 0.77, width, 1.69), 0.026, _trim)
		_panel(Rect2(left + 0.065, floor_y + 0.844, width - 0.13, 1.54), 0.032, REVEAL)
		_panel(Rect2(left + 0.11, floor_y + 0.90, width - 0.22, 1.42), 0.036, glazing)
		_panel(Rect2(center - 0.027, floor_y + 0.90, 0.054, 1.42), 0.040, _trim.darkened(0.09))
		_panel(Rect2(left + 0.11, floor_y + 1.91, width - 0.22, 0.053), 0.040, _trim.darkened(0.09))
		_projection(Rect2(left - 0.035, floor_y + 0.72, width + 0.07, 0.104),
			0.019, 0.15, _trim, Surfaces.CONCRETE)
		if level > 0 and level < 4 and posmod(_seed + bay * 5 + level * 2, 7) == 0 and width > 0.95:
			var cabinet := Rect2(left + 0.11, floor_y + 0.32, 0.46, 0.34)
			_projection(cabinet, 0.02, 0.27, _trim.darkened(0.13))
			_panel(Rect2(cabinet.position + Vector2(0.10, 0.075), Vector2(0.26, 0.19)), 0.275, METAL)

	func _panel(rect: Rect2, depth: float, color: Color, finish := Surfaces.PLAIN) -> void:
		var z := -(_depth + depth)
		_quad(Vector3(rect.position.x, rect.position.y, z), Vector3(rect.end.x, rect.position.y, z),
			Vector3(rect.end.x, rect.end.y, z), Vector3(rect.position.x, rect.end.y, z), color, finish)

	func _projection(rect: Rect2, back: float, front: float, color: Color, finish := Surfaces.PLAIN) -> void:
		var front_z := -(_depth + front)
		var back_z := -(_depth + back)
		var a := Vector3(rect.position.x, rect.position.y, front_z)
		var b := Vector3(rect.end.x, rect.position.y, front_z)
		var c := Vector3(rect.end.x, rect.end.y, front_z)
		var d := Vector3(rect.position.x, rect.end.y, front_z)
		var e := Vector3(rect.position.x, rect.position.y, back_z)
		var f := Vector3(rect.end.x, rect.position.y, back_z)
		var g := Vector3(rect.end.x, rect.end.y, back_z)
		var h := Vector3(rect.position.x, rect.end.y, back_z)
		# Model exposed faces only. The back faces the existing solid wall.
		_quad(a, b, c, d, color, finish)
		_quad(b, f, g, c, color, finish)
		_quad(e, a, d, h, color, finish)
		_quad(e, f, b, a, color, finish)
		_quad(d, c, g, h, color, finish)

	func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, finish: int) -> void:
		Surfaces.add_triangle(_surface, _frame * a, _frame * b, _frame * c, color, finish)
		Surfaces.add_triangle(_surface, _frame * a, _frame * c, _frame * d, color, finish)
