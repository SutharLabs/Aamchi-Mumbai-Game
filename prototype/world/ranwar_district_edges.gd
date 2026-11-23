extends Node3D
## Collision and safe return for the single loaded Ranwar district.

const EXTENT := Rect2(-108.0, -584.0, 394.0, 678.0)
const MIN_BODY_HEIGHT := -8.0
const GATE_NOTICE_RANGE := 14.0
const ROAD_SIGN_FONT := preload("res://startup/art/NotoSansDevanagari.ttf")
# Connected, mapped continuations from the bundled OSM extract. The work
# barriers are fictional. The current drivable circuit ends at the junctions.
const STUBS := [
	{"name": "Hill Road westbound", "road": 0, "last": false, "width": 14.0,
		"points": [Vector2(72.8260148, 19.0546913), Vector2(72.8254941, 19.0546550)]},
	{"name": "Hill Road eastbound", "road": 0, "last": true, "width": 14.0,
		"points": [Vector2(72.8311525, 19.0552664), Vector2(72.8311922, 19.0552731)]},
	{"name": "Chapel Road", "road": 1, "last": true, "width": 8.0,
		"points": [Vector2(72.8306278, 19.0536914), Vector2(72.8304821, 19.0535767)]},
	{"name": "Bazar Road", "road": 1, "last": true, "width": 8.0,
		"points": [Vector2(72.8310345, 19.0539173), Vector2(72.8314724, 19.0539897)]},
]

var gate_positions := PackedVector3Array()
var _tracked_actor: CharacterBody3D
var _safe_pose := Transform3D(Basis.IDENTITY, Vector3.INF)
var _wall := _material(Color("8a7465"))
var _concrete := _material(Color("b7ada1"))
var _reflector := _material(Color("b8432c"))
var _marking := _material(Color("d9d4c3"))


func configure(roads: Array[PackedVector3Array], project: Callable, asphalt: Material) -> void:
	name = "DistrictEdges"
	_build_perimeter()
	for stub: Dictionary in STUBS:
		var road: PackedVector3Array = roads[stub["road"]]
		var previous := road[-1] if stub["last"] else road[0]
		var direction := Vector3.ZERO
		var width: float = stub["width"]
		for coordinate: Vector2 in stub["points"]:
			var next: Vector3 = project.call(coordinate)
			direction = (next - previous).normalized()
			_add_road_segment(previous, next, width, asphalt)
			previous = next
		_add_road_segment(previous, previous + direction * 15.0, width, asphalt)
		_add_gate(stub["name"], previous, direction, width)


func notice_at(position: Vector3) -> String:
	if not position.is_finite():
		return ""
	for gate: Vector3 in gate_positions:
		if Vector2(gate.x - position.x, gate.z - position.z).length_squared() < GATE_NOTICE_RANGE ** 2:
			return "Road closed. Turn back toward Ranwar."
	if not EXTENT.grow(-5.0).has_point(Vector2(position.x, position.z)):
		return "Ranwar ends here. Follow the streets back."
	return ""


func clear_checkpoint() -> void:
	_tracked_actor = null
	_safe_pose.origin = Vector3.INF


func recovery_pose(actor: CharacterBody3D, fallback: Transform3D) -> Transform3D:
	if actor != _tracked_actor:
		clear_checkpoint()
		_tracked_actor = actor
	var pose := actor.global_transform
	var position := pose.origin
	var plane := Vector2(position.x, position.z)
	if not pose.is_finite() or position.y < MIN_BODY_HEIGHT or not EXTENT.has_point(plane):
		return _safe_pose if _safe_pose.origin.is_finite() else fallback
	if position.y >= -0.1 and (actor.is_on_floor() or (not _safe_pose.origin.is_finite() and position.y <= 0.8)):
		if EXTENT.grow(-1.8).has_point(plane):
			_safe_pose = pose
	return Transform3D(Basis.IDENTITY, Vector3.INF)


func _build_perimeter() -> void:
	var middle := EXTENT.get_center()
	var end := EXTENT.end
	_solid_box(self, "WestCompoundWall", Vector3(EXTENT.position.x, 1.25, middle.y), Vector3(1.0, 2.5, EXTENT.size.y + 1.0), _wall)
	_solid_box(self, "EastCompoundWall", Vector3(end.x, 1.25, middle.y), Vector3(1.0, 2.5, EXTENT.size.y + 1.0), _wall)
	_solid_box(self, "NorthCompoundWall", Vector3(middle.x, 1.25, EXTENT.position.y), Vector3(EXTENT.size.x, 2.5, 1.0), _wall)
	_solid_box(self, "SouthCompoundWall", Vector3(middle.x, 1.25, end.y), Vector3(EXTENT.size.x, 2.5, 1.0), _wall)


func _add_road_segment(from: Vector3, to: Vector3, width: float, asphalt: Material) -> void:
	var delta := to - from
	var direction := delta.normalized()
	var yaw := atan2(direction.x, direction.z)
	var asphalt_position := (from + to) * 0.5 + Vector3(0.0, -0.015, 0.0)
	var strip := _box(self, "RoadContinuation", asphalt_position, Vector3(width, 0.056, delta.length() + 0.08), asphalt)
	strip.rotation.y = yaw
	if width > 10.0:
		for offset: int in range(6, floori(delta.length()) - 2, 8):
			var dash := _box(self, "LaneMarking", from + direction * float(offset) + Vector3.UP * 0.02,
				Vector3(0.13, 0.009, 2.2), _marking)
			dash.rotation.y = yaw


func _add_gate(label: String, position: Vector3, direction: Vector3, width: float) -> void:
	var gate := Node3D.new()
	gate.name = label.to_pascal_case() + "Gate"
	gate.position = position
	gate.rotation.y = atan2(direction.x, direction.z)
	add_child(gate)
	gate_positions.append(position)
	var barrier_width := width + 1.8
	_solid_box(gate, "ConcreteBarrier", Vector3(0.0, 0.65, 0.0), Vector3(barrier_width, 1.3, 0.7))
	var segments := ceili(barrier_width / 2.5)
	var segment_width := barrier_width / float(segments)
	var slabs := PackedVector3Array()
	var caps := PackedVector3Array()
	var stripes := PackedVector3Array()
	for segment in range(segments):
		var offset := (float(segment) + 0.5) * segment_width - barrier_width * 0.5
		slabs.append(Vector3(offset, 0.56, 0.0))
		caps.append(Vector3(offset, 1.19, 0.0))
		stripes.append(Vector3(offset, 0.78, -0.38))
	_box_instances(gate, "ConcreteSegments", slabs, Vector3(segment_width - 0.04, 1.12, 0.75), _concrete)
	_box_instances(gate, "BarrierCaps", caps, Vector3(segment_width - 0.04, 0.16, 0.62), _concrete)
	_box_instances(gate, "ReflectiveStripes", stripes, Vector3(segment_width * 0.65, 0.23, 0.03), _reflector)
	for side: float in [-1.0, 1.0]:
		_box(gate, "SignPost", Vector3(side * 0.76, 1.63, 0.0), Vector3(0.10, 0.72, 0.10), _wall)
	_box(gate, "ClosureSign", Vector3(0.0, 2.02, 0.0), Vector3(2.75, 0.79, 0.16), _reflector)
	var text := Label3D.new()
	text.text = "रस्ता बंद\nROAD CLOSED"
	text.font = ROAD_SIGN_FONT
	text.font_size = 60
	text.pixel_size = 0.004
	text.outline_size = 0
	text.position = Vector3(0.0, 2.02, -0.087)
	text.rotation.y = PI
	gate.add_child(text)


func _solid_box(parent: Node3D, label: String, position: Vector3, size: Vector3, appearance: Material = null) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = position
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	if appearance != null:
		_box(body, "Surface", Vector3.ZERO, size, appearance)


func _box(parent: Node3D, label: String, position: Vector3, size: Vector3, appearance: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = appearance
	instance.mesh = mesh
	parent.add_child(instance)
	return instance


func _box_instances(parent: Node3D, label: String, positions: PackedVector3Array,
		size: Vector3, appearance: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = appearance
	var transforms := MultiMesh.new()
	transforms.transform_format = MultiMesh.TRANSFORM_3D
	transforms.mesh = mesh
	transforms.instance_count = positions.size()
	for index in positions.size():
		transforms.set_instance_transform(index, Transform3D(Basis.IDENTITY, positions[index]))
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = transforms
	parent.add_child(instance)


func _material(color: Color) -> Material:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.95
	return material
