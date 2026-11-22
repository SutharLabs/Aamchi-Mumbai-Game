extends "res://vehicle/phase1_vehicle.gd"
## Shared arcade two-wheel presentation. Collision stays upright while the
## original primitive body and its seated rider lean together visually.

var rider: Node3D = Node3D.new()
var lean_visual: Node3D = Node3D.new()
var max_lean_radians: float = deg_to_rad(22.0)
var lean_response: float = 8.0


func _init() -> void:
	super()
	is_two_wheeler = true
	lean_visual.name = "LeanVisual"
	add_child(lean_visual)
	rider.name = "SeatedRider"
	rider.visible = false
	lean_visual.add_child(rider)


func set_driver_active(active: bool) -> void:
	super.set_driver_active(active)
	rider.visible = active


func reset_to(pose: Transform3D) -> void:
	super.reset_to(pose)
	lean_visual.rotation = Vector3.ZERO
	rider.visible = driver_active


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var target_lean: float = 0.0
	if driver_active and is_on_floor():
		var lean_speed: float = clampf(get_speed_mps() / 7.0, 0.0, 1.0)
		target_lean = -_steering * signf(_signed_speed) * max_lean_radians * lean_speed
	var smoothing: float = 1.0 - exp(-lean_response * delta)
	lean_visual.rotation.z = clampf(
		lerpf(lean_visual.rotation.z, target_lean, smoothing),
		-max_lean_radians,
		max_lean_radians
	)


func _visual_box(part_name: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	return _part_box(lean_visual, part_name, size, at, material)


func _part_box(parent: Node3D, part_name: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.material_override = material
	part.position = at
	parent.add_child(part)
	return part


func _visual_wheel(at: Vector3, tire: Material, hub: Material, front: bool, width: float) -> Node3D:
	var wheel: Node3D = _add_wheel_at(at, tire, hub, front, wheel_radius, width)
	# The common controller keeps wheel-roll/steer references; only their visual
	# parent changes, never the upright CharacterBody3D collision shape.
	remove_child(wheel)
	lean_visual.add_child(wheel)
	return wheel


func _build_rider(step_through: bool) -> void:
	var shirt: StandardMaterial3D = _material(Color(0.17, 0.43, 0.48))
	var trousers: StandardMaterial3D = _material(Color(0.13, 0.17, 0.22))
	var skin: StandardMaterial3D = _material(Color(0.53, 0.32, 0.20))
	var helmet: StandardMaterial3D = _material(Color(0.94, 0.80, 0.44))
	var visor: StandardMaterial3D = _material(Color(0.055, 0.11, 0.15))
	var shoes: StandardMaterial3D = _material(Color(0.045, 0.05, 0.055))
	var hips := Vector3(0.0, 0.38, 0.18)
	var shoulders := Vector3(0.0, 0.83, 0.04)
	var head := Vector3(0.0, 1.16, -0.025)
	if step_through:
		hips = Vector3(0.0, 0.40, 0.24)
		shoulders = Vector3(0.0, 0.89, 0.19)
		head = Vector3(0.0, 1.20, 0.15)
	rider.position = hips
	_rider_box("Hips", Vector3(0.31, 0.18, 0.22), hips, trousers)
	var torso := _rider_box("Torso", Vector3(0.36, 0.45, 0.22), (hips + shoulders) * 0.5, shirt)
	torso.quaternion = Quaternion(Vector3.UP, (shoulders - hips).normalized())
	_rider_limb("Neck", shoulders + Vector3(0.0, 0.01, 0.0), head + Vector3(0.0, -0.12, 0.0), 0.065, skin)
	var helmet_mesh := MeshInstance3D.new()
	helmet_mesh.name = "Helmet"
	var sphere := SphereMesh.new()
	sphere.radius = 0.165
	sphere.height = 0.33
	sphere.radial_segments = 12
	sphere.rings = 6
	helmet_mesh.mesh = sphere
	helmet_mesh.material_override = helmet
	helmet_mesh.position = head - hips
	rider.add_child(helmet_mesh)
	_rider_box("ForwardVisor", Vector3(0.235, 0.095, 0.045), head + Vector3(0.0, -0.005, -0.15), visor)
	for side: float in [-1.0, 1.0]:
		var shoulder: Vector3 = shoulders + Vector3(side * 0.18, -0.015, 0.0)
		var elbow := Vector3(side * 0.25, 0.62, -0.28)
		var hand := Vector3(side * 0.29, 0.52, -0.57)
		var knee := Vector3(side * 0.25, 0.12, -0.18)
		var ankle := Vector3(side * 0.20, -0.14, 0.10)
		if step_through:
			elbow = Vector3(side * 0.25, 0.66, -0.10)
			hand = Vector3(side * 0.28, 0.57, -0.52)
			knee = Vector3(side * 0.14, 0.14, -0.18)
			ankle = Vector3(side * 0.14, -0.19, -0.35)
		_rider_limb("UpperArm", shoulder, elbow, 0.065, shirt)
		_rider_limb("Forearm", elbow, hand, 0.05, skin)
		_rider_box("Hand", Vector3(0.095, 0.085, 0.105), hand, skin)
		_rider_limb("Thigh", hips + Vector3(side * 0.105, -0.01, 0.0), knee, 0.085, trousers)
		_rider_limb("Shin", knee, ankle, 0.07, trousers)
		_rider_box("Shoe", Vector3(0.13, 0.09, 0.255), ankle + Vector3(0.0, -0.015, -0.055), shoes)


func _rider_box(part_name: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	return _part_box(rider, part_name, size, at - rider.position, material)


func _rider_limb(part_name: String, start: Vector3, finish: Vector3, radius: float, material: Material) -> void:
	var offset: Vector3 = finish - start
	var part := MeshInstance3D.new()
	part.name = part_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = offset.length()
	mesh.radial_segments = 6
	mesh.rings = 1
	part.mesh = mesh
	part.material_override = material
	part.position = (start + finish) * 0.5 - rider.position
	part.quaternion = Quaternion(Vector3.UP, offset.normalized())
	rider.add_child(part)
