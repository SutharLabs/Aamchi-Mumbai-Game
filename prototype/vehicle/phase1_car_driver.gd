extends "res://character/player_character.gd"
## The hatchback occupant is a visual child of the chassis.

const Hatchback := preload("res://vehicle/phase1_car.gd")
const LimbPose := preload("res://character/limb_pose.gd")
const DRIVER_SCALE := 0.72
const WHEEL_GRIP := Vector3(0.132, 0.0, -0.065)


func _init() -> void:
	name = "SeatedDriver"
	position = Vector3(Hatchback.FRONT_SEAT_OFFSET, 0.51, -0.105)
	scale = Vector3.ONE * DRIVER_SCALE


func _ready() -> void:
	super._ready()
	(get_node("ClothedBody") as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	skeleton.set_bone_pose_position(skeleton.find_bone("Hips"), Vector3.ZERO)
	skeleton.set_bone_pose_rotation(skeleton.find_bone("Spine"), Quaternion(Vector3.RIGHT, -0.48))
	skeleton.set_bone_pose_rotation(skeleton.find_bone("Neck"), Quaternion(Vector3.RIGHT, 0.48))
	for side: float in [-1.0, 1.0]:
		var label := "Left" if side < 0.0 else "Right"
		var hand := Hatchback.STEERING_POSE * Vector3(side * WHEEL_GRIP.x, WHEEL_GRIP.y, WHEEL_GRIP.z)
		var ankle := position + Vector3(side * 0.085, -0.36, -0.37)
		LimbPose.aim(skeleton, Vector3i(skeleton.find_bone(label + "UpperArm"),
			skeleton.find_bone(label + "LowerArm"), skeleton.find_bone(label + "Hand")),
			(hand - position) / DRIVER_SCALE, Vector3(side * 0.55, -0.8, 0.2),
			Quaternion(side * Vector3.RIGHT, Vector3.FORWARD))
		LimbPose.aim(skeleton, Vector3i(skeleton.find_bone(label + "UpperLeg"),
			skeleton.find_bone(label + "LowerLeg"), skeleton.find_bone(label + "Foot")),
			(ankle - position) / DRIVER_SCALE, Vector3(0.0, 1.0, -0.5), Quaternion.IDENTITY)
