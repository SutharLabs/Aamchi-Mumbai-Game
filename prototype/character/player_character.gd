extends Node3D
## Original low-poly civilian, skinned to a reproducible humanoid rest pose.
## The driving and walking controllers own gameplay collision separately.

const SKIN_TONE := Color("a57556")
const HAIR_COLOR := Color("29242b")
const TROUSER_COLOR := Color("42474e")
const SHOE_COLOR := Color("3b3c3a")
const SOLE_COLOR := Color("8b8375")

@export var shirt_color: Color = Color("447a75")

var skeleton := Skeleton3D.new()
var _bone_ids: Dictionary[String, int] = {}
var _joints: Dictionary[String, Vector3] = {}
var _surface := SurfaceTool.new()


class Ring:
	var center: Vector3
	var radii: Vector2
	var bones: PackedInt32Array
	var weights: PackedFloat32Array

	func _init(point: Vector3, size: Vector2, primary: int, secondary: int, blend: float) -> void:
		center = point
		radii = size
		bones = PackedInt32Array([primary, secondary, 0, 0])
		weights = PackedFloat32Array([1.0 - blend, blend, 0.0, 0.0])


func _ready() -> void:
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	_build_rig()
	_build_body()


func _build_rig() -> void:
	_add_joint("Hips", "", Vector3(0, 0.90, 0))
	_add_joint("Spine", "Hips", Vector3(0, 1.03, 0))
	_add_joint("Chest", "Spine", Vector3(0, 1.23, 0))
	_add_joint("Neck", "Chest", Vector3(0, 1.40, 0))
	_add_joint("Head", "Neck", Vector3(0, 1.49, -0.01))
	for side: float in [-1.0, 1.0]:
		var label := "Left" if side < 0.0 else "Right"
		_add_joint(label + "Shoulder", "Chest", Vector3(side * 0.12, 1.35, 0))
		_add_joint(label + "UpperArm", label + "Shoulder", Vector3(side * 0.205, 1.35, 0))
		_add_joint(label + "LowerArm", label + "UpperArm", Vector3(side * 0.455, 1.35, 0))
		_add_joint(label + "Hand", label + "LowerArm", Vector3(side * 0.665, 1.35, 0))
		_add_joint(label + "UpperLeg", "Hips", Vector3(side * 0.097, 0.89, 0))
		_add_joint(label + "LowerLeg", label + "UpperLeg", Vector3(side * 0.102, 0.488, -0.016))
		_add_joint(label + "Foot", label + "LowerLeg", Vector3(side * 0.103, 0.082, 0.009))
		_add_joint(label + "Toes", label + "Foot", Vector3(side * 0.103, 0.038, -0.132))
	skeleton.reset_bone_poses()


func _add_joint(bone: String, parent_bone: String, point: Vector3) -> void:
	var index := skeleton.get_bone_count()
	skeleton.add_bone(bone)
	var offset := point
	if not parent_bone.is_empty():
		skeleton.set_bone_parent(index, _bone_ids[parent_bone])
		offset -= _joints[parent_bone]
	skeleton.set_bone_rest(index, Transform3D(Basis.IDENTITY, offset))
	_bone_ids[bone] = index
	_joints[bone] = point


func _build_body() -> void:
	_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube([
		_ring(Vector3(0, 0.826, 0), 0.0, 0.0, "Hips"),
		_ring(Vector3(0, 0.861, 0.005), 0.144, 0.097, "Hips"),
		_ring(Vector3(0, 0.925, 0.005), 0.165, 0.101, "Hips", "Spine", 0.22),
		_ring(Vector3(0, 0.986, 0.007), 0.149, 0.097, "Hips", "Spine", 0.55),
		_ring(Vector3(0, 0.987, 0.007), 0.0, 0.0, "Spine"),
	], Vector3.UP, Vector3.RIGHT, 10, TROUSER_COLOR)
	_tube([
		_ring(Vector3(0, 0.930, 0.005), 0.0, 0.0, "Hips", "Spine", 0.22),
		_ring(Vector3(0, 0.931, 0.005), 0.175, 0.115, "Hips", "Spine", 0.22),
		_ring(Vector3(0, 1.001, 0.002), 0.175, 0.114, "Hips", "Spine", 0.48),
		_ring(Vector3(0, 1.095, -0.001), 0.160, 0.109, "Spine", "Chest", 0.21),
		_ring(Vector3(0, 1.233, -0.006), 0.196, 0.124, "Chest", "Spine", 0.24),
		_ring(Vector3(0, 1.316, 0), 0.207, 0.116, "Chest"),
		_ring(Vector3(0, 1.369, 0.005), 0.172, 0.092, "Chest"),
		_ring(Vector3(0, 1.401, -0.004), 0.075, 0.062, "Chest", "Neck", 0.24),
		_ring(Vector3(0, 1.402, -0.004), 0.0, 0.0, "Neck"),
	], Vector3.UP, Vector3.RIGHT, 12, shirt_color)
	_build_head()
	for side: float in [-1.0, 1.0]:
		var label := "Left" if side < 0.0 else "Right"
		_build_arm(side, label)
		_build_leg(side, label)

	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.92
	_surface.generate_normals()
	_surface.index()
	_surface.set_material(material)
	var visual := MeshInstance3D.new()
	visual.name = "ClothedBody"
	visual.mesh = _surface.commit()
	_surface.clear()
	visual.skin = skeleton.create_skin_from_rest_transforms()
	visual.skeleton = NodePath("../Skeleton3D")
	# The skinned bounds include limbs during locomotion and the head during idle.
	visual.custom_aabb = AABB(Vector3(-1.25, -0.55, -1.3), Vector3(2.5, 2.7, 2.6))
	add_child(visual)


func _build_head() -> void:
	_tube([
		_ring(Vector3(0, 1.365, -0.012), 0.049, 0.047, "Chest", "Neck", 0.60),
		_ring(Vector3(0, 1.412, -0.015), 0.052, 0.052, "Neck"),
		_ring(Vector3(0, 1.479, -0.012), 0.056, 0.055, "Neck", "Head", 0.56),
	], Vector3.UP, Vector3.RIGHT, 10, SKIN_TONE)
	_tube([
		_ring(Vector3(0, 1.443, -0.014), 0.0, 0.0, "Head"),
		_ring(Vector3(0, 1.463, -0.029), 0.054, 0.064, "Head"),
		_ring(Vector3(0, 1.499, -0.016), 0.076, 0.082, "Head"),
		_ring(Vector3(0, 1.550, -0.012), 0.090, 0.092, "Head"),
		_ring(Vector3(0, 1.606, -0.010), 0.085, 0.089, "Head"),
		_ring(Vector3(0, 1.654, 0.001), 0.059, 0.059, "Head"),
		_ring(Vector3(0, 1.670, 0.003), 0.0, 0.0, "Head"),
	], Vector3.UP, Vector3.RIGHT, 12, SKIN_TONE)
	_tube([
		_ring(Vector3(0, 1.551, 0.043), 0.073, 0.047, "Head"),
		_ring(Vector3(0, 1.591, 0.025), 0.092, 0.071, "Head"),
		_ring(Vector3(0, 1.623, -0.004), 0.086, 0.092, "Head"),
		_ring(Vector3(0, 1.660, -0.011), 0.073, 0.075, "Head"),
		_ring(Vector3(0, 1.690, 0.005), 0.038, 0.047, "Head"),
		_ring(Vector3(0.007, 1.697, 0.008), 0.0, 0.0, "Head"),
	], Vector3.UP, Vector3.RIGHT, 12, HAIR_COLOR)
	# Keep facial forms legible at chase-camera scale.
	_ellipsoid(Vector3(0, 1.540, -0.098), Vector3(0.020, 0.030, 0.023), "Head", SKIN_TONE)
	for side: float in [-1.0, 1.0]:
		_ellipsoid(Vector3(side * 0.087, 1.541, 0.000), Vector3(0.014, 0.031, 0.020), "Head", SKIN_TONE)
		_ellipsoid(Vector3(side * 0.036, 1.560, -0.094), Vector3(0.013, 0.006, 0.005), "Head", HAIR_COLOR)


func _build_arm(side: float, label: String) -> void:
	var upper := label + "UpperArm"
	var lower := label + "LowerArm"
	var hand := label + "Hand"
	var outward := Vector3(side, 0, 0)
	_tube([
		_ring(Vector3(side * 0.120, 1.345, 0), 0.0, 0.0, "Chest"),
		_ring(Vector3(side * 0.155, 1.339, 0), 0.069, 0.080, "Chest", upper, 0.20),
		_ring(Vector3(side * 0.207, 1.341, 0), 0.071, 0.072, upper, "Chest", 0.32),
		_ring(Vector3(side * 0.276, 1.348, 0), 0.066, 0.061, upper),
		_ring(Vector3(side * 0.314, 1.350, 0), 0.063, 0.058, upper),
		_ring(Vector3(side * 0.315, 1.350, 0), 0.0, 0.0, upper),
	], outward, Vector3.UP, 9, shirt_color)
	_tube([
		_ring(Vector3(side * 0.291, 1.350, 0), 0.0, 0.0, upper),
		_ring(Vector3(side * 0.310, 1.350, 0), 0.054, 0.051, upper),
		_ring(Vector3(side * 0.373, 1.350, 0.005), 0.052, 0.046, upper),
		_ring(Vector3(side * 0.448, 1.350, 0.004), 0.040, 0.038, upper, lower, 0.52),
		_ring(Vector3(side * 0.508, 1.350, 0.003), 0.045, 0.040, lower),
		_ring(Vector3(side * 0.603, 1.350, 0.001), 0.035, 0.031, lower),
		_ring(Vector3(side * 0.666, 1.350, 0.002), 0.027, 0.026, lower, hand, 0.56),
		_ring(Vector3(side * 0.668, 1.350, 0.002), 0.0, 0.0, hand),
	], outward, Vector3.UP, 8, SKIN_TONE)
	_tube([
		_ring(Vector3(side * 0.646, 1.350, 0.002), 0.0, 0.0, lower),
		_ring(Vector3(side * 0.665, 1.350, 0.003), 0.026, 0.026, hand, lower, 0.33),
		_ring(Vector3(side * 0.702, 1.350, -0.004), 0.026, 0.039, hand),
		_ring(Vector3(side * 0.741, 1.345, -0.005), 0.019, 0.034, hand),
		_ring(Vector3(side * 0.768, 1.341, -0.005), 0.0, 0.0, hand),
	], outward, Vector3.UP, 8, SKIN_TONE)
	_ellipsoid(Vector3(side * 0.703, 1.340, -0.036), Vector3(0.025, 0.019, 0.018), hand, SKIN_TONE)


func _build_leg(side: float, label: String) -> void:
	var upper := label + "UpperLeg"
	var lower := label + "LowerLeg"
	var foot := label + "Foot"
	var toes := label + "Toes"
	_tube([
		_ring(Vector3(side * 0.103, 0.092, 0.009), 0.0, 0.0, foot),
		_ring(Vector3(side * 0.103, 0.095, 0.009), 0.052, 0.061, lower, foot, 0.54),
		_ring(Vector3(side * 0.104, 0.180, 0.013), 0.054, 0.063, lower),
		_ring(Vector3(side * 0.104, 0.296, 0.012), 0.063, 0.071, lower),
		_ring(Vector3(side * 0.104, 0.410, -0.001), 0.058, 0.069, lower, upper, 0.15),
		_ring(Vector3(side * 0.102, 0.488, -0.016), 0.064, 0.068, lower, upper, 0.54),
		_ring(Vector3(side * 0.099, 0.599, -0.002), 0.080, 0.080, upper),
		_ring(Vector3(side * 0.097, 0.758, 0.009), 0.090, 0.096, upper),
		_ring(Vector3(side * 0.093, 0.855, 0.006), 0.093, 0.102, upper, "Hips", 0.35),
		_ring(Vector3(side * 0.088, 0.904, 0.006), 0.074, 0.093, upper, "Hips", 0.66),
		_ring(Vector3(side * 0.087, 0.914, 0.006), 0.0, 0.0, "Hips"),
	], Vector3.UP, Vector3.RIGHT, 10, TROUSER_COLOR)
	var x := side * 0.103
	_tube([
		_ring(Vector3(x, 0.042, 0.083), 0.0, 0.0, foot),
		_ring(Vector3(x, 0.063, 0.061), 0.046, 0.041, foot),
		_ring(Vector3(x, 0.059, 0.008), 0.054, 0.059, foot),
		_ring(Vector3(x, 0.045, -0.062), 0.057, 0.043, foot, toes, 0.28),
		_ring(Vector3(x, 0.037, -0.124), 0.058, 0.031, foot, toes, 0.62),
		_ring(Vector3(x, 0.030, -0.168), 0.047, 0.024, toes),
		_ring(Vector3(x, 0.029, -0.189), 0.0, 0.0, toes),
	], Vector3.FORWARD, Vector3.RIGHT, 10, SHOE_COLOR)
	_tube([
		_ring(Vector3(x, 0.016, 0.088), 0.0, 0.0, foot),
		_ring(Vector3(x, 0.017, 0.064), 0.047, 0.014, foot),
		_ring(Vector3(x, 0.016, 0.005), 0.056, 0.014, foot),
		_ring(Vector3(x, 0.016, -0.078), 0.058, 0.014, foot, toes, 0.38),
		_ring(Vector3(x, 0.016, -0.151), 0.059, 0.014, toes),
		_ring(Vector3(x, 0.017, -0.178), 0.047, 0.013, toes),
		_ring(Vector3(x, 0.018, -0.193), 0.0, 0.0, toes),
	], Vector3.FORWARD, Vector3.RIGHT, 10, SOLE_COLOR)


func _ring(point: Vector3, width: float, depth: float, primary: String, secondary := "", blend := 0.0) -> Ring:
	return Ring.new(point, Vector2(width, depth), _bone_ids[primary], _bone_ids.get(secondary, 0), blend)


func _ellipsoid(point: Vector3, size: Vector3, bone: String, color: Color) -> void:
	_tube([
		_ring(point - Vector3.UP * size.y, 0.0, 0.0, bone),
		_ring(point - Vector3.UP * size.y * 0.56, size.x * 0.78, size.z * 0.78, bone),
		_ring(point, size.x, size.z, bone),
		_ring(point + Vector3.UP * size.y * 0.56, size.x * 0.78, size.z * 0.78, bone),
		_ring(point + Vector3.UP * size.y, 0.0, 0.0, bone),
	], Vector3.UP, Vector3.RIGHT, 8, color)


func _tube(rings: Array[Ring], along: Vector3, across: Vector3, sides: int, color: Color) -> void:
	var depth_axis := across.cross(along)
	for row: int in range(rings.size() - 1):
		var a := rings[row]
		var b := rings[row + 1]
		for i: int in range(sides):
			var theta := TAU * float(i) / sides
			var next := TAU * float((i + 1) % sides) / sides
			if a.radii.x > 0.0:
				_vertex(a, theta, across, depth_axis, color)
				_vertex(a, next, across, depth_axis, color)
				_vertex(b, theta, across, depth_axis, color)
			if b.radii.x > 0.0:
				_vertex(a, next, across, depth_axis, color)
				_vertex(b, next, across, depth_axis, color)
				_vertex(b, theta, across, depth_axis, color)


func _vertex(ring: Ring, angle: float, across: Vector3, depth_axis: Vector3, color: Color) -> void:
	_surface.set_bones(ring.bones)
	_surface.set_weights(ring.weights)
	_surface.set_color(color)
	_surface.add_vertex(ring.center + across * (ring.radii.x * cos(angle)) + depth_axis * (ring.radii.y * sin(angle)))
