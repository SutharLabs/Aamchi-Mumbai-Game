extends RefCounted
## Authored street furniture on the service side of the St Peter's BEST shelter.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const STONE := Color("a49a83")
const BIN_BODY := Color("475754")
const CABINET_PAINT := Color("777b6d")
const DARK_METAL := Color("353b38")
const LEAVES := [Color("425133"), Color("5c6c42"), Color("758354")]


static func add_to(world: Node3D, shelter: Vector3, along: Vector3,
		church_side: Vector3, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	# These placements are on grade, beyond the deck and clear of the Hill Road footpath.
	_planter(surface, Vector3(4.32, 0.0, 2.19))
	_litter_bin(surface, Vector3(-3.84, 0.0, 1.35))
	_utility_cabinet(surface, Vector3(-5.55, 0.0, 2.83))
	surface.generate_normals()
	surface.index()
	var cluster := Node3D.new()
	cluster.name = "StPetersStopStreetFurniture"
	world.add_child(cluster)
	cluster.transform = Transform3D(Basis(along, Vector3.UP, church_side), shelter)
	var visual := MeshInstance3D.new()
	visual.mesh = surface.commit()
	visual.material_override = material
	cluster.add_child(visual)


static func _planter(surface: SurfaceTool, base: Vector3) -> void:
	Surfaces.add_box(surface, base + Vector3.UP * 0.145,
		Vector3(1.60, 0.29, 0.62), STONE.darkened(0.25), Surfaces.CONCRETE)
	Surfaces.add_box(surface, base + Vector3.UP * 0.289,
		Vector3(1.68, 0.092, 0.70), STONE, Surfaces.CONCRETE)
	Surfaces.add_box(surface, base + Vector3(0.0, 0.245, -0.312),
		Vector3(1.55, 0.024, 0.021), STONE.darkened(0.41), Surfaces.CONCRETE)
	Surfaces.add_box(surface, base + Vector3.UP * 0.339,
		Vector3(1.47, 0.017, 0.49), Color("54483c"))
	_plant(surface, base + Vector3(-0.43, 0.347, 0.04), 0.73, 0.62)
	_plant(surface, base + Vector3(0.06, 0.347, -0.07), 0.91, 2.34)
	_plant(surface, base + Vector3(0.47, 0.347, 0.06), 0.65, 3.96)


static func _plant(surface: SurfaceTool, root: Vector3, scale: float, angle: float) -> void:
	for index in 7:
		var heading := angle + float(index) * 2.40
		var out := Vector3(cos(heading), 0.0, sin(heading))
		var side := out.cross(Vector3.UP) * (0.062 * scale)
		var stalk := 0.53 + float(index % 4) * 0.085
		var shoulder := root + (out * 0.22 + Vector3.UP * stalk * 0.74) * scale
		var ridge := shoulder + (Vector3.UP - out) * (0.040 * scale)
		var tip := root + (out * (0.40 + float(index % 3) * 0.065) + Vector3.UP * stalk) * scale
		var color: Color = LEAVES[index % LEAVES.size()]
		_leaf_face(surface, root, shoulder - side, ridge, color)
		_leaf_face(surface, shoulder - side, tip, ridge, color)
		_leaf_face(surface, root, ridge, shoulder + side, color.lightened(0.12))
		_leaf_face(surface, ridge, tip, shoulder + side, color.lightened(0.12))


static func _leaf_face(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	Surfaces.add_triangle(surface, a, b, c, color, Surfaces.PLAIN)
	# Thicken the underside so the exchange does not discard it as a duplicate triangle.
	var underside := Vector3.DOWN * 0.002
	Surfaces.add_triangle(surface, c + underside, b + underside, a + underside,
		color.darkened(0.13), Surfaces.PLAIN)


static func _litter_bin(surface: SurfaceTool, base: Vector3) -> void:
	# Interrupted front panels form an open mouth beneath the formed lip.
	const SIDES := 16
	surface.set_smooth_group(1)
	for index in SIDES:
		var angle := TAU * float(index) / float(SIDES)
		var next_angle := TAU * float(index + 1) / float(SIDES)
		var from := Vector3(cos(angle), 0, sin(angle))
		var to := Vector3(cos(next_angle), 0, sin(next_angle))
		var foot := base + from * 0.205
		var next_foot := base + to * 0.205
		var lip := base + from * 0.254 + Vector3.UP * 0.73
		var next_lip := base + to * 0.254 + Vector3.UP * 0.73
		var lower := foot.lerp(lip, 0.78) if index >= 10 and index <= 13 else lip
		var next_lower := next_foot.lerp(next_lip, 0.78) if index >= 10 and index <= 13 else next_lip
		Surfaces.add_triangle(surface, foot, next_foot, lower, BIN_BODY, Surfaces.PLAIN)
		Surfaces.add_triangle(surface, lower, next_foot, next_lower, BIN_BODY, Surfaces.PLAIN)
		var rim := base + from * 0.26 + Vector3.UP * 0.754
		var next_rim := base + to * 0.26 + Vector3.UP * 0.754
		Surfaces.add_triangle(surface, lip, next_lip, rim, BIN_BODY.lightened(0.15), Surfaces.PLAIN)
		Surfaces.add_triangle(surface, rim, next_lip, next_rim, BIN_BODY.lightened(0.15), Surfaces.PLAIN)
		Surfaces.add_triangle(surface, base + Vector3.UP * 0.759, rim, next_rim, BIN_BODY.lightened(0.08), Surfaces.PLAIN)
	surface.set_smooth_group(-1)
	Surfaces.add_box(surface, base + Vector3(0.0, 0.655, -0.088),
		Vector3(0.30, 0.16, 0.018), Color("262d28"))
	Surfaces.add_box(surface, base + Vector3(0.0, 0.717, -0.220),
		Vector3(0.35, 0.046, 0.122), BIN_BODY.lightened(0.13))


static func _utility_cabinet(surface: SurfaceTool, base: Vector3) -> void:
	Surfaces.add_box(surface, base + Vector3.UP * 0.048,
		Vector3(0.73, 0.096, 0.43), STONE.darkened(0.22), Surfaces.CONCRETE)
	Surfaces.add_box(surface, base + Vector3.UP * 0.548,
		Vector3(0.59, 0.91, 0.33), CABINET_PAINT)
	Surfaces.add_box(surface, base + Vector3.UP * 1.017,
		Vector3(0.635, 0.051, 0.39), CABINET_PAINT.lightened(0.16), Surfaces.PLAIN,
		Basis(Vector3.RIGHT, deg_to_rad(4.0)))
	Surfaces.add_box(surface, base + Vector3(0.0, 0.579, -0.169),
		Vector3(0.52, 0.755, 0.020), DARK_METAL)
	Surfaces.add_box(surface, base + Vector3(0, 0.579, -0.174),
		Vector3(0.49, 0.72, 0.027), CABINET_PAINT.lightened(0.07))
	Surfaces.add_box(surface, base + Vector3(0.155, 0.572, -0.202),
		Vector3(0.06, 0.033, 0.052), DARK_METAL)
	for hinge: float in [0.339, 0.824]:
		Surfaces.add_box(surface, base + Vector3(-0.242, hinge, -0.190),
			Vector3(0.037, 0.085, 0.028), CABINET_PAINT.darkened(0.18))
	for groove in 4:
		Surfaces.add_box(surface, base + Vector3(0, 0.806 - float(groove) * 0.039, -0.188),
			Vector3(0.28, 0.009, 0.008), DARK_METAL)
