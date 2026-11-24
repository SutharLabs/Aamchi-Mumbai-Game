extends RefCounted
## Original Hill Road shelter trim and signs. The world owns the walkable deck and collision.

const Materials := preload("res://world/ranwar_surface_materials.gd")
const FASCIA_SIGN := preload("res://world/textures/st_peters_shelter_fascia.png")
const END_SIGN := preload("res://world/textures/st_peters_shelter_stop.png")
const FRAME := Color("35494a")
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
	# The sheet crown slopes toward its roadside gutter. Posts bear the rear beam.
	var pitch := Basis(Vector3.RIGHT, deg_to_rad(2.5))
	Materials.add_box(surface, Vector3(0.0, 2.59, 0.0), Vector3(4.85, 0.075, 2.05), ROOF, Materials.PLAIN, pitch)
	Materials.add_box(surface, Vector3(0.0, 2.53, 1.02), Vector3(4.88, 0.091, 0.07), FRAME)
	Materials.add_box(surface, Vector3(0.0, 2.51, -0.69), Vector3(4.36, 0.10, 0.10), FRAME)
	for index in range(-7, 8):
		var crest := pitch * Vector3(float(index) * 0.32, 0.043, 0.0)
		Materials.add_box(surface, Vector3(0.0, 2.59, 0.0) + crest,
			Vector3(0.025, 0.024, 1.99), ROOF.lightened(0.15), Materials.PLAIN, pitch)
	for offset: float in [-2.08, 2.08]:
		Materials.add_box(surface, Vector3(offset, 0.17, -0.69), Vector3(0.23, 0.10, 0.23), FRAME)
		Materials.add_box(surface, Vector3(offset, 2.49, 0.09), Vector3(0.055, 0.10, 1.90), FRAME)
	# The original solid bench remains the low-cost collider under the three timber slats.
	for row in 3:
		var strip := -0.64 + float(row) * 0.15
		Materials.add_box(surface, Vector3(0.0, 0.642, strip), Vector3(2.88, 0.035, 0.133),
			WOOD.lerp(TIMBER_EDGE, float(row) * 0.22), Materials.TIMBER)
	# Shallow horizontal folded edges and an original information strip on the apron.
	for height: float in [0.81, 1.18, 1.56, 1.94, 2.32]:
		Materials.add_box(surface, Vector3(0.0, height, -0.641), Vector3(4.15, 0.030, 0.030), FRAME.lightened(0.14))
	Materials.add_box(surface, Vector3(0.73, 1.76, -0.608), Vector3(1.43, 0.55, 0.078), FRAME)
	Materials.add_box(surface, Vector3(0.73, 1.76, -0.561), Vector3(1.34, 0.47, 0.020), NOTICE_PAPER)
	Materials.add_box(surface, Vector3(0.73, 1.93, -0.547), Vector3(1.25, 0.065, 0.012), SIGN_RED)
	Materials.add_box(surface, Vector3(0.73, 1.73, -0.547), Vector3(1.05, 0.017, 0.012), FRAME)
	for mark in 5:
		var x := 0.23 + float(mark) * 0.25
		Materials.add_box(surface, Vector3(x, 1.73, -0.535), Vector3(0.025, 0.055, 0.014), SIGN_RED)
		Materials.add_box(surface, Vector3(x, 1.65, -0.546), Vector3(0.104, 0.017, 0.012), FRAME)

	surface.generate_normals()
	surface.index()
	var visual := MeshInstance3D.new()
	visual.mesh = surface.commit()
	visual.material_override = material
	shelter_kit.add_child(visual)


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
