extends Node3D
## Original frontage and shop interiors positioned with the saved OSM footprints.

const Footprints := preload("res://world/ranwar_building_footprints.gd")
const FacadeKit := preload("res://world/ranwar_facade_kit.gd")
const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const TeaRoomFrontage := preload("res://world/ranwar_tea_room_frontage.gd")
const TEA_ROOM_WAY := 360291657
const DOOR_WIDTH := 2.14
const DOOR_HEIGHT := 2.62
const ROOM_HEIGHT := 3.18
const ROOM_WIDTH := 6.50
const ROOM_DEPTH := 5.50
const TRIM := Color("d8c6ab")
const GLASS := Color("445959")
const TILE := Color("c0ada0")
const INSIDE_WALL := Color("dfd1ba")
const PALETTE: Array[Color] = [
	Color("ae9c82"), Color("cab29c"), Color("a9a38d"),
	Color("bc9185"), Color("9aa8a1"), Color("949f9b"),
]
# Edge indices refer to the source's vertex order. Shop names and interiors are fictional.
const OPEN_SHOPS := {
	TEA_ROOM_WAY: [3, "HILL ROAD TEA ROOM", 5.12, Color("883f31")],
	357472313: [1, "CHAPEL CORNER GROCER", 1.22, Color("446a62")],
}

var entrances: Array[Dictionary] = []
var _footprints: Array[PackedVector2Array] = []
var _bounds: Array[Rect2] = []


func configure(material: Material) -> void:
	for site: Array in Footprints.SITES:
		var way: int = site[0]
		var polygon := PackedVector2Array(site[3])
		var setback: Vector2 = Footprints.SETBACKS.get(way, Vector2.ZERO)
		for index in polygon.size():
			polygon[index] += setback
		var shop: Array = OPEN_SHOPS.get(way, [])
		var door := Vector2.INF
		if not shop.is_empty():
			var edge: int = shop[0]
			door = polygon[edge].lerp(polygon[(edge + 1) % polygon.size()], 0.5)
		if Geometry2D.is_polygon_clockwise(polygon):
			polygon.reverse()
		_footprints.append(polygon)
		_bounds.append(_extents(polygon))
		_add_building(way, polygon, site[1], PALETTE[site[2]], shop, door, material)


func contains_interior(position: Vector3) -> bool:
	if not position.is_finite() or position.y < 0.0 or position.y >= ROOM_HEIGHT:
		return false
	for entrance: Dictionary in entrances:
		var threshold: Vector3 = entrance["threshold"]
		var inside: Vector3 = entrance["inside"]
		var inward := (inside - threshold).normalized()
		var offset := position - threshold
		var depth := offset.dot(inward)
		if depth > 0.0 and depth < ROOM_DEPTH and absf(offset.dot(Vector3.UP.cross(inward))) < ROOM_WIDTH * 0.5:
			return true
	return false


func overlaps_placeholder(center: Vector3, yaw: float) -> bool:
	const CORNERS: Array[Vector3] = [
		Vector3(-6.2, 0.0, -6.9), Vector3(6.2, 0.0, -6.9),
		Vector3(6.2, 0.0, 6.9), Vector3(-6.2, 0.0, 6.9),
	]
	var pose := Transform3D(Basis(Vector3.UP, yaw), center)
	var lot := PackedVector2Array()
	for corner: Vector3 in CORNERS:
		var point := pose * corner
		lot.append(Vector2(point.x, point.z))
	var bounds := _extents(lot)
	for index in _bounds.size():
		if bounds.intersects(_bounds[index]) and not Geometry2D.intersect_polygons(lot, _footprints[index]).is_empty():
			return true
	return false


func _add_building(way: int, polygon: PackedVector2Array, height: float, paint: Color,
		shop: Array, door: Vector2, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = "Footprint_%d" % way
	body.set_meta(&"osm_way", way)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var is_enterable := not shop.is_empty()
	var updated_exterior := surface
	if is_enterable:
		# Keep render refinements out of the authored shop collision mesh.
		updated_exterior = SurfaceTool.new()
		updated_exterior.begin(Mesh.PRIMITIVE_TRIANGLES)
		updated_exterior.set_smooth_group(-1)
	var legacy_exterior := surface
	if way == TEA_ROOM_WAY:
		legacy_exterior = SurfaceTool.new()
		legacy_exterior.begin(Mesh.PRIMITIVE_TRIANGLES)
		legacy_exterior.set_smooth_group(-1)
	for index in polygon.size():
		var p := polygon[index]
		var q := polygon[(index + 1) % polygon.size()]
		var start := Vector3(p.x, 0, p.y)
		var end := Vector3(q.x, 0, q.y)
		var tangent := (end - start).normalized()
		var outward := Vector3.UP.cross(tangent)
		var has_opening := is_enterable and p.lerp(q, 0.5).is_equal_approx(door)
		if has_opening:
			var center := start.lerp(end, 0.5)
			var half_opening := tangent * (DOOR_WIDTH * 0.5)
			_wall(surface, start, center - half_opening, 0.0, height, paint, true)
			_wall(surface, center + half_opening, end, 0.0, height, paint, true)
			_wall(surface, center - half_opening, center + half_opening, DOOR_HEIGHT, height, paint, true)
			var frame := Transform3D(Basis(tangent, Vector3.UP, -outward), center)
			_add_room(body, surface, legacy_exterior, frame, shop, way)
			if way == TEA_ROOM_WAY:
				TeaRoomFrontage.add_to(body, frame, material, start.distance_to(end), height, paint)
		else:
			_wall(surface, start, end, 0.0, height, paint, is_enterable)
		if is_enterable:
			var panel_offset := outward * 0.102
			_add_windows(legacy_exterior if has_opening else surface, start + panel_offset, end + panel_offset,
				height, paint, true)
		if not has_opening:
			FacadeKit.add_face(updated_exterior, start, end, height, paint, way,
				1 if is_enterable else 0, 0.115 if is_enterable else 0.0)

	var roof := Geometry2D.triangulate_polygon(polygon)
	for index in range(0, roof.size(), 3):
		var a := polygon[roof[index]]
		var b := polygon[roof[index + 1]]
		var c := polygon[roof[index + 2]]
		Surfaces.add_triangle(surface, Vector3(a.x, height, a.y), Vector3(b.x, height, b.y),
			Vector3(c.x, height, c.y), paint.darkened(0.23), Surfaces.CONCRETE)
	FacadeKit.add_roof(updated_exterior, polygon, height, paint)
	surface.generate_normals()
	surface.index()
	var visual := MeshInstance3D.new()
	visual.name = "Facade"
	visual.mesh = surface.commit()
	visual.material_override = material
	body.add_child(visual)
	if is_enterable:
		var collision := CollisionShape3D.new()
		var shape := visual.mesh.create_trimesh_shape()
		if legacy_exterior != surface:
			# Preserve the original shop collisions while exporting the new street-facing trim separately.
			var faces := shape.get_faces()
			faces.append_array(legacy_exterior.commit().get_faces())
			shape.set_faces(faces)
		shape.backface_collision = true
		collision.shape = shape
		body.add_child(collision)
		updated_exterior.generate_normals()
		updated_exterior.index()
		var refinement := MeshInstance3D.new()
		refinement.name = "SideAndRearFinishes"
		refinement.mesh = updated_exterior.commit()
		refinement.material_override = material
		body.add_child(refinement)
	else:
		var collision := CollisionPolygon3D.new()
		collision.polygon = polygon
		collision.rotation.x = PI * 0.5
		collision.depth = height
		collision.position.y = height * 0.5
		body.add_child(collision)
	add_child(body)


func _add_room(body: StaticBody3D, surface: SurfaceTool, exterior: SurfaceTool, frame: Transform3D,
		shop: Array, way: int) -> void:
	var center := frame.origin
	var outward := -frame.basis.z
	var accent: Color = shop[3]
	var approach: float = shop[2]
	var tea_room := way == TEA_ROOM_WAY
	_add_threshold_ramp(surface, frame, approach)
	_piece(surface, frame, Vector3(0, 0.015, ROOM_DEPTH * 0.5), Vector3(ROOM_WIDTH, 0.025, ROOM_DEPTH), TILE, Surfaces.CONCRETE)
	_piece(surface, frame, Vector3(0, ROOM_HEIGHT, ROOM_DEPTH * 0.5), Vector3(ROOM_WIDTH, 0.13, ROOM_DEPTH), INSIDE_WALL)
	_piece(surface, frame, Vector3(0, ROOM_HEIGHT * 0.5, ROOM_DEPTH), Vector3(ROOM_WIDTH, ROOM_HEIGHT, 0.16), INSIDE_WALL)
	_piece(surface, frame, Vector3(0, 0.63, ROOM_DEPTH - 0.087), Vector3(ROOM_WIDTH, 1.17, 0.02), accent.lightened(0.22))
	_piece(surface, frame, Vector3(0, 0.47, 4.78), Vector3(2.30, 0.89, 0.76), accent.darkened(0.15))
	_piece(surface, frame, Vector3(0, 0.96, 4.78), Vector3(2.43, 0.10, 0.86), TILE, Surfaces.CONCRETE)
	_piece(exterior, frame, Vector3(0, 2.87, -0.18), Vector3(6.34, 0.42, 0.17), accent)
	_piece(exterior, frame, Vector3(0, 2.69, -0.76), Vector3(6.50, 0.09, 1.00), accent.darkened(0.15))
	_piece(exterior, frame, Vector3(0, 2.60, -1.22), Vector3(6.50, 0.14, 0.08), accent)
	for side: float in [-1.0, 1.0]:
		_piece(surface, frame, Vector3(side * ROOM_WIDTH * 0.5, ROOM_HEIGHT * 0.5, ROOM_DEPTH * 0.5),
			Vector3(0.16, ROOM_HEIGHT, ROOM_DEPTH), INSIDE_WALL)
		_piece(surface, frame, Vector3(side * (ROOM_WIDTH * 0.5 - 0.09), 0.63, ROOM_DEPTH * 0.5),
			Vector3(0.02, 1.17, ROOM_DEPTH), accent.lightened(0.22))
		_piece(exterior, frame, Vector3(side * 1.19, DOOR_HEIGHT * 0.5, -0.09),
			Vector3(0.16, DOOR_HEIGHT, 0.20), accent)
		_piece(exterior, frame, Vector3(side * 2.27, 1.28, -0.108), Vector3(1.82, 2.23, 0.09), TRIM)
		_piece(exterior, frame, Vector3(side * 2.27, 1.31, -0.167), Vector3(1.60, 1.92, 0.06), GLASS)
		_piece(exterior, frame, Vector3(side * 2.27, 1.31, -0.216), Vector3(0.07, 1.94, 0.04), accent)
		_piece(exterior, frame, Vector3(side * 2.27, 1.39, -0.214), Vector3(1.60, 0.07, 0.04), accent)
		_piece(exterior, frame, Vector3(side * 2.27, 0.31, -0.245), Vector3(1.90, 0.12, 0.24), TILE, Surfaces.CONCRETE)
		_piece(surface, frame, Vector3(side * 2.51, 0.41, 2.16), Vector3(0.72, 0.82, 1.72),
			accent.darkened(0.14), Surfaces.TIMBER)
		_piece(surface, frame, Vector3(side * 2.51, 0.85, 2.16), Vector3(0.81, 0.10, 1.84), TILE, Surfaces.CONCRETE)
		for row in range(3):
			_piece(surface, frame, Vector3(side * 2.86, 0.36 + row * 0.44, 3.92),
				Vector3(0.48, 0.09, 1.38), accent, Surfaces.TIMBER)
			for jar in range(4):
				var tint := PALETTE[(jar + row) % PALETTE.size()]
				var packet_height := 0.12 if tea_room else (0.14 + float((jar + row) % 3) * 0.071)
				_piece(surface, frame, Vector3(side * 2.85, 0.49 + row * 0.44, 3.42 + jar * 0.30),
					Vector3(0.16, packet_height, 0.16), tint)

	_piece(surface, frame, Vector3(0, 2.04, ROOM_DEPTH - 0.13), Vector3(2.34, 0.70, 0.07), GLASS.darkened(0.36))
	var board := Label3D.new()
	board.text = "CHAI    BISCUITS    BUN MASKA" if tea_room else "RICE    DAL    SPICES"
	board.position = frame * Vector3(0, 2.04, ROOM_DEPTH - 0.172)
	board.rotation.y = atan2(outward.x, outward.z)
	board.font_size = 34
	board.pixel_size = 0.0039
	board.outline_size = 0
	body.add_child(board)
	if not tea_room:
		var nameplate := Label3D.new()
		nameplate.text = shop[1]
		nameplate.position = center + outward * 0.276 + Vector3.UP * 2.87
		nameplate.rotation.y = atan2(outward.x, outward.z)
		nameplate.font_size = 42
		nameplate.pixel_size = 0.0046
		nameplate.outline_size = 1
		body.add_child(nameplate)

	var lamp := OmniLight3D.new()
	lamp.position = frame * Vector3(0, 2.90, ROOM_DEPTH * 0.62)
	lamp.omni_range = 6.5
	lamp.light_energy = 1.05
	lamp.light_color = Color("ffdfb7")
	body.add_child(lamp)
	entrances.append({
		"name": shop[1], "osm_way": way, "threshold": center,
		"outside": center + outward * approach, "inside": center - outward * 3.35,
	})


func _add_threshold_ramp(surface: SurfaceTool, frame: Transform3D, length: float) -> void:
	var a := frame * Vector3(-1.26, 0.13, -length)
	var b := frame * Vector3(1.26, 0.13, -length)
	var c := frame * Vector3(1.26, 0.0275, 0)
	var d := frame * Vector3(-1.26, 0.0275, 0)
	Surfaces.add_triangle(surface, a, b, c, TILE, Surfaces.CONCRETE)
	Surfaces.add_triangle(surface, a, c, d, TILE, Surfaces.CONCRETE)


func _add_windows(surface: SurfaceTool, start: Vector3, end: Vector3, height: float, paint: Color,
		skip_ground_floor: bool) -> void:
	var span := start.distance_to(end)
	if span < 2.25:
		return
	var bays := maxi(1, floori(span / 3.05))
	var storeys := maxi(1, floori(height / 3.05))
	for storey in range(1 if skip_ground_floor else 0, storeys):
		var floor_y := storey * 3.05
		for bay in bays:
			var a := start.lerp(end, (bay + 0.19) / bays)
			var b := start.lerp(end, (bay + 0.81) / bays)
			_wall(surface, a, b, floor_y + 0.84, floor_y + 2.35, GLASS, false, Surfaces.PLAIN)
			_wall(surface, a, b, floor_y + 0.75, floor_y + 0.92, paint.lightened(0.27), false)
			_wall(surface, a, b, floor_y + 2.32, floor_y + 2.44, TRIM, false)


func _wall(surface: SurfaceTool, a: Vector3, b: Vector3, low: float, high: float, paint: Color,
		solid: bool, finish: int = Surfaces.PLASTER) -> void:
	if solid:
		var tangent := (b - a).normalized()
		var axes := Basis(tangent, Vector3.UP, tangent.cross(Vector3.UP))
		var center := (a + b) * 0.5 + Vector3.UP * ((low + high) * 0.5)
		Surfaces.add_box(surface, center, Vector3(a.distance_to(b), high - low, 0.17), paint, finish, axes)
	else:
		var p := a + Vector3.UP * low
		var q := b + Vector3.UP * low
		var r := b + Vector3.UP * high
		var s := a + Vector3.UP * high
		Surfaces.add_triangle(surface, p, q, r, paint, finish)
		Surfaces.add_triangle(surface, p, r, s, paint, finish)


func _piece(surface: SurfaceTool, frame: Transform3D, local_center: Vector3, size: Vector3, color: Color,
		finish: int = Surfaces.PLAIN) -> void:
	Surfaces.add_box(surface, frame * local_center, size, color, finish, frame.basis)


func _extents(polygon: PackedVector2Array) -> Rect2:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point: Vector2 in polygon:
		bounds = bounds.expand(point)
	return bounds
