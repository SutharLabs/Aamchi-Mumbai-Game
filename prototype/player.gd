extends CharacterBody3D

const WALK_SPEED := 4.6
const BODY_HEIGHT := 1.68
const BODY_RADIUS := 0.31

var body_shape := CapsuleShape3D.new()
var active := true
var direction := Vector3.ZERO


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	floor_snap_length = 0.22
	body_shape.radius = BODY_RADIUS
	body_shape.height = BODY_HEIGHT
	var collider := CollisionShape3D.new()
	collider.position.y = BODY_HEIGHT * 0.5
	collider.shape = body_shape
	add_child(collider)
	_add_box(Vector3(0.48, 0.56, 0.31), Vector3(0.0, 1.05, 0.0), Color("228e9b"))
	_add_box(Vector3(0.27, 0.29, 0.27), Vector3(0.0, 1.52, 0.0), Color("b97c55"))
	_add_box(Vector3(0.28, 0.09, 0.28), Vector3(0.0, 1.65, 0.0), Color("262932"))
	for side in [-1.0, 1.0]:
		_add_box(Vector3(0.17, 0.71, 0.23), Vector3(side * 0.13, 0.38, 0.0), Color("303847"))
		_add_box(Vector3(0.13, 0.44, 0.17), Vector3(side * 0.32, 0.99, 0.0), Color("b97c55"))


func set_on_foot(enabled: bool) -> void:
	active = enabled
	visible = enabled
	collision_layer = 2 if enabled else 0
	collision_mask = 1 | 4 if enabled else 0
	velocity = Vector3.ZERO
	direction = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if not active:
		return
	var weight := minf(delta * 18.0, 1.0)
	velocity.x = lerpf(velocity.x, direction.x * WALK_SPEED, weight)
	velocity.z = lerpf(velocity.z, direction.z * WALK_SPEED, weight)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= 18.0 * delta
	if direction.length_squared() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), minf(delta * 14.0, 1.0))
	move_and_slide()


func _add_box(size: Vector3, offset: Vector3, tint: Color) -> void:
	var box := BoxMesh.new()
	box.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	var visual := MeshInstance3D.new()
	visual.mesh = box
	visual.material_override = material
	visual.position = offset
	add_child(visual)
