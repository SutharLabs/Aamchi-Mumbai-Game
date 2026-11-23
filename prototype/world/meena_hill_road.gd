extends RefCounted
## OSM way 255362104. See layout.json and the local map attribution.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const FOOTPRINT_LON_LAT: Array[Vector2] = [
	Vector2(72.8278686, 19.0551477),
	Vector2(72.8279576, 19.0551446),
	Vector2(72.8279563, 19.0551110),
	Vector2(72.8279813, 19.0551101),
	Vector2(72.8279796, 19.0550673),
	Vector2(72.8279604, 19.0550680),
	Vector2(72.8279582, 19.0550128),
	Vector2(72.8279723, 19.0550123),
	Vector2(72.8279700, 19.0549544),
	Vector2(72.8278612, 19.0549582),
]
const STOREYS := 15
const STOREY_HEIGHT := 3.05
const HEIGHT := STOREYS * STOREY_HEIGHT
const WALL := Color("b7b0a0")
const BAND := Color("c8bda7")
const GLASS := Color("4d6166")
const ROOF := Color("777b77")


static func create(footprint: PackedVector3Array, material: Material) -> StaticBody3D:
	var origin := footprint[0]
	var polygon := PackedVector2Array()
	for vertex: Vector3 in footprint:
		var local := vertex - origin
		polygon.append(Vector2(local.x, local.z))
	if Geometry2D.is_polygon_clockwise(polygon):
		polygon.reverse()

	var body := StaticBody3D.new()
	body.name = "MeenaHillRoad"
	body.position = origin
	var collision := CollisionPolygon3D.new()
	collision.name = "MappedFootprint"
	collision.polygon = polygon
	collision.rotation.x = PI * 0.5
	collision.depth = HEIGHT
	collision.position.y = HEIGHT * 0.5
	body.add_child(collision)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(polygon.size()):
		var first := polygon[index]
		var second := polygon[(index + 1) % polygon.size()]
		_add_wall(surface, Vector3(first.x, 0.0, first.y), Vector3(second.x, 0.0, second.y))
	var roof := Geometry2D.triangulate_polygon(polygon)
	for index in range(0, roof.size(), 3):
		var a := polygon[roof[index]]
		var b := polygon[roof[index + 1]]
		var c := polygon[roof[index + 2]]
		Surfaces.add_triangle(surface, Vector3(a.x, HEIGHT, a.y), Vector3(b.x, HEIGHT, b.y),
			Vector3(c.x, HEIGHT, c.y), ROOF, Surfaces.CONCRETE)
	surface.generate_normals()
	surface.index()
	var exterior := MeshInstance3D.new()
	exterior.name = "MassingExterior"
	exterior.mesh = surface.commit()
	exterior.material_override = material
	body.add_child(exterior)
	return body


static func _add_wall(surface: SurfaceTool, start: Vector3, end: Vector3) -> void:
	_quad(surface, start, end, end + Vector3.UP * HEIGHT, start + Vector3.UP * HEIGHT, WALL, Surfaces.PLASTER)
	var span := start.distance_to(end)
	if span < 2.75:
		return
	var outward := Vector3.UP.cross((end - start).normalized())
	var bay_count := maxi(1, floori(span / 2.8))
	for floor_index in range(STOREYS):
		var height := float(floor_index) * STOREY_HEIGHT
		_panel(surface, start, end, outward * 0.035, 0.02, 0.98, height + 0.24, height + 0.47, BAND)
		for bay in range(bay_count):
			var left := (float(bay) + 0.20) / float(bay_count)
			var right := (float(bay) + 0.80) / float(bay_count)
			_panel(surface, start, end, outward * 0.055, left, right, height + 0.91, height + 2.38, GLASS)


static func _panel(surface: SurfaceTool, start: Vector3, end: Vector3, offset: Vector3,
		left: float, right: float, low: float, high: float, color: Color) -> void:
	var a := start.lerp(end, left) + offset
	var b := start.lerp(end, right) + offset
	_quad(surface, a + Vector3.UP * low, b + Vector3.UP * low,
		b + Vector3.UP * high, a + Vector3.UP * high, color, Surfaces.PLAIN)


static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, color: Color, finish: int) -> void:
	Surfaces.add_triangle(surface, a, b, c, color, finish)
	Surfaces.add_triangle(surface, a, c, d, color, finish)
