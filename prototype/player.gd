extends CharacterBody3D

const Visual := preload("res://character/locomotion_visual.gd")
const WALK_SPEED := 1.12
const RUN_SPEED := 2.18
const BODY_HEIGHT := 1.68
const BODY_RADIUS := 0.31
const STREET_SOLIDS := 1 | 2 | 4

var body_shape := CapsuleShape3D.new()
var visual := Visual.new()
var active := true
var running := false
var direction := Vector3.ZERO


func _ready() -> void:
	collision_layer = 2
	collision_mask = STREET_SOLIDS
	floor_snap_length = 0.22
	body_shape.radius = BODY_RADIUS
	body_shape.height = BODY_HEIGHT
	var collider := CollisionShape3D.new()
	collider.position.y = BODY_HEIGHT * 0.5
	collider.shape = body_shape
	add_child(collider)
	visual.name = "CharacterVisual"
	add_child(visual)


func set_on_foot(enabled: bool) -> void:
	active = enabled
	visible = enabled
	collision_layer = 2 if enabled else 0
	collision_mask = STREET_SOLIDS if enabled else 0
	velocity = Vector3.ZERO
	direction = Vector3.ZERO
	running = false
	visual.animation_player.active = enabled
	if enabled:
		visual.set_ground_speed(0.0)


func _physics_process(delta: float) -> void:
	if not active:
		return
	var weight := minf(delta * 18.0, 1.0)
	var target_speed := RUN_SPEED if running else WALK_SPEED
	velocity.x = lerpf(velocity.x, direction.x * target_speed, weight)
	velocity.z = lerpf(velocity.z, direction.z * target_speed, weight)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= 18.0 * delta
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 14.0, 1.0))
	move_and_slide()
	var travel := get_real_velocity()
	visual.set_ground_speed(Vector2(travel.x, travel.z).length())
