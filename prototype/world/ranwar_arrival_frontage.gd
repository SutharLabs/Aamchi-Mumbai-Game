extends RefCounted
## Visual fittings for the authored building beside the St Peter's BEST stop.

const Surfaces := preload("res://world/ranwar_surface_materials.gd")
const REVEAL := Color("56544b")
const STONE := Color("b3a692")
const IRON := Color("454e48")
const FRAMES := [Color("a6a295"), Color("737e77"), Color("858679")]
const GLASS := [Color("485651"), Color("596664"), Color("373f40")]
const PIPE := Color("766658")


static func create(material: Material, height: float) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	# Positive local Z faces the shelter alley. Positive local X faces the footpath.
	for face in 2:
		var tangent := Vector3.RIGHT if face == 0 else Vector3.FORWARD
		var outward := Vector3.BACK if face == 0 else Vector3.RIGHT
		var wall := outward * (6.5 if face == 0 else 6.0)
		var axes := Basis(tangent, Vector3.UP, outward)
		var span := 12.0 if face == 0 else 13.0
		Surfaces.add_box(surface, wall + outward * 0.025 + Vector3.UP * 0.41,
			Vector3(span, 0.82, 0.09), STONE.darkened(0.14), Surfaces.CONCRETE, axes)
		Surfaces.add_box(surface, wall + outward * 0.12 + Vector3.UP * (height - 0.28),
			Vector3(span, 0.19, 0.30), STONE, Surfaces.CONCRETE, axes)
		for level_y: float in [1.61, 4.54, 7.42, 9.72]:
			for bay in (3 if face == 0 else 4):
				var offset := -3.75 + float(bay) * 2.56 if face == 0 else -4.63 + float(bay) * 2.95
				var center := wall + tangent * offset + Vector3.UP * level_y
				_window(surface, center, axes, face + bay, level_y < 3.0)
		_downpipe(surface, wall + tangent * (span * 0.43), axes, height)
		if face == 0:
			var mount := wall + tangent * -2.31 + Vector3.UP * 3.53
			_air_conditioner(surface, mount, axes)
		else:
			var mount := wall + tangent * 4.07 + Vector3.UP * 3.51
			_air_conditioner(surface, mount, axes)
	surface.generate_normals()
	surface.index()
	var mesh := MeshInstance3D.new()
	mesh.name = "HillRoadArrivalFacadeFittings"
	mesh.mesh = surface.commit()
	mesh.material_override = material
	return mesh


static func _window(surface: SurfaceTool, center: Vector3, axes: Basis, variant: int, grille: bool) -> void:
	var trim: Color = FRAMES[variant % FRAMES.size()]
	var glazing: Color = GLASS[variant % GLASS.size()]
	_piece(surface, center, axes, Vector3(0, 0, 0.022), Vector3(1.33, 1.46, 0.040), REVEAL)
	for side: float in [-1.0, 1.0]:
		_piece(surface, center, axes, Vector3(side * 0.60, -0.02, 0.08),
			Vector3(0.14, 1.39, 0.16), trim)
		_piece(surface, center, axes, Vector3(side * 0.26, 0.02, 0.053),
			Vector3(0.49, 1.17, 0.034), glazing.lightened(0.04 if side > 0.0 else 0.0))
	_piece(surface, center, axes, Vector3(0, 0.69, 0.092), Vector3(1.34, 0.15, 0.18), trim)
	_piece(surface, center, axes, Vector3(0, -0.695, 0.16), Vector3(1.56, 0.125, 0.34), STONE, Surfaces.CONCRETE)
	_piece(surface, center, axes, Vector3(0, 0.02, 0.095), Vector3(0.071, 1.22, 0.082), trim.darkened(0.13))
	_piece(surface, center, axes, Vector3(0, 0.31, 0.095), Vector3(1.08, 0.053, 0.064), trim.darkened(0.13))
	if grille:
		for bar: float in [-0.43, -0.22, 0.0, 0.22, 0.43]:
			_piece(surface, center, axes, Vector3(bar, 0, 0.183), Vector3(0.035, 1.19, 0.035), IRON)
		_piece(surface, center, axes, Vector3(0, -0.25, 0.183), Vector3(1.08, 0.045, 0.039), IRON)


static func _downpipe(surface: SurfaceTool, base: Vector3, axes: Basis, height: float) -> void:
	_piece(surface, base, axes, Vector3(0, (height + 0.40) * 0.5, 0.16),
		Vector3(0.11, height - 0.56, 0.11), PIPE)
	for y: float in [0.67, 2.80, 5.03, 7.31, height - 0.49]:
		_piece(surface, base, axes, Vector3(0, y, 0.143), Vector3(0.17, 0.062, 0.15), IRON)
	_piece(surface, base, axes, Vector3(0, 0.48, 0.255), Vector3(0.11, 0.11, 0.30), PIPE)


static func _air_conditioner(surface: SurfaceTool, mount: Vector3, axes: Basis) -> void:
	_piece(surface, mount, axes, Vector3(0, 0, 0.25), Vector3(0.74, 0.47, 0.44), Color("a6a69a"))
	_piece(surface, mount, axes, Vector3(-0.084, 0, 0.478), Vector3(0.47, 0.345, 0.032), IRON)
	for row in 7:
		_piece(surface, mount, axes, Vector3(-0.084, -0.137 + float(row) * 0.046, 0.50),
			Vector3(0.49, 0.020, 0.016), STONE.darkened(0.18))
	for end: float in [-0.24, 0.24]:
		_piece(surface, mount, axes, Vector3(end, -0.29, 0.24), Vector3(0.048, 0.17, 0.44), IRON)


static func _piece(surface: SurfaceTool, center: Vector3, axes: Basis, offset: Vector3,
		size: Vector3, color: Color, finish: int = Surfaces.PLAIN) -> void:
	Surfaces.add_box(surface, center + axes * offset, size, color, finish, axes)
