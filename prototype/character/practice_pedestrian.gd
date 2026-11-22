extends "res://character/locomotion_visual.gd"

const WALK_SPEED := 0.98

var path_start: Vector3
var path_end: Vector3
var start_fraction := 0.0
var _target: Vector3


func _ready() -> void:
	super._ready()
	position = path_start.lerp(path_end, start_fraction)
	_target = path_end
	var heading := _target - position
	rotation.y = atan2(-heading.x, -heading.z)


func _physics_process(delta: float) -> void:
	if position.distance_squared_to(_target) < 0.0025:
		_target = path_start if _target == path_end else path_end
	var toward_target := _target - position
	var heading := atan2(-toward_target.x, -toward_target.z)
	rotation.y = lerp_angle(rotation.y, heading, 1.0 - exp(-7.0 * delta))
	# Turn at the end of the path before walking back.
	var alignment := maxf(0.0, cos(angle_difference(rotation.y, heading)))
	var step := minf(WALK_SPEED * alignment * delta, toward_target.length())
	position = position.move_toward(_target, step)
	set_ground_speed(step / delta)
