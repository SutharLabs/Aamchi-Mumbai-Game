extends "res://character/player_character.gd"

const MOTIONS := preload("res://character/motion/phase1_motions.tres")
const FALLS := preload("res://character/motion/cmu_falls.tres")
const CAPTURED_RUN := preload("res://character/motion/cmu_run.tres")
const WALK_REFERENCE_SPEED := 0.893
const RUN_REFERENCE_SPEED := 2.937
const RUN_THRESHOLD := 1.44
const RUN_EXIT_THRESHOLD := 1.28

static var _ground_motions: AnimationLibrary
var animation_player := AnimationPlayer.new()


func _ready() -> void:
	super._ready()
	animation_player.name = "Locomotion"
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	add_child(animation_player)
	if _ground_motions == null:
		_ground_motions = MOTIONS.duplicate() as AnimationLibrary
		_ground_motions.remove_animation(&"run")
		_ground_motions.add_animation(&"run", CAPTURED_RUN)
	animation_player.add_animation_library(&"", _ground_motions)
	animation_player.add_animation_library(&"impacts", FALLS)
	animation_player.play(&"idle")


func set_ground_speed(speed: float) -> void:
	var clip := &"idle"
	var playback_rate := 1.0
	var was_running := animation_player.current_animation == &"run"
	if speed >= (RUN_EXIT_THRESHOLD if was_running else RUN_THRESHOLD):
		clip = &"run"
		playback_rate = clampf(speed / RUN_REFERENCE_SPEED, 0.40, 1.35)
	elif speed > 0.18:
		clip = &"walk"
		playback_rate = clampf(speed / WALK_REFERENCE_SPEED, 0.35, 1.4)
	animation_player.speed_scale = playback_rate
	if animation_player.current_animation != clip:
		animation_player.play(clip, 0.10 if clip == &"run" else 0.16)


func play_action(clip: StringName, duration: float, blend: float) -> void:
	animation_player.speed_scale = animation_player.get_animation(clip).length / duration
	animation_player.play(clip, blend)


func pose_captured_fall(clip: StringName, progress: float, settle: float) -> void:
	animation_player.active = true
	if animation_player.assigned_animation != clip:
		animation_player.speed_scale = 1.0
		animation_player.play(clip)
		animation_player.pause()
	animation_player.seek(animation_player.get_animation(clip).length * progress, true)
	if settle > 0.0:
		# Ease the captured landing's residual leg lift as the body comes to rest.
		for side: String in ["Left", "Right"]:
			var thigh := skeleton.find_bone(side + "UpperLeg")
			var relief := -0.10 if side == "Left" else 0.06
			var rested := Quaternion(Vector3.RIGHT, relief)
			var weight := 0.85 if clip == &"impacts/fall_backward" else 0.25
			skeleton.set_bone_pose_rotation(thigh,
				skeleton.get_bone_pose_rotation(thigh).slerp(rested, settle * weight))


func set_impact_brace(amount: float) -> void:
	if animation_player.active:
		animation_player.active = false
		skeleton.reset_bone_poses()
	skeleton.set_bone_pose_rotation(skeleton.find_bone("Chest"), Quaternion(Vector3.RIGHT, -0.20 * amount))
	skeleton.set_bone_pose_rotation(skeleton.find_bone("Head"), Quaternion(Vector3.RIGHT, 0.24 * amount))
	for side: float in [-1.0, 1.0]:
		var name_prefix := "Left" if side < 0.0 else "Right"
		var arm := Basis(Vector3.FORWARD, side * lerpf(1.24, 0.83, amount)) * Basis(Vector3.UP, side * 0.35 * amount)
		skeleton.set_bone_pose_rotation(skeleton.find_bone(name_prefix + "UpperArm"), arm.get_rotation_quaternion())
		skeleton.set_bone_pose_rotation(skeleton.find_bone(name_prefix + "LowerArm"), Quaternion(Vector3.UP, side * 0.66 * amount))
		var knee := (0.37 + side * 0.1) * amount
		skeleton.set_bone_pose_rotation(skeleton.find_bone(name_prefix + "UpperLeg"), Quaternion(Vector3.RIGHT, -knee * 0.6))
		skeleton.set_bone_pose_rotation(skeleton.find_bone(name_prefix + "LowerLeg"), Quaternion(Vector3.RIGHT, knee))


func end_impact_brace() -> void:
	animation_player.active = true
	animation_player.stop()
	animation_player.play(&"idle")
	animation_player.advance(0.0)
