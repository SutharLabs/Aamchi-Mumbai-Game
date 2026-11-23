extends CharacterBody3D

const Visual := preload("res://character/locomotion_visual.gd")
const ImpactReaction := preload("res://character/vehicle_impact_reaction.gd")
const WALK_SPEED := 1.12
const RUN_SPEED := 3.05
const BODY_HEIGHT := 1.68
const BODY_RADIUS := 0.31
const STREET_SOLIDS := 1 | 2 | 4
const GRAVITY := 18.0
const JUMP_VELOCITY := 4.45
const TAKEOFF_TIME := 0.08
const LANDING_TIME := 0.15

enum { GROUNDED, TAKEOFF, AIRBORNE, LANDING }

var body_shape := CapsuleShape3D.new()
var visual := Visual.new()
var display_name := "Omkar Shirodkar"
var active := true
var running := false
var direction := Vector3.ZERO
var _collider := CollisionShape3D.new()
var _impact := ImpactReaction.new()
var _jump_stage := GROUNDED
var _jump_seconds := 0.0
var _jump_requested := false


func _ready() -> void:
	collision_layer = 2
	collision_mask = STREET_SOLIDS
	floor_snap_length = 0.22
	body_shape.radius = BODY_RADIUS
	body_shape.height = BODY_HEIGHT
	_collider.position.y = BODY_HEIGHT * 0.5
	_collider.shape = body_shape
	add_child(_collider)
	visual.name = "CharacterVisual"
	visual.wears_dhotar = true
	add_child(visual)


func set_on_foot(enabled: bool) -> void:
	active = enabled
	visible = enabled
	collision_layer = 2 if enabled else 0
	collision_mask = STREET_SOLIDS if enabled else 0
	velocity = Vector3.ZERO
	direction = Vector3.ZERO
	running = false
	_jump_stage = GROUNDED
	_jump_requested = false
	if is_reacting():
		_impact.reset(_collider, visual)
	visual.animation_player.active = enabled
	if enabled:
		visual.set_ground_speed(0.0)


func receive_vehicle_impact(direction: Vector3, closing_speed: float) -> void:
	if active:
		_impact.apply(self, direction, closing_speed)


func is_reacting() -> bool:
	return _impact.state != ImpactReaction.UPRIGHT


func request_jump() -> void:
	_jump_requested = active


func can_interact() -> bool:
	return not is_reacting() and _jump_stage != TAKEOFF and _jump_stage != AIRBORNE


func _physics_process(delta: float) -> void:
	if not active:
		return
	var jump := _jump_requested or Input.is_action_just_pressed(&"brake")
	_jump_requested = false
	if _impact.step(self, _collider, visual, delta):
		_jump_stage = GROUNDED
		return
	if jump and _jump_stage == GROUNDED and is_on_floor():
		_jump_stage = TAKEOFF
		_jump_seconds = TAKEOFF_TIME
		visual.play_action(&"jump_takeoff", TAKEOFF_TIME, 0.05)
	var weight := minf(delta * (7.0 if _jump_stage == AIRBORNE else 18.0), 1.0)
	var target_speed := RUN_SPEED if running else WALK_SPEED
	velocity.x = lerpf(velocity.x, direction.x * target_speed, weight)
	velocity.z = lerpf(velocity.z, direction.z * target_speed, weight)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	_advance_jump(delta)
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 14.0, 1.0))
	move_and_slide()
	if _jump_stage == AIRBORNE and is_on_floor():
		_jump_stage = LANDING
		_jump_seconds = LANDING_TIME
		visual.play_action(&"jump_land", LANDING_TIME, 0.06)
	if _jump_stage == GROUNDED:
		var travel := get_real_velocity()
		visual.set_ground_speed(Vector2(travel.x, travel.z).length())


func _advance_jump(delta: float) -> void:
	if _jump_stage == TAKEOFF:
		if not is_on_floor():
			_jump_stage = GROUNDED
		else:
			_jump_seconds -= delta
			if _jump_seconds <= 0.0:
				_jump_stage = AIRBORNE
				velocity.y = JUMP_VELOCITY
				visual.play_action(&"jump_air", 2.0 * JUMP_VELOCITY / GRAVITY, 0.03)
	elif _jump_stage == LANDING:
		_jump_seconds -= delta
		if _jump_seconds <= 0.0:
			_jump_stage = GROUNDED
