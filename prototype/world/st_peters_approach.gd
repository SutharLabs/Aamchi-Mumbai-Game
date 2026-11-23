extends RefCounted
## Original Romanesque landmark study. The front faces local -Z.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")

const STONE := Color("b49c77")
const TRIM := Color("daceaa")
const SHADOW := Color("887457")
const TIMBER := Color("58463b")
const GLASS := Color("3a4e54")
const TILE := Color("735548")
const PAVING := Color("a5a098")
const LEAF := Color("526345")
const PORTAL_Z := -0.28


static func create(material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "StPetersChurch"
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	_build_church(surface)
	_build_facade(surface)
	_build_forecourt(surface)
	surface.generate_normals()
	surface.index()
	var visible := MeshInstance3D.new()
	visible.name = "StPetersExterior"
	visible.mesh = surface.commit()
	visible.material_override = material
	body.add_child(visible)
	_collider(body, Vector3(0, 6, 12.7), Vector3(23.6, 12, 25.8))
	_collider(body, Vector3(0, 0.24, -1.45), Vector3(19.2, 0.48, 2.43))
	_collider(body, Vector3(0, 0.12, -2.89), Vector3(19.6, 0.24, 0.45))
	for side: float in [-1.0, 1.0]:
		_collider(body, Vector3(side * 9.58, 6.8, 1.05), Vector3(5.02, 13.6, 3.75))
		_collider(body, Vector3(side * 7.3, 3.2, -3.58), Vector3(0.45, 6.1, 0.45))
	return body


static func _build_church(surface: SurfaceTool) -> void:
	_box(surface, Vector3(0, 5.8, 12.8), Vector3(23.4, 11.6, 25.6), STONE)
	_box(surface, Vector3(0, 0.42, 12.9), Vector3(23.6, 0.84, 25.8), SHADOW)
	_box(surface, Vector3(0, 11.42, 12.8), Vector3(23.7, 0.43, 25.9), TRIM)
	var front := -0.12
	var back := 25.78
	var left := Vector3(-12.0, 11.7, front)
	var right := Vector3(12.0, 11.7, front)
	var ridge := Vector3(0, 15.45, front)
	var length := Vector3(0, 0, back - front)
	_quad(surface, left, ridge, ridge + length, left + length, TILE)
	_quad(surface, ridge, right, right + length, ridge + length, TILE.darkened(0.08))
	_triangle(surface, left, right, ridge, STONE)
	_triangle(surface, right + length, left + length, ridge + length, STONE.darkened(0.08))
	_cross(surface, Vector3(0, 16.30, 0.08), 1.64, TRIM.lightened(0.08))
	for side: float in [-1.0, 1.0]:
		for z: float in [6.5, 12.0, 17.5, 23.0]:
			_side_window(surface, side, z)
		_build_tower(surface, side * 9.58)


static func _build_tower(surface: SurfaceTool, x: float) -> void:
	var center := Vector3(x, 0, 1.7)
	_column(surface, center, 2.56, 0.55, 1.1, SHADOW, 8)
	_column(surface, center, 2.44, 6.92, 12.79, STONE, 8)
	_column(surface, center, 2.53, 13.80, 2.83, TRIM, 8)
	_column(surface, center, 2.88, 15.28, 0.52, TRIM, 8)
	_column(surface, center, 2.65, 15.62, 0.38, SHADOW, 8)
	_dome(surface, Vector3(x, 15.81, center.z), 2.50, 1.64, TRIM)
	var front := center.z - 2.29
	_arch_fill(surface, x, 1.72, 12.55, 0.61, front - 0.07, TRIM)
	_arch_fill(surface, x, 1.91, 12.49, 0.37, front - 0.10, GLASS)
	for row in range(15):
		var y := 2.22 + float(row) * 0.70
		_box(surface, Vector3(x, y, front - 0.11), Vector3(0.71, 0.057, 0.035), TRIM.darkened(0.15))
	for side: float in [-1.0, 1.0]:
		_box(surface, Vector3(x + side * 1.15, 13.82, front + 0.2), Vector3(0.49, 1.62, 0.34), GLASS)


static func _build_facade(surface: SurfaceTool) -> void:
	for row in range(1, 12):
		var y := 0.72 + float(row) * 0.83
		_box(surface, Vector3(0, y, -0.028), Vector3(18.7, 0.026, 0.035), STONE.darkened(0.08))
	_arch_fill(surface, 0.0, 0.53, 4.51, 6.70, PORTAL_Z, SHADOW)
	_arch_band(surface, 0.0, 0.53, 4.51, 6.18, 6.77, PORTAL_Z - 0.15, TRIM)
	_arch_band(surface, 0.0, 0.53, 4.51, 5.76, 6.04, PORTAL_Z - 0.19, STONE.lightened(0.09))
	_arch_fill(surface, 0.0, 0.64, 5.18, 3.92, PORTAL_Z - 0.24, GLASS)
	_arch_band(surface, 0.0, 0.64, 5.18, 3.92, 4.21, PORTAL_Z - 0.30, TRIM)
	_box(surface, Vector3(0, 2.29, PORTAL_Z - 0.38), Vector3(6.33, 3.39, 0.24), TIMBER)
	_box(surface, Vector3(0, 2.29, PORTAL_Z - 0.51), Vector3(0.12, 3.25, 0.04), SHADOW)
	_box(surface, Vector3(0, 4.12, PORTAL_Z - 0.38), Vector3(7.25, 0.34, 0.40), TRIM)
	for side: float in [-1.0, 1.0]:
		_arch_fill(surface, side * 4.97, 0.63, 3.36, 0.82, PORTAL_Z - 0.22, TIMBER)
		_arch_band(surface, side * 4.97, 0.63, 3.36, 0.82, 1.06, PORTAL_Z - 0.28, TRIM)
		_arch_fill(surface, side * 4.92, 11.15, 12.43, 0.59, -0.17, GLASS)
		_arch_band(surface, side * 4.92, 11.15, 12.43, 0.59, 0.74, -0.21, TRIM)
	_box(surface, Vector3(0, 10.89, -0.28), Vector3(18.7, 0.46, 0.48), TRIM)
	_box(surface, Vector3(0, 11.18, -0.25), Vector3(19.1, 0.13, 0.32), SHADOW)
	_disk(surface, Vector3(0, 12.58, -0.16), 1.52, TRIM)
	_disk(surface, Vector3(0, 12.58, -0.19), 1.27, SHADOW)
	_disk(surface, Vector3(0, 12.58, -0.21), 1.10, STONE)
	_cross(surface, Vector3(0, 12.58, -0.23), 1.13, TRIM)
	for side: float in [-1.0, 1.0]:
		for index in range(7):
			var distance := 0.79 + 1.02 * float(index)
			var y := 15.41 - 0.312 * distance
			_box(surface, Vector3(side * distance, y, -0.15), Vector3(0.82, 0.23, 0.28), TRIM)


static func _build_forecourt(surface: SurfaceTool) -> void:
	_box(surface, Vector3(0, 0.02, -2.40), Vector3(24.9, 0.06, 4.8), PAVING)
	_box(surface, Vector3(0, 0.24, -1.45), Vector3(19.2, 0.48, 2.43), TRIM)
	_box(surface, Vector3(0, 0.12, -2.89), Vector3(19.6, 0.24, 0.45), PAVING)
	_box(surface, Vector3(0, 0.05, -3.84), Vector3(3.7, 0.012, 1.72), PAVING.lightened(0.16))
	for side: float in [-1.0, 1.0]:
		var x := side * 7.3
		_box(surface, Vector3(x, 0.11, -3.58), Vector3(1.85, 0.21, 1.75), SHADOW)
		_palm(surface, Vector3(x, 0.22, -3.58), 8.7 if side < 0.0 else 9.4)


static func _palm(surface: SurfaceTool, start: Vector3, height: float) -> void:
	var crown := start + Vector3.UP * height
	_column(surface, start, 0.22, height * 0.5, height, SHADOW, 7)
	for index in range(9):
		var angle := float(index) * TAU / 9.0
		var along := Vector3(cos(angle), 0, sin(angle))
		var across := Vector3(-along.z, 0, along.x)
		var shoulder := crown + along * 1.12 + Vector3.UP * 0.38
		var middle := crown + along * 2.11 - Vector3.UP * 0.08
		var tip := crown + along * 2.82 - Vector3.UP * 1.58
		var color := LEAF.lightened(0.12 * float(index % 2))
		_quad(surface, crown, shoulder + across * 0.53, middle + across * 0.48, middle, color)
		_quad(surface, crown, middle, middle - across * 0.48, shoulder - across * 0.53, color.darkened(0.15))
		_triangle(surface, middle + across * 0.48, tip, middle - across * 0.48, color)


static func _side_window(surface: SurfaceTool, side: float, z: float) -> void:
	_box(surface, Vector3(side * 11.72, 7.68, z), Vector3(0.17, 3.38, 1.75), TRIM)
	_box(surface, Vector3(side * 11.83, 7.68, z), Vector3(0.06, 3.00, 1.32), GLASS)
	_box(surface, Vector3(side * 11.87, 7.68, z), Vector3(0.045, 2.99, 0.115), TRIM.darkened(0.16))
	_box(surface, Vector3(side * 11.89, 6.05, z), Vector3(0.22, 0.16, 1.84), TRIM)


static func _cross(surface: SurfaceTool, at: Vector3, height: float, color: Color) -> void:
	_box(surface, at, Vector3(height * 0.14, height, 0.17), color)
	_box(surface, at + Vector3.UP * height * 0.14, Vector3(height * 0.65, height * 0.14, 0.23), color)


static func _arch_fill(surface: SurfaceTool, x: float, base: float, spring: float, radius: float, z: float, color: Color) -> void:
	var center := Vector3(x, spring, z)
	_quad(surface, Vector3(x - radius, base, z), Vector3(x + radius, base, z),
		Vector3(x + radius, spring, z), Vector3(x - radius, spring, z), color)
	for step in range(14):
		_triangle(surface, center, _arc(center, radius, step), _arc(center, radius, step + 1), color)


static func _arch_band(surface: SurfaceTool, x: float, base: float, spring: float, inner: float, outer: float, z: float, color: Color) -> void:
	var center := Vector3(x, spring, z)
	for step in range(14):
		_quad(surface, _arc(center, inner, step), _arc(center, outer, step),
			_arc(center, outer, step + 1), _arc(center, inner, step + 1),
			color.darkened(0.08) if step % 3 == 0 else color)
	for side: float in [-1.0, 1.0]:
		var offset := side * (inner + outer) * 0.5
		_box(surface, Vector3(x + offset, (spring + base) * 0.5, z + 0.055),
			Vector3(outer - inner, spring - base, 0.11), color)


static func _arc(center: Vector3, radius: float, step: int) -> Vector3:
	var angle := PI * float(step) / 14.0
	return center + Vector3(cos(angle) * radius, sin(angle) * radius, 0)


static func _disk(surface: SurfaceTool, center: Vector3, radius: float, color: Color) -> void:
	for step in range(20):
		var a := TAU * float(step) / 20.0
		var b := TAU * float(step + 1) / 20.0
		_triangle(surface, center, center + Vector3(cos(a), sin(a), 0) * radius,
			center + Vector3(cos(b), sin(b), 0) * radius, color)


static func _column(surface: SurfaceTool, center: Vector3, radius: float, y: float, height: float, color: Color, sides: int) -> void:
	var bottom := center + Vector3.UP * (y - height * 0.5)
	var top := bottom + Vector3.UP * height
	for step in range(sides):
		var a := _ring_offset(radius, sides, step)
		var b := _ring_offset(radius, sides, step + 1)
		_quad(surface, bottom + a, bottom + b, top + b, top + a, color)
		_triangle(surface, top, top + a, top + b, color)


static func _dome(surface: SurfaceTool, base: Vector3, radius: float, height: float, color: Color) -> void:
	for band in range(4):
		var lower := float(band) * PI / 8.0
		var upper := float(band + 1) * PI / 8.0
		var bottom := base + Vector3.UP * height * sin(lower)
		var top := base + Vector3.UP * height * sin(upper)
		for step in range(16):
			var a := bottom + _ring_offset(radius * cos(lower), 16, step)
			var b := bottom + _ring_offset(radius * cos(lower), 16, step + 1)
			var c := top + _ring_offset(radius * cos(upper), 16, step + 1)
			var d := top + _ring_offset(radius * cos(upper), 16, step)
			if band == 3:
				_triangle(surface, a, b, top, color)
			else:
				_quad(surface, a, b, c, d, color)


static func _ring_offset(radius: float, sides: int, step: int) -> Vector3:
	var angle := TAU * (float(step) + 0.5) / float(sides)
	return Vector3(cos(angle) * radius, 0, sin(angle) * radius)


static func _collider(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.position = at
	collider.shape = shape
	body.add_child(collider)


static func _box(surface: SurfaceTool, center: Vector3, size: Vector3, color: Color) -> void:
	var low := center - size * 0.5
	var high := center + size * 0.5
	var a := low
	var b := Vector3(high.x, low.y, low.z)
	var c := Vector3(high.x, high.y, low.z)
	var d := Vector3(low.x, high.y, low.z)
	var e := Vector3(low.x, low.y, high.z)
	var f := Vector3(high.x, low.y, high.z)
	var g := high
	var h := Vector3(low.x, high.y, high.z)
	_quad(surface, a, b, c, d, color)
	_quad(surface, f, e, h, g, color)
	_quad(surface, b, f, g, c, color)
	_quad(surface, e, a, d, h, color)
	_quad(surface, e, f, b, a, color)
	_quad(surface, d, c, g, h, color)


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	_triangle(surface, a, b, c, color)
	_triangle(surface, a, c, d, color)


static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var finish := Surfaces.PLAIN
	if color == STONE or color == SHADOW:
		finish = Surfaces.PLASTER
	elif color == PAVING:
		finish = Surfaces.CONCRETE
	elif color == TILE:
		finish = Surfaces.CLAY
	elif color == TIMBER:
		finish = Surfaces.TIMBER
	Surfaces.add_triangle(surface, a, b, c, color, finish)
