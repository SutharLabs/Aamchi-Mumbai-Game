extends CharacterBody3D

const Visual := preload("res://character/locomotion_visual.gd")
const ImpactReaction := preload("res://character/vehicle_impact_reaction.gd")
const WALK_SPEED := 0.98
const BODY_HEIGHT := 1.68
const BODY_RADIUS := 0.29
const TURN_RESPONSE := 7.0
const BLOCKED_TURN_TIME := 1.2
const WORLD_LAYER := 1
const PERSON_LAYER := 2
const VEHICLE_LAYER := 4

var path_start: Vector3
var path_end: Vector3
var start_fraction := 0.0
var display_name := "Pedestrian"
var greeting := "Hello."
var shirt_color := Color("a4654d")
var wears_overshirt := false
var visual := Visual.new()
var animation_player: AnimationPlayer:
	get:
		return visual.animation_player

var _target: Vector3
var _blocked_time := 0.0
var _conversation_time := 0.0
var _speaker_position := Vector3.ZERO
var _collider := CollisionShape3D.new()
var _impact := ImpactReaction.new()
var _return_to_path := false


func _ready() -> void:
	collision_layer = PERSON_LAYER
	collision_mask = WORLD_LAYER | PERSON_LAYER | VEHICLE_LAYER
	platform_floor_layers = WORLD_LAYER
	floor_snap_length = 0.18
	var capsule := CapsuleShape3D.new()
	capsule.radius = BODY_RADIUS
	capsule.height = BODY_HEIGHT
	_collider.position.y = BODY_HEIGHT * 0.5
	_collider.shape = capsule
	add_child(_collider)
	visual.name = "CharacterVisual"
	visual.shirt_color = shirt_color
	visual.wears_overshirt = wears_overshirt
	add_child(visual)
	reset_to_path()


func reset_to_path() -> void:
	position = path_start.lerp(path_end, clampf(start_fraction, 0.0, 1.0))
	velocity = Vector3.ZERO
	_target = path_end
	_blocked_time = 0.0
	_conversation_time = 0.0
	_return_to_path = false
	if is_reacting():
		_impact.reset(_collider, visual)
	var direction := _target - position
	rotation.y = atan2(-direction.x, -direction.z)
	visual.set_ground_speed(0.0)
	reset_physics_interpolation()


func begin_conversation(speaker_position: Vector3, duration: float) -> void:
	if not is_reacting() and speaker_position.is_finite() and is_finite(duration):
		_speaker_position = speaker_position
		_conversation_time = maxf(0.0, duration)
		_blocked_time = 0.0


func receive_vehicle_impact(direction: Vector3, closing_speed: float) -> void:
	_impact.apply(self, direction, closing_speed)
	if is_reacting():
		_conversation_time = 0.0
		_return_to_path = true


func is_reacting() -> bool:
	return _impact.state != ImpactReaction.UPRIGHT


func _physics_process(delta: float) -> void:
	if _impact.step(self, _collider, visual, delta):
		return
	if _conversation_time > 0.0:
		_conversation_time = maxf(0.0, _conversation_time - delta)
		_face(_speaker_position - global_position, delta)
		_move(Vector3.ZERO, delta)
		return
	var destination := _target
	if _return_to_path:
		destination = Geometry3D.get_closest_point_to_segment(position, path_start, path_end)
		if destination.distance_squared_to(position) < 0.15:
			_return_to_path = false
			destination = _target
	if (destination - position).slide(Vector3.UP).length_squared() < 0.0025:
		_turn_back()
		destination = _target
	var toward_target := (destination - position).slide(Vector3.UP)
	var direction := toward_target.normalized()
	_face(direction, delta)
	# Give the walker time to turn around before advancing along the path.
	var alignment := maxf(0.0, (-global_basis.z).dot(direction))
	var speed := minf(WALK_SPEED * alignment, toward_target.length() / delta)
	var travel := _move(direction * speed, delta)
	if speed > 0.2 and travel.dot(direction) < 0.12:
		_blocked_time += delta
		if _blocked_time >= BLOCKED_TURN_TIME:
			_return_to_path = false
			_turn_back()
	else:
		_blocked_time = 0.0


func _turn_back() -> void:
	_target = path_start if _target == path_end else path_end
	_blocked_time = 0.0


func _face(direction: Vector3, delta: float) -> void:
	if Vector2(direction.x, direction.z).length_squared() > 0.0001:
		var heading := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, heading, 1.0 - exp(-TURN_RESPONSE * delta))


func _move(horizontal_velocity: Vector3, delta: float) -> Vector3:
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - 18.0 * delta
	move_and_slide()
	var travel := get_real_velocity().slide(Vector3.UP)
	visual.set_ground_speed(travel.length())
	return travel
