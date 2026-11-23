extends RefCounted
## Drives a person's swept capsule while the visual braces, falls and stands.

const Visual := preload("res://character/locomotion_visual.gd")
const FALL_SPEED := 8.5
const MIN_REACTION_SPEED := 4.5
const STREET_SOLIDS := 1 | 2 | 4
const GRAVITY := 18.0

enum { UPRIGHT, STAGGER, FALLING, DOWN, RISING }

var state := UPRIGHT
var _elapsed := 0.0
var _angle := 0.0
var _speed := 0.0
var _direction := Vector3.ZERO


func apply(body: CharacterBody3D, impulse_direction: Vector3, closing_speed: float) -> void:
	if (not is_finite(closing_speed) or closing_speed < MIN_REACTION_SPEED or not impulse_direction.is_finite()
		or state != UPRIGHT):
		return
	_direction = impulse_direction.slide(Vector3.UP).normalized()
	if _direction.is_zero_approx():
		return
	_speed = closing_speed
	_elapsed = 0.0
	state = FALLING if closing_speed >= FALL_SPEED else STAGGER
	var push := clampf(closing_speed * (0.5 if state == FALLING else 0.40), 1.5, 7.5)
	var lift := clampf((closing_speed - 5.0) * 0.23, 0.75, 2.1) if state == FALLING else 0.0
	body.velocity = _direction * push + Vector3.UP * lift


func step(body: CharacterBody3D, collider: CollisionShape3D, visual: Visual, delta: float) -> bool:
	if state == UPRIGHT:
		return false
	_elapsed += delta
	var grounded := body.is_on_floor() and body.velocity.y <= 0.0
	var drag := 7.5 if grounded else 1.8
	var horizontal := Vector3(body.velocity.x, 0.0, body.velocity.z).move_toward(Vector3.ZERO, drag * delta)
	var vertical := -0.15 if grounded else body.velocity.y - GRAVITY * delta
	body.velocity = horizontal + Vector3.UP * vertical
	body.move_and_slide()

	var desired_angle := _angle
	match state:
		STAGGER:
			var t := clampf(_elapsed / 0.55, 0.0, 1.0)
			desired_angle = sin(t * PI) * lerpf(0.16, 0.35, inverse_lerp(MIN_REACTION_SPEED, FALL_SPEED, _speed))
			if t >= 1.0 and _try_posture(body, collider, visual, 0.0):
				reset(collider, visual)
				return true
		FALLING:
			desired_angle = smoothstep(0.0, 0.46, _elapsed) * PI * 0.48
			if body.is_on_floor() and _elapsed >= 0.46:
				state = DOWN
				_elapsed = 0.0
		DOWN:
			desired_angle = PI * 0.48
			if _elapsed >= clampf(_speed * 0.10, 0.85, 1.65):
				state = RISING
		RISING:
			desired_angle = move_toward(_angle, 0.0, 2.35 * delta)
			if desired_angle <= 0.0001 and _try_posture(body, collider, visual, 0.0):
				reset(collider, visual)
				return true
	_try_posture(body, collider, visual, desired_angle)
	return true


func _try_posture(body: CharacterBody3D, collider: CollisionShape3D, visual: Visual, angle: float) -> bool:
	var capsule := collider.shape as CapsuleShape3D
	var toward := body.global_basis.inverse() * _direction
	var tilt := Basis(Vector3.UP.cross(toward).normalized(), angle)
	var pivot := Vector3.UP * capsule.height * 0.5
	var center := Vector3.UP * (capsule.radius + (pivot.y - capsule.radius) * cos(angle))
	if not is_equal_approx(_angle, angle):
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		# Lift the clearance query above the support surface while tilting.
		query.transform = body.global_transform * Transform3D(tilt, center + Vector3.UP * 0.035)
		query.exclude = [body.get_rid()]
		query.collision_mask = STREET_SOLIDS
		if not body.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			return false
	_angle = angle
	collider.transform = Transform3D(tilt, center)
	# The capsule leaves clearance around the arms. Settle the thinner torso
	# down into that clearance as the visual approaches the ground.
	var settle := Vector3.UP * (0.14 * pow(sin(angle), 4.0))
	visual.transform = Transform3D(tilt, center - tilt * pivot - settle)
	var brace := sin(_angle) if state != STAGGER else clampf(_angle * 2.5, 0.0, 1.0)
	visual.set_impact_brace(brace)
	return true


func reset(collider: CollisionShape3D, visual: Visual) -> void:
	state = UPRIGHT
	_elapsed = 0.0
	_angle = 0.0
	var capsule := collider.shape as CapsuleShape3D
	collider.transform = Transform3D(Basis.IDENTITY, Vector3.UP * capsule.height * 0.5)
	visual.transform = Transform3D.IDENTITY
	visual.end_impact_brace()
