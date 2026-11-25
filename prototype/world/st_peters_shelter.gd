extends RefCounted
## Original Hill Road shelter trim and signs. The world owns the walkable deck and collision.

const Materials := preload("res://world/ranwar_surface_materials.gd")
const FASCIA_SIGN := preload("res://world/textures/st_peters_shelter_fascia.png")
const END_SIGN := preload("res://world/textures/st_peters_shelter_stop.png")
const FRAME := Color("35494a")
const FRAME_EDGE := Color("566b69")
const GALVANIZED := Color("8a9289")
const DARK_SEAM := Color("283638")
const ROOF := Color("9a9d90")
const WOOD := Color("896a50")
const TIMBER_EDGE := Color("ac8967")
const SIGN_RED := Color("823c37")
const NOTICE_PAPER := Color("d0c6ad")


static func add_kit(world: Node3D, position: Vector3, yaw: float, material: Material) -> void:
	var shelter_kit := Node3D.new()
	shelter_kit.name = "StPetersStopDetail"
	shelter_kit.position = position
	shelter_kit.rotation.y = yaw
	world.add_child(shelter_kit)

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	_canopy(surface)
	_bench(surface)
	_notice_board(surface)
	surface.generate_normals()
	surface.index()
	var visual := MeshInstance3D.new()
	visual.mesh = surface.commit()
	visual.material_override = material
	shelter_kit.add_child(visual)


static func _canopy(surface: SurfaceTool) -> void:
	# The sheet crown slopes toward its roadside gutter. Posts bear the rear beam.
	var pitch := Basis(Vector3.RIGHT, deg_to_rad(2.5))
	Materials.add_box(surface, Vector3(0.0, 2.59, 0.0), Vector3(4.85, 0.075, 2.05),
		ROOF.darkened(0.10), Materials.PLAIN, pitch)
	Materials.add_box(surface, Vector3(0.0, 2.53, 1.02), Vector3(4.88, 0.091, 0.095), FRAME)
	Materials.add_box(surface, Vector3(0.0, 2.559, 1.072), Vector3(4.88, 0.025, 0.027), GALVANIZED)
	Materials.add_box(surface, Vector3(0.0, 2.479, -0.69), Vector3(4.37, 0.135, 0.13), FRAME)
	Materials.add_box(surface, Vector3(0.0, 2.406, -0.633), Vector3(4.36, 0.020, 0.045), FRAME_EDGE)
	for offset: float in [-2.08, -1.04, 0.0, 1.04, 2.08]:
		Materials.add_box(surface, Vector3(offset, 2.50, 0.09), Vector3(0.073, 0.10, 1.90),
			FRAME_EDGE, Materials.PLAIN, pitch)
	for side: float in [-1.0, 1.0]:
		var offset := side * 2.08
		Materials.add_box(surface, Vector3(offset, 1.29, -0.69), Vector3(0.141, 2.23, 0.141), FRAME)
		Materials.add_box(surface, Vector3(offset, 0.162, -0.69), Vector3(0.23, 0.082, 0.23), DARK_SEAM)
		Materials.add_box(surface, Vector3(offset, 0.220, -0.69), Vector3(0.171, 0.108, 0.171), FRAME_EDGE)
		Materials.add_box(surface, Vector3(offset, 2.242, -0.369), Vector3(0.062, 0.071, 0.69),
			FRAME, Materials.PLAIN, Basis(Vector3.RIGHT, deg_to_rad(-39.0)))
		Materials.add_box(surface, Vector3(offset, 2.046, -0.603), Vector3(0.161, 0.158, 0.021), FRAME_EDGE)
		for bolt: float in [-0.048, 0.048]:
			Materials.add_box(surface, Vector3(offset + bolt, 2.056, -0.587),
				Vector3(0.023, 0.022, 0.014), GALVANIZED)
		Materials.add_box(surface, Vector3(side * 2.325, 2.554, 0.0), Vector3(0.075, 0.097, 2.06),
			FRAME, Materials.PLAIN, pitch)
	# The underside housing is placed under the existing shelter light.
	Materials.add_box(surface, Vector3(0.0, 2.471, 0.10), Vector3(1.13, 0.061, 0.17), DARK_SEAM)
	Materials.add_box(surface, Vector3(0.0, 2.432, 0.10), Vector3(1.03, 0.032, 0.113), Color("e0dbc6"))
	# Closed gutter return and downpipe sit at the edge of the original rear post.
	Materials.add_box(surface, Vector3(-2.31, 2.515, 0.18), Vector3(0.068, 0.073, 1.71), GALVANIZED,
		Materials.PLAIN, pitch)
	Materials.add_box(surface, Vector3(-2.189, 1.336, -0.693), Vector3(0.063, 2.30, 0.067), GALVANIZED)
	for height: float in [0.51, 1.25, 1.98]:
		Materials.add_box(surface, Vector3(-2.177, height, -0.693), Vector3(0.09, 0.024, 0.088), FRAME_EDGE)
	Materials.add_box(surface, Vector3(-2.188, 0.177, -0.764), Vector3(0.067, 0.066, 0.201), GALVANIZED)


static func _bench(surface: SurfaceTool) -> void:
	# The original solid bench remains the low-cost collider under the three timber slats.
	for row in 3:
		var strip := -0.64 + float(row) * 0.15
		Materials.add_box(surface, Vector3(0.0, 0.642, strip), Vector3(2.88, 0.035, 0.133),
			WOOD.lerp(TIMBER_EDGE, float(row) * 0.22), Materials.TIMBER)
		for screw: float in [-1.20, 1.20]:
			Materials.add_box(surface, Vector3(screw, 0.661, strip), Vector3(0.024, 0.007, 0.026), DARK_SEAM)
	Materials.add_box(surface, Vector3(0.0, 0.586, -0.213), Vector3(2.93, 0.096, 0.035), FRAME)
	Materials.add_box(surface, Vector3(0.0, 0.623, -0.194), Vector3(2.86, 0.027, 0.027), TIMBER_EDGE,
		Materials.TIMBER)
	for offset: float in [-1.21, 1.21]:
		Materials.add_box(surface, Vector3(offset, 0.188, -0.49), Vector3(0.19, 0.063, 0.30), FRAME)


static func _notice_board(surface: SurfaceTool) -> void:
	# Galvanized folds subdivide the backing around the timetable and support rail.
	for height: float in [0.81, 1.18, 1.56, 1.94, 2.32]:
		Materials.add_box(surface, Vector3(0.0, height, -0.641), Vector3(4.15, 0.030, 0.030), FRAME_EDGE)
	for offset: float in [-1.40, -0.44, 0.49, 1.40]:
		Materials.add_box(surface, Vector3(offset, 1.597, -0.643), Vector3(0.021, 1.52, 0.017), DARK_SEAM)
	Materials.add_box(surface, Vector3(0.0, 1.117, -0.552), Vector3(3.88, 0.049, 0.060), FRAME)
	Materials.add_box(surface, Vector3(0.73, 1.76, -0.608), Vector3(1.43, 0.55, 0.091), FRAME_EDGE)
	Materials.add_box(surface, Vector3(0.73, 1.76, -0.561), Vector3(1.34, 0.47, 0.020), NOTICE_PAPER)
	Materials.add_box(surface, Vector3(0.73, 1.93, -0.547), Vector3(1.25, 0.065, 0.012), SIGN_RED)
	Materials.add_box(surface, Vector3(0.73, 1.73, -0.547), Vector3(1.05, 0.017, 0.012), FRAME)
	for mark in 5:
		var x := 0.23 + float(mark) * 0.25
		Materials.add_box(surface, Vector3(x, 1.73, -0.535), Vector3(0.025, 0.055, 0.014), SIGN_RED)
		Materials.add_box(surface, Vector3(x, 1.65, -0.546), Vector3(0.104, 0.017, 0.012), FRAME)


static func add_curb_detail(world: Node3D, position: Vector3, yaw: float, material: Material) -> void:
	# A pair of flush gully grates sits on the carriageway side of the existing curb.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var frame := Color("535b57")
	for offset: float in [-2.32, 2.68]:
		Materials.add_box(surface, Vector3(offset, 0.022, 3.57),
			Vector3(0.57, 0.014, 0.36), frame, Materials.CONCRETE)
		Materials.add_box(surface, Vector3(offset, 0.031, 3.57),
			Vector3(0.50, 0.007, 0.29), Color("252927"))
		for bar in 7:
			var x := offset - 0.222 + float(bar) * 0.074
			Materials.add_box(surface, Vector3(x, 0.038, 3.57),
				Vector3(0.022, 0.008, 0.28), frame)
	surface.generate_normals()
	surface.index()
	var grates := MeshInstance3D.new()
	grates.name = "HillRoadGullyGrates"
	grates.mesh = surface.commit()
	grates.material_override = material
	grates.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	grates.position = position
	grates.rotation.y = yaw
	world.add_child(grates)


static func add_sign_face(panel: Node3D, depth: float, size: Vector2, paint: Texture2D) -> void:
	# Opaque painted faces preserve the Marathi shaping in both engine exports.
	var mesh := QuadMesh.new()
	mesh.size = size
	var paint_finish := StandardMaterial3D.new()
	paint_finish.albedo_texture = paint
	paint_finish.roughness = 0.88
	paint_finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	paint_finish.texture_repeat = false
	var sign := MeshInstance3D.new()
	sign.name = "BilingualSignFace"
	sign.mesh = mesh
	sign.material_override = paint_finish
	sign.position.z = depth
	sign.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.add_child(sign)
