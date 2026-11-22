extends "res://character/player_character.gd"

const MOTIONS := preload("res://character/motion/phase1_motions.tres")
const WALK_REFERENCE_SPEED := 0.893
const RUN_REFERENCE_SPEED := 1.743
const RUN_THRESHOLD := 1.44

var animation_player := AnimationPlayer.new()


func _ready() -> void:
	super._ready()
	animation_player.name = "Locomotion"
	animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
	add_child(animation_player)
	animation_player.add_animation_library(&"", MOTIONS)
	animation_player.play(&"idle")


func set_ground_speed(speed: float) -> void:
	var clip := &"idle"
	var playback_rate := 1.0
	if speed >= RUN_THRESHOLD:
		clip = &"run"
		playback_rate = clampf(speed / RUN_REFERENCE_SPEED, 0.55, 1.35)
	elif speed > 0.18:
		clip = &"walk"
		playback_rate = clampf(speed / WALK_REFERENCE_SPEED, 0.35, 1.4)
	animation_player.speed_scale = playback_rate
	if animation_player.current_animation != clip:
		animation_player.play(clip, 0.16)
