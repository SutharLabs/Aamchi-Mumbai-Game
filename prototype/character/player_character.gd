extends Node3D
## Textured civilian, skinned to a reproducible humanoid rest pose.
## The driving and walking controllers own gameplay collision separately.

const OMKAR_SKIN := Color("966b53")
const MIRA_SKIN := Color("b78063")
const RAFIQ_SKIN := Color("966a51")
const TROUSER_COLOR := Color("42474e")
const SHOE_COLOR := Color("3b3c3a")
const SOLE_COLOR := Color("8b8375")
const CHINO_COLOR := Color("a59373")
const CANVAS_COLOR := Color("4d5658")
const RUBBER_COLOR := Color("c1b6a0")
const SADARA_COLOR := Color("394d63")
const SADARA_TRIM := Color("344558")
const DHOTAR_COLOR := Color("c9bba0")
const DHOTAR_PLEAT_COLOR := Color("bfb096")
const DHOTAR_BORDER_COLOR := Color("80624f")
const DHOTAR_FOLDS := 0.085
const CHAPPAL_COLOR := Color("65482f")
const OMKAR_TORSO_SIDES := 24
const OMKAR_TORSO_FOLDS := 0.034
const ARMHOLE_BOTTOM := 7
const ARMHOLE_TOP := 9
const ARMHOLE_HALF_ARC := 3
const OmkarHand := preload("res://character/omkar_hand.gd")
const HEAD_GEOMETRY: ArrayMesh = preload("res://character/art/head_mesh.obj")
const BODY_ALBEDO := preload("res://character/art/civilian_surface.png")
const BODY_NORMAL := preload("res://character/art/civilian_normal.png")
const OMKAR_ALBEDO := preload("res://character/art/omkar_surface.png")
const OMKAR_NORMAL := preload("res://character/art/omkar_normal.png")
const OMKAR_ROUGHNESS := preload("res://character/art/omkar_roughness.png")
const OMKAR_SCAN_HEAD: ArrayMesh = preload("res://character/art/omkar_scan_head.obj")
const OMKAR_SCAN_ALBEDO := preload("res://character/art/omkar_scan_surface.png")
const OMKAR_SCAN_NORMAL := preload("res://character/art/omkar_scan_normal.png")
const OMKAR_SCAN_ROUGHNESS := preload("res://character/art/omkar_scan_roughness.png")
const ATLAS_SIZE := 1024.0
const HEAD_ATLAS_EDGE := Vector2(8.5, 512.5)
const HEAD_ATLAS_SPAN := 503.0
const EYE_WHITE := Color("8e8580")
const LIMBAL_RING := Color("362c28")
const IRIS := Color("5c4735")
const PUPIL := Color("211b1a")
const CAST_SKIN: Array[Color] = [Color("ad775a"), Color("a86d52"), Color("bd886b")]

@export var shirt_color: Color = Color("447a75")
@export var wears_dhotar := false
@export var wears_overshirt := false
@export var wears_kurta_with_dupatta := false
@export_enum("Side part", "Braid", "Bob") var kurta_hair_style: int = 0
@export_enum("Automatic", "Ravi", "Kavita") var face_variant := "Automatic"

var avatar_options: Dictionary = {}
var skeleton := Skeleton3D.new()
var _bone_ids: Dictionary[String, int] = {}
var _joints: Dictionary[String, Vector3] = {}
var _surface := SurfaceTool.new()
var _skin := OMKAR_SKIN
var _omkar_style := false
var _avatar_gender := ""
var _avatar_hair := ""
var _avatar_outfit := ""
var _avatar_trousers := TROUSER_COLOR
static var _avatar_neck_edges: Array[Vector2i] = []
static var _avatar_neck_albedo := PackedColorArray()
static var _avatar_neck_profile: Dictionary[Vector3, Vector3] = {}
static var _body_material: StandardMaterial3D
static var _omkar_material: StandardMaterial3D
static var _omkar_scan_material: StandardMaterial3D


class Ring:
	var center: Vector3
	var radii: Vector2
	var bones: PackedInt32Array
	var weights: PackedFloat32Array
	var thigh_blend := 0.0
	var crease_offset := 0.0

	func _init(point: Vector3, size: Vector2, primary: int, secondary: int, blend: float) -> void:
		center = point
		radii = size
		bones = PackedInt32Array([primary, secondary, 0, 0])
		weights = PackedFloat32Array([1.0 - blend, blend, 0.0, 0.0])


func _ready() -> void:
	if not avatar_options.is_empty():
		_apply_avatar_options()
	_omkar_style = wears_dhotar and face_variant == "Automatic"
	if not wears_dhotar:
		_skin = RAFIQ_SKIN if wears_overshirt else MIRA_SKIN
	if wears_kurta_with_dupatta:
		_skin = CAST_SKIN[clampi(kurta_hair_style, 0, CAST_SKIN.size() - 1)]
	match face_variant:
		"Ravi":
			_skin = Color("a16b52")
		"Kavita":
			_skin = Color("b57d5f")
	if not _avatar_gender.is_empty():
		_skin = Color("ac765b") if _avatar_gender == "woman" else Color("9f6d54")
	skeleton.name = "Skeleton3D"
	add_child(skeleton)
	_build_rig()
	_build_body()


func _apply_avatar_options() -> void:
	_avatar_gender = "woman" if avatar_options.get("gender") == "woman" else "man"
	_avatar_hair = str(avatar_options.get("hair", "bun" if _avatar_gender == "woman" else "crop"))
	_avatar_outfit = str(avatar_options.get("outfit", "traditional"))
	wears_dhotar = _avatar_gender == "man" and _avatar_outfit == "traditional"
	wears_kurta_with_dupatta = false
	wears_overshirt = false
	face_variant = "Automatic"
	match _avatar_outfit:
		"casual":
			shirt_color = Color("4b7474") if _avatar_gender == "woman" else Color("596481")
			_avatar_trousers = Color("383f4c") if _avatar_gender == "woman" else Color("8c7b65")
		"kurta":
			shirt_color = Color("a65a72") if _avatar_gender == "woman" else Color("687750")
			_avatar_trousers = Color("d5c6ab")
		_:
			shirt_color = Color("496847") if _avatar_gender == "woman" else SADARA_COLOR
			_avatar_trousers = Color("783f4c")


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
	if not _avatar_gender.is_empty():
		lower_color = _avatar_trousers
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

	if _body_material == null:
		_body_material = StandardMaterial3D.new()
		_body_material.vertex_color_use_as_albedo = true
		_body_material.vertex_color_is_srgb = true
		_body_material.albedo_texture = BODY_ALBEDO
		_body_material.normal_enabled = true
		_body_material.normal_texture = BODY_NORMAL
		_body_material.normal_scale = 0.40
		_body_material.roughness = 0.88
		_body_material.metallic_specular = 0.27
		_body_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var use_hero_material := _omkar_style or not _avatar_gender.is_empty()
	if use_hero_material and _omkar_material == null:
		_omkar_material = _body_material.duplicate() as StandardMaterial3D
		_omkar_material.resource_name = "OmkarCottonAndSkin"
		_omkar_material.albedo_texture = OMKAR_ALBEDO
		_omkar_material.normal_texture = OMKAR_NORMAL
		_omkar_material.roughness = 1.0
		_omkar_material.roughness_texture = OMKAR_ROUGHNESS
		_omkar_material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	var material := _omkar_material if use_hero_material else _body_material
	if _omkar_style and _avatar_gender.is_empty():
		if _omkar_scan_material == null:
			_omkar_scan_material = _omkar_material.duplicate() as StandardMaterial3D
			_omkar_scan_material.resource_name = "OmkarScanAndCotton"
			_omkar_scan_material.albedo_texture = OMKAR_SCAN_ALBEDO
			_omkar_scan_material.normal_texture = OMKAR_SCAN_NORMAL
			_omkar_scan_material.roughness_texture = OMKAR_SCAN_ROUGHNESS
		material = _omkar_scan_material
	_surface.generate_normals()
	_surface.index()
	_surface.generate_tangents()
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
	if wears_kurta_with_dupatta:
		_build_kurta_torso()
		return
	if _omkar_style:
		_build_omkar_torso()
		return
	if not _avatar_gender.is_empty():
		_build_avatar_torso()
		return
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
		_ring(Vector3(0, 1.307, 0.001), 0.193, 0.113, "Chest"),
		_ring(Vector3(0, 1.343, 0.002), 0.177, 0.100, "Chest"),
		_ring(Vector3(0, 1.376, 0.004), 0.134, 0.080, "Chest"),
		_ring(Vector3(0, 1.401, -0.004), 0.075, 0.062, "Chest", "Neck", 0.24),
		_ring(Vector3(0, 1.402, -0.004), 0.0, 0.0, "Neck"),
	])
	var torso_folds := 0.026 if wears_dhotar or wears_overshirt else 0.014
	_tube(sections, Vector3.UP, Vector3.RIGHT, 16, top_color, torso_folds)
	if wears_dhotar:
		_build_sadara_details()
	elif wears_overshirt:
		_build_overshirt_details()


func _build_omkar_torso() -> void:
	# A close-fitting cotton top broadens at the chest and hangs clear of the wrapped waist.
	var hem := _sadara_hem_ring(0.814, 0.181, 0.143, 0.79)
	hem.crease_offset = -0.12
	var lower := _sadara_hem_ring(0.850, 0.183, 0.130, 0.52)
	lower.crease_offset = -0.05
	var waist := _sadara_hem_ring(0.914, 0.167, 0.111, 0.19)
	waist.crease_offset = 0.09
	var sections: Array[Ring] = [
		_sadara_hem_ring(0.819, 0.173, 0.133, 0.79), hem, lower, waist,
		_ring(Vector3(0, 0.989, 0.005), 0.163, 0.102, "Hips", "Spine", 0.48),
		_ring(Vector3(0, 1.080, 0.005), 0.151, 0.100, "Spine", "Chest", 0.18),
		_ring(Vector3(0, 1.174, 0.002), 0.167, 0.107, "Spine", "Chest", 0.65),
		_ring(Vector3(0, 1.243, -0.004), 0.178, 0.111, "Chest"),
		_ring(Vector3(0, 1.304, 0.001), 0.179, 0.106, "Chest"),
		_ring(Vector3(0, 1.342, 0.001), 0.172, 0.096, "Chest"),
		_ring(Vector3(0, 1.374, 0.004), 0.125, 0.075, "Chest"),
		_ring(Vector3(0, 1.401, -0.004), 0.069, 0.060, "Chest", "Neck", 0.24),
		_ring(Vector3(0, 1.402, -0.004), 0.0, 0.0, "Neck"),
	]
	_tube(sections, Vector3.UP, Vector3.RIGHT, OMKAR_TORSO_SIDES, SADARA_COLOR, OMKAR_TORSO_FOLDS, -1, true, true, true)
	_build_omkar_sleeve(-1.0, "LeftUpperArm", "LeftLowerArm", sections)
	_build_omkar_sleeve(1.0, "RightUpperArm", "RightLowerArm", sections)
	_build_sadara_details()

	# A gently curved back yoke follows the chest ring rather than spanning it as a flat strip.
	for section in range(8):
		var left := _omkar_yoke_point(lerpf(-0.144, 0.144, section / 8.0))
		var right := _omkar_yoke_point(lerpf(-0.144, 0.144, (section + 1) / 8.0))
		var seam := Vector3.UP * 0.0026
		for point: Vector3 in [left, left + seam, right, right, left + seam, right + seam]:
			_vertex(_ring(point, 0.0, 0.0, "Chest"), 0.0, Vector3.RIGHT, Vector3.BACK,
				SADARA_COLOR.darkened(0.21), 0.0, false)


func _omkar_yoke_point(x: float) -> Vector3:
	var chest_curve := sqrt(1.0 - pow(x / 0.179, 2.0))
	return Vector3(x, 1.301 - absf(x) * 0.045, 0.004 + 0.110 * chest_curve)


func _build_avatar_torso() -> void:
	var feminine := _avatar_gender == "woman"
	var casual := _avatar_outfit == "casual"
	var hem := 0.907 if casual else 0.728
	var hem_width := 0.185 if casual else 0.211
	var hem_depth := 0.131 if casual else 0.157
	var waist := 0.142 if feminine else 0.158
	var chest := 0.167 if feminine else 0.181
	var shoulder := 0.149 if feminine else 0.167
	var chest_depth := 0.119 if feminine else 0.109
	var trim := shirt_color.darkened(0.19)
	var sections: Array[Ring] = [
		_sadara_hem_ring(hem + 0.006, hem_width - 0.009, hem_depth - 0.010, 0.60),
		_sadara_hem_ring(hem, hem_width, hem_depth, 0.60),
		_sadara_hem_ring(lerpf(hem, 0.976, 0.30), hem_width + 0.001, hem_depth - 0.002, 0.46),
		_sadara_hem_ring(lerpf(hem, 0.976, 0.67), hem_width - 0.008, hem_depth - 0.012, 0.24),
		_ring(Vector3(0, 0.986, 0.005), waist + 0.019, 0.108, "Hips", "Spine", 0.46),
		_ring(Vector3(0, 1.081, 0.005), waist, 0.101, "Spine", "Chest", 0.18),
		_ring(Vector3(0, 1.166, 0.004), waist + 0.011, 0.109, "Spine", "Chest", 0.58),
		_ring(Vector3(0, 1.243, -0.007), chest, chest_depth, "Chest"),
		_ring(Vector3(0, 1.304, 0.001), chest, 0.104, "Chest"),
		_ring(Vector3(0, 1.342, 0.001), shoulder, 0.095, "Chest"),
		_ring(Vector3(0, 1.374, 0.003), 0.121, 0.075, "Chest"),
		_ring(Vector3(0, 1.399, -0.004), 0.066, 0.059, "Chest", "Neck", 0.25),
		_ring(Vector3(0, 1.402, -0.004), 0.0, 0.0, "Neck"),
	]
	_tube(sections, Vector3.UP, Vector3.RIGHT, OMKAR_TORSO_SIDES, shirt_color, OMKAR_TORSO_FOLDS, -1, true, true)
	_build_omkar_sleeve(-1.0, "LeftUpperArm", "LeftLowerArm", sections, shirt_color, casual)
	_build_omkar_sleeve(1.0, "RightUpperArm", "RightLowerArm", sections, shirt_color, casual)
	_tube([
		_ring(Vector3(0, 1.393, -0.007), 0.071, 0.064, "Chest", "Neck", 0.24),
		_ring(Vector3(0, 1.405, -0.009), 0.064, 0.059, "Neck", "Chest", 0.29),
		_ring(Vector3(0, 1.413 if casual else 1.424, -0.010), 0.055, 0.055, "Neck"),
		_ring(Vector3(0, 1.412 if casual else 1.423, -0.010), 0.049, 0.049, "Neck"),
	], Vector3.UP, Vector3.RIGHT, 12, trim)
	_tube([
		_ring(Vector3(0.002, 1.220, -chest_depth - 0.009), 0.0, 0.0, "Chest"),
		_ring(Vector3(0.002, 1.247, -chest_depth - 0.012), 0.014, 0.003, "Chest"),
		_ring(Vector3(0.002, 1.306, -0.109), 0.013, 0.003, "Chest"),
		_ring(Vector3(0.002, 1.356, -0.091), 0.012, 0.003, "Chest"),
		_ring(Vector3(0.002, 1.399, -0.071), 0.008, 0.003, "Chest", "Neck", 0.24),
	], Vector3.UP, Vector3.RIGHT, 8, trim)
	if feminine and _avatar_outfit == "traditional":
		_build_dupatta()


func _build_kurta_torso() -> void:
	# Fitted woven kurta over trousers, with a soft hem weighted to both thighs.
	_tube([
		_sadara_hem_ring(0.708, 0.199, 0.146, 0.80),
		_sadara_hem_ring(0.724, 0.201, 0.152, 0.77),
		_sadara_hem_ring(0.840, 0.194, 0.142, 0.46),
		_sadara_hem_ring(0.933, 0.183, 0.126, 0.14),
		_ring(Vector3(0, 1.061, 0.003), 0.148, 0.111, "Spine", "Hips", 0.20),
		_ring(Vector3(0, 1.168, -0.007), 0.168, 0.118, "Spine", "Chest", 0.55),
		_ring(Vector3(0, 1.249, -0.017), 0.173, 0.133, "Chest"),
		_ring(Vector3(0, 1.318, -0.001), 0.166, 0.102, "Chest"),
		_ring(Vector3(0, 1.362, 0.004), 0.127, 0.078, "Chest"),
		_ring(Vector3(0, 1.398, -0.005), 0.071, 0.060, "Chest", "Neck", 0.38),
		_ring(Vector3(0, 1.404, -0.005), 0.0, 0.0, "Neck"),
	], Vector3.UP, Vector3.RIGHT, 16, shirt_color, 0.027)
	_build_dupatta()


func _build_dupatta() -> void:
	# A lighter dupatta crosses the chest and falls behind the same shoulder.
	var scarf := shirt_color.lerp(Color("e5c995"), 0.62)
	var folds := [
		[Vector3(-0.140, 1.356, -0.088), Vector3(-0.055, 1.400, -0.067)],
		[Vector3(-0.122, 1.277, -0.132), Vector3(-0.040, 1.323, -0.139)],
		[Vector3(-0.056, 1.223, -0.151), Vector3(0.018, 1.254, -0.158)],
		[Vector3(0.032, 1.183, -0.146), Vector3(0.112, 1.232, -0.135)],
		[Vector3(0.103, 1.211, -0.126), Vector3(0.155, 1.282, -0.096)],
	]
	for index in range(folds.size() - 1):
		var edge: Array = folds[index]
		var next_edge: Array = folds[index + 1]
		_front_panel(edge[0], next_edge[0], edge[1], scarf.darkened(0.06))
		_front_panel(edge[1], next_edge[0], next_edge[1], scarf)
	_tube([
		_ring(Vector3(-0.111, 1.152, 0.093), 0.045, 0.013, "Chest"),
		_ring(Vector3(-0.114, 1.243, 0.101), 0.052, 0.018, "Chest"),
		_ring(Vector3(-0.107, 1.338, 0.082), 0.053, 0.013, "Chest"),
		_ring(Vector3(-0.092, 1.401, 0.005), 0.047, 0.075, "Chest", "Neck", 0.18),
		_ring(Vector3(-0.088, 1.393, -0.022), 0.035, 0.042, "Chest", "Neck", 0.20),
	], Vector3.UP, Vector3.RIGHT, 10, scarf, 0.045)


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


func _front_panel(a: Vector3, b: Vector3, c: Vector3, color: Color, fabric := false) -> void:
	var clockwise := (b - a).cross(c - a).z >= 0.0
	var points := [a, b, c] if clockwise else [a, c, b]
	for point: Vector3 in points:
		var neck_weight := clampf((point.y - 1.37) / 0.04, 0.0, 0.45)
		_vertex(_ring(point, 0.0, 0.0, "Chest", "Neck", neck_weight),
			0.0, Vector3.RIGHT, Vector3.BACK, color, 0.0, fabric)


func _sadara_hem_ring(height: float, width: float, depth: float, thigh_blend: float) -> Ring:
	var section := _ring(Vector3(0, height, 0.005), width, depth, "Hips")
	section.thigh_blend = thigh_blend
	return section


func _build_sadara_details() -> void:
	# Raised band collar and narrow button placket over the woven tunic.
	_tube([
		_ring(Vector3(0, 1.393, -0.007), 0.072, 0.066, "Chest", "Neck", 0.24),
		_ring(Vector3(0, 1.409, -0.008), 0.065, 0.061, "Neck", "Chest", 0.28),
		_ring(Vector3(0, 1.424, -0.010), 0.055, 0.055, "Neck"),
		_ring(Vector3(0, 1.422, -0.010), 0.049, 0.049, "Neck"),
	], Vector3.UP, Vector3.RIGHT, 12, SADARA_TRIM)
	_tube([
		_ring(Vector3(0.004, 1.237, -0.118), 0.0, 0.0, "Chest"),
		_ring(Vector3(0.004, 1.248, -0.117), 0.012, 0.003, "Chest"),
		_ring(Vector3(0.004, 1.302, -0.109), 0.012, 0.003, "Chest"),
		_ring(Vector3(0.004, 1.358, -0.090), 0.012, 0.004, "Chest"),
		_ring(Vector3(0.004, 1.404, -0.069), 0.010, 0.003, "Chest", "Neck", 0.24),
	], Vector3.UP, Vector3.RIGHT, 8, SADARA_TRIM)
	var button := Color("726252")
	_ellipsoid(Vector3(0.004, 1.260, -0.118), Vector3(0.0046, 0.0046, 0.0023), "Chest", button)
	_ellipsoid(Vector3(0.004, 1.310, -0.109), Vector3(0.0046, 0.0046, 0.0023), "Chest", button)
	_ellipsoid(Vector3(0.004, 1.357, -0.095), Vector3(0.0046, 0.0046, 0.0023), "Chest", button)
	if _omkar_style:
		var pocket := SADARA_COLOR.lightened(0.013)
		var top_left := Vector3(0.051, 1.303, -0.107)
		var top_right := Vector3(0.104, 1.300, -0.093)
		var lower_left := Vector3(0.056, 1.243, -0.115)
		var lower_right := Vector3(0.101, 1.240, -0.103)
		_front_panel(top_left, top_right, lower_left, pocket, true)
		_front_panel(lower_left, top_right, lower_right, pocket, true)
		var seam := Vector3.FORWARD * 0.0007
		var opening := Vector3.DOWN * 0.003
		_front_panel(top_left + seam, top_right + seam, top_left + seam + opening, SADARA_TRIM, true)
		_front_panel(top_left + seam + opening, top_right + seam, top_right + seam + opening, SADARA_TRIM, true)


func _build_dhotar_tucks() -> void:
	# The pleated apron and narrow rear tuck follow the thighs through a stride.
	var front_edge := _ring(Vector3(0.051, 0.409, -0.099), 0.051, 0.011, "RightUpperLeg", "RightLowerLeg", 0.72)
	var front_border := _ring(Vector3(0.049, 0.424, -0.113), 0.054, 0.016, "RightUpperLeg", "RightLowerLeg", 0.56)
	_tube([
		_ring(Vector3(0.051, 0.408, -0.099), 0.0, 0.0, "RightUpperLeg", "RightLowerLeg", 0.72),
		front_edge,
		front_border,
	], Vector3.UP, Vector3.RIGHT, 14, DHOTAR_BORDER_COLOR, DHOTAR_FOLDS)
	_tube([
		front_border,
		_ring(Vector3(0.049, 0.526, -0.125), 0.063, 0.022, "RightUpperLeg"),
		_ring(Vector3(0.000, 0.675, -0.116), 0.077, 0.025, "RightUpperLeg", "Hips", 0.22),
		_ring(Vector3(0.018, 0.788, -0.087), 0.058, 0.017, "RightUpperLeg", "Hips", 0.66),
		_ring(Vector3(0.027, 0.876, -0.077), 0.022, 0.009, "Hips"),
	], Vector3.UP, Vector3.RIGHT, 14, DHOTAR_PLEAT_COLOR, DHOTAR_FOLDS, 8)
	_tube([
		_ring(Vector3(-0.075, 0.505, 0.053), 0.0, 0.0, "LeftUpperLeg"),
		_ring(Vector3(-0.058, 0.555, 0.074), 0.042, 0.015, "LeftUpperLeg"),
		_ring(Vector3(-0.029, 0.670, 0.094), 0.050, 0.022, "LeftUpperLeg", "Hips", 0.25),
		_ring(Vector3(-0.008, 0.780, 0.100), 0.044, 0.015, "LeftUpperLeg", "Hips", 0.66),
		_ring(Vector3(-0.009, 0.883, 0.111), 0.019, 0.008, "Hips"),
	], Vector3.UP, Vector3.RIGHT, 12, DHOTAR_PLEAT_COLOR, DHOTAR_FOLDS)


func _build_head() -> void:
	if _omkar_style and _avatar_gender.is_empty():
		_add_scanned_omkar_head()
		return
	if _avatar_gender.is_empty():
		_tube([
			_ring(Vector3(0, 1.365, -0.012), 0.049, 0.047, "Chest", "Neck", 0.60),
			_ring(Vector3(0, 1.412, -0.015), 0.052, 0.052, "Neck"),
			_ring(Vector3(0, 1.474, -0.015), 0.055, 0.055, "Neck", "Head", 0.58),
		], Vector3.UP, Vector3.RIGHT, 12, _skin, 0.0, -1, false)
	var width := 1.04 if wears_overshirt else (1.0 if wears_dhotar else 0.94)
	if not _avatar_gender.is_empty():
		width = 0.944 if _avatar_gender == "woman" else 1.015
	elif wears_kurta_with_dupatta:
		width = 0.92 if face_variant == "Kavita" else 0.90
	elif face_variant == "Ravi":
		width = 1.015
	var face_tint := Color(_skin.r / 0.84, _skin.g / 0.69, _skin.b / 0.59)
	_add_textured_head(width, face_tint)
	for side: float in [-1.0, 1.0]:
		_build_eye(side, width)
		_build_brow(side, width)
	if not _avatar_gender.is_empty():
		_build_avatar_hair()
	elif wears_kurta_with_dupatta:
		_build_kurta_hair(kurta_hair_style)


func _add_scanned_omkar_head() -> void:
	var arrays := OMKAR_SCAN_HEAD.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var joints := PackedInt32Array([_bone_ids["Head"], _bone_ids["Neck"], _bone_ids["Chest"], 0])
	for index in indices:
		var point := vertices[index]
		var upper := smoothstep(1.418, 1.464, point.y)
		var lower := (1.0 - upper) * (1.0 - smoothstep(1.377, 1.417, point.y)) * 0.48
		_surface.set_bones(joints)
		_surface.set_weights(PackedFloat32Array([upper, 1.0 - upper - lower, lower, 0.0]))
		_surface.set_color(Color.WHITE)
		_surface.set_uv((HEAD_ATLAS_EDGE + uvs[index] * HEAD_ATLAS_SPAN) / ATLAS_SIZE)
		_surface.add_vertex(point)


func _build_eye(side: float, width: float) -> void:
	# The neutral head's eyelids mask the globe. Seat it under their widest opening.
	var eye := Vector3(side * 0.0312 * width, 1.5467, -0.079)
	var globe_height := 0.0075 if wears_kurta_with_dupatta or not _avatar_gender.is_empty() else 0.0087
	var globe_width := 0.016
	if _omkar_style:
		globe_height = 0.0077
		globe_width = 0.0152
	_ellipsoid(eye, Vector3(globe_width * width, globe_height, 0.0160), "Head", EYE_WHITE)
	var gaze := eye + Vector3.UP * 0.0017
	_ellipsoid(gaze + Vector3.FORWARD * 0.0154, Vector3(0.0049, 0.0047, 0.0016), "Head", LIMBAL_RING)
	_ellipsoid(gaze + Vector3.FORWARD * 0.0166, Vector3(0.0039, 0.0039, 0.0009), "Head", IRIS)
	_ellipsoid(gaze + Vector3.FORWARD * 0.0171, Vector3(0.0024, 0.0024, 0.00065), "Head", PUPIL)
	if not _omkar_style:
		_ellipsoid(gaze + Vector3(-0.0009, 0.00145, -0.0176),
			Vector3(0.00065, 0.00056, 0.00033), "Head", Color("b8aaa0"))


func _build_brow(side: float, width: float) -> void:
	# These points follow the brow ridge of the neutral UV-mapped head.
	const RIDGE: Array[Vector3] = [
		Vector3(0.016, 1.560, -0.102), Vector3(0.023, 1.564, -0.101),
		Vector3(0.031, 1.566, -0.099), Vector3(0.040, 1.563, -0.094),
		Vector3(0.049, 1.557, -0.088),
	]
	const THICKNESS: Array[float] = [0.0005, 0.00135, 0.00145, 0.00098, 0.0002]
	var hair := Color("6a5144") if wears_kurta_with_dupatta or _avatar_gender == "woman" else Color("544135")
	for index in range(RIDGE.size() - 1):
		var a := RIDGE[index]
		var b := RIDGE[index + 1]
		a.x *= side * width
		b.x *= side * width
		var high_a := a + Vector3.UP * THICKNESS[index]
		var low_a := a - Vector3.UP * THICKNESS[index]
		var high_b := b + Vector3.UP * THICKNESS[index + 1]
		var low_b := b - Vector3.UP * THICKNESS[index + 1]
		# Two sides keep the same outward winding and taper at the temple.
		var points := [high_a, high_b, low_a, low_a, high_b, low_b]
		if side > 0.0:
			points = [high_a, low_a, high_b, low_a, low_b, high_b]
		for offset in points.size():
			var at: Vector3 = points[offset]
			_face_vertex(at, hair if offset % 3 == 0 else hair.darkened(0.12))


func _face_vertex(at: Vector3, color: Color) -> void:
	_surface.set_bones(PackedInt32Array([_bone_ids["Head"], 0, 0, 0]))
	_surface.set_weights(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
	_surface.set_color(color)
	_surface.set_uv(Vector2(0.90 + at.x * 0.06, 0.04 + at.y * 0.23))
	_surface.add_vertex(at)


func _build_avatar_hair() -> void:
	match _avatar_hair:
		"bun":
			_build_kurta_hair(0)
		"braid":
			_build_kurta_hair(1)
		"bob":
			_build_kurta_hair(2)
	# The three short styles use the authored scalp and differ through its silhouette.


func _build_kurta_hair(style: int) -> void:
	var dark_hair := Color("28201b") if style != 2 else Color("32261f")
	var use_textured_hairline := not _avatar_gender.is_empty()
	var front_clearance := 0.030 if use_textured_hairline else 0.0
	_tube([
		_ring(Vector3(0, 1.514, 0.062), 0.047, 0.024, "Head"),
		_ring(Vector3(0, 1.561, 0.038), 0.074, 0.066, "Head"),
		_ring(Vector3(0, 1.610, 0.007 + front_clearance), 0.083, 0.096 - front_clearance, "Head"),
		_ring(Vector3(0.002, 1.642, -0.006 + front_clearance), 0.074, 0.088 - front_clearance, "Head"),
		_ring(Vector3(0.006, 1.664, -0.010 + 0.70 * front_clearance), 0.048, 0.060 - 0.72 * front_clearance, "Head"),
		_ring(Vector3(0.007, 1.676, -0.014 + 0.45 * front_clearance), 0.0, 0.0, "Head"),
	], Vector3.UP, Vector3.RIGHT, 20, dark_hair, 0.018, -1, false)
	# Narrow, tapering temple pieces blend into the scalp across the part.
	for side: float in [-1.0, 1.0]:
		_tube([
			_ring(Vector3(side * 0.069, 1.558, -0.033 + front_clearance), 0.0, 0.0, "Head"),
			_ring(Vector3(side * 0.072, 1.579, -0.034 + front_clearance), 0.010, 0.020, "Head"),
			_ring(Vector3(side * 0.074, 1.604, -0.032 + front_clearance), 0.012, 0.037, "Head"),
			_ring(Vector3(side * 0.063, 1.629, -0.029 + front_clearance), 0.016, 0.051, "Head"),
			_ring(Vector3(side * 0.050, 1.650, -0.024), 0.0, 0.0, "Head"),
		], Vector3.UP, Vector3.RIGHT, 12, dark_hair, 0.016, -1, false)
	match style:
		0:
			_ellipsoid(Vector3(0.005, 1.532, 0.098), Vector3(0.043, 0.031, 0.047), "Head", dark_hair)
			_ellipsoid(Vector3(-0.024, 1.631, -0.077), Vector3(0.039, 0.017, 0.021), "Head", dark_hair)
		1:
			if not _avatar_gender.is_empty():
				_build_avatar_braid(dark_hair)
				return
			# The braided silhouette falls over the shoulder and follows the upper body.
			_tube([
				_ring(Vector3(-0.107, 1.211, -0.128), 0.011, 0.011, "Chest"),
				_ring(Vector3(-0.119, 1.271, -0.108), 0.018, 0.022, "Chest"),
				_ring(Vector3(-0.151, 1.343, -0.063), 0.024, 0.029, "Chest", "Neck", 0.20),
				_ring(Vector3(-0.129, 1.394, 0.024), 0.027, 0.029, "Chest", "Neck", 0.48),
				_ring(Vector3(-0.059, 1.464, 0.062), 0.035, 0.036, "Neck", "Head", 0.65),
				_ring(Vector3(-0.015, 1.529, 0.079), 0.046, 0.035, "Head"),
			], Vector3.UP, Vector3.RIGHT, 10, dark_hair, 0.11, -1, false)
		2:
			for side: float in [-1.0, 1.0]:
				_tube([
					_ring(Vector3(side * 0.053, 1.451, 0.022), 0.0, 0.0, "Head"),
					_ring(Vector3(side * 0.067, 1.478, 0.019), 0.022, 0.042, "Head"),
					_ring(Vector3(side * 0.071, 1.520, 0.011), 0.020, 0.057, "Head"),
					_ring(Vector3(side * 0.072, 1.574, -0.005), 0.018, 0.058, "Head"),
					_ring(Vector3(side * 0.052, 1.630, -0.013), 0.015, 0.055, "Head"),
					_ring(Vector3(side * 0.047, 1.657, -0.019), 0.0, 0.0, "Head"),
				], Vector3.UP, Vector3.RIGHT, 12, dark_hair, 0.022, -1, false)
			_ellipsoid(Vector3(0.0, 1.517, 0.067), Vector3(0.071, 0.074, 0.042), "Head", dark_hair)


func _build_avatar_braid(hair: Color) -> void:
	# Lay the braid over the shoulder opposite the dupatta fold.
	var curve := Curve3D.new()
	curve.bake_interval = 0.012
	curve.add_point(Vector3(0.115, 1.231, -0.141), Vector3.ZERO, Vector3(0.015, 0.034, -0.002))
	curve.add_point(Vector3(0.155, 1.327, -0.113), Vector3(0, -0.027, -0.024), Vector3(0, 0.027, 0.024))
	curve.add_point(Vector3(0.141, 1.395, 0.014), Vector3(0.009, -0.016, -0.041), Vector3(-0.009, 0.016, 0.041))
	curve.add_point(Vector3(0.079, 1.473, 0.091), Vector3(0.024, -0.025, 0.003), Vector3(-0.024, 0.025, -0.003))
	curve.add_point(Vector3(0.024, 1.531, 0.075), Vector3(0.018, -0.017, 0.010))
	var length := curve.get_baked_length()
	# Three interleaved strands keep the plait visible in side light at small scales.
	for strand in range(3):
		var sections: Array[Ring] = []
		for row in range(25):
			var progress := row / 24.0
			var point := curve.sample_baked(length * progress, true)
			var thickness := lerpf(0.0075, 0.022, smoothstep(0.0, 0.92, progress))
			var angle := TAU * (2.7 * progress + strand / 3.0)
			point += Vector3(cos(angle), 0.0, sin(angle)) * thickness * 0.43
			var radius := thickness * 0.68 * smoothstep(0.0, 0.09, progress)
			var toward_neck := smoothstep(0.35, 0.72, progress)
			var toward_head := smoothstep(0.55, 1.0, progress)
			var rim := _ring(point, radius, radius, "Chest", "Neck", toward_neck)
			rim.bones[2] = _bone_ids["Head"]
			rim.weights = PackedFloat32Array([
				(1.0 - toward_neck) * (1.0 - toward_head), toward_neck * (1.0 - toward_head), toward_head, 0.0,
			])
			sections.append(rim)
		_tube(sections, Vector3.UP, Vector3.RIGHT, 6, hair.lightened(strand * 0.019), 0.0, -1, false)


func _add_textured_head(width: float, tint: Color) -> void:
	# Bring the adapted head into the existing draw call and Head bone.
	var arrays := HEAD_GEOMETRY.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var joint := PackedInt32Array([_bone_ids["Head"], 0, 0, 0])
	var weight := PackedFloat32Array([1.0, 0.0, 0.0, 0.0])
	var avatar := not _avatar_gender.is_empty()
	var fitted_head := PackedVector3Array()
	var fitted_tints := PackedColorArray()
	if avatar:
		fitted_head.resize(vertices.size())
		fitted_tints.resize(vertices.size())
		if _avatar_neck_edges.is_empty():
			_avatar_neck_edges = _find_avatar_neck_edges(vertices, indices)
			_avatar_neck_albedo.resize(vertices.size())
			var atlas := OMKAR_ALBEDO.get_image()
			for offset in _avatar_neck_edges.size():
				var edge := _avatar_neck_edges[offset]
				var previous := _avatar_neck_edges[offset - 1]
				var point := vertices[edge.x]
				var neighbors := (vertices[previous.x] + vertices[edge.y]) * 0.5
				var smooth_point := point.lerp(neighbors, 0.62)
				smooth_point.y = 1.447 + 0.004 * smoothstep(-0.081, 0.043, smooth_point.z)
				_avatar_neck_profile[point] = smooth_point
				_avatar_neck_albedo[edge.x] = atlas.get_pixelv(Vector2i(HEAD_ATLAS_EDGE + uvs[edge.x] * HEAD_ATLAS_SPAN))
				_avatar_neck_albedo[edge.y] = atlas.get_pixelv(Vector2i(HEAD_ATLAS_EDGE + uvs[edge.y] * HEAD_ATLAS_SPAN))
	for index in indices:
		var point := vertices[index]
		var skin_tint := tint
		if avatar:
			if point.y < 1.463:
				point = _avatar_neck_profile.get(point, point)
			var front := smoothstep(0.017, 0.090, -point.z)
			var jaw := smoothstep(1.456, 1.481, point.y) * (1.0 - smoothstep(1.503, 1.528, point.y))
			var cheek := smoothstep(1.494, 1.516, point.y) * (1.0 - smoothstep(1.528, 1.544, point.y))
			var side_cheek := smoothstep(0.020, 0.060, absf(point.x))
			var bridge := smoothstep(1.521, 1.541, point.y) * (1.0 - smoothstep(1.553, 1.572, point.y))
			var middle := 1.0 - smoothstep(0.009, 0.037, absf(point.x))
			if _avatar_gender == "woman":
				point.x *= 1.0 + front * (0.067 * cheek - 0.114 * jaw)
				point.y += 0.005 * jaw * middle * front
				point.z += front * (0.004 * bridge * middle - 0.005 * cheek * side_cheek)
			else:
				point.x *= 1.0 + front * (0.036 * cheek + 0.090 * jaw)
				point.y -= 0.003 * jaw * middle * front
				point.z -= front * (0.003 * bridge * middle + 0.003 * cheek * side_cheek)
				# Keep the transition to the lip and cheek soft at normal camera distances.
				skin_tint = skin_tint.darkened(0.16 * jaw * front * lerpf(0.38, 1.0, side_cheek))
			point = _shape_avatar_scalp(point, front)
		elif wears_kurta_with_dupatta:
			# Reshape the neutral head while keeping the existing UV correspondence.
			var chin := smoothstep(1.459, 1.486, point.y) * (1.0 - smoothstep(1.511, 1.553, point.y))
			var front := smoothstep(0.014, 0.077, -point.z)
			var bridge := smoothstep(1.519, 1.541, point.y) * (1.0 - smoothstep(1.554, 1.578, point.y))
			var middle := 1.0 - smoothstep(0.012, 0.048, absf(point.x))
			var cheek := smoothstep(1.490, 1.521, point.y) * (1.0 - smoothstep(1.533, 1.545, point.y))
			var chin_shape := 0.105 if face_variant == "Kavita" else 0.12 + kurta_hair_style * 0.018
			point.x *= 1.0 - chin_shape * chin * front
			point.x *= 1.0 + 0.057 * cheek * front
			point.y += 0.008 * chin * middle * front
			point.z += 0.011 * bridge * middle * front
			point.z -= 0.006 * cheek * (1.0 - middle) * front
			var lip := smoothstep(1.476, 1.489, point.y) * (1.0 - smoothstep(1.496, 1.513, point.y))
			lip *= front * (1.0 - smoothstep(0.011, 0.036, absf(point.x)))
			point.z += 0.003 * lip
			skin_tint.r *= 1.0 - 0.09 * lip
		elif _omkar_style:
			var front := smoothstep(0.015, 0.094, -point.z)
			var jaw := smoothstep(1.461, 1.488, point.y) * (1.0 - smoothstep(1.506, 1.534, point.y))
			var cheek := smoothstep(1.504, 1.522, point.y) * (1.0 - smoothstep(1.530, 1.544, point.y))
			var side_cheek := smoothstep(0.020, 0.058, absf(point.x))
			point.x *= 1.0 + 0.072 * jaw * front + 0.045 * cheek * front
			point.z -= 0.003 * cheek * side_cheek * front
			point.y -= 0.004 * jaw * (1.0 - side_cheek) * front
			var beard := jaw * (0.36 + side_cheek * 0.64)
			skin_tint = skin_tint.darkened(beard * front * 0.20)
			# A slight sweep through the crown changes the silhouette while keeping the fitted UVs.
			var top := smoothstep(1.578 + front * 0.023, 1.658, point.y)
			var sweep := smoothstep(-0.072, 0.060, point.x)
			point.y += top * lerpf(0.004, 0.013, sweep)
			point.x += 0.0055 * top
			point.z -= 0.004 * top
		elif face_variant == "Ravi":
			var jaw := smoothstep(1.453, 1.485, point.y) * (1.0 - smoothstep(1.510, 1.541, point.y))
			point.x *= 1.0 + 0.085 * jaw
			point.z -= 0.004 * jaw * (1.0 - smoothstep(0.018, 0.05, absf(point.x)))
		if not avatar and (wears_dhotar or face_variant == "Ravi"):
			# Faint lower-face color variation follows the jaw and keeps the lip texture.
			var lower := smoothstep(1.460, 1.477, point.y) * (1.0 - smoothstep(1.491, 1.529, point.y))
			var lip_clear := smoothstep(0.013, 0.027, absf(point.x))
			var front := smoothstep(0.015, 0.075, -point.z)
			var stubble := 0.17 if face_variant == "Ravi" else 0.10
			skin_tint = skin_tint.darkened(lower * front * lerpf(0.55, 1.0, lip_clear) * stubble)
		point.x *= width
		if avatar:
			fitted_head[index] = point
			fitted_tints[index] = skin_tint
			var atlas_uv := (HEAD_ATLAS_EDGE + uvs[index] * HEAD_ATLAS_SPAN) / ATLAS_SIZE
			_avatar_head_vertex(point, atlas_uv, skin_tint)
			continue
		_surface.set_bones(joint)
		_surface.set_weights(weight)
		_surface.set_color(skin_tint)
		_surface.set_uv((HEAD_ATLAS_EDGE + uvs[index] * HEAD_ATLAS_SPAN) / ATLAS_SIZE)
		_surface.add_vertex(point)
	if avatar:
		_build_avatar_neck(fitted_head, fitted_tints, width)


static func _find_avatar_neck_edges(vertices: PackedVector3Array, indices: PackedInt32Array) -> Array[Vector2i]:
	# The atlas can split an imported vertex along a seam. Match edges by position.
	const NECK_CROP_TOP := 1.463
	var position_ids: Dictionary[Vector3, int] = {}
	var borders: Dictionary[Vector2i, Vector2i] = {}
	for triangle in range(0, indices.size(), 3):
		for corner in range(3):
			var a := indices[triangle + corner]
			var b := indices[triangle + (corner + 1) % 3]
			if vertices[a].y > NECK_CROP_TOP or vertices[b].y > NECK_CROP_TOP:
				continue
			var a_id: int = position_ids.get_or_add(vertices[a], a)
			var b_id: int = position_ids.get_or_add(vertices[b], b)
			if not borders.erase(Vector2i(b_id, a_id)):
				borders[Vector2i(a_id, b_id)] = Vector2i(a, b)
	var following: Dictionary[Vector3, Vector2i] = {}
	var chin := Vector3(0, 0, INF)
	for edge: Vector2i in borders.values():
		var at := vertices[edge.x]
		following[at] = edge
		if at.z < chin.z:
			chin = at
	# Begin at the front of the chin to follow the outside loop of the cropped head.
	var outline: Array[Vector2i] = []
	var point := chin
	while following.has(point):
		var edge := following[point]
		outline.append(edge)
		following.erase(point)
		point = vertices[edge.y]
	return outline


func _build_avatar_neck(points: PackedVector3Array, tints: PackedColorArray, width: float) -> void:
	# Continue the head's actual boundary into the collar to avoid an overlapping edge.
	var base_color := _skin.darkened(0.035)
	for edge in _avatar_neck_edges:
		var top_a := points[edge.x]
		var top_b := points[edge.y]
		var base_a := _avatar_neck_base(top_a, width)
		var base_b := _avatar_neck_base(top_b, width)
		var middle_a := top_a.lerp(base_a, 0.44)
		var middle_b := top_b.lerp(base_b, 0.44)
		middle_a.z = lerpf(top_a.z, base_a.z, 0.86)
		middle_b.z = lerpf(top_b.z, base_b.z, 0.86)
		# Carry the matching complexion into the neck without stretching its facial texture.
		var top_color_a := _avatar_neck_albedo[edge.x] * tints[edge.x]
		var top_color_b := _avatar_neck_albedo[edge.y] * tints[edge.y]
		var middle_color_a := top_color_a.lerp(base_color, 0.72)
		var middle_color_b := top_color_b.lerp(base_color, 0.72)
		_avatar_neck_vertex(top_b, top_color_b)
		_avatar_neck_vertex(top_a, top_color_a)
		_avatar_neck_vertex(middle_a, middle_color_a)
		_avatar_neck_vertex(top_b, top_color_b)
		_avatar_neck_vertex(middle_a, middle_color_a)
		_avatar_neck_vertex(middle_b, middle_color_b)
		_avatar_neck_vertex(middle_b, middle_color_b)
		_avatar_neck_vertex(middle_a, middle_color_a)
		_avatar_neck_vertex(base_a, base_color)
		_avatar_neck_vertex(middle_b, middle_color_b)
		_avatar_neck_vertex(base_a, base_color)
		_avatar_neck_vertex(base_b, base_color)


func _avatar_neck_base(point: Vector3, width: float) -> Vector3:
	var direction := Vector2(point.x / (0.044 * width), (point.z + 0.023) / 0.073).normalized()
	return Vector3(direction.x * 0.050 * width, 1.376, -0.014 + direction.y * 0.046)


func _avatar_neck_vertex(point: Vector3, color: Color) -> void:
	# The right-hand strip of the atlas is an even 250/255 for procedural skin.
	var uv := Vector2(0.90 + (point.x + 0.32 * point.z) * 0.20, 0.04 + point.y * 0.23)
	_avatar_head_vertex(point, uv, Color(color.r * 1.02, color.g * 1.02, color.b * 1.02))


func _avatar_head_vertex(point: Vector3, uv: Vector2, tint: Color) -> void:
	var head_weight := smoothstep(1.428, 1.490, point.y)
	_surface.set_bones(PackedInt32Array([_bone_ids["Head"], _bone_ids["Neck"], 0, 0]))
	_surface.set_weights(PackedFloat32Array([head_weight, 1.0 - head_weight, 0.0, 0.0]))
	_surface.set_color(tint)
	_surface.set_uv(uv)
	_surface.add_vertex(point)


func _shape_avatar_scalp(point: Vector3, front: float) -> Vector3:
	# Shape the original UV-mapped hair instead of placing a ridge across the forehead.
	var crown := smoothstep(1.576 + front * 0.024, 1.656, point.y)
	match _avatar_hair:
		"side_part":
			var part := smoothstep(0.011, 0.032, point.x)
			var groove := 1.0 - smoothstep(0.0, 0.009, absf(point.x - 0.024))
			point.y += crown * (lerpf(0.015, 0.004, part) - 0.002 * groove)
			point.x -= 0.013 * crown
		"swept":
			var front_crown := 1.0 - smoothstep(-0.052, 0.043, point.z)
			point.y += crown * lerpf(0.012, 0.034, front_crown)
			point.z += 0.014 * crown
		"bun", "braid", "bob":
			var part := smoothstep(-0.040, 0.055, point.x)
			point.y += crown * lerpf(0.008, 0.017, part)
			point.x += 0.006 * crown
	return point


func _build_arm(side: float, label: String) -> void:
	var upper := label + "UpperArm"
	var lower := label + "LowerArm"
	var hand := label + "Hand"
	var outward := Vector3(side, 0, 0)
	if _avatar_gender.is_empty() and not _omkar_style and (wears_dhotar or wears_kurta_with_dupatta):
		_build_sadara_sleeve(side, upper, lower)
	elif _avatar_gender.is_empty() and not _omkar_style:
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
	var covered_arm := 0.040 if not _avatar_gender.is_empty() else 0.0
	var use_scanned_hand := _omkar_style and _avatar_gender.is_empty()
	var forearm: Array[Ring] = [
		_ring(Vector3(side * (0.291 + covered_arm), 1.350, 0), 0.0, 0.0, upper),
		_ring(Vector3(side * (0.310 + covered_arm), 1.350, 0), 0.049 if covered_arm > 0.0 else 0.054,
			0.044 if covered_arm > 0.0 else 0.051, upper),
		_ring(Vector3(side * 0.373, 1.350, 0.005), 0.052, 0.046, upper),
		_ring(Vector3(side * 0.448, 1.350, 0.004), 0.040, 0.038, upper, lower, 0.52),
		_ring(Vector3(side * 0.508, 1.350, 0.003), 0.045, 0.040, lower),
		_ring(Vector3(side * 0.603, 1.350, 0.001), 0.035, 0.031, lower),
		_ring(Vector3(side * 0.666, 1.350, 0.002), 0.027, 0.026, lower, hand, 0.56),
	]
	if not use_scanned_hand:
		forearm.append(_ring(Vector3(side * 0.668, 1.350, 0.002), 0.0, 0.0, hand))
	_tube(forearm, outward, Vector3.UP, 10, _skin, 0.0, -1, false)
	if use_scanned_hand:
		OmkarHand.add_scan(_surface, side, _bone_ids[hand], _bone_ids[lower], _skin)
		return
	if _omkar_style or not _avatar_gender.is_empty():
		OmkarHand.add(_surface, side, _bone_ids[hand], _bone_ids[lower], _skin)
		return
	_tube([
		_ring(Vector3(side * 0.646, 1.350, 0.002), 0.0, 0.0, lower),
		_ring(Vector3(side * 0.665, 1.350, 0.003), 0.026, 0.026, hand, lower, 0.33),
		_ring(Vector3(side * 0.702, 1.350, -0.004), 0.026, 0.039, hand),
		_ring(Vector3(side * 0.741, 1.345, -0.005), 0.019, 0.034, hand),
		_ring(Vector3(side * 0.768, 1.341, -0.005), 0.0, 0.0, hand),
	], outward, Vector3.UP, 10, _skin, 0.0, -1, false)
	_ellipsoid(Vector3(side * 0.701, 1.339, -0.031), Vector3(0.025, 0.015, 0.014), hand, _skin)


func _build_omkar_sleeve(side: float, upper: String, lower: String, torso: Array[Ring],
		top_color: Color = SADARA_COLOR, short_sleeves := false) -> void:
	var outward := Vector3(side, 0, 0)
	var sleeve_ease := 0.003 if not _avatar_gender.is_empty() else 0.0
	var cuff := _ring(Vector3(side * 0.519, 1.351, 0.003), 0.054 + sleeve_ease, 0.049 + sleeve_ease, lower)
	var shoulder := _ring(Vector3(side * 0.240, 1.339, 0.004), 0.057, 0.063, upper, "Chest", 0.21)
	if not _avatar_gender.is_empty():
		shoulder.center = Vector3(side * 0.229, 1.324, 0.004)
		shoulder.radii = Vector2(0.051, 0.059)
	var central_arc := 0 if side > 0.0 else OMKAR_TORSO_SIDES / 2
	var rim: Array[Vector2i] = []
	for offset in range(0, -ARMHOLE_HALF_ARC - 1, -1):
		rim.append(Vector2i(ARMHOLE_TOP, central_arc + offset))
	for row in range(ARMHOLE_TOP - 1, ARMHOLE_BOTTOM - 1, -1):
		rim.append(Vector2i(row, central_arc - ARMHOLE_HALF_ARC))
	for offset in range(1 - ARMHOLE_HALF_ARC, ARMHOLE_HALF_ARC + 1):
		rim.append(Vector2i(ARMHOLE_BOTTOM, central_arc + offset))
	for row in range(ARMHOLE_BOTTOM + 1, ARMHOLE_TOP + 1):
		rim.append(Vector2i(row, central_arc + ARMHOLE_HALF_ARC))
	for offset in range(ARMHOLE_HALF_ARC - 1, 0, -1):
		rim.append(Vector2i(ARMHOLE_TOP, central_arc + offset))
	# Join every sleeve vertex to the same weighted vertex on the cut torso edge.
	var depth_axis := Vector3.UP.cross(outward)
	for index in rim.size():
		var next := (index + 1) % rim.size()
		var theta := TAU * index / rim.size()
		var next_theta := TAU * next / rim.size()
		_omkar_armhole_vertex(torso, rim[index], top_color)
		_omkar_armhole_vertex(torso, rim[next], top_color)
		_vertex(shoulder, theta, Vector3.UP, depth_axis, top_color, 0.046, true)
		_omkar_armhole_vertex(torso, rim[next], top_color)
		_vertex(shoulder, next_theta, Vector3.UP, depth_axis, top_color, 0.046, true)
		_vertex(shoulder, theta, Vector3.UP, depth_axis, top_color, 0.046, true)
	if short_sleeves:
		_tube([
			shoulder,
			_ring(Vector3(side * 0.277, 1.342, 0.004), 0.055, 0.059, upper),
			_ring(Vector3(side * 0.345, 1.350, 0.006), 0.061, 0.061, upper),
			_ring(Vector3(side * 0.354, 1.350, 0.006), 0.060, 0.060, upper),
			_ring(Vector3(side * 0.356, 1.350, 0.006), 0.051, 0.046, upper),
		], outward, Vector3.UP, 16, top_color, 0.046)
		return
	_tube([
		shoulder,
		_ring(Vector3(side * 0.271, 1.346, 0.004), 0.055, 0.059, upper),
		_ring(Vector3(side * 0.342, 1.350, 0.001), 0.060, 0.055, upper),
		_ring(Vector3(side * 0.416, 1.350, 0.005), 0.052 + sleeve_ease, 0.049 + sleeve_ease, upper, lower, 0.21),
		_ring(Vector3(side * 0.462, 1.351, 0.005), 0.052 + sleeve_ease, 0.046 + sleeve_ease, lower, upper, 0.40),
		cuff,
	], outward, Vector3.UP, 16, top_color, 0.046)
	_tube([
		cuff,
		_ring(Vector3(side * 0.536, 1.351, 0.003), 0.052, 0.047, lower),
		_ring(Vector3(side * 0.552, 1.351, 0.003), 0.049, 0.044, lower),
		_ring(Vector3(side * 0.554, 1.351, 0.003), 0.039, 0.035, lower),
	], outward, Vector3.UP, 16, SADARA_TRIM if _avatar_gender.is_empty() else top_color.darkened(0.16), 0.037)


func _omkar_armhole_vertex(torso: Array[Ring], corner: Vector2i, top_color: Color) -> void:
	var radial_index := posmod(corner.y, OMKAR_TORSO_SIDES)
	_vertex(torso[corner.x], TAU * radial_index / OMKAR_TORSO_SIDES, Vector3.RIGHT, Vector3.BACK,
		top_color, OMKAR_TORSO_FOLDS, true)


func _build_sadara_sleeve(side: float, upper: String, lower: String) -> void:
	var outward := Vector3(side, 0, 0)
	if wears_kurta_with_dupatta:
		var fitted := _sleeve_shoulder(side, upper)
		for ring: Ring in fitted:
			ring.radii *= 0.82
		fitted.append_array([
			_ring(Vector3(side * 0.345, 1.350, 0.002), 0.060, 0.056, upper),
			_ring(Vector3(side * 0.439, 1.350, 0.004), 0.047, 0.045, upper, lower, 0.36),
			_ring(Vector3(side * 0.476, 1.350, 0.004), 0.052, 0.049, lower, upper, 0.18),
			_ring(Vector3(side * 0.549, 1.350, 0.001), 0.045, 0.040, lower),
			_ring(Vector3(side * 0.550, 1.350, 0.001), 0.036, 0.033, lower),
		])
		_tube(fitted, outward, Vector3.UP, 12, shirt_color, 0.023)
		return
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
		_ring(Vector3(side * 0.155, 1.323, 0.001), 0.042, 0.063, "Chest", upper, 0.20),
		_ring(Vector3(side * 0.194, 1.329, 0.004), 0.048, 0.065, "Chest", upper, 0.55),
		_ring(Vector3(side * 0.230, 1.337, 0.005), 0.053, 0.066, upper, "Chest", 0.15),
		_ring(Vector3(side * 0.274, 1.346, 0.004), 0.061, 0.062, upper),
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
	var color := CHINO_COLOR if wears_overshirt else TROUSER_COLOR
	if not _avatar_gender.is_empty():
		color = _avatar_trousers
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
	], Vector3.UP, Vector3.RIGHT, 12, color, 0.028)


func _build_dhotar_leg(side: float, upper: String, lower: String, foot: String) -> void:
	# Short work drape with visible calf and a narrow woven edge near each cuff.
	var drape_width := 0.074 + side * 0.004
	var drape_hem := _ring(Vector3(side * 0.107, 0.241 + side * 0.017, 0.012), drape_width, 0.065, lower)
	var drape_border := _ring(Vector3(side * 0.105, 0.254 + side * 0.017, 0.009), drape_width + 0.004, 0.068, lower)
	drape_hem.crease_offset = 0.10 * side
	drape_border.crease_offset = drape_hem.crease_offset
	_tube([
		_ring(Vector3(side * 0.103, 0.075, 0.006), 0.040, 0.047, lower, foot, 0.65),
		_ring(Vector3(side * 0.103, 0.112, 0.009), 0.040, 0.041, lower, foot, 0.22),
		_ring(Vector3(side * 0.104, 0.190, 0.010), 0.045, 0.046, lower),
		_ring(Vector3(side * 0.104, 0.296, 0.011), 0.053, 0.054, lower),
	], Vector3.UP, Vector3.RIGHT, 10, _skin, 0.0, -1, false)
	_tube([
		_ring(drape_hem.center + Vector3.UP * 0.002, 0.053, 0.054, lower),
		drape_hem,
		drape_border,
	], Vector3.UP, Vector3.RIGHT, 16, DHOTAR_BORDER_COLOR, DHOTAR_FOLDS)
	_tube([
		drape_border,
		_ring(Vector3(side * 0.106, 0.322, 0.011), 0.074, 0.072, lower),
		_ring(Vector3(side * 0.103, 0.419, -0.002), 0.073, 0.076, lower, upper, 0.19),
		_ring(Vector3(side * 0.104, 0.489, -0.016), 0.076, 0.080, lower, upper, 0.53),
		_ring(Vector3(side * 0.104, 0.610, -0.001), 0.086, 0.087, upper),
		_ring(Vector3(side * 0.097, 0.747, 0.010), 0.089, 0.094, upper),
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
	], Vector3.FORWARD, Vector3.RIGHT, 12, foot_color, 0.0, -1, not wears_dhotar)
	_tube([
		_ring(Vector3(x, 0.016, 0.088), 0.0, 0.0, foot),
		_ring(Vector3(x, 0.017, 0.064), 0.047, 0.014, foot),
		_ring(Vector3(x, 0.016, 0.005), 0.056, 0.014, foot),
		_ring(Vector3(x, 0.016, -0.078), 0.058, 0.014, foot, toes, 0.38),
		_ring(Vector3(x, 0.016, -0.151), 0.059, 0.014, toes),
		_ring(Vector3(x, 0.017, -0.178), 0.047, 0.013, toes),
		_ring(Vector3(x, 0.018, -0.193), 0.0, 0.0, toes),
	], Vector3.FORWARD, Vector3.RIGHT, 12, sole_color, 0.0, -1, false)
	if wears_dhotar:
		# Open leather vamp with a separate loop around the big toe.
		_tube([
			_ring(Vector3(x, 0.045, -0.067), 0.059, 0.045, foot, toes, 0.31),
			_ring(Vector3(x, 0.043, -0.083), 0.060, 0.041, foot, toes, 0.40),
			_ring(Vector3(x, 0.041, -0.111), 0.059, 0.038, foot, toes, 0.53),
		], Vector3.FORWARD, Vector3.RIGHT, 12, CHAPPAL_COLOR, 0.0, -1, false)
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
	], Vector3.UP, Vector3.RIGHT, 12, color, 0.0, -1, false)


func _tube(rings: Array[Ring], along: Vector3, across: Vector3, sides: int, color: Color,
		folds := 0.0, border_sector := -1, fabric := true, has_omkar_armholes := false,
		scanned_fabric := false) -> void:
	var depth_axis := across.cross(along)
	for row: int in range(rings.size() - 1):
		var a := rings[row]
		var b := rings[row + 1]
		for i: int in range(sides):
			if has_omkar_armholes and row >= ARMHOLE_BOTTOM and row < ARMHOLE_TOP:
				var half_turn := i % (OMKAR_TORSO_SIDES / 2)
				if half_turn < ARMHOLE_HALF_ARC or half_turn >= OMKAR_TORSO_SIDES / 2 - ARMHOLE_HALF_ARC:
					continue
			var theta := TAU * float(i) / sides
			var next := TAU * float(i + 1) / sides
			var cloth_color := DHOTAR_BORDER_COLOR if i == border_sector else color
			if a.radii.x > 0.0:
				_vertex(a, theta, across, depth_axis, cloth_color, folds, fabric, scanned_fabric)
				_vertex(a, next, across, depth_axis, cloth_color, folds, fabric, scanned_fabric)
				_vertex(b, theta, across, depth_axis, cloth_color, folds, fabric, scanned_fabric)
			if b.radii.x > 0.0:
				_vertex(a, next, across, depth_axis, cloth_color, folds, fabric, scanned_fabric)
				_vertex(b, next, across, depth_axis, cloth_color, folds, fabric, scanned_fabric)
				_vertex(b, theta, across, depth_axis, cloth_color, folds, fabric, scanned_fabric)


func _vertex(ring: Ring, angle: float, across: Vector3, depth_axis: Vector3, color: Color,
		folds: float, fabric: bool, scanned_fabric := false) -> void:
	var turn := wrapf(angle, 0.0, TAU)
	var radial := across * (ring.radii.x * cos(turn)) + depth_axis * (ring.radii.y * sin(turn))
	if folds > 0.0:
		var fold_angle := turn + ring.crease_offset
		var crease := 0.66 * cos(fold_angle * 5.0) + 0.34 * cos(fold_angle * 7.0 + 0.5)
		radial *= 1.0 + folds * crease
		color = color.darkened(maxf(0.0, -crease) * folds * 0.65)
	if ring.thigh_blend > 0.0:
		# The side of the hem follows its leg. The front and back share both legs.
		var right := 0.5 + 0.5 * cos(turn)
		_surface.set_bones(PackedInt32Array([
			_bone_ids["Hips"], _bone_ids["LeftUpperLeg"], _bone_ids["RightUpperLeg"], 0,
		]))
		_surface.set_weights(PackedFloat32Array([
			1.0 - ring.thigh_blend, (1.0 - right) * ring.thigh_blend, right * ring.thigh_blend, 0.0,
		]))
	else:
		_surface.set_bones(ring.bones)
		_surface.set_weights(ring.weights)
	var point := ring.center + radial
	if scanned_fabric:
		var cloth_height := clampf((ring.center.y - 0.76) / 0.70, 0.0, 1.0)
		_surface.set_uv(Vector2(540.5 + angle / TAU * 451.0, 560.5 + cloth_height * 415.0) / ATLAS_SIZE)
	elif fabric:
		var cloth_height := clampf(ring.center.y + absf(ring.center.x) * 0.50, 0.0, 1.78)
		_surface.set_uv(Vector2(0.012 + angle / TAU * 0.728, 0.012 + cloth_height * 0.251))
	else:
		_surface.set_uv(Vector2(0.90 + (point.x + point.z) * 0.06, 0.04 + point.y * 0.23))
	_surface.set_color(color)
	_surface.add_vertex(point)
