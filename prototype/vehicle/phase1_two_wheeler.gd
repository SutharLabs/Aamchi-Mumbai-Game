extends "res://vehicle/phase1_vehicle.gd"
## The visual chassis and skinned rider lean together on an upright collision body.

const Geometry := preload("res://vehicle/vehicle_body_mesh.gd")
const Character := preload("res://character/player_character.gd")
const LimbPose := preload("res://character/limb_pose.gd")
const PROFILE_SIDES := 12

var rider := Node3D.new()
var lean_visual := Node3D.new()
var max_lean_radians := deg_to_rad(22.0)
var lean_response := 8.0
var avatar_options: Dictionary = {}:
	set(options):
		avatar_options = options
		_rider_model.avatar_options = options

var _cockpit := Node3D.new()
var _rider_model := Character.new()
var _grip_half_width := 0.31
var _grip_sweep := 0.0
var _ankle_point := Vector3.ZERO
var _step_through := false
var _arm_joints: Array[Vector3i] = []


func _init() -> void:
	super()
	is_two_wheeler = true
	lean_visual.name = "LeanVisual"
	add_child(lean_visual)
	_cockpit.name = "SteeringCockpit"
	lean_visual.add_child(_cockpit)
	rider.name = "SeatedRider"
	rider.visible = false
	lean_visual.add_child(rider)


func _ready() -> void:
	super._ready()
	var rig: Skeleton3D = _rider_model.skeleton
	rig.set_bone_pose_position(rig.find_bone("Hips"), Vector3.ZERO)
	_set_rider_pitch("Hips", -0.11 if _step_through else -0.23)
	_set_rider_pitch("Chest", 0.02 if _step_through else -0.10)
	_set_rider_pitch("Neck", 0.23 if _step_through else 0.63)
	_set_rider_pitch("Head", 0.12 if _step_through else 0.18)
	for side: float in [-1.0, 1.0]:
		var label := "Left" if side < 0.0 else "Right"
		_arm_joints.append(Vector3i(
			rig.find_bone(label + "UpperArm"),
			rig.find_bone(label + "LowerArm"),
			rig.find_bone(label + "Hand")
		))
		var ankle := Vector3(side * _ankle_point.x, _ankle_point.y, _ankle_point.z)
		var leg := Vector3i(
			rig.find_bone(label + "UpperLeg"),
			rig.find_bone(label + "LowerLeg"),
			rig.find_bone(label + "Foot")
		)
		var knee := Vector3(side * (0.26 if _step_through else 1.05), 0.05, -1.0)
		LimbPose.aim(rig, leg, ankle - rider.position, knee, Quaternion.IDENTITY)
	_pose_grip()
	_add_helmet()


func set_driver_active(active: bool) -> void:
	super.set_driver_active(active)
	rider.visible = active


func reset_to(pose: Transform3D) -> void:
	super.reset_to(pose)
	lean_visual.rotation = Vector3.ZERO
	rider.visible = driver_active
	if is_node_ready():
		_update_cockpit(0.0)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	var target_lean := 0.0
	if driver_active and is_on_floor():
		var lean_speed := clampf(get_speed_mps() / 7.0, 0.0, 1.0)
		target_lean = -_steering * signf(_signed_speed) * max_lean_radians * lean_speed
	var smoothing := 1.0 - exp(-lean_response * delta)
	lean_visual.rotation.z = lerpf(lean_visual.rotation.z, target_lean, smoothing)
	_update_cockpit(-_steering * visual_steering_angle if driver_active else 0.0)


func _update_cockpit(angle: float) -> void:
	if not is_equal_approx(_cockpit.rotation.y, angle):
		_cockpit.rotation.y = angle
		_pose_grip()


func _build_rider(hips: Vector3, ankles: Vector3, step_through: bool) -> void:
	rider.position = hips
	_ankle_point = ankles
	_step_through = step_through
	_rider_model.wears_dhotar = true
	rider.add_child(_rider_model)


func _set_rider_pitch(label: String, angle: float) -> void:
	var rig: Skeleton3D = _rider_model.skeleton
	rig.set_bone_pose_rotation(rig.find_bone(label), Quaternion(Vector3.RIGHT, angle))


func _pose_grip() -> void:
	var rig: Skeleton3D = _rider_model.skeleton
	var pitch := Quaternion(Vector3.RIGHT, -0.46 if _step_through else -0.52)
	var twist := Quaternion(Vector3.UP, _cockpit.rotation.y * 0.85)
	rig.set_bone_pose_rotation(rig.find_bone("Spine"), twist * pitch)
	for i in range(_arm_joints.size()):
		var side := -1.0 if i == 0 else 1.0
		var wrist := _cockpit.transform * Vector3(side * _grip_half_width, 0.006, _grip_sweep + 0.042)
		var facing := _cockpit.basis * Vector3.FORWARD
		LimbPose.aim(rig, _arm_joints[i], wrist - rider.position, Vector3(side * 0.65, -1.0, 0.2),
			Quaternion(side * Vector3.RIGHT, facing))


func _add_helmet() -> void:
	var head := BoneAttachment3D.new()
	head.bone_name = "Head"
	_rider_model.skeleton.add_child(head)
	var shell := _finish(Color("555e69"), 0.32, 0.20)
	var visor := _finish(Color("18252b"), 0.27, 0.10)
	_round_part(head, "HelmetShell", Vector3(0.112, 0.125, 0.114), Vector3(0, 0.101, 0.002), shell)
	_profile(head, "HelmetVisor", [
		Vector4(-0.128, 0.098, 0.047, 0.023), Vector4(-0.116, 0.100, 0.090, 0.039),
		Vector4(-0.078, 0.104, 0.105, 0.039), Vector4(-0.054, 0.105, 0.092, 0.032),
	], visor, 0.76)


# Authored sections list Z, center Y, half width and half height in metres.
func _profile(parent: Node3D, label: String, sections: Array[Vector4], material: Material,
		power := 0.78) -> MeshInstance3D:
	var rings: Array[PackedVector3Array] = []
	for section: Vector4 in sections:
		var ring := PackedVector3Array()
		for i in range(PROFILE_SIDES):
			var angle := -TAU * float(i) / PROFILE_SIDES
			var x := cos(angle)
			var y := sin(angle)
			ring.append(Vector3(signf(x) * pow(absf(x), power) * section.z,
				section.y + signf(y) * pow(absf(y), power) * section.w, section.x))
		rings.append(ring)
	return Geometry.loft(parent, label, rings, material)


func _fender(wheel: Node3D, radius: float, width: float, material: Material, sweep: float) -> void:
	var sections: Array[Vector4] = []
	for i in range(9):
		var u := float(i) / 8.0
		var angle := lerpf(-sweep, sweep, u)
		var half_width := width * lerpf(0.58, 1.0, sin(PI * u)) * 0.5
		sections.append(Vector4(sin(angle) * radius, cos(angle) * radius,
			half_width, lerpf(0.008, 0.016, sin(PI * u))))
	_profile(wheel, "CurvedMudguard", sections, material)


func _visual_wheel(at: Vector3, tire: Material, rim: Material, front: bool, width: float) -> Node3D:
	var wheel := _add_wheel_at(at, tire, rim, front, wheel_radius, width)
	Geometry.dress_wheel(wheel, wheel_radius, width, tire, rim, _finish(Color("303337"), 0.68), 5)
	remove_child(wheel)
	lean_visual.add_child(wheel)
	return wheel


func _build_handlebars(half_width: float, metal: Material, rubber: Material, glass: Material, sweep := 0.0) -> void:
	_grip_half_width = half_width
	_grip_sweep = sweep
	var switches: Array[Array] = []
	for side: float in [-1.0, 1.0]:
		var inside := Vector3(side * 0.088, -0.032, -0.04)
		var outside := Vector3(side * (half_width - 0.045), 0.0, sweep)
		Geometry.bar(_cockpit, "Handlebar", inside, outside, 0.013, metal)
		Geometry.bar(_cockpit, "RubberGrip", outside, Vector3(side * (half_width + 0.042), 0.0, sweep), 0.018, rubber)
		Geometry.bar(_cockpit, "GripEndCap", Vector3(side * (half_width + 0.031), 0.0, sweep),
			Vector3(side * (half_width + 0.042), 0.0, sweep), 0.0185, metal)
		var control := outside - Vector3(side * 0.019, 0.0, 0.003)
		switches.append([control, Vector3(0.038, 0.039, 0.048)])
		var strain_relief := control + Vector3(-side * 0.043, -0.030, -0.006)
		Geometry.bar(_cockpit, "ControlCable", control - Vector3(0, 0.019, 0), strain_relief, 0.0048, rubber)
		Geometry.bar(_cockpit, "ControlCableReturn", strain_relief,
			Vector3(side * 0.106, -0.089, sweep - 0.087), 0.0048, rubber)
		Geometry.bar(_cockpit, "BrakeLever", outside + Vector3(0, 0.0, -0.025),
			Vector3(side * (half_width + 0.006), 0.003, sweep - 0.047), 0.005, metal)
		var mirror := Vector3(side * (half_width + 0.017), 0.178, -0.047)
		Geometry.bar(_cockpit, "MirrorStem", outside, mirror, 0.0065, metal)
		_round_part(_cockpit, "MirrorHousing", Vector3(0.067, 0.035, 0.018), mirror, rubber)
		_round_part(_cockpit, "MirrorGlass", Vector3(0.060, 0.028, 0.007), mirror + Vector3(0, 0, 0.014), glass)
	Geometry.detail_boxes(_cockpit, "HandlebarSwitchPods", switches, rubber)


func _round_part(parent: Node3D, label: String, radii: Vector3, at: Vector3, material: Material) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	var part := MeshInstance3D.new()
	part.name = label
	part.mesh = mesh
	part.material_override = material
	part.position = at
	part.scale = radii
	parent.add_child(part)


func _finish(color: Color, roughness: float, metallic := 0.0) -> StandardMaterial3D:
	var material := _material(color)
	material.roughness = roughness
	material.metallic = metallic
	return material


func _lens(color: Color, energy: float) -> StandardMaterial3D:
	var material := _finish(color, 0.40)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material
