extends Node3D
## Original low-poly civilian, skinned to a reproducible humanoid rest pose.
## The driving and walking controllers own gameplay collision separately.

const OMKAR_SKIN := Color("a57556")
const MIRA_SKIN := Color("b78063")
const RAFIQ_SKIN := Color("966a51")
const HAIR_COLOR := Color("29252a")
const TROUSER_COLOR := Color("42474e")
const SHOE_COLOR := Color("3b3c3a")
const SOLE_COLOR := Color("8b8375")
const CHINO_COLOR := Color("a59373")
const CANVAS_COLOR := Color("4d5658")
const RUBBER_COLOR := Color("c1b6a0")
const SADARA_COLOR := Color("405675")
const SADARA_TRIM := Color("33455c")
const DHOTAR_COLOR := Color("e2d2b1")
const DHOTAR_PLEAT_COLOR := Color("cdbb94")
const DHOTAR_BORDER_COLOR := Color("98634c")
const DHOTAR_FOLDS := 0.10
const CHAPPAL_COLOR := Color("825836")

@export var shirt_color: Color = Color("447a75")
@export var wears_dhotar := false
@export var wears_overshirt := false

var skeleton := Skeleton3D.new()
var _bone_ids: Dictionary[String, int] = {}
var _joints: Dictionary[String, Vector3] = {}
var _surface := SurfaceTool.new()
var _skin := OMKAR_SKIN


class Ring:
	var center: Vector3
	var radii: Vector2
	var bones: PackedInt32Array
	var weights: PackedFloat32Array
	var thigh_blend := 0.0
	var nose_depth := 0.0
	var socket_depth := 0.0
	var hairline := Vector2.ZERO

	func _init(point: Vector3, size: Vector2, primary: int, secondary: int, blend: float) -> void:
		center = point
		radii = size
		bones = PackedInt32Array([primary, secondary, 0, 0])
		weights = PackedFloat32Array([1.0 - blend, blend, 0.0, 0.0])


func _ready() -> void:
	if not wears_dhotar:
		_skin = RAFIQ_SKIN if wears_overshirt else MIRA_SKIN
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
	var lower_color := CHINO_COLOR if wears_overshirt else TROUSER_COLOR
	if wears_dhotar:
		lower_color = DHOTAR_COLOR
	_tube([
		_ring(Vector3(0, 0.826, 0), 0.0, 0.0, "Hips"),
		_ring(Vector3(0, 0.861, 0.005), 0.144, 0.097, "Hips"),
		_ring(Vector3(0, 0.925, 0.005), 0.165, 0.101, "Hips", "Spine", 0.22),
		_ring(Vector3(0, 0.986, 0.007), 0.149, 0.097, "Hips", "Spine", 0.55),
		_ring(Vector3(0, 0.987, 0.007), 0.0, 0.0, "Spine"),
	], Vector3.UP, Vector3.RIGHT, 10, lower_color)
	_build_torso()
	if wears_dhotar:
		_build_dhotar_tucks()
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


func _build_torso() -> void:
	var top_color := SADARA_COLOR if wears_dhotar else shirt_color
	var sections: Array[Ring]
	if wears_dhotar:
		sections = [
			_sadara_hem_ring(0.790, 0.204, 0.157, 0.78),
			_sadara_hem_ring(0.786, 0.214, 0.166, 0.78),
			_sadara_hem_ring(0.854, 0.195, 0.144, 0.46),
			_sadara_hem_ring(0.918, 0.179, 0.123, 0.14),
		]
	elif wears_overshirt:
		sections = [
			_ring(Vector3(0, 0.890, 0.005), 0.178, 0.111, "Hips", "Spine", 0.12),
			_ring(Vector3(0, 0.889, 0.005), 0.192, 0.134, "Hips", "Spine", 0.12),
			_ring(Vector3(0, 0.924, 0.004), 0.187, 0.129, "Hips", "Spine", 0.22),
		]
	else:
		sections = [
			_ring(Vector3(0, 0.930, 0.005), 0.0, 0.0, "Hips", "Spine", 0.22),
			_ring(Vector3(0, 0.931, 0.005), 0.175, 0.115, "Hips", "Spine", 0.22),
		]
	sections.append_array([
		_ring(Vector3(0, 1.001, 0.002), 0.175, 0.114, "Hips", "Spine", 0.48),
		_ring(Vector3(0, 1.095, -0.001), 0.160, 0.109, "Spine", "Chest", 0.21),
		_ring(Vector3(0, 1.233, -0.006), 0.196, 0.124, "Chest", "Spine", 0.24),
		_ring(Vector3(0, 1.307, 0.001), 0.204, 0.118, "Chest"),
		_ring(Vector3(0, 1.350, 0.002), 0.189, 0.104, "Chest"),
		_ring(Vector3(0, 1.378, 0.004), 0.148, 0.083, "Chest"),
		_ring(Vector3(0, 1.401, -0.004), 0.075, 0.062, "Chest", "Neck", 0.24),
		_ring(Vector3(0, 1.402, -0.004), 0.0, 0.0, "Neck"),
	])
	var torso_folds := 0.026 if wears_dhotar or wears_overshirt else 0.014
	_tube(sections, Vector3.UP, Vector3.RIGHT, 16, top_color, torso_folds)
	if wears_dhotar:
		_build_sadara_details()
	elif wears_overshirt:
		_build_overshirt_details()


func _build_overshirt_details() -> void:
	var trim := shirt_color.darkened(0.16)
	_tube([
		_ring(Vector3(0.005, 0.893, -0.131), 0.010, 0.003, "Hips", "Spine", 0.13),
		_ring(Vector3(0.005, 0.924, -0.128), 0.011, 0.004, "Hips", "Spine", 0.22),
		_ring(Vector3(0.005, 1.001, -0.115), 0.011, 0.004, "Hips", "Spine", 0.48),
		_ring(Vector3(0.005, 1.095, -0.113), 0.011, 0.004, "Spine", "Chest", 0.21),
		_ring(Vector3(0.005, 1.233, -0.133), 0.011, 0.004, "Chest", "Spine", 0.24),
		_ring(Vector3(0.005, 1.316, -0.119), 0.011, 0.004, "Chest"),
		_ring(Vector3(0.005, 1.353, -0.100), 0.011, 0.004, "Chest"),
	], Vector3.UP, Vector3.RIGHT, 6, trim)
	for center: Vector3 in [Vector3(0.005, 1.321, -0.124), Vector3(0.005, 1.266, -0.136)]:
		var raised := center + Vector3.FORWARD * 0.002
		var top := center + Vector3.UP * 0.005
		var bottom := center + Vector3.DOWN * 0.005
		var left := center + Vector3.LEFT * 0.005
		var right := center + Vector3.RIGHT * 0.005
		_front_panel(top, left, raised, RUBBER_COLOR)
		_front_panel(left, bottom, raised, RUBBER_COLOR)
		_front_panel(bottom, right, raised, RUBBER_COLOR)
		_front_panel(right, top, raised, RUBBER_COLOR)

	# Keep the folded collar and sewn pocket in the skinned body surface.
	var collar := shirt_color.lightened(0.14)
	for side: float in [-1.0, 1.0]:
		var neck := Vector3(side * 0.042, 1.410, -0.064)
		var shoulder := Vector3(side * 0.089, 1.384, -0.081)
		var tip := Vector3(side * 0.078, 1.335, -0.102)
		var lapel := Vector3(side * 0.014, 1.359, -0.104)
		_front_panel(neck, shoulder, lapel, collar)
		_front_panel(lapel, shoulder, tip, collar)
	var pocket_outer := Vector3(-0.146, 1.275, -0.094)
	var pocket_inner := Vector3(-0.067, 1.276, -0.124)
	var pocket_lower := Vector3(-0.070, 1.209, -0.124)
	var pocket_corner := Vector3(-0.134, 1.213, -0.097)
	var pocket_color := shirt_color.lightened(0.10)
	_front_panel(pocket_outer, pocket_inner, pocket_lower, pocket_color)
	_front_panel(pocket_outer, pocket_lower, pocket_corner, pocket_color)


func _front_panel(a: Vector3, b: Vector3, c: Vector3, color: Color, is_face := false) -> void:
	var clockwise := (b - a).cross(c - a).z >= 0.0
	var points := [a, b, c] if clockwise else [a, c, b]
	for point: Vector3 in points:
		if is_face:
			_vertex(_ring(point, 0.0, 0.0, "Head"), 0.0, Vector3.RIGHT, Vector3.BACK, color, 0.0)
			continue
		var neck_weight := clampf((point.y - 1.37) / 0.04, 0.0, 0.45)
		_vertex(_ring(point, 0.0, 0.0, "Chest", "Neck", neck_weight),
			0.0, Vector3.RIGHT, Vector3.BACK, color, 0.0)


func _sadara_hem_ring(height: float, width: float, depth: float, thigh_blend: float) -> Ring:
	var section := _ring(Vector3(0, height, 0.005), width, depth, "Hips")
	section.thigh_blend = thigh_blend
	return section


func _build_sadara_details() -> void:
	# Raised band collar and narrow button placket over the woven tunic.
	_tube([
		_ring(Vector3(0, 1.393, -0.007), 0.072, 0.066, "Chest", "Neck", 0.24),
		_ring(Vector3(0, 1.409, -0.008), 0.065, 0.061, "Neck", "Chest", 0.28),
		_ring(Vector3(0, 1.430, -0.010), 0.057, 0.057, "Neck"),
		_ring(Vector3(0, 1.429, -0.010), 0.049, 0.049, "Neck"),
	], Vector3.UP, Vector3.RIGHT, 12, SADARA_TRIM)
	_tube([
		_ring(Vector3(0.008, 1.237, -0.133), 0.0, 0.0, "Chest", "Spine", 0.22),
		_ring(Vector3(0.008, 1.249, -0.130), 0.018, 0.004, "Chest", "Spine", 0.20),
		_ring(Vector3(0.008, 1.314, -0.117), 0.018, 0.004, "Chest"),
		_ring(Vector3(0.008, 1.367, -0.088), 0.019, 0.004, "Chest"),
		_ring(Vector3(0.008, 1.404, -0.070), 0.012, 0.004, "Chest", "Neck", 0.24),
	], Vector3.UP, Vector3.RIGHT, 8, SADARA_TRIM)
	_ellipsoid(Vector3(0.008, 1.260, -0.135), Vector3(0.006, 0.006, 0.003), "Chest", DHOTAR_COLOR)
	_ellipsoid(Vector3(0.008, 1.310, -0.121), Vector3(0.006, 0.006, 0.003), "Chest", DHOTAR_COLOR)
	_ellipsoid(Vector3(0.008, 1.359, -0.098), Vector3(0.006, 0.006, 0.003), "Chest", DHOTAR_COLOR)


func _build_dhotar_tucks() -> void:
	# The pleated apron and narrow rear tuck follow the thighs through a stride.
	var front_edge := _ring(Vector3(0.057, 0.397, -0.106), 0.060, 0.015, "RightUpperLeg", "RightLowerLeg", 0.72)
	var front_border := _ring(Vector3(0.055, 0.418, -0.122), 0.067, 0.021, "RightUpperLeg", "RightLowerLeg", 0.56)
	_tube([
		_ring(Vector3(0.057, 0.396, -0.106), 0.0, 0.0, "RightUpperLeg", "RightLowerLeg", 0.72),
		front_edge,
		front_border,
	], Vector3.UP, Vector3.RIGHT, 14, DHOTAR_BORDER_COLOR, DHOTAR_FOLDS)
	_tube([
		front_border,
		_ring(Vector3(0.049, 0.526, -0.132), 0.073, 0.038, "RightUpperLeg"),
		_ring(Vector3(-0.005, 0.675, -0.119), 0.087, 0.037, "RightUpperLeg", "Hips", 0.22),
		_ring(Vector3(0.018, 0.788, -0.089), 0.066, 0.021, "RightUpperLeg", "Hips", 0.66),
		_ring(Vector3(0.027, 0.876, -0.107), 0.022, 0.009, "Hips"),
	], Vector3.UP, Vector3.RIGHT, 14, DHOTAR_PLEAT_COLOR, DHOTAR_FOLDS, 8)
	_tube([
		_ring(Vector3(-0.075, 0.505, 0.053), 0.0, 0.0, "LeftUpperLeg"),
		_ring(Vector3(-0.058, 0.555, 0.074), 0.042, 0.015, "LeftUpperLeg"),
		_ring(Vector3(-0.029, 0.670, 0.094), 0.050, 0.022, "LeftUpperLeg", "Hips", 0.25),
		_ring(Vector3(-0.008, 0.780, 0.100), 0.044, 0.015, "LeftUpperLeg", "Hips", 0.66),
		_ring(Vector3(-0.009, 0.883, 0.111), 0.019, 0.008, "Hips"),
	], Vector3.UP, Vector3.RIGHT, 12, DHOTAR_PLEAT_COLOR, DHOTAR_FOLDS)


func _build_head() -> void:
	_tube([
		_ring(Vector3(0, 1.365, -0.012), 0.049, 0.047, "Chest", "Neck", 0.60),
		_ring(Vector3(0, 1.412, -0.015), 0.052, 0.052, "Neck"),
		_ring(Vector3(0, 1.474, -0.015), 0.055, 0.055, "Neck", "Head", 0.58),
	], Vector3.UP, Vector3.RIGHT, 12, _skin)
	var width := 1.04 if wears_overshirt else (1.0 if wears_dhotar else 0.94)
	_tube([
		_ring(Vector3(0, 1.443, -0.014), 0.0, 0.0, "Head"),
		_face_ring(1.462, -0.022, 0.047 * width, 0.060),
		_face_ring(1.482, -0.018, 0.061 * width, 0.071),
		_face_ring(1.506, -0.014, 0.070 * width, 0.080, 0.003),
		_face_ring(1.521, -0.016, 0.074 * width, 0.080, 0.007),
		_face_ring(1.535, -0.014, 0.080 * width, 0.086, 0.025),
		_face_ring(1.551, -0.014, 0.083 * width, 0.088, 0.022),
		_face_ring(1.568, -0.014, 0.084 * width, 0.086, 0.011, 0.006),
		_face_ring(1.587, -0.013, 0.083 * width, 0.089, 0.004),
		_face_ring(1.611, -0.008, 0.083 * width, 0.088),
		_face_ring(1.639, 0.001, 0.072 * width, 0.073),
		_face_ring(1.658, 0.003, 0.048 * width, 0.051),
		_face_ring(1.670, 0.003, 0.0, 0.0),
	], Vector3.UP, Vector3.RIGHT, 24, _skin)
	_build_scalp(width)
	_build_face_details(width)


func _face_ring(height: float, depth: float, width: float, radius: float, nose := 0.0, sockets := 0.0) -> Ring:
	var profile := _ring(Vector3(0.0, height, depth), width, radius, "Head")
	profile.nose_depth = nose
	profile.socket_depth = sockets
	return profile


func _build_scalp(width: float) -> void:
	var part := 0.013 if wears_dhotar else (-0.007 if wears_overshirt else -0.020)
	var crown := 0.0 if wears_dhotar else (-0.005 if wears_overshirt else 0.010)
	var hair := HAIR_COLOR.lightened(0.045) if wears_overshirt else HAIR_COLOR
	_tube([
		_scalp_ring(Vector3(0.0, 1.573, -0.008), Vector2(0.090 * width, 0.094), Vector2(0.037, part)),
		_scalp_ring(Vector3(0.0, 1.602, -0.009), Vector2(0.091 * width, 0.096), Vector2(0.024, part * 0.60)),
		_scalp_ring(Vector3(0.002, 1.633 + crown, -0.005), Vector2(0.089 * width, 0.089), Vector2(0.004, part * 0.38)),
		_scalp_ring(Vector3(part * 0.4, 1.658 + crown, 0.000), Vector2(0.064 * width, 0.069), Vector2(0.001, part * 0.16)),
		_ring(Vector3(part * 0.7, 1.676 + crown, 0.004), 0.034 * width, 0.040, "Head"),
		_ring(Vector3(part * 1.2, 1.682 + crown, 0.009), 0.0, 0.0, "Head"),
	], Vector3.UP, Vector3.RIGHT, 24, hair, 0.015)


func _scalp_ring(point: Vector3, radii: Vector2, hairline: Vector2) -> Ring:
	var profile := _ring(point, radii.x, radii.y, "Head")
	profile.hairline = hairline
	return profile


func _build_face_details(width: float) -> void:
	for side: float in [-1.0, 1.0]:
		_ellipsoid(Vector3(side * 0.081 * width, 1.550, -0.002), Vector3(0.011, 0.024, 0.015), "Head", _skin)
		_ellipsoid(Vector3(side * 0.087 * width, 1.549, -0.009), Vector3(0.004, 0.013, 0.006), "Head", _skin.darkened(0.15))
		_build_eye(side * width)
	var lip_color := _skin.darkened(0.26)
	var left := Vector3(-0.020 * width, 1.513, -0.094)
	var right := Vector3(0.023 * width, 1.512, -0.093)
	var lip_seam := Vector3(0.001, 1.511, -0.102)
	var upper_lip := Vector3(0.000, 1.515, -0.102)
	_front_panel(left, upper_lip, lip_seam, lip_color, true)
	_front_panel(lip_seam, upper_lip, right, lip_color, true)


func _build_eye(side: float) -> void:
	var inner := Vector3(side * 0.020, 1.567, -0.095)
	var outer := Vector3(side * 0.050, 1.568, -0.081)
	var upper := Vector3(side * 0.032, 1.574, -0.093)
	var lower := Vector3(side * 0.034, 1.563, -0.091)
	var corner := Vector3(side * 0.033, 1.569, -0.095)
	var eye_shade := Color("d8c4b3")
	_front_panel(inner, upper, corner, eye_shade, true)
	_front_panel(upper, outer, corner, eye_shade, true)
	_front_panel(outer, lower, corner, eye_shade, true)
	_front_panel(lower, inner, corner, eye_shade, true)
	_ellipsoid(Vector3(side * 0.033, 1.569, -0.095), Vector3(0.005, 0.0045, 0.0018), "Head", Color("473229"))
	var brow_inner := Vector3(side * 0.018, 1.586, -0.103)
	var brow_peak := Vector3(side * 0.032, 1.591, -0.097)
	var brow_outer := Vector3(side * 0.053, 1.584, -0.085)
	var brow_fold := Vector3(side * 0.031, 1.586, -0.099)
	_front_panel(brow_inner, brow_peak, brow_fold, HAIR_COLOR, true)
	_front_panel(brow_fold, brow_peak, brow_outer, HAIR_COLOR, true)


func _build_arm(side: float, label: String) -> void:
	var upper := label + "UpperArm"
	var lower := label + "LowerArm"
	var hand := label + "Hand"
	var outward := Vector3(side, 0, 0)
	if wears_dhotar:
		_build_sadara_sleeve(side, upper, lower)
	else:
		var sleeve := _sleeve_shoulder(side, upper)
		if wears_overshirt:
			var sleeve_edge := _ring(Vector3(side * 0.373, 1.350, 0.005), 0.064, 0.058, upper)
			sleeve.append(sleeve_edge)
			_tube(sleeve, outward, Vector3.UP, 12, shirt_color, 0.022)
			_tube([
				sleeve_edge,
				_ring(Vector3(side * 0.387, 1.350, 0.005), 0.064, 0.058, upper),
				_ring(Vector3(side * 0.387, 1.350, 0.005), 0.056, 0.052, upper),
			], outward, Vector3.UP, 12, shirt_color.darkened(0.09), 0.022)
		else:
			sleeve.append_array([
				_ring(Vector3(side * 0.314, 1.350, 0), 0.063, 0.058, upper),
				_ring(Vector3(side * 0.315, 1.350, 0), 0.0, 0.0, upper),
			])
			_tube(sleeve, outward, Vector3.UP, 12, shirt_color, 0.022)
	_tube([
		_ring(Vector3(side * 0.291, 1.350, 0), 0.0, 0.0, upper),
		_ring(Vector3(side * 0.310, 1.350, 0), 0.054, 0.051, upper),
		_ring(Vector3(side * 0.373, 1.350, 0.005), 0.052, 0.046, upper),
		_ring(Vector3(side * 0.448, 1.350, 0.004), 0.040, 0.038, upper, lower, 0.52),
		_ring(Vector3(side * 0.508, 1.350, 0.003), 0.045, 0.040, lower),
		_ring(Vector3(side * 0.603, 1.350, 0.001), 0.035, 0.031, lower),
		_ring(Vector3(side * 0.666, 1.350, 0.002), 0.027, 0.026, lower, hand, 0.56),
		_ring(Vector3(side * 0.668, 1.350, 0.002), 0.0, 0.0, hand),
	], outward, Vector3.UP, 8, _skin)
	_tube([
		_ring(Vector3(side * 0.646, 1.350, 0.002), 0.0, 0.0, lower),
		_ring(Vector3(side * 0.665, 1.350, 0.003), 0.026, 0.026, hand, lower, 0.33),
		_ring(Vector3(side * 0.702, 1.350, -0.004), 0.026, 0.039, hand),
		_ring(Vector3(side * 0.741, 1.345, -0.005), 0.019, 0.034, hand),
		_ring(Vector3(side * 0.768, 1.341, -0.005), 0.0, 0.0, hand),
	], outward, Vector3.UP, 8, _skin)
	_ellipsoid(Vector3(side * 0.701, 1.339, -0.031), Vector3(0.025, 0.015, 0.014), hand, _skin)


func _build_sadara_sleeve(side: float, upper: String, lower: String) -> void:
	var outward := Vector3(side, 0, 0)
	var cuff_start := _ring(Vector3(side * 0.605, 1.350, 0.001), 0.041, 0.037, lower)
	var sleeve := _sleeve_shoulder(side, upper)
	sleeve.append_array([
		_ring(Vector3(side * 0.333, 1.350, 0.002), 0.064, 0.061, upper),
		_ring(Vector3(side * 0.426, 1.350, 0.004), 0.054, 0.053, upper, lower, 0.22),
		_ring(Vector3(side * 0.461, 1.350, 0.004), 0.055, 0.051, upper, lower, 0.54),
		_ring(Vector3(side * 0.510, 1.350, 0.003), 0.054, 0.049, lower),
		cuff_start,
	])
	_tube(sleeve, outward, Vector3.UP, 12, SADARA_COLOR, 0.023)
	_tube([
		cuff_start,
		_ring(Vector3(side * 0.628, 1.350, 0.001), 0.039, 0.036, lower),
		_ring(Vector3(side * 0.629, 1.350, 0.001), 0.033, 0.030, lower),
	], outward, Vector3.UP, 12, SADARA_TRIM, 0.023)


func _sleeve_shoulder(side: float, upper: String) -> Array[Ring]:
	# Bury the inner cap in the chest and transfer its weights across the deltoid.
	return [
		_ring(Vector3(side * 0.113, 1.332, 0.001), 0.0, 0.0, "Chest"),
		_ring(Vector3(side * 0.155, 1.330, 0.001), 0.042, 0.068, "Chest", upper, 0.20),
		_ring(Vector3(side * 0.194, 1.331, 0.004), 0.051, 0.073, "Chest", upper, 0.55),
		_ring(Vector3(side * 0.230, 1.338, 0.005), 0.062, 0.071, upper, "Chest", 0.15),
		_ring(Vector3(side * 0.274, 1.348, 0.004), 0.065, 0.063, upper),
	]


func _build_leg(side: float, label: String) -> void:
	var upper := label + "UpperLeg"
	var lower := label + "LowerLeg"
	var foot := label + "Foot"
	var toes := label + "Toes"
	if wears_dhotar:
		_build_dhotar_leg(side, upper, lower, foot)
	else:
		_build_trouser_leg(side, upper, lower, foot)
	_build_footwear(side, foot, toes)


func _build_trouser_leg(side: float, upper: String, lower: String, foot: String) -> void:
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
	], Vector3.UP, Vector3.RIGHT, 12, CHINO_COLOR if wears_overshirt else TROUSER_COLOR, 0.028)


func _build_dhotar_leg(side: float, upper: String, lower: String, foot: String) -> void:
	# Short work drape with visible calf and a narrow woven edge near each cuff.
	var drape_width := 0.085 + side * 0.004
	var drape_hem := _ring(Vector3(side * 0.107, 0.241 + side * 0.017, 0.012), drape_width, 0.075, lower)
	var drape_border := _ring(Vector3(side * 0.105, 0.260 + side * 0.017, 0.009), drape_width + 0.004, 0.078, lower)
	_tube([
		_ring(Vector3(side * 0.103, 0.075, 0.006), 0.040, 0.047, lower, foot, 0.65),
		_ring(Vector3(side * 0.103, 0.112, 0.009), 0.040, 0.041, lower, foot, 0.22),
		_ring(Vector3(side * 0.104, 0.190, 0.010), 0.045, 0.046, lower),
		_ring(Vector3(side * 0.104, 0.296, 0.011), 0.053, 0.054, lower),
	], Vector3.UP, Vector3.RIGHT, 10, _skin)
	_tube([
		_ring(drape_hem.center + Vector3.UP * 0.002, 0.053, 0.054, lower),
		drape_hem,
		drape_border,
	], Vector3.UP, Vector3.RIGHT, 16, DHOTAR_BORDER_COLOR, DHOTAR_FOLDS)
	_tube([
		drape_border,
		_ring(Vector3(side * 0.106, 0.322, 0.011), 0.079, 0.079, lower),
		_ring(Vector3(side * 0.103, 0.419, -0.002), 0.077, 0.083, lower, upper, 0.19),
		_ring(Vector3(side * 0.104, 0.489, -0.016), 0.082, 0.084, lower, upper, 0.53),
		_ring(Vector3(side * 0.104, 0.610, -0.001), 0.093, 0.091, upper),
		_ring(Vector3(side * 0.097, 0.747, 0.010), 0.096, 0.099, upper),
		_ring(Vector3(side * 0.088, 0.856, 0.007), 0.065, 0.075, upper, "Hips", 0.36),
		_ring(Vector3(side * 0.084, 0.904, 0.007), 0.059, 0.066, upper, "Hips", 0.65),
		_ring(Vector3(side * 0.087, 0.914, 0.006), 0.0, 0.0, "Hips"),
	], Vector3.UP, Vector3.RIGHT, 16, DHOTAR_COLOR, DHOTAR_FOLDS)


func _build_footwear(side: float, foot: String, toes: String) -> void:
	var x := side * 0.103
	var foot_color := _skin if wears_dhotar else SHOE_COLOR
	var sole_color := CHAPPAL_COLOR.darkened(0.20) if wears_dhotar else SOLE_COLOR
	if wears_overshirt and not wears_dhotar:
		foot_color = CANVAS_COLOR
		sole_color = RUBBER_COLOR
	_tube([
		_ring(Vector3(x, 0.042, 0.083), 0.0, 0.0, foot),
		_ring(Vector3(x, 0.063, 0.061), 0.046, 0.041, foot),
		_ring(Vector3(x, 0.059, 0.008), 0.054, 0.059, foot),
		_ring(Vector3(x, 0.045, -0.062), 0.057, 0.043, foot, toes, 0.28),
		_ring(Vector3(x, 0.037, -0.124), 0.058, 0.031, foot, toes, 0.62),
		_ring(Vector3(x, 0.030, -0.168), 0.047, 0.024, toes),
		_ring(Vector3(x, 0.029, -0.189), 0.0, 0.0, toes),
	], Vector3.FORWARD, Vector3.RIGHT, 10, foot_color)
	_tube([
		_ring(Vector3(x, 0.016, 0.088), 0.0, 0.0, foot),
		_ring(Vector3(x, 0.017, 0.064), 0.047, 0.014, foot),
		_ring(Vector3(x, 0.016, 0.005), 0.056, 0.014, foot),
		_ring(Vector3(x, 0.016, -0.078), 0.058, 0.014, foot, toes, 0.38),
		_ring(Vector3(x, 0.016, -0.151), 0.059, 0.014, toes),
		_ring(Vector3(x, 0.017, -0.178), 0.047, 0.013, toes),
		_ring(Vector3(x, 0.018, -0.193), 0.0, 0.0, toes),
	], Vector3.FORWARD, Vector3.RIGHT, 10, sole_color)
	if wears_dhotar:
		# Open leather vamp with a separate loop around the big toe.
		_tube([
			_ring(Vector3(x, 0.045, -0.067), 0.059, 0.045, foot, toes, 0.31),
			_ring(Vector3(x, 0.043, -0.083), 0.060, 0.041, foot, toes, 0.40),
			_ring(Vector3(x, 0.041, -0.111), 0.059, 0.038, foot, toes, 0.53),
		], Vector3.FORWARD, Vector3.RIGHT, 10, CHAPPAL_COLOR)
		_ellipsoid(Vector3(x - side * 0.028, 0.056, -0.146), Vector3(0.014, 0.009, 0.019), toes, CHAPPAL_COLOR)


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


func _tube(rings: Array[Ring], along: Vector3, across: Vector3, sides: int, color: Color,
		folds := 0.0, border_sector := -1) -> void:
	var depth_axis := across.cross(along)
	for row: int in range(rings.size() - 1):
		var a := rings[row]
		var b := rings[row + 1]
		for i: int in range(sides):
			var theta := TAU * float(i) / sides
			var next := TAU * float((i + 1) % sides) / sides
			var cloth_color := DHOTAR_BORDER_COLOR if i == border_sector else color
			if a.radii.x > 0.0:
				_vertex(a, theta, across, depth_axis, cloth_color, folds)
				_vertex(a, next, across, depth_axis, cloth_color, folds)
				_vertex(b, theta, across, depth_axis, cloth_color, folds)
			if b.radii.x > 0.0:
				_vertex(a, next, across, depth_axis, cloth_color, folds)
				_vertex(b, next, across, depth_axis, cloth_color, folds)
				_vertex(b, theta, across, depth_axis, cloth_color, folds)


func _vertex(ring: Ring, angle: float, across: Vector3, depth_axis: Vector3, color: Color,
		folds: float) -> void:
	var radial := across * (ring.radii.x * cos(angle)) + depth_axis * (ring.radii.y * sin(angle))
	if folds > 0.0:
		var crease := 0.66 * cos(angle * 5.0) + 0.34 * cos(angle * 7.0 + 0.5)
		radial *= 1.0 + folds * crease
		color = color.darkened(maxf(0.0, -crease) * folds * 0.65)
	if ring.nose_depth > 0.0 or ring.socket_depth > 0.0:
		var front := maxf(0.0, -sin(angle))
		var socket := clampf(1.0 - absf(absf(cos(angle)) - 0.42) / 0.33, 0.0, 1.0)
		radial += depth_axis * (ring.socket_depth * socket * front - ring.nose_depth * pow(front, 30.0))
	if ring.hairline != Vector2.ZERO:
		var forward := -sin(angle)
		radial.y += ring.hairline.x * forward + ring.hairline.y * cos(angle) * (0.62 + forward * 0.38)
	if ring.thigh_blend > 0.0:
		# The side of the hem follows its leg. The front and back share both legs.
		var right := 0.5 + 0.5 * cos(angle)
		_surface.set_bones(PackedInt32Array([
			_bone_ids["Hips"], _bone_ids["LeftUpperLeg"], _bone_ids["RightUpperLeg"], 0,
		]))
		_surface.set_weights(PackedFloat32Array([
			1.0 - ring.thigh_blend, (1.0 - right) * ring.thigh_blend, right * ring.thigh_blend, 0.0,
		]))
	else:
		_surface.set_bones(ring.bones)
		_surface.set_weights(ring.weights)
	_surface.set_color(color)
	_surface.add_vertex(ring.center + radial)
