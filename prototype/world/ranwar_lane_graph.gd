extends RefCounted
## Directed traffic lanes derived from the same projected centerlines as the road mesh.

const FORWARD := 1
const REVERSE := 2
const BOTH := FORWARD | REVERSE
const TURN_STEPS := 8


class Lane:
	var road_index: int
	var from_junction: Vector3
	var to_junction: Vector3
	var points: PackedVector3Array
	var successors: Array[int] = []


var _lanes: Array[Lane] = []


func _init(roads: Array[PackedVector3Array], widths: Array[float], directions: Array[int]) -> void:
	assert(roads.size() == widths.size() and roads.size() == directions.size())
	_lanes.resize(roads.size() * 2)
	for road_index in range(roads.size()):
		var centerline := roads[road_index]
		assert(centerline.size() >= 2 and widths[road_index] > 0.0)
		if directions[road_index] & FORWARD:
			_lanes[road_index * 2] = _build_lane(road_index, centerline, widths[road_index])
		if directions[road_index] & REVERSE:
			var reversed := centerline.duplicate()
			reversed.reverse()
			_lanes[road_index * 2 + 1] = _build_lane(road_index, reversed, widths[road_index])
	for lane: Lane in _lanes:
		if lane == null:
			continue
		for next_id in range(_lanes.size()):
			var next_lane := _lanes[next_id]
			if next_lane != null and next_lane.road_index != lane.road_index \
					and lane.to_junction.is_equal_approx(next_lane.from_junction):
				lane.successors.append(next_id)


## Returns a closed left-hand route or an empty array if the requested start has no circuit.
func loop_for_road(road_index: int, reverse: bool = true) -> PackedVector3Array:
	if road_index < 0 or road_index >= _lanes.size() / 2:
		return PackedVector3Array()
	var start := road_index * 2 + int(reverse)
	if _lanes[start] == null:
		return PackedVector3Array()
	var cycle: Array[int] = [start]
	if not _find_cycle(start, start, cycle):
		return PackedVector3Array()

	var route := PackedVector3Array()
	for index in range(cycle.size()):
		var lane := _lanes[cycle[index]]
		var next_lane := _lanes[cycle[(index + 1) % cycle.size()]]
		route.append_array(lane.points)
		_append_turn(route, lane.points, next_lane.points)
	route.append(route[0])
	return route


func _find_cycle(current: int, start: int, path: Array[int]) -> bool:
	for next_id: int in _lanes[current].successors:
		if next_id == start:
			return true
		if next_id in path:
			continue
		path.append(next_id)
		if _find_cycle(next_id, start, path):
			return true
		path.pop_back()
	return false


func _build_lane(road_index: int, centerline: PackedVector3Array, width: float) -> Lane:
	var lane := Lane.new()
	lane.road_index = road_index
	lane.from_junction = centerline[0]
	lane.to_junction = centerline[-1]
	var offset := width * 0.25
	var first_delta := centerline[1] - centerline[0]
	var first_direction := first_delta.normalized()
	var start_inset := minf(width * 0.4, first_delta.length() * 0.25)
	lane.points.append(centerline[0] + first_direction * start_inset + Vector3.UP.cross(first_direction) * offset)
	for index in range(1, centerline.size() - 1):
		var incoming := (centerline[index] - centerline[index - 1]).normalized()
		var outgoing := (centerline[index + 1] - centerline[index]).normalized()
		var left_in := Vector3.UP.cross(incoming)
		var left_out := Vector3.UP.cross(outgoing)
		var across := (left_in + left_out).normalized()
		# Limit the miter so a tight bend stays on the authored carriageway.
		var miter := offset / maxf(0.7, across.dot(left_in))
		lane.points.append(centerline[index] + across * miter)
	var last_delta := centerline[-1] - centerline[-2]
	var last_direction := last_delta.normalized()
	var end_inset := minf(width * 0.4, last_delta.length() * 0.25)
	lane.points.append(centerline[-1] - last_direction * end_inset + Vector3.UP.cross(last_direction) * offset)
	return lane


func _append_turn(route: PackedVector3Array, incoming: PackedVector3Array, outgoing: PackedVector3Array) -> void:
	var start := incoming[-1]
	var end := outgoing[0]
	var span := start.distance_to(end) * 0.4
	var start_handle := start + (start - incoming[-2]).normalized() * span
	var end_handle := end - (outgoing[1] - end).normalized() * span
	for step in range(1, TURN_STEPS):
		route.append(start.bezier_interpolate(start_handle, end_handle, end, float(step) / TURN_STEPS))
