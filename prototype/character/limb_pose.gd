extends RefCounted
## Positions a wrist or ankle using the existing humanoid bone lengths.


static func aim(rig: Skeleton3D, joints: Vector3i, goal: Vector3, pole: Vector3, endpoint_rotation: Quaternion) -> void:
	var start := rig.get_bone_global_pose(joints.x).origin
	var upper := rig.get_bone_rest(joints.y).origin
	var lower := rig.get_bone_rest(joints.z).origin
	var upper_length := upper.length()
	var lower_length := lower.length()
	var offset := goal - start
	var reach := clampf(offset.length(), absf(upper_length - lower_length) + 0.001, upper_length + lower_length - 0.001)
	var axis := offset.normalized()
	var bend := (pole - axis * pole.dot(axis)).normalized()
	var bend_along := (upper_length * upper_length - lower_length * lower_length + reach * reach) / (2.0 * reach)
	var joint := start + axis * bend_along + bend * sqrt(maxf(0.0, upper_length * upper_length - bend_along * bend_along))
	var finish := start + axis * reach
	_set_global_rotation(rig, joints.x, Quaternion(upper.normalized(), (joint - start).normalized()))
	_set_global_rotation(rig, joints.y, Quaternion(lower.normalized(), (finish - joint).normalized()))
	_set_global_rotation(rig, joints.z, endpoint_rotation)


static func _set_global_rotation(rig: Skeleton3D, bone: int, target: Quaternion) -> void:
	var parent := rig.get_bone_global_pose(rig.get_bone_parent(bone)).basis.get_rotation_quaternion()
	rig.set_bone_pose_rotation(bone, (parent.inverse() * target).normalized())
