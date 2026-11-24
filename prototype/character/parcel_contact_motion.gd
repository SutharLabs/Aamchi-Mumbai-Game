extends RefCounted
## In-place street poses grounded to the authored shoe surface.

const REST_SAMPLE := 0.32
const SAMPLE_COUNT := 24
const OFFER_TIME := 1.65
const RECEIVE_TIME := 1.45


static func create_library(actor: Node3D, receiving: bool) -> AnimationLibrary:
	var player: AnimationPlayer = actor.animation_player
	var skeleton: Skeleton3D = actor.skeleton
	player.play(&"idle")
	player.pause()
	player.seek(REST_SAMPLE, true)
	skeleton.force_update_all_bone_transforms()

	var floor_offset := get_sole_height(actor)
	var library := AnimationLibrary.new()
	var breath_duration := 4.80 if receiving else 4.25
	library.add_animation(&"breath", _make_clip(skeleton, floor_offset, breath_duration, false, receiving))
	var gesture_duration := RECEIVE_TIME if receiving else OFFER_TIME
	library.add_animation(&"gesture", _make_clip(skeleton, floor_offset, gesture_duration, true, receiving))
	return library


static func get_sole_height(actor: Node3D) -> float:
	var body := actor.get_node("ClothedBody") as MeshInstance3D
	var arrays := body.mesh.surface_get_arrays(0)
	var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var transforms: Array[Transform3D] = []
	for bind in body.skin.get_bind_count():
		var bone := body.skin.get_bind_bone(bind)
		transforms.append(actor.skeleton.get_bone_global_pose(bone) * body.skin.get_bind_pose(bind))
	var lowest := INF
	for index in positions.size():
		if positions[index].y > 0.10:
			continue
		var height := 0.0
		for slot in range(index * 4, index * 4 + 4):
			if weights[slot] > 0.0:
				height += (transforms[bones[slot]] * positions[index]).y * weights[slot]
		lowest = minf(lowest, height)
	return lowest


static func _make_clip(skeleton: Skeleton3D, floor_offset: float, duration: float,
		gesturing: bool, receiving: bool) -> Animation:
	var clip := Animation.new()
	clip.length = duration
	clip.loop_mode = Animation.LOOP_NONE if gesturing else Animation.LOOP_LINEAR
	var hips := skeleton.find_bone("Hips")
	var root_position := skeleton.get_bone_pose_position(hips) - Vector3.UP * floor_offset
	var translation := clip.add_track(Animation.TYPE_POSITION_3D)
	clip.track_set_path(translation, NodePath("Skeleton3D:Hips"))
	clip.position_track_insert_key(translation, 0.0, root_position)
	clip.position_track_insert_key(translation, duration, root_position)

	for bone in skeleton.get_bone_count():
		var label := skeleton.get_bone_name(bone)
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath("Skeleton3D:" + label))
		var rest := skeleton.get_bone_pose_rotation(bone)
		for index in range(SAMPLE_COUNT + 1):
			var progress := float(index) / float(SAMPLE_COUNT)
			var pose := _gesture_pose(label, rest, progress, receiving) if gesturing else _breath_pose(label, rest, progress)
			clip.rotation_track_insert_key(track, duration * progress, pose.normalized())
	return clip


static func _breath_pose(bone: String, rest: Quaternion, progress: float) -> Quaternion:
	var rise := sin(progress * TAU)
	var sway := sin(progress * TAU * 2.0)
	match bone:
		"Chest":
			return rest * Quaternion(Vector3.RIGHT, -rise * 0.022)
		"Neck":
			return rest * Quaternion(Vector3.FORWARD, sway * 0.015)
		"Head":
			return rest * Quaternion(Vector3.UP, rise * 0.027) * Quaternion(Vector3.RIGHT, rise * 0.013)
		"LeftUpperArm", "RightUpperArm":
			return rest * Quaternion(Vector3.UP, sway * 0.019)
		_:
			return rest


static func _gesture_pose(bone: String, rest: Quaternion, progress: float, receiving: bool) -> Quaternion:
	var reach := smoothstep(0.10, 0.42, progress) * (1.0 - smoothstep(0.57, 0.97, progress))
	var nod := smoothstep(0.10, 0.23, progress) * (1.0 - smoothstep(0.30, 0.50, progress))
	match bone:
		"Head":
			return rest * Quaternion(Vector3.RIGHT, -0.11 * nod)
		"Chest":
			return rest * Quaternion(Vector3.UP, -0.038 * reach)
		"RightUpperArm":
			var forward := Quaternion(Vector3.UP, 0.51 if receiving else 0.63)
			var lowered := Quaternion(Vector3.BACK, -1.06 if receiving else -0.93)
			return rest.slerp(forward * lowered, reach)
		"RightLowerArm":
			var elbow := Quaternion(Vector3.BACK, 0.85 if receiving else 0.81)
			var inward := Quaternion(Vector3.UP, 0.94 if receiving else 0.76)
			return rest.slerp(inward * elbow, reach)
		"RightHand":
			return rest * Quaternion(Vector3.RIGHT, 0.21 * reach)
		_:
			return rest
