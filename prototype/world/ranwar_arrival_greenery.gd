extends RefCounted
## Original shade trees for the service edge of the Hill Road forecourt.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const BARK := Color("6a5b49")
const SOIL := Color("756951")
const EDGE := Color("8c836e")
const CROWN := [Color("566543"), Color("647449"), Color("6e7c50"), Color("5d704c")]


static func add_to(world: Node3D, shelter: Vector3, along: Vector3,
		church_side: Vector3, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# The wider crown sits in the gap between the church and the Hill Road frontage.
	_tree(surface, Vector3(1.45, 0.0, 5.30), 1.0, 1.0, 1947)
	# The narrow crown follows the building setback and leaves the through pavement clear.
	_tree(surface, Vector3(-8.30, 0.0, 2.05), 0.85, 0.70, 4259)
	surface.generate_normals()
	surface.index()
	var grove := Node3D.new()
	grove.name = "StPetersShadeTrees"
	grove.transform = Transform3D(Basis(along, Vector3.UP, church_side), shelter)
	world.add_child(grove)
	var visual := MeshInstance3D.new()
	visual.mesh = surface.commit()
	visual.material_override = material
	grove.add_child(visual)


static func _tree(surface: SurfaceTool, base: Vector3, scale: float,
		depth_scale: float, seed_value: int) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var dimensions := Vector3(scale, scale, scale * depth_scale)
	var knee := base + Vector3(0.17, 1.78, -0.09) * dimensions
	var fork := base + Vector3(-0.04, 3.38, 0.04) * dimensions
	var leader := base + Vector3(0.42, 5.52, -0.19) * dimensions
	_planting_bed(surface, base, dimensions)
	surface.set_smooth_group(-1)
	_branch(surface, base - Vector3.UP * 0.03, knee, 0.27 * scale, 0.18 * scale, BARK)
	_branch(surface, knee, fork, 0.183 * scale, 0.124 * scale, BARK)
	_branch(surface, fork, leader, 0.129 * scale, 0.029 * scale, BARK.lightened(0.05))
	var first_angle := random.randf_range(0.0, TAU)
	for index in 5:
		var heading := first_angle + TAU * float(index) / 5.0 + random.randf_range(-0.22, 0.22)
		var outward := Vector3(cos(heading), 0.0, sin(heading))
		var side := Vector3(-outward.z, 0.0, outward.x)
		var spread := random.randf_range(1.16, 1.56)
		var height := random.randf_range(4.66, 5.49)
		var arm_root := knee.lerp(fork, random.randf_range(0.50, 0.94))
		var elbow := base + (outward * spread * 0.56 + Vector3.UP * (height - 0.78)) * dimensions
		var tip := base + (outward * spread + Vector3.UP * height) * dimensions
		var twig := tip + (side * random.randf_range(-0.54, 0.54) + outward * 0.36 - Vector3.UP * 0.32) * dimensions
		surface.set_smooth_group(-1)
		_branch(surface, arm_root, elbow, 0.092 * scale, 0.054 * scale, BARK)
		_branch(surface, elbow, tip, 0.059 * scale, 0.021 * scale, BARK.lightened(0.06))
		_branch(surface, elbow, twig, 0.042 * scale, 0.013 * scale, BARK)
		var canopy_color: Color = CROWN[index % CROWN.size()]
		_lobe(surface, tip + Vector3.UP * (0.19 * scale),
			Vector3(1.02, 0.75, 1.04) * dimensions * random.randf_range(0.91, 1.12), canopy_color, random)
		_lobe(surface, twig, Vector3(0.70, 0.56, 0.72) * dimensions, canopy_color.darkened(0.07), random)
		var upper := tip.lerp(leader, 0.37) + (side * 0.31 + Vector3.UP * 0.52) * dimensions
		_lobe(surface, upper, Vector3(0.70, 0.64, 0.71) * dimensions, canopy_color.lightened(0.045), random)
	var main_color: Color = CROWN[seed_value % CROWN.size()]
	_lobe(surface, leader + Vector3.UP * (0.22 * scale), Vector3(1.14, 0.99, 1.18) * dimensions, main_color, random)


static func _planting_bed(surface: SurfaceTool, base: Vector3, dimensions: Vector3) -> void:
	surface.set_smooth_group(-1)
	const SIDES := 10
	for index in SIDES:
		var angle := TAU * float(index) / float(SIDES)
		var next_angle := TAU * float(index + 1) / float(SIDES)
		var radial := Vector3(cos(angle), 0.0, sin(angle)) * dimensions
		var next_radial := Vector3(cos(next_angle), 0.0, sin(next_angle)) * dimensions
		var inner := base + radial * 0.86 + Vector3.UP * 0.028
		var next_inner := base + next_radial * 0.86 + Vector3.UP * 0.028
		var outer := base + radial + Vector3.UP * 0.014
		var next_outer := base + next_radial + Vector3.UP * 0.014
		Surfaces.add_triangle(surface, base + Vector3.UP * 0.017, inner, next_inner, SOIL, Surfaces.PLAIN)
		Surfaces.add_triangle(surface, inner, outer, next_inner, EDGE, Surfaces.CONCRETE)
		Surfaces.add_triangle(surface, outer, next_outer, next_inner, EDGE, Surfaces.CONCRETE)


static func _branch(surface: SurfaceTool, start: Vector3, end: Vector3,
		start_radius: float, end_radius: float, color: Color) -> void:
	var axis := (end - start).normalized()
	var right := axis.cross(Vector3.FORWARD).normalized()
	var across := right.cross(axis)
	const SIDES := 7
	for index in SIDES:
		var angle := TAU * float(index) / float(SIDES)
		var next_angle := TAU * float(index + 1) / float(SIDES)
		var radial := right * cos(angle) + across * sin(angle)
		var next_radial := right * cos(next_angle) + across * sin(next_angle)
		var a := start + radial * start_radius
		var b := start + next_radial * start_radius
		var c := end + next_radial * end_radius
		var d := end + radial * end_radius
		var tint := color.lerp(Color("817364"), 0.10 * float(index % 3))
		Surfaces.add_triangle(surface, a, b, d, tint, Surfaces.TIMBER)
		Surfaces.add_triangle(surface, b, c, d, tint, Surfaces.TIMBER)


static func _lobe(surface: SurfaceTool, center: Vector3, radius: Vector3,
		color: Color, random: RandomNumberGenerator) -> void:
	surface.set_smooth_group(0)
	const SIDES := 9
	var lower := PackedVector3Array()
	var middle := PackedVector3Array()
	var upper := PackedVector3Array()
	var first_angle := random.randf_range(0.0, TAU)
	for index in SIDES:
		var angle := first_angle + TAU * float(index) / float(SIDES)
		var radial := Vector3(cos(angle), 0.0, sin(angle))
		var angular_offset := Vector3(cos(angle - 0.25), 0.0, sin(angle - 0.25))
		var shape := random.randf_range(0.84, 1.18)
		lower.append(center + (radial * 0.74 * shape + Vector3.UP * random.randf_range(-0.69, -0.47)) * radius)
		middle.append(center + (angular_offset * shape + Vector3.UP * random.randf_range(-0.18, 0.18)) * radius)
		upper.append(center + (radial * 0.72 * shape + Vector3.UP * random.randf_range(0.46, 0.73)) * radius)
	var bottom := center - Vector3.UP * radius.y * 0.94
	var top := center + Vector3(0.09, 1.0, -0.07) * radius
	for index in SIDES:
		var next := (index + 1) % SIDES
		var shade := color.darkened(random.randf_range(0.04, 0.12))
		var mid := color.lightened(random.randf_range(0.0, 0.06))
		var bright := color.lightened(random.randf_range(0.05, 0.09))
		Surfaces.add_triangle(surface, bottom, lower[next], lower[index], shade, Surfaces.PLAIN)
		_lobe_band(surface, lower[index], lower[next], middle[next], middle[index], shade)
		_lobe_band(surface, middle[index], middle[next], upper[next], upper[index], mid)
		Surfaces.add_triangle(surface, top, upper[index], upper[next], bright, Surfaces.PLAIN)


static func _lobe_band(surface: SurfaceTool, a: Vector3, b: Vector3,
		c: Vector3, d: Vector3, color: Color) -> void:
	Surfaces.add_triangle(surface, a, b, d, color, Surfaces.PLAIN)
	Surfaces.add_triangle(surface, b, c, d, color, Surfaces.PLAIN)
