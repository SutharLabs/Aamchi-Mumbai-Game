extends Node3D
## Deterministic traversal blockout, not a surveyed or period-approved Bandra model.
## Modern OSM-derived polylines: see README.md and layout.json beside this script.

const ORIGIN := Vector2(72.8260536, 19.0546940)
const EAST_METERS := 105220.0
const NORTH_METERS := 111320.0
const AXIS_FORWARD := Vector2(0.99347, 0.11401)
const PLAYER_START := Vector3(0.0, 0.5, 5.0)
const VEHICLE_START := Vector3(0.0, 0.55, 0.0)
const ROAD_WIDTHS: Array[float] = [14.0, 10.0, 8.0, 8.0]
const ROAD_NAMES: Array[String] = ["Hill Road", "St Peter's Road", "Waroda Road east", "Waroda Road west"]
const ROAD_SOURCE: Array = [
	[Vector2(72.8260536,19.0546940), Vector2(72.8278068,19.0547279), Vector2(72.8283741,19.0547747), Vector2(72.8294289,19.0549497), Vector2(72.8300536,19.0550739), Vector2(72.8308263,19.0552115)],
	[Vector2(72.8308263,19.0552115), Vector2(72.8307538,19.0546559), Vector2(72.8306910,19.0541219), Vector2(72.8306934,19.0539441), Vector2(72.8307258,19.0537922)],
	[Vector2(72.8307258,19.0537922), Vector2(72.8302674,19.0537625), Vector2(72.8297316,19.0537443), Vector2(72.8293725,19.0538226), Vector2(72.8286970,19.0540686), Vector2(72.8284513,19.0541089)],
	[Vector2(72.8284513,19.0541089), Vector2(72.8275960,19.0541387), Vector2(72.8273395,19.0541344), Vector2(72.8269875,19.0541631), Vector2(72.8266270,19.0542347), Vector2(72.8264071,19.0543412), Vector2(72.8260753,19.0546043), Vector2(72.8260536,19.0546940)]
]
const GULLY_SOURCE: Array[Vector2] = [Vector2(72.8275960,19.0541387), Vector2(72.8276071,19.0542799), Vector2(72.8276677,19.0544493), Vector2(72.8277695,19.0546053), Vector2(72.8278068,19.0547279)]

var _roads: Array[PackedVector3Array] = []
var _gully := PackedVector3Array()
var _lots: Array[Vector3] = []
var _materials: Dictionary = {}


func _ready() -> void:
	_build_materials()
	_box("GroundSurface", Vector3(90,-0.50,-245), Vector3(420,1,700), "ground", false)
	var ground := StaticBody3D.new()
	ground.name = "Ground"
	var floor_shape := CollisionShape3D.new()
	floor_shape.shape = WorldBoundaryShape3D.new()
	ground.add_child(floor_shape)
	add_child(ground)
	for path: Array in ROAD_SOURCE:
		var points := PackedVector3Array()
		for coordinate: Vector2 in path:
			points.append(_project(coordinate))
		_roads.append(points)
	for coordinate: Vector2 in GULLY_SOURCE:
		_gully.append(_project(coordinate))
	_build_roads()
	_build_gully()
	_build_recovery_yard()
	_build_frontages()
	_build_boundary()
	_build_markers()


func _project(coordinate: Vector2) -> Vector3:
	var relative := coordinate - ORIGIN
	var local_meters := Vector2(relative.x * EAST_METERS, relative.y * NORTH_METERS)
	return Vector3(local_meters.x * AXIS_FORWARD.y - local_meters.y * AXIS_FORWARD.x, 0.0, -local_meters.dot(AXIS_FORWARD))


func _build_materials() -> void:
	var colors := {
		"ground": Color("ad9d81"), "asphalt": Color("42484d"),
		"paving": Color("aba699"), "curb": Color("dad1b9"),
		"paint": Color("d3bd78"), "barrier": Color("c9993e"),
		"roof": Color("885d4c"), "dark": Color("28383e"),
		"cream": Color("d9c9a7"), "ochre": Color("bd9f66"),
		"mint": Color("93aba0"), "rose": Color("b58e83"),
		"blue": Color("879da9"), "gully": Color("6a9e98")
	}
	for key: String in colors:
		var material := StandardMaterial3D.new()
		material.albedo_color = colors[key]
		material.roughness = 1.0
		_materials[key] = material


func _box(label: String, at: Vector3, size: Vector3, material_name: String, solid: bool = false, rotation_y: float = 0.0) -> Node3D:
	var root: Node3D
	if solid:
		root = StaticBody3D.new()
	else:
		root = Node3D.new()
	root.name = label
	root.position = at
	root.rotation.y = rotation_y
	add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.material_override = _materials[material_name]
	root.add_child(mesh_instance)
	if solid:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		root.add_child(collision)
	return root


func _strip(label: String, from: Vector3, to: Vector3, width: float, height: float, top: float, material_name: String, solid: bool) -> void:
	var delta := to - from
	var middle := (from + to) * 0.5
	middle.y = top - height * 0.5
	_box(label, middle, Vector3(width,height,delta.length() + 0.12), material_name, solid, atan2(delta.x,delta.z))


func _build_roads() -> void:
	for road_index in range(_roads.size()):
		var points: PackedVector3Array = _roads[road_index]
		var width: float = ROAD_WIDTHS[road_index]
		for index in range(points.size() - 1):
			var from: Vector3 = points[index]
			var to: Vector3 = points[index + 1]
			var length := from.distance_to(to)
			var along := (to-from).normalized()
			var across := Vector3(-along.z,0.0,along.x)
			# Keep a single collision floor under the road to avoid catching on mesh seams.
			_strip("Road",from,to,width,0.03,0.015,"asphalt",false)
			if length > 20.0:
				# End curb runs before the intersection pads and gully mouths.
				var sidewalk_start := from + along * 9.0
				var sidewalk_end := to - along * 9.0
				for side: float in [-1.0,1.0]:
					var offset := across * side * (width*0.5+1.15)
					var midpoint := (sidewalk_start+sidewalk_end) * 0.5 + offset
					if _distance_to_path(midpoint,_gully) < (length-18.0)*0.5+2.0:
						continue
					_strip("Sidewalk",sidewalk_start+offset,sidewalk_end+offset,2.3,0.12,0.12,"paving",true)
					var edge := across * side * (width*0.5+0.12)
					_strip("Curb",sidewalk_start+edge,sidewalk_end+edge,0.22,0.14,0.14,"curb",true)
			if width >= 10.0:
				var distance := 5.0
				while distance < length-4.0:
					_strip("CenterDash",from+along*distance,from+along*minf(distance+3.0,length),0.14,0.008,0.024,"paint",false)
					distance += 10.0
		# Junction pads cover small polyline corner gaps without a navigation mesh.
		for point: Vector3 in points:
			_box("Junction",point+Vector3(0,-0.004,0),Vector3(width,0.032,width),"asphalt",false)


func _build_gully() -> void:
	for index in range(_gully.size()-1):
		_strip("NagranaFootway",_gully[index],_gully[index+1],2.4,0.03,0.025,"gully",false)
		var direction: Vector3 = (_gully[index+1]-_gully[index]).normalized()
		var across := Vector3(-direction.z,0,direction.x)
		var distance := 0.0
		var length: float = _gully[index].distance_to(_gully[index+1])
		while distance < length:
			var part_end := minf(distance+2.0,length)
			var midpoint := _gully[index]+direction*(distance+part_end)*0.5
			# Clip walls out of the driving carriageways at both mouths.
			if _outside_carriageway(midpoint,2.0):
				for side: float in [-1.0,1.0]:
					_strip("GullyWall",_gully[index]+direction*distance+across*side*1.55,_gully[index]+direction*part_end+across*side*1.55,0.35,1.4,1.4,"cream",true)
			distance = part_end
	# Physical filters reinforce the on-foot-only route; clear gap is 1.1 m.
	for endpoint: int in [0,_gully.size()-1]:
		var point: Vector3 = _gully[endpoint]
		var inside: Vector3 = _gully[1] if endpoint == 0 else _gully[_gully.size()-2]
		var direction := (inside-point).normalized()
		var across := Vector3(-direction.z,0,direction.x)
		var inset := 7.0 if endpoint == 0 else 10.0
		for side: float in [-1.0,1.0]:
			_box("FootwayBollard",point+direction*inset+across*side*0.7+Vector3(0,0.5,0),Vector3(0.3,1.0,0.3),"barrier",true)


func _build_recovery_yard() -> void:
	_box("RecoveryYard",Vector3(-28,-0.015,-32),Vector3(48,0.05,82),"asphalt",false)
	# Separate handling ramp: 1.2 m rise over 15 m, deck, and matching descent.
	var ramp_angle := atan2(1.2,15.0)
	var ramp_up := _box("SlopeUp",Vector3(-31,0.52,-35.5),Vector3(7,0.16,sqrt(226.44)),"paving",true)
	ramp_up.rotation.x = ramp_angle
	_box("SlopeDeck",Vector3(-31,1.12,-47),Vector3(7,0.16,8),"paving",true)
	var ramp_down := _box("SlopeDown",Vector3(-31,0.52,-58.5),Vector3(7,0.16,sqrt(226.44)),"paving",true)
	ramp_down.rotation.x = -ramp_angle
	_box("ImpactWall",Vector3(-50,0.7,-68),Vector3(7,1.4,0.8),"barrier",true)
	_box("CurbTest",Vector3(-11,0.11,-45),Vector3(0.4,0.22,8),"curb",true)
	_label("HANDLING YARD",Vector3(-31,3,-10))
	_label("SLOPE / CURB / RECOVERY",Vector3(-31,3,-26))


func _distance_to_path(point: Vector3, path: PackedVector3Array) -> float:
	var result := INF
	for index in range(path.size()-1):
		result = minf(result,point.distance_to(Geometry3D.get_closest_point_to_segment(point,path[index],path[index+1])))
	return result


func _outside_carriageway(point: Vector3, margin: float) -> bool:
	for road_index in range(_roads.size()):
		if _distance_to_path(point,_roads[road_index]) < ROAD_WIDTHS[road_index]*0.5+margin:
			return false
	return true


func _is_free_lot(point: Vector3, radius: float) -> bool:
	if point.x < 5.0 and point.z > -85.0:
		return false
	for road_index in range(_roads.size()):
		if _distance_to_path(point,_roads[road_index]) < ROAD_WIDTHS[road_index]*0.5+radius+2.5:
			return false
	if _distance_to_path(point,_gully) < radius+4.0:
		return false
	for existing: Vector3 in _lots:
		if existing.distance_to(point) < radius+10.0:
			return false
	return true


func _build_frontages() -> void:
	var palette: Array[String] = ["cream","ochre","mint","rose","blue"]
	var building_count := 0
	for road_index in range(_roads.size()):
		var points: PackedVector3Array = _roads[road_index]
		for index in range(points.size()-1):
			var from: Vector3 = points[index]
			var to: Vector3 = points[index+1]
			var along := (to-from).normalized()
			var across := Vector3(-along.z,0,along.x)
			var distance := 12.0
			while distance < from.distance_to(to)-7.0:
				for side: float in [-1.0,1.0]:
					var point := from+along*distance+across*side*(ROAD_WIDTHS[road_index]*0.5+13.0)
					if not _is_free_lot(point,8.0):
						continue
					_lots.append(point)
					var tall: bool = road_index == 0 and building_count % 3 == 0
					var height := 11.0 if tall else 5.5+float(building_count%3)*1.5
					var angle := atan2(along.x,along.z)
					_box("Frontage",point+Vector3(0,height*0.5,0),Vector3(12,height,13),palette[building_count%palette.size()],true,angle)
					_box("RoofCap",point+Vector3(0,height+0.15,0),Vector3(12.6,0.3,13.6),"roof",false,angle)
					var facing := point-across*side*6.15
					_box("Porch",facing+Vector3(0,2.1,0),Vector3(9,0.18,2.4),"dark",false,angle)
					building_count += 1
				distance += 24.0


func _build_boundary() -> void:
	_box("WestBoundary",Vector3(-108,1.2,-245),Vector3(1,2.4,680),"dark",true)
	_box("EastBoundary",Vector3(286,1.2,-245),Vector3(1,2.4,680),"dark",true)
	_box("NorthBoundary",Vector3(90,1.2,-584),Vector3(394,2.4,1),"dark",true)
	_box("SouthBoundary",Vector3(90,1.2,94),Vector3(394,2.4,1),"dark",true)


func _label(text: String, at: Vector3) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = 48
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = false
	label.modulate = Color("fff1c9")
	label.outline_modulate = Color("243138")
	label.outline_size = 10
	add_child(label)


func _build_markers() -> void:
	var names: Array[String] = ["A  HILL / WARODA", "B  ST PETER'S APPROACH", "C  CHAPEL / WARODA", "D  VERONICA APPROACH"]
	for index in range(_roads.size()):
		var offset := Vector3(0,3.5,0) if index > 0 else Vector3(4.0,2.7,-16.0)
		_label(names[index],_roads[index][0]+offset)
	_label("NAGRANA: ON FOOT",_gully[0]+Vector3(0,3,0))
	_label("NAGRANA: ON FOOT",_gully[_gully.size()-1]+Vector3(0,3,0))
