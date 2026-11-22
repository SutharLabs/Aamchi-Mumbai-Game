extends RefCounted
## Original Ranwar-inspired frontage kit. Each lot batches its parts into one opaque surface.

const PLINTH := Color("777068")
const TIMBER := Color("5b4235")
const WINDOW := Color("354b56")
const REFLECTION := Color("66858a")
const TRIM := Color("e3d5b5")
const SHUTTER := Color("7d8784")
const TILE := Color("a4553d")
const FASCIA := Color("684138")
const PORCH_CENTER := Vector3(0, 0.16, -6.60)
const PORCH_DEPTH := 1.24
const STEP_CENTER := Vector3(0, 0.08, -7.28)
const STEP_SIZE := Vector3(2.55, 0.16, 0.24)
const POST_BASE_X := 1.47
const POST_Z := -7.18
const SIGN_COLORS: Array[Color] = [Color("25676c"), Color("8a6330"), Color("345c83")]


static func create(height: float, wall_color: Color, storefront: bool, variant: int, material: Material, photo_gallery: bool = false) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	_box(surface, Vector3(0, height * 0.5, 0), Vector3(13, height, 12), wall_color)
	_box(surface, Vector3(0, 0.27, 0), Vector3(13.08, 0.54, 12.08), PLINTH)
	var frontage_name := "RanwarShopfront" if storefront else "RanwarVerandah"
	if storefront:
		_shop(surface, height, variant)
	elif photo_gallery:
		_timber_gallery(surface, height, variant, wall_color)
		frontage_name = "RanwarTimberGallery"
	else:
		_verandah(surface, height, variant)
	_side_windows(surface, minf(3.85, height - 1.1))
	surface.generate_normals()
	surface.index()
	var instance := MeshInstance3D.new()
	instance.name = frontage_name
	instance.mesh = surface.commit()
	instance.material_override = material
	return instance


static func add_verandah_collisions(body: StaticBody3D, frontage: Transform3D, variant: int, photo_gallery: bool = false) -> void:
	var half_width := _porch_half_width(variant)
	_collide_box(body, frontage, PORCH_CENTER, Vector3(half_width * 2.0, 0.32, PORCH_DEPTH))
	_collide_box(body, frontage, STEP_CENTER, STEP_SIZE)
	for x: float in [-half_width, -POST_BASE_X, POST_BASE_X, half_width]:
		_collide_box(body, frontage, Vector3(x, 1.60, POST_Z), Vector3(0.15, 2.60, 0.16))
	for side: float in [-1.0, 1.0]:
		var span := half_width - POST_BASE_X
		var center := Vector3(side * (POST_BASE_X + span * 0.5), 0.68, POST_Z)
		_collide_box(body, frontage, center, Vector3(span, 0.80, 0.10))
	if photo_gallery:
		for x: float in [-POST_BASE_X, -half_width]:
			_collide_box(body, frontage, Vector3(x, 0.75, -6.59), Vector3(0.14, 0.86, 1.13))


static func _collide_box(body: StaticBody3D, frontage: Transform3D, at: Vector3, size: Vector3) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var collision := CollisionShape3D.new()
	collision.name = "VerandahCollision"
	collision.transform = frontage * Transform3D(Basis.IDENTITY, at)
	collision.shape = box
	body.add_child(collision)


static func _porch_half_width(variant: int) -> float:
	return 5.6 if variant % 2 == 0 else 4.95


static func _shop(surface: SurfaceTool, height: float, variant: int) -> void:
	var sign_color := SIGN_COLORS[variant % SIGN_COLORS.size()]
	_box(surface, Vector3(0, 3.12, -6.09), Vector3(11.8, 0.74, 0.18), sign_color)
	_box(surface, Vector3(0, 1.46, -6.05), Vector3(10.6, 2.74, 0.12), TRIM)
	_box(surface, Vector3(0, 1.47, -6.13), Vector3(10.1, 2.52, 0.08), SHUTTER)
	for index in range(7):
		var line_y := 0.5 + float(index) * 0.31
		_quad(surface, Vector3(-4.99, line_y, -6.176), Vector3(4.99, line_y, -6.176),
			Vector3(4.99, line_y + 0.023, -6.176), Vector3(-4.99, line_y + 0.023, -6.176), SHUTTER.darkened(0.24))
	_box(surface, Vector3(-3.9, 1.43, -6.20), Vector3(1.45, 2.38, 0.08), WINDOW)
	_box(surface, Vector3(-3.9, 1.91, -6.25), Vector3(1.25, 1.08, 0.02), REFLECTION)
	_canopy(surface, 5.92, 2.85, 1.17, sign_color)
	for x: float in [-4.1, 0.0, 4.1]:
		_window(surface, x, 4.52, false)
	if height > 8.0:
		if height > 9.0:
			for x: float in [-4.1, 0.0, 4.1]:
				_window(surface, x, height - 2.04, false)
		_box(surface, Vector3(0, height + 0.2, 0), Vector3(13.35, 0.4, 12.35), sign_color.lerp(TRIM, 0.35))
		_box(surface, Vector3(-3.65, height - 2.95, -6.20), Vector3(1.08, 0.55, 0.42), PLINTH.lightened(0.21))
	else:
		_tiled_roof(surface, height, 1.65, variant)


static func _verandah(surface: SurfaceTool, height: float, variant: int) -> void:
	var porch_width := _porch_half_width(variant)
	_tiled_roof(surface, height, 1.92, variant)
	_box(surface, PORCH_CENTER, Vector3(porch_width * 2.0, 0.32, PORCH_DEPTH), PLINTH)
	_box(surface, STEP_CENTER, STEP_SIZE, PLINTH.lightened(0.10))
	_box(surface, Vector3(0, 1.62, -6.06), Vector3(1.64, 2.34, 0.14), TRIM)
	_box(surface, Vector3(0, 1.58, -6.17), Vector3(1.37, 2.12, 0.16), TIMBER)
	_box(surface, Vector3(0, 2.12, -6.28), Vector3(1.18, 0.74, 0.08), WINDOW)
	_canopy(surface, porch_width + 0.25, 3.06, 1.40, TILE)
	for x: float in [-porch_width, -POST_BASE_X, POST_BASE_X, porch_width]:
		_box(surface, Vector3(x, 1.60, POST_Z), Vector3(0.15, 2.60, 0.16), TIMBER)
		_box(surface, Vector3(x, 0.42, POST_Z), Vector3(0.25, 0.20, 0.27), PLINTH.lightened(0.13))
	_verandah_rail(surface, porch_width, TIMBER)
	for side: float in [-1.0, 1.0]:
		_window(surface, side * 3.52, 1.89, true)
		_window(surface, side * 3.40, maxf(4.33, height * 0.68), true)
	if variant % 2 == 0:
		_box(surface, Vector3(0, 3.52, -6.34), Vector3(9.1, 0.16, 0.67), PLINTH)
		_box(surface, Vector3(0, 4.03, -6.63), Vector3(9.1, 0.08, 0.13), TIMBER)
		_window(surface, 0.0, maxf(4.43, height * 0.68), false)
		for index in range(9):
			_box(surface, Vector3(float(index - 4), 3.80, -6.63), Vector3(0.11, 0.45, 0.12), TIMBER)


static func _timber_gallery(surface: SurfaceTool, height: float, variant: int, wall_color: Color) -> void:
	# The Chapel Road reference shows a timber upper gallery and an exposed return stair.
	var half_width := _porch_half_width(variant)
	var gallery_floor := 3.48
	var gallery_top := height - 0.17
	var gallery_width := (half_width + 0.20) * 2.0
	var wood := TIMBER.darkened(0.10)
	_tiled_roof(surface, height, 1.90, variant)
	_box(surface, PORCH_CENTER, Vector3(half_width * 2.0, 0.32, PORCH_DEPTH), PLINTH)
	_box(surface, STEP_CENTER, STEP_SIZE, PLINTH.lightened(0.10))
	_box(surface, Vector3(2.8, 1.55, -6.06), Vector3(1.56, 2.13, 0.14), TRIM)
	_box(surface, Vector3(2.8, 1.51, -6.16), Vector3(1.31, 1.96, 0.08), Color("698274"))
	_window(surface, 0.0, 1.88, true)
	_box(surface, Vector3(0, gallery_floor - 0.13, -6.61), Vector3(gallery_width, 0.26, 1.37), wood)
	_box(surface, Vector3(0, gallery_top, -6.61), Vector3(gallery_width, 0.21, 1.34), wood)
	_box(surface, Vector3(0, (gallery_floor + gallery_top) * 0.5, -6.16),
		Vector3(gallery_width, gallery_top - gallery_floor, 0.13), wall_color.darkened(0.42))
	_timber_gallery_panels(surface, half_width, gallery_floor, gallery_top, wood)
	_canopy(surface, half_width + 0.32, gallery_top + 0.06, 1.53, TILE.darkened(0.13))
	for x: float in [-half_width, -POST_BASE_X, POST_BASE_X, half_width]:
		_box(surface, Vector3(x, (gallery_floor + 0.28) * 0.5, POST_Z),
			Vector3(0.17, gallery_floor - 0.28, 0.19), wood)
	_stair_flight(surface, Vector2(-half_width + 2.62, 0.33), Vector2(-half_width + 0.42, 1.33), wood, 5)
	_box(surface, Vector3(-half_width + 0.32, 1.31, -6.61), Vector3(0.58, 0.13, 1.05), wood)
	_stair_flight(surface, Vector2(-half_width + 0.42, 1.33), Vector2(-1.66, gallery_floor), wood, 9)
	_verandah_rail(surface, half_width, wood)
	for x: float in [-POST_BASE_X, -half_width]:
		_box(surface, Vector3(x, 1.05, -6.59), Vector3(0.12, 0.10, 1.15), wood)
		for index in range(4):
			_box(surface, Vector3(x, 0.69, -6.23 - float(index) * 0.24), Vector3(0.08, 0.62, 0.08), wood)


static func _timber_gallery_panels(surface: SurfaceTool, half_width: float, low: float, high: float, wood: Color) -> void:
	var sill := low + 0.38
	var head := high - 0.28
	var metal := Color("b2b193")
	_box(surface, Vector3(0, sill - 0.07, -7.21), Vector3(half_width * 2.0, 0.14, 0.14), wood)
	_box(surface, Vector3(0, head + 0.07, -7.21), Vector3(half_width * 2.0, 0.14, 0.14), wood)
	var panel_width := half_width * 2.0 / 6.0
	for bay in range(7):
		var edge := -half_width + float(bay) * panel_width
		_box(surface, Vector3(edge, (low + high) * 0.5, -7.21), Vector3(0.13, high - low, 0.15), wood)
		if bay == 6:
			continue
		for bar in range(3):
			var x := edge + float(bar + 1) * panel_width * 0.25
			_box(surface, Vector3(x, (sill + head) * 0.5, -7.20), Vector3(0.034, head - sill, 0.040), metal)
		var center := Vector2(edge + panel_width * 0.5, (sill + head) * 0.5)
		var left := center + Vector2(-panel_width * 0.34, 0)
		var right := center + Vector2(panel_width * 0.34, 0)
		var top := center + Vector2(0, (head - sill) * 0.33)
		var bottom := center + Vector2(0, -(head - sill) * 0.33)
		_raked_strip(surface, left, top, -7.23, 0.048, metal)
		_raked_strip(surface, top, right, -7.23, 0.048, metal)
		_raked_strip(surface, right, bottom, -7.23, 0.048, metal)
		_raked_strip(surface, bottom, left, -7.23, 0.048, metal)


static func _stair_flight(surface: SurfaceTool, first: Vector2, last: Vector2, wood: Color, steps: int) -> void:
	var step := (last - first) / float(steps)
	for index in range(steps):
		var position := first + step * float(index)
		_box(surface, Vector3(position.x + step.x * 0.5, position.y + step.y - 0.04, -6.65),
			Vector3(absf(step.x) + 0.045, 0.08, 0.76), wood.lightened(0.12))
	_raked_strip(surface, first, last, -7.06, 0.20, wood)
	_raked_strip(surface, first + Vector2(0, 0.77), last + Vector2(0, 0.77), -7.07, 0.085, wood)
	for index in range(3):
		var position := first.lerp(last, float(index) / 2.0)
		_box(surface, Vector3(position.x, position.y + 0.38, -7.08), Vector3(0.065, 0.76, 0.075), wood)


static func _raked_strip(surface: SurfaceTool, first: Vector2, last: Vector2, z: float, width: float, color: Color) -> void:
	var start := first if first.x < last.x else last
	var end := last if first.x < last.x else first
	var run := end - start
	var offset := Vector2(-run.y, run.x).normalized() * (width * 0.5)
	_quad(surface, Vector3(start.x - offset.x, start.y - offset.y, z),
		Vector3(end.x - offset.x, end.y - offset.y, z),
		Vector3(end.x + offset.x, end.y + offset.y, z),
		Vector3(start.x + offset.x, start.y + offset.y, z), color)


static func _verandah_rail(surface: SurfaceTool, half_width: float, wood: Color) -> void:
	for side: float in [-1.0, 1.0]:
		var span := half_width - POST_BASE_X
		_box(surface, Vector3(side * (POST_BASE_X + span * 0.5), 1.05, POST_Z), Vector3(span, 0.08, 0.1), wood)
		for index in range(1, 6):
			var post_x := side * (POST_BASE_X + span * float(index) / 6.0)
			_box(surface, Vector3(post_x, 0.74, POST_Z), Vector3(0.07, 0.52, 0.08), wood)


static func _window(surface: SurfaceTool, x: float, y: float, shuttered: bool) -> void:
	_box(surface, Vector3(x, y, -6.05), Vector3(1.57, 1.52, 0.12), TRIM)
	_box(surface, Vector3(x, y, -6.14), Vector3(1.31, 1.25, 0.06), WINDOW)
	_box(surface, Vector3(x, y + 0.26, -6.18), Vector3(1.22, 0.52, 0.02), REFLECTION)
	_box(surface, Vector3(x, y, -6.19), Vector3(0.055, 1.25, 0.08), TRIM)
	_box(surface, Vector3(x, y - 0.72, -6.17), Vector3(1.74, 0.17, 0.29), TRIM.darkened(0.14))
	if shuttered:
		_box(surface, Vector3(x - 0.89, y, -6.105), Vector3(0.32, 1.30, 0.11), Color("627a68"))
		_box(surface, Vector3(x + 0.89, y, -6.105), Vector3(0.32, 1.30, 0.11), Color("627a68"))


static func _side_windows(surface: SurfaceTool, y: float) -> void:
	for side: float in [-1.0, 1.0]:
		_box(surface, Vector3(side * 6.53, y, 1.2), Vector3(0.10, 1.32, 1.34), TRIM)
		_box(surface, Vector3(side * 6.59, y, 1.2), Vector3(0.04, 1.08, 1.08), WINDOW)
		_box(surface, Vector3(side * 6.62, y + 0.24, 1.2), Vector3(0.025, 0.44, 1.0), REFLECTION)
		_box(surface, Vector3(side * 6.63, y, 1.2), Vector3(0.03, 1.08, 0.055), TRIM)


static func _canopy(surface: SurfaceTool, half_width: float, y: float, projection: float, color: Color) -> void:
	var front := -6.0 - projection
	_quad(surface, Vector3(-half_width, y, front), Vector3(half_width, y, front),
		Vector3(half_width, y + 0.25, -5.95), Vector3(-half_width, y + 0.25, -5.95), color)
	_quad(surface, Vector3(half_width, y - 0.025, front), Vector3(-half_width, y - 0.025, front),
		Vector3(-half_width, y + 0.225, -5.95), Vector3(half_width, y + 0.225, -5.95), color.darkened(0.30))
	_box(surface, Vector3(0, y - 0.02, front), Vector3(half_width * 2.0, 0.13, 0.13), color.darkened(0.23))


static func _tiled_roof(surface: SurfaceTool, y: float, height: float, variant: int) -> void:
	const EAVE := 6.54
	const HALF_WIDTH := 6.90
	var color := TILE.lightened(0.04 * float(variant % 3))
	var lf := Vector3(-HALF_WIDTH, y, -EAVE)
	var rf := Vector3(HALF_WIDTH, y, -EAVE)
	var lr := Vector3(-HALF_WIDTH, y + height, 0.0)
	var rr := Vector3(HALF_WIDTH, y + height, 0.0)
	var lb := Vector3(-HALF_WIDTH, y, EAVE)
	var rb := Vector3(HALF_WIDTH, y, EAVE)
	_quad(surface, lf, rf, rr, lr, color)
	_quad(surface, lr, rr, rb, lb, color.darkened(0.08))
	_triangle(surface, lb, lf, lr, FASCIA)
	_triangle(surface, rf, rb, rr, FASCIA)
	_quad(surface, rf, lf, lr, rr, FASCIA)
	_quad(surface, lr, lb, rb, rr, FASCIA)
	for side: float in [-1.0, 1.0]:
		_box(surface, Vector3(0, y - 0.05, side * EAVE), Vector3(HALF_WIDTH * 2.0, 0.19, 0.15), FASCIA)
		for row in range(1, 8):
			var t := float(row) / 8.0
			var edge := side * EAVE * (1.0 - t)
			var from_z := edge - 0.048
			var to_z := edge + 0.048
			var from_y := y + height * (1.0 - absf(from_z) / EAVE) + 0.012
			var to_y := y + height * (1.0 - absf(to_z) / EAVE) + 0.012
			_quad(surface, Vector3(-HALF_WIDTH, from_y, from_z), Vector3(HALF_WIDTH, from_y, from_z),
				Vector3(HALF_WIDTH, to_y, to_z), Vector3(-HALF_WIDTH, to_y, to_z), color.darkened(0.14))
	_box(surface, Vector3(0, y + height, 0), Vector3(HALF_WIDTH * 2.0, 0.12, 0.16), FASCIA)


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
	surface.set_color(color)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)
